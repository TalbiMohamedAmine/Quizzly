import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
import '../models/room.dart';
import 'auth_screen.dart';
import 'lobby_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  static const routeName = '/join-room';

  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _roomService = RoomService();
  final _authService = AuthService();
  final _codeController = TextEditingController();

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
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'You must sign in or use guest mode first.');
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter room code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final room = await _roomService.getRoomByCode(code);
      if (room == null) {
        setState(() => _error = 'Room not found.');
      } else {
        final name = user.displayName ?? 'Guest';
        final avatar = await _authService.getUserAvatar();
        await _roomService.addPlayerToRoom(
          roomId: room.id,
          uid: user.uid,
          name: name,
          avatar: avatar,
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LobbyScreen(roomId: room.id)),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to join room.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Game')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Room code'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _joinRoom,
                    child: const Text('Join Room'),
                  ),
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
