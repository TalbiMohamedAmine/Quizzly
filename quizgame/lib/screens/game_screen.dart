import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game.dart';
import '../models/question.dart';
import '../services/game_service.dart';
import 'leaderboard_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final String roomId;

  const GameScreen({super.key, required this.gameId, required this.roomId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final _gameService = GameService();
  late final AnimationController _timerController;
  late final AnimationController _countdownController;

  int? _selectedOption;
  bool _hasAnswered = false;
  int _countdownValue = 5;
  Timer? _countdownTimer;
  Timer? _roundTimer;
  int _timeRemaining = 0;
  DateTime? _questionStartTime;
  bool _countdownStarted = false;
  String? _lastGameState;
  Game? _cachedGame;
  bool _isAutoAdvancing = false; // Prevents multiple auto-advance triggers

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(vsync: this);
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    _roundTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _countdownValue = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdownValue--;
      });

      if (_countdownValue <= 0) {
        timer.cancel();
      }
    });
  }

  void _startRoundTimer(int totalSeconds) {
    _roundTimer?.cancel();
    _questionStartTime = DateTime.now();

    setState(() {
      _timeRemaining = totalSeconds;
      _selectedOption = null;
      _hasAnswered = false;
    });

    _timerController.duration = Duration(seconds: totalSeconds);
    _timerController.forward(from: 0);

    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        timer.cancel();
        // Time's up - auto submit if not answered
        if (!_hasAnswered) {
          _submitTimeUp();
        }
        // Auto advance to reviewing when timer ends (host triggers it)
        _autoAdvanceRound();
      }
    });
  }

  void _submitTimeUp() {
    // Player didn't answer in time
    setState(() {
      _hasAnswered = true;
    });
  }

  /// Automatically advance the round - called when timer ends or all players answered
  Future<void> _autoAdvanceRound() async {
    if (_isAutoAdvancing) return;

    final user = FirebaseAuth.instance.currentUser;
    final game = _cachedGame;
    if (user == null || game == null) return;

    // Only the host can advance the round
    if (user.uid != game.hostId) return;

    // Only advance if we're still in playing state
    if (game.state != 'playing') return;

    _isAutoAdvancing = true;

    try {
      // End the current round (show correct answers briefly)
      await _gameService.endRound(gameId: widget.gameId);

      // Wait a moment for players to see the correct answer
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Check if it's the last round
      if (game.isLastRound) {
        await _gameService.showResults(gameId: widget.gameId);
      } else {
        await _gameService.nextRound(gameId: widget.gameId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error advancing round: $e')));
      }
    } finally {
      _isAutoAdvancing = false;
    }
  }

  /// Check if all players have answered and auto-advance if so
  void _checkAllPlayersAnswered(Game game) {
    if (_isAutoAdvancing) return;
    if (game.state != 'playing') return;

    final currentRoundAnswers = game.roundAnswers[game.currentRound] ?? [];
    final totalPlayers = game.playerScores.length;

    if (currentRoundAnswers.length >= totalPlayers && totalPlayers > 0) {
      // All players have answered - auto advance
      _autoAdvanceRound();
    }
  }

  Future<void> _submitAnswer(Game game, int optionIndex) async {
    if (_hasAnswered) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _selectedOption = optionIndex;
      _hasAnswered = true;
    });

    // Calculate time taken
    final timeToAnswer = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inSeconds
        : game.tourTime;

    try {
      await _gameService.submitAnswer(
        gameId: widget.gameId,
        odbc: user.uid,
        selectedOption: optionIndex,
        timeToAnswer: timeToAnswer,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting answer: $e')));
      }
    }
  }

  Future<void> _hostNextRound() async {
    try {
      await _gameService.nextRound(gameId: widget.gameId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _hostStartRound() async {
    try {
      await _gameService.startRound(gameId: widget.gameId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _hostEndRound() async {
    try {
      await _gameService.endRound(gameId: widget.gameId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _hostShowResults() async {
    try {
      await _gameService.showResults(gameId: widget.gameId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF05396B),
      body: StreamBuilder<Game>(
        stream: _gameService.watchGame(widget.gameId),
        builder: (context, snapshot) {
          // Only show loading on initial load, not on every update
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cachedGame == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading game...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData && _cachedGame == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Game not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Lobby'),
                  ),
                ],
              ),
            );
          }

          // Use new data if available, otherwise use cached
          final game = snapshot.data ?? _cachedGame!;
          _cachedGame = game;

          final isHost = currentUser?.uid == game.hostId;

          // Reset states when game state changes
          if (_lastGameState != game.state) {
            if (game.state == 'playing' && _lastGameState == 'countdown') {
              // Reset for new round
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _countdownStarted = false;
                _questionStartTime = null;
                _hasAnswered = false;
                _selectedOption = null;
                _isAutoAdvancing = false;
              });
            } else if (game.state == 'playing' &&
                _lastGameState == 'reviewing') {
              // Reset for next round after reviewing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _countdownStarted = false;
                _questionStartTime = null;
                _hasAnswered = false;
                _selectedOption = null;
                _isAutoAdvancing = false;
              });
            } else if (game.state == 'countdown') {
              // Reset countdown state
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _countdownStarted = false;
              });
            }
            _lastGameState = game.state;
          }

          return SafeArea(
            child: _buildGameContent(game, isHost, currentUser?.uid),
          );
        },
      ),
    );
  }

  Widget _buildGameContent(Game game, bool isHost, String? currentUserId) {
    switch (game.state) {
      case 'generating':
        return _buildGeneratingScreen();
      case 'countdown':
        return _buildCountdownScreen(game);
      case 'playing':
        return _buildPlayingScreen(game, isHost, currentUserId);
      case 'reviewing':
        return _buildReviewingScreen(game, isHost, currentUserId);
      case 'results':
      case 'finished':
        // Navigate to the standalone leaderboard screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LeaderboardScreen(
                  leaderboard: _gameService.getLeaderboard(game),
                  roomId: widget.roomId,
                ),
              ),
            );
          }
        });
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
        );
      default:
        return _buildPlayingScreen(game, isHost, currentUserId);
    }
  }

  Widget _buildGeneratingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF22D3EE), strokeWidth: 4),
          SizedBox(height: 24),
          Text(
            'Generating Questions...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'AI is crafting unique questions for your game',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownScreen(Game game) {
    final isHost = FirebaseAuth.instance.currentUser?.uid == game.hostId;

    // Start countdown timer only once
    if (!_countdownStarted) {
      _countdownStarted = true;
      _countdownValue = 5;

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _countdownValue--;
        });

        if (_countdownValue <= 0) {
          timer.cancel();
          // Host triggers the state change to 'playing'
          if (isHost) {
            _hostStartRound();
          }
        }
      });
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Get Ready!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22D3EE), width: 4),
              color: const Color(0xFF0E5F88),
            ),
            child: Center(
              child: Text(
                '${_countdownValue > 0 ? _countdownValue : 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Round ${game.currentRound + 1} of ${game.totalRounds}',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayingScreen(Game game, bool isHost, String? currentUserId) {
    final question = game.currentQuestion;
    if (question == null) {
      return const Center(
        child: Text(
          'No question available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Start timer if not started
    if (_questionStartTime == null && game.state == 'playing') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRoundTimer(game.tourTime);
      });
    }

    // Check if current user already answered
    final currentRoundAnswers = game.roundAnswers[game.currentRound] ?? [];
    final userAnswer = currentRoundAnswers
        .where((a) => a.odbc == currentUserId)
        .firstOrNull;
    if (userAnswer != null && !_hasAnswered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _hasAnswered = true;
          _selectedOption = userAnswer.selectedOption;
        });
      });
    }

    // Check if all players have answered (host will auto-advance)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllPlayersAnswered(game);
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with round info and timer
          _buildGameHeader(game),
          const SizedBox(height: 24),

          // Question card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuestionCard(question),
                  const SizedBox(height: 24),

                  // Answer options
                  ...List.generate(question.options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionButton(
                        game: game,
                        question: question,
                        index: index,
                        isSelected: _selectedOption == index,
                        hasAnswered: _hasAnswered,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Host controls
          if (isHost) _buildHostControls(game),

          // Player count who answered
          _buildAnswerProgress(game, currentRoundAnswers.length),
        ],
      ),
    );
  }

  Widget _buildGameHeader(Game game) {
    final progress = _timeRemaining / game.tourTime;

    return Row(
      children: [
        // Round indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0E5F88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF22D3EE), width: 2),
          ),
          child: Text(
            'Round ${game.currentRound + 1}/${game.totalRounds}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Spacer(),

        // Timer
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _timeRemaining <= 5 ? Colors.red : const Color(0xFF22D3EE),
              width: 4,
            ),
            color: const Color(0xFF0E5F88),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeRemaining <= 5 ? Colors.red : const Color(0xFF2DD4BF),
                ),
                strokeWidth: 6,
              ),
              Text(
                '$_timeRemaining',
                style: TextStyle(
                  color: _timeRemaining <= 5 ? Colors.red : Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0E5F88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
      ),
      child: Column(
        children: [
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.category,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Question text
          Text(
            question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required Game game,
    required Question question,
    required int index,
    required bool isSelected,
    required bool hasAnswered,
  }) {
    final optionLabels = ['A', 'B', 'C', 'D'];
    final isCorrect = index == question.correctAnswerIndex;

    Color backgroundColor;
    Color borderColor;

    if (hasAnswered && game.state == 'reviewing') {
      if (isCorrect) {
        backgroundColor = Colors.green.shade700;
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.red.shade700;
        borderColor = Colors.red;
      } else {
        backgroundColor = const Color(0xFF0E5F88);
        borderColor = Colors.white24;
      }
    } else if (isSelected) {
      backgroundColor = const Color(0xFF6366F1);
      borderColor = const Color(0xFF22D3EE);
    } else {
      backgroundColor = const Color(0xFF0E5F88);
      borderColor = Colors.white24;
    }

    return GestureDetector(
      onTap: hasAnswered ? null : () => _submitAnswer(game, index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white24 : const Color(0xFF05396B),
              ),
              child: Center(
                child: Text(
                  optionLabels[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                question.options[index],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (hasAnswered && game.state == 'reviewing')
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : (isSelected ? Icons.cancel : null),
                color: isCorrect
                    ? Colors.green
                    : (isSelected ? Colors.red : null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostControls(Game game) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (game.state == 'playing')
            Expanded(
              child: ElevatedButton(
                onPressed: _hostEndRound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9A223),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('End Round'),
              ),
            ),
          if (game.state == 'reviewing') ...[
            Expanded(
              child: ElevatedButton(
                onPressed: game.isLastRound ? _hostShowResults : _hostNextRound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(game.isLastRound ? 'Show Results' : 'Next Round'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerProgress(Game game, int answeredCount) {
    final totalPlayers = game.playerScores.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E5F88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            '$answeredCount/$totalPlayers answered',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewingScreen(Game game, bool isHost, String? currentUserId) {
    // Reset timer state when reviewing
    if (_questionStartTime != null) {
      _roundTimer?.cancel();
      _questionStartTime = null;
    }

    return _buildPlayingScreen(game, isHost, currentUserId);
  }
}