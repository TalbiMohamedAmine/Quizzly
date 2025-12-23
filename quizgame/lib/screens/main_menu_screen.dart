import 'package:flutter/material.dart';
import 'auth_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _openAuth(BuildContext context) {
    Navigator.of(context).pushNamed(AuthScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Duel'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: navigate to CreateRoomScreen
              },
              child: const Text('Create Game'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: navigate to JoinRoomScreen
              },
              child: const Text('Join Game'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAuth(context),
        child: const Icon(Icons.account_circle),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
