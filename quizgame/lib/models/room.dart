import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String hostId;
  final String hostName;
  final String code;
  final int maxPlayers;
  final int playerCount;
  final String state;
  final DateTime createdAt;
  final List<Map<String, dynamic>> players;
  
  // Game settings
  final int tourTime; // in seconds
  final int numberOfRounds;
  final bool tvSettings;
  final bool regulatorSetting;
  final List<String> selectedCategories;
  final List<String> customCategories;
  
  // Game reference
  final String? gameId;

  Room({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.code,
    required this.maxPlayers,
    required this.playerCount,
    required this.state,
    required this.createdAt,
    required this.players,
    this.tourTime = 60,
    this.numberOfRounds = 10,
    this.tvSettings = false,
    this.regulatorSetting = false,
    this.selectedCategories = const [],
    this.customCategories = const [],
    this.gameId,
  });

  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Room(
      id: doc.id,
      hostId: data['hostId'] as String,
      hostName: data['hostName'] as String,
      code: data['code'] as String,
      maxPlayers: data['maxPlayers'] as int,
      playerCount: data['playerCount'] as int,
      state: data['state'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      players: List<Map<String, dynamic>>.from(data['players'] ?? []),
      tourTime: data['tourTime'] as int? ?? 60,
      numberOfRounds: data['numberOfRounds'] as int? ?? 10,
      tvSettings: data['tvSettings'] as bool? ?? false,
      regulatorSetting: data['regulatorSetting'] as bool? ?? false,
      selectedCategories: List<String>.from(data['selectedCategories'] ?? []),
      customCategories: List<String>.from(data['customCategories'] ?? []),
      gameId: data['gameId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'hostId': hostId,
    'hostName': hostName,
    'code': code,
    'maxPlayers': maxPlayers,
    'playerCount': playerCount,
    'state': state,
    'createdAt': Timestamp.fromDate(createdAt),
    'players': players,
    'tourTime': tourTime,
    'numberOfRounds': numberOfRounds,
    'tvSettings': tvSettings,
    'regulatorSetting': regulatorSetting,
    'selectedCategories': selectedCategories,
    'customCategories': customCategories,
    if (gameId != null) 'gameId': gameId,
  };
}
