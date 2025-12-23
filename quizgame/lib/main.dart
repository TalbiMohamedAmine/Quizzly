import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Duel',
      theme: ThemeData.dark(),
      home: const MainMenuScreen(),
      routes: {
        AuthScreen.routeName: (_) => const AuthScreen(),
        CreateRoomScreen.routeName: (_) => const CreateRoomScreen(),
        JoinRoomScreen.routeName: (_) => const JoinRoomScreen(),
      },
    );
  }
}
