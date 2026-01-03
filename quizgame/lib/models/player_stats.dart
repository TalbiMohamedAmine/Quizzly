import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerStats {
  final String odbc; // User ID
  final int totalGamesPlayed;
  final int totalWins;
  final int totalPoints;
  final Map<String, int> categoryStats; // Map of category name to games played in that category
  final DateTime? lastPlayedAt;
  final DateTime createdAt;

  PlayerStats({
    required this.odbc,
    this.totalGamesPlayed = 0,
    this.totalWins = 0,
    this.totalPoints = 0,
    this.categoryStats = const {},
    this.lastPlayedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate average score per game
  double get avgScore {
    if (totalGamesPlayed == 0) return 0.0;
    return totalPoints / totalGamesPlayed;
  }

  /// Get the favorite category (most played)
  String? get favoriteCategory {
    if (categoryStats.isEmpty) return null;
    
    String? favorite;
    int maxCount = 0;
    
    categoryStats.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        favorite = category;
      }
    });
    
    return favorite;
  }

  /// Get win rate as a percentage
  double get winRate {
    if (totalGamesPlayed == 0) return 0.0;
    return (totalWins / totalGamesPlayed) * 100;
  }

  factory PlayerStats.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return PlayerStats(odbc: doc.id);
    }
    
    return PlayerStats(
      odbc: doc.id,
      totalGamesPlayed: data['totalGamesPlayed'] as int? ?? 0,
      totalWins: data['totalWins'] as int? ?? 0,
      totalPoints: data['totalPoints'] as int? ?? 0,
      categoryStats: Map<String, int>.from(data['categoryStats'] ?? {}),
      lastPlayedAt: data['lastPlayedAt'] != null 
          ? (data['lastPlayedAt'] as Timestamp).toDate() 
          : null,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'totalGamesPlayed': totalGamesPlayed,
    'totalWins': totalWins,
    'totalPoints': totalPoints,
    'categoryStats': categoryStats,
    'lastPlayedAt': lastPlayedAt != null ? Timestamp.fromDate(lastPlayedAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  PlayerStats copyWith({
    int? totalGamesPlayed,
    int? totalWins,
    int? totalPoints,
    Map<String, int>? categoryStats,
    DateTime? lastPlayedAt,
  }) {
    return PlayerStats(
      odbc: odbc,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      totalPoints: totalPoints ?? this.totalPoints,
      categoryStats: categoryStats ?? this.categoryStats,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt,
    );
  }

  @override
  String toString() {
    return 'PlayerStats(odbc: $odbc, games: $totalGamesPlayed, wins: $totalWins, points: $totalPoints, avgScore: ${avgScore.toStringAsFixed(1)}, favorite: $favoriteCategory)';
  }
}
