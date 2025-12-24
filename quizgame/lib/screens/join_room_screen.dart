import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'lobby_screen.dart';

// Star model for the animated background
class Star {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class JoinRoomScreen extends StatefulWidget {
  static const routeName = '/join-room';

  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen>
    with SingleTickerProviderStateMixin {
  final _roomService = RoomService();
  final _authService = AuthService();

  // Animation controller for stars
  late AnimationController _animController;
  late List<Star> _stars;
  final Random _random = Random();

  // Controllers for each digit
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stars = _generateStars(50);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animController.addListener(_updateStars);
    _checkAuth();
  }

  List<Star> _generateStars(int count) {
    return List.generate(count, (_) => _createStar(randomY: true));
  }

  Star _createStar({bool randomY = false}) {
    return Star(
      x: _random.nextDouble(),
      y: randomY ? _random.nextDouble() : 0,
      size: _random.nextDouble() * 3 + 1,
      speed: _random.nextDouble() * 0.003 + 0.001,
      opacity: _random.nextDouble() * 0.6 + 0.4,
    );
  }

  void _updateStars() {
    for (var star in _stars) {
      star.y += star.speed;
      star.x += (sin(star.y * 10) * 0.0005);
      if (star.y > 1) {
        star.y = 0;
        star.x = _random.nextDouble();
        star.opacity = _random.nextDouble() * 0.6 + 0.4;
      }
      if (star.x < 0) star.x = 1;
      if (star.x > 1) star.x = 0;
    }
  }

  void _checkAuth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const AuthScreen(returnTo: 'join_room'),
          ),
        ).then((_) {
          // After returning from auth, check if user is authenticated
          if (mounted && FirebaseAuth.instance.currentUser == null) {
            // User is still not authenticated, pop this screen
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _joinRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'You must sign in or use guest mode first.');
      return;
    }

    final code = _code.trim().toUpperCase();
    if (code.length < 6) {
      setState(() => _error = 'Enter complete code.');
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

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    // Auto-submit when all fields are filled
    if (_code.length == 6) {
      _joinRoom();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05396B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF05396B), Color(0xFF0E5F88)],
              ),
            ),
          ),
          // Animated stars - using AnimatedBuilder for efficiency
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              _updateStars();
              return CustomPaint(
                painter: _StarsPainter(stars: _stars),
                size: Size.infinite,
              );
            },
          ),
          // Main content wrapped in RepaintBoundary
          RepaintBoundary(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FC),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'Enter Your Secret Code',
                          style: GoogleFonts.comicNeue(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D3748),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bunny avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/assets/bunny.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Code input boxes - 6 boxes in a row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 50,
                                child: RawKeyboardListener(
                                  focusNode: FocusNode(),
                                  onKey: (event) =>
                                      _onKeyPressed(index, event),
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    maxLength: 1,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D3748),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF22D3EE),
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF22D3EE),
                                          width: 2,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF6366F1),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) =>
                                        _onCodeChanged(index, value),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Join button
                        _loading
                            ? const CircularProgressIndicator()
                            : Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF2DD4BF),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF22D3EE),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF22D3EE,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _joinRoom,
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.sports_esports_rounded,
                                            color: Color(0xFFE0E0E0),
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'JOIN GAME',
                                            style: GoogleFonts.comicNeue(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFE0E0E0),
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for rendering animated stars
class _StarsPainter extends CustomPainter {
  final List<Star> stars;

  _StarsPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final x = star.x * size.width;
      final y = star.y * size.height;

      canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => true;
}
