import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/room_service.dart';
import '../models/room.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomService = RoomService();
  bool _leaving = false;

  Future<void> _leaveRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _leaving) return;

    setState(() => _leaving = true);

    try {
      await _roomService.removePlayerFromRoom(
        roomId: widget.roomId,
        uid: user.uid,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _leaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to leave room')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    await _leaveRoom();
    return false; // We handle navigation in _leaveRoom
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _leaveRoom();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lobby'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaving ? null : _leaveRoom,
          ),
        ),
        body: _leaving
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<Room>(
                stream: _roomService.watchRoom(widget.roomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Room no longer exists'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Back to Menu'),
                          ),
                        ],
                      ),
                    );
                  }
                  final room = snapshot.data!;
                  final isHost = currentUser?.uid == room.hostId;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Code: ${room.code}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'HOST',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
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
                              final isPlayerHost = p['uid'] == room.hostId;
                              return ListTile(
                                leading: Icon(
                                  isPlayerHost ? Icons.star : Icons.person,
                                  color: isPlayerHost ? Colors.amber : null,
                                ),
                                title: Text(p['name'] ?? 'Player'),
                                trailing: isPlayerHost
                                    ? const Text(
                                        'Host',
                                        style: TextStyle(color: Colors.grey),
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _leaveRoom,
                            icon: const Icon(Icons.exit_to_app),
                            label: Text(isHost ? 'Close Room' : 'Leave Room'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
