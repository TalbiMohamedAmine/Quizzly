import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to leave room')));
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isHost)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'HOST',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Players: ${room.playerCount}/${room.maxPlayers}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Players',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Use more columns on wider screens (web)
                              final screenWidth = constraints.maxWidth;
                              int crossAxisCount;
                              if (screenWidth > 1200) {
                                crossAxisCount = 8; // Large desktop/fullscreen
                              } else if (screenWidth > 900) {
                                crossAxisCount = 6; // Medium desktop
                              } else if (screenWidth > 600) {
                                crossAxisCount = 5; // Small desktop/tablet
                              } else {
                                crossAxisCount = 3; // Mobile
                              }

                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.7,
                                    ),
                                itemCount: room.players.length,
                                itemBuilder: (context, index) {
                                  final p = room.players[index];
                                  final isPlayerHost = p['uid'] == room.hostId;
                                  final playerAvatar = p['avatar'] as String?;
                                  final playerName = p['name'] ?? 'Player';

                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      final avatarSize =
                                          constraints.maxWidth * 0.85;
                                      final fontSize = avatarSize * 0.4;
                                      final starSize = avatarSize * 0.18;
                                      final nameFontSize =
                                          constraints.maxWidth * 0.12;

                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: avatarSize,
                                                height: avatarSize,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: playerAvatar != null
                                                    ? ClipOval(
                                                        child: Image.asset(
                                                          'lib/assets/$playerAvatar',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Text(
                                                          playerName.isNotEmpty
                                                              ? playerName[0]
                                                                    .toUpperCase()
                                                              : '?',
                                                          style: TextStyle(
                                                            fontSize: fontSize,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                              if (isPlayerHost)
                                                Positioned(
                                                  top: -4,
                                                  right: -4,
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      starSize * 0.2,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.amber,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Icon(
                                                      Icons.star,
                                                      size: starSize,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            playerName,
                                            style: TextStyle(
                                              fontSize: nameFontSize.clamp(
                                                14.0,
                                                22.0,
                                              ),
                                              fontWeight: isPlayerHost
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
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
