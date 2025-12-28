import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/question.dart';
import '../models/room.dart';
import 'question_generator_service.dart';

class GameService {
  final _firestore = FirebaseFirestore.instance;
  final _questionGenerator = QuestionGeneratorService();

  /// Starts a new game for the given room
  /// Generates questions using AI and creates the game document
  Future<Game> startGame({
    required Room room,
  }) async {
    // First, update room state to 'starting'
    await _firestore.collection('rooms').doc(room.id).update({
      'state': 'starting',
    });

    try {
      // Generate questions using AI
      final questions = await _questionGenerator.generateQuestions(
        categories: room.selectedCategories,
        totalQuestions: room.numberOfRounds,
      );

      // Initialize player scores
      final playerScores = <String, PlayerScore>{};
      for (final player in room.players) {
        final uid = player['uid'] as String;
        
        // Skip host if regulator setting is enabled
        if (room.regulatorSetting && uid == room.hostId) {
          continue;
        }
        
        playerScores[uid] = PlayerScore(
          odbc: uid,
          name: player['name'] as String? ?? 'Player',
          avatar: player['avatar'] as String?,
        );
      }

      // Create game document
      final gameRef = _firestore.collection('games').doc();
      final game = Game(
        id: gameRef.id,
        roomId: room.id,
        hostId: room.hostId,
        questions: questions,
        currentRound: 0,
        totalRounds: room.numberOfRounds,
        tourTime: room.tourTime,
        state: 'countdown', // Show countdown before first question
        playerScores: playerScores,
        roundAnswers: {},
        roundStartTime: DateTime.now().add(const Duration(seconds: 5)), // 5 second countdown
        createdAt: DateTime.now(),
      );

      await gameRef.set(game.toFirestore());

      // Update room with game reference and state
      await _firestore.collection('rooms').doc(room.id).update({
        'state': 'playing',
        'gameId': gameRef.id,
      });

      return game;
    } catch (e) {
      // Revert room state on error
      await _firestore.collection('rooms').doc(room.id).update({
        'state': 'waiting',
      });
      rethrow;
    }
  }

  /// Watch game updates
  Stream<Game> watchGame(String gameId) {
    return _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .map((doc) => Game.fromFirestore(doc));
  }

  /// Submit a player's answer for the current round
  Future<void> submitAnswer({
    required String gameId,
    required String odbc,
    required int selectedOption,
    required int timeToAnswer,
  }) async {
    final gameRef = _firestore.collection('games').doc(gameId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(gameRef);
      if (!snap.exists) throw Exception('Game not found');

      final game = Game.fromFirestore(snap);
      
      if (game.state != 'playing') {
        throw Exception('Cannot submit answer when game is not playing');
      }

      final currentQuestion = game.currentQuestion;
      if (currentQuestion == null) {
        throw Exception('No current question');
      }

      // Check if player already answered this round
      final currentRoundAnswers = game.roundAnswers[game.currentRound] ?? [];
      if (currentRoundAnswers.any((a) => a.odbc == odbc)) {
        return; // Already answered
      }

      // Calculate if answer is correct
      final isCorrect = selectedOption == currentQuestion.correctAnswerIndex;

      // Create answer record
      final answer = RoundAnswer(
        odbc: odbc,
        selectedOption: selectedOption,
        timeToAnswer: timeToAnswer,
        isCorrect: isCorrect,
      );

      // Update round answers
      final updatedRoundAnswers = Map<int, List<RoundAnswer>>.from(game.roundAnswers);
      updatedRoundAnswers[game.currentRound] = [...currentRoundAnswers, answer];

      // Update player score
      final updatedScores = Map<String, PlayerScore>.from(game.playerScores);
      if (updatedScores.containsKey(odbc)) {
        final currentScore = updatedScores[odbc]!;
        final pointsEarned = isCorrect ? _calculatePoints(timeToAnswer, game.tourTime) : 0;
        
        updatedScores[odbc] = currentScore.copyWith(
          score: currentScore.score + pointsEarned,
          correctAnswers: currentScore.correctAnswers + (isCorrect ? 1 : 0),
          totalAnswered: currentScore.totalAnswered + 1,
          answerTimes: [...currentScore.answerTimes, timeToAnswer],
        );
      }

      // Update game document
      tx.update(gameRef, {
        'roundAnswers': updatedRoundAnswers.map(
          (k, v) => MapEntry(k.toString(), v.map((a) => a.toMap()).toList()),
        ),
        'playerScores': updatedScores.map((k, v) => MapEntry(k, v.toMap())),
      });
    });
  }

  /// Calculate points based on answer time
  /// Faster answers get more points
  int _calculatePoints(int timeToAnswer, int maxTime) {
    // Base points: 1000
    // Bonus for speed: up to 500 extra points
    const basePoints = 1000;
    const maxBonusPoints = 500;
    
    final timeRatio = 1 - (timeToAnswer / maxTime);
    final bonus = (maxBonusPoints * timeRatio).round();
    
    return basePoints + bonus;
  }

  /// Advance to the next round (host only)
  Future<void> nextRound({required String gameId}) async {
    final gameRef = _firestore.collection('games').doc(gameId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(gameRef);
      if (!snap.exists) throw Exception('Game not found');

      final game = Game.fromFirestore(snap);
      
      if (game.currentRound >= game.totalRounds - 1) {
        // Game is finished
        tx.update(gameRef, {
          'state': 'finished',
          'currentRound': game.currentRound,
        });
        
        // Update room state
        tx.update(_firestore.collection('rooms').doc(game.roomId), {
          'state': 'finished',
        });
      } else {
        // Move to next round
        tx.update(gameRef, {
          'currentRound': game.currentRound + 1,
          'state': 'playing',
          'roundStartTime': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  /// Start the current round (transition from countdown/reviewing to playing)
  Future<void> startRound({required String gameId}) async {
    final gameRef = _firestore.collection('games').doc(gameId);

    await gameRef.update({
      'state': 'playing',
      'roundStartTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// End the current round (transition to reviewing answers)
  Future<void> endRound({required String gameId}) async {
    final gameRef = _firestore.collection('games').doc(gameId);

    await gameRef.update({
      'state': 'reviewing',
    });
  }

  /// Show final results
  Future<void> showResults({required String gameId}) async {
    final gameRef = _firestore.collection('games').doc(gameId);

    await gameRef.update({
      'state': 'results',
    });
  }

  /// End the game and clean up
  Future<void> endGame({required String gameId, required String roomId}) async {
    await _firestore.collection('games').doc(gameId).update({
      'state': 'finished',
    });

    await _firestore.collection('rooms').doc(roomId).update({
      'state': 'finished',
    });
  }

  /// Get sorted leaderboard
  List<PlayerScore> getLeaderboard(Game game) {
    final scores = game.playerScores.values.toList();
    scores.sort((a, b) {
      // First by score (descending)
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      
      // Then by correct answers (descending)
      final correctCompare = b.correctAnswers.compareTo(a.correctAnswers);
      if (correctCompare != 0) return correctCompare;
      
      // Then by average time (ascending - faster is better)
      final aAvgTime = a.answerTimes.isEmpty ? 0 : a.answerTimes.reduce((x, y) => x + y) / a.answerTimes.length;
      final bAvgTime = b.answerTimes.isEmpty ? 0 : b.answerTimes.reduce((x, y) => x + y) / b.answerTimes.length;
      return aAvgTime.compareTo(bAvgTime);
    });
    
    return scores;
  }
}
