import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class RoomService {
  final _firestore = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<Room> createRoom({
    required String hostId,
    required String hostName,
    int maxPlayers = 10,
    String? hostAvatar,
  }) async {
    final code = _generateCode();
    final docRef = _firestore.collection('rooms').doc();

    final players = [
      {'uid': hostId, 'name': hostName, 'avatar': hostAvatar},
    ];

    final room = Room(
      id: docRef.id,
      hostId: hostId,
      hostName: hostName,
      code: code,
      maxPlayers: maxPlayers,
      playerCount: 1,
      state: 'waiting',
      createdAt: DateTime.now(),
      players: players,
    );

    await docRef.set(room.toFirestore());
    return room;
  }

  Future<Room?> getRoomByCode(String code) async {
    final snap = await _firestore
        .collection('rooms')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return Room.fromFirestore(snap.docs.first);
  }

  Future<void> addPlayerToRoom({
    required String roomId,
    required String uid,
    required String name,
    String? avatar,
  }) async {
    final docRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data() as Map<String, dynamic>;
      final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
      final maxPlayers = data['maxPlayers'] as int;
      final playerCount = data['playerCount'] as int;

      if (playerCount >= maxPlayers) {
        throw Exception('Room is full');
      }

      // prevent duplicates
      if (!players.any((p) => p['uid'] == uid)) {
        players.add({'uid': uid, 'name': name, 'avatar': avatar});
      }

      tx.update(docRef, {'players': players, 'playerCount': players.length});
    });
  }

  Stream<Room> watchRoom(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map(
          (doc) =>
              Room.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>),
        );
  }

  Future<void> removePlayerFromRoom({
    required String roomId,
    required String uid,
  }) async {
    final docRef = _firestore.collection('rooms').doc(roomId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final players = List<Map<String, dynamic>>.from(data['players'] ?? []);
      final hostId = data['hostId'] as String;

      // Remove the player
      players.removeWhere((p) => p['uid'] == uid);

      // If host leaves or no players left, delete the room
      if (uid == hostId || players.isEmpty) {
        tx.delete(docRef);
      } else {
        tx.update(docRef, {'players': players, 'playerCount': players.length});
      }
    });
  }

  /// Update room settings (host only)
  Future<void> updateRoomSettings({
    required String roomId,
    int? tourTime,
    int? numberOfRounds,
    int? maxPlayers,
    bool? tvSettings,
    bool? regulatorSetting,
    List<String>? selectedCategories,
  }) async {
    final docRef = _firestore.collection('rooms').doc(roomId);
    
    final Map<String, dynamic> updates = {};
    if (tourTime != null) updates['tourTime'] = tourTime;
    if (numberOfRounds != null) updates['numberOfRounds'] = numberOfRounds;
    if (maxPlayers != null) updates['maxPlayers'] = maxPlayers;
    if (tvSettings != null) updates['tvSettings'] = tvSettings;
    if (regulatorSetting != null) updates['regulatorSetting'] = regulatorSetting;
    if (selectedCategories != null) updates['selectedCategories'] = selectedCategories;
    
    if (updates.isNotEmpty) {
      await docRef.update(updates);
    }
  }

  /// Toggle a category selection
  Future<void> toggleCategory({
    required String roomId,
    required String category,
  }) async {
    final docRef = _firestore.collection('rooms').doc(roomId);
    
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      
      final data = snap.data() as Map<String, dynamic>;
      final categories = List<String>.from(data['selectedCategories'] ?? []);
      
      if (categories.contains(category)) {
        categories.remove(category);
      } else {
        categories.add(category);
      }
      
      tx.update(docRef, {'selectedCategories': categories});
    });
  }

  /// Add a custom category to the room's available categories
  Future<void> addCustomCategory({
    required String roomId,
    required String categoryName,
  }) async {
    final docRef = _firestore.collection('rooms').doc(roomId);
    
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      
      final data = snap.data() as Map<String, dynamic>;
      final customCategories = List<String>.from(data['customCategories'] ?? []);
      
      // Add the custom category if it doesn't already exist
      if (!customCategories.contains(categoryName)) {
        customCategories.add(categoryName);
        tx.update(docRef, {'customCategories': customCategories});
      }
    });
  }
}
