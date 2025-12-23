import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/room_service.dart';
import '../models/room.dart';
import 'auth_screen.dart';
import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  static const routeName = '/create-room';

  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _roomService = RoomService();
  final _maxPlayersController = TextEditingController(text: '10');

  Room? _room;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
      }
    });
  }

  @override
  void dispose() {
    _maxPlayersController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'You must be signed in or guest.');
      return;
    }

    final hostName = user.displayName ?? 'Guest';
    final maxPlayers = int.tryParse(_maxPlayersController.text) ?? 10;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final room = await _roomService.createRoom(
        hostId: user.uid,
        hostName: hostName,
        maxPlayers: maxPlayers,
      );
      setState(() => _room = room);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LobbyScreen(roomId: room.id)),
      );
    } catch (e) {
      setState(() => _error = 'Failed to create room.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextField(
                    controller: _maxPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max players (2–20)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createRoom,
                    child: const Text('Create Room'),
                  ),
                  const SizedBox(height: 16),
                  if (_room != null) ...[
                    const Text('Room created!'),
                    Text(
                      'Code: ${_room!.code}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
      ),
    );
  }
}
