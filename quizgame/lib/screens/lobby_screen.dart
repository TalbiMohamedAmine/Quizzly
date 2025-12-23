import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../models/room.dart';

class LobbyScreen extends StatelessWidget {
  final String roomId;
  final _roomService = RoomService();

  LobbyScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: StreamBuilder<Room>(
        stream: _roomService.watchRoom(roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Room not found'));
          }
          final room = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code: ${room.code}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Players: ${room.playerCount}/${room.maxPlayers}'),
                const SizedBox(height: 16),
                const Text('Player list:'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: room.players.length,
                    itemBuilder: (context, index) {
                      final p = room.players[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(p['name'] ?? 'Player'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
