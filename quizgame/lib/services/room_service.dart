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
  }) async {
    final code = _generateCode();
    final docRef = _firestore.collection('rooms').doc();

    final players = [
      {'uid': hostId, 'name': hostName},
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
        players.add({'uid': uid, 'name': name});
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
}
