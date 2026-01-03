import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/join_room_screen.dart';
import 'screens/player_stats_screen.dart';

String? _initialJoinCode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Check for join parameter in URL (web only)
  if (kIsWeb) {
    _initialJoinCode = _getJoinCodeFromUrl();
  }
  
  runApp(const MyApp());
}

String? _getJoinCodeFromUrl() {
  try {
    // Use Uri.base which works in Flutter web
    final uri = Uri.base;
    return uri.queryParameters['join'];
  } catch (_) {
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // If there's a join code from the URL, go directly to JoinRoomScreen
    final hasJoinCode = _initialJoinCode != null && _initialJoinCode!.isNotEmpty;
    
    return MaterialApp(
      title: 'Quizzly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05396B),
          brightness: Brightness.dark,
          primary: const Color(0xFF4BA4FF),
          secondary: const Color(0xFFD9A223),
          tertiary: const Color(0xFF0E5F88),
          surface: const Color(0xFF05396B),
        ),
        scaffoldBackgroundColor: const Color(0xFF05396B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF262B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF111319), width: 2),
            ),
            elevation: 4,
          ),
        ),
      ),
      home: hasJoinCode 
          ? JoinRoomScreen(initialCode: _initialJoinCode)
          : const MainMenuScreen(),
      routes: {
        AuthScreen.routeName: (_) => const AuthScreen(),
        JoinRoomScreen.routeName: (_) => const JoinRoomScreen(),
        PlayerStatsScreen.routeName: (_) => const PlayerStatsScreen(),
      },
    );
  }
}
