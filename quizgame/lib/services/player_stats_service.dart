import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_stats.dart';
import '../models/game.dart';

class PlayerStatsService {
  final _firestore = FirebaseFirestore.instance;

  /// Collection reference for player stats
  CollectionReference<Map<String, dynamic>> get _statsCollection =>
      _firestore.collection('player_stats');

  /// Get player stats for a specific user
  Future<PlayerStats> getPlayerStats(String odbc) async {
    final doc = await _statsCollection.doc(odbc).get();
    if (!doc.exists) {
      // Return default stats if none exist
      return PlayerStats(odbc: odbc);
    }
    return PlayerStats.fromFirestore(doc);
  }

  /// Stream player stats for real-time updates
  Stream<PlayerStats> watchPlayerStats(String odbc) {
    return _statsCollection.doc(odbc).snapshots().map((doc) {
      // Always return a PlayerStats object, even if document doesn't exist
      if (!doc.exists || doc.data() == null) {
        return PlayerStats(odbc: odbc);
      }
      return PlayerStats.fromFirestore(doc);
    });
  }

  /// Record game results for all players in a game
  /// Should be called when a game ends
  Future<void> recordGameResults({
    required Game game,
    required List<PlayerScore> leaderboard,
    required List<String> categories,
  }) async {
    if (leaderboard.isEmpty) return;

    final batch = _firestore.batch();
    final winnerUid = leaderboard.first.odbc;

    for (final playerScore in leaderboard) {
      final statsRef = _statsCollection.doc(playerScore.odbc);
      final currentStats = await getPlayerStats(playerScore.odbc);

      // Update category stats
      final updatedCategoryStats = Map<String, int>.from(currentStats.categoryStats);
      for (final category in categories) {
        updatedCategoryStats[category] = (updatedCategoryStats[category] ?? 0) + 1;
      }

      final isWinner = playerScore.odbc == winnerUid;

      final updatedStats = currentStats.copyWith(
        totalGamesPlayed: currentStats.totalGamesPlayed + 1,
        totalWins: currentStats.totalWins + (isWinner ? 1 : 0),
        totalPoints: currentStats.totalPoints + playerScore.score,
        categoryStats: updatedCategoryStats,
        lastPlayedAt: DateTime.now(),
      );

      batch.set(statsRef, updatedStats.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Increment a single stat field atomically
  Future<void> incrementStat({
    required String odbc,
    required String field,
    int incrementBy = 1,
  }) async {
    await _statsCollection.doc(odbc).set({
      field: FieldValue.increment(incrementBy),
    }, SetOptions(merge: true));
  }

  /// Get top players by total points (for global leaderboard)
  Future<List<PlayerStats>> getTopPlayersByPoints({int limit = 10}) async {
    final query = await _statsCollection
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => PlayerStats.fromFirestore(doc)).toList();
  }

  /// Get top players by total wins
  Future<List<PlayerStats>> getTopPlayersByWins({int limit = 10}) async {
    final query = await _statsCollection
        .orderBy('totalWins', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => PlayerStats.fromFirestore(doc)).toList();
  }

  /// Get top players by average score
  /// Note: This requires fetching all and sorting client-side since avgScore is computed
  Future<List<PlayerStats>> getTopPlayersByAvgScore({int limit = 10}) async {
    // First get players with at least 1 game
    final query = await _statsCollection
        .where('totalGamesPlayed', isGreaterThan: 0)
        .limit(100) // Limit initial fetch
        .get();

    final stats = query.docs.map((doc) => PlayerStats.fromFirestore(doc)).toList();
    
    // Sort by average score
    stats.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    
    return stats.take(limit).toList();
  }

  /// Reset player stats (for testing or user request)
  Future<void> resetPlayerStats(String odbc) async {
    await _statsCollection.doc(odbc).delete();
  }
}
