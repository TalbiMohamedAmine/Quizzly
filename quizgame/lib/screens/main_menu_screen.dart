import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/room_service.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'join_room_screen.dart';
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

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  final Random _random = Random();
  final _roomService = RoomService();
  final _authService = AuthService();
  bool _creatingRoom = false;

  @override
  void initState() {
    super.initState();
    _stars = _generateStars(50);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_updateStars);
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
    setState(() {
      for (var star in _stars) {
        star.y += star.speed;
        // Add subtle horizontal drift
        star.x += (sin(star.y * 10) * 0.0005);

        // Reset star when it goes off screen
        if (star.y > 1) {
          star.y = 0;
          star.x = _random.nextDouble();
          star.opacity = _random.nextDouble() * 0.6 + 0.4;
        }
        // Wrap horizontal position
        if (star.x < 0) star.x = 1;
        if (star.x > 1) star.x = 0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAuth(BuildContext context) {
    Navigator.of(context).pushNamed(AuthScreen.routeName);
  }

  Future<void> _createRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Redirect to auth if not signed in
      final authResult = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(returnTo: 'create_room'),
        ),
      );
      // If auth was successful, try creating room again
      if (authResult == true && mounted) {
        _createRoom();
      }
      return;
    }

    setState(() => _creatingRoom = true);

    try {
      final hostName = user.displayName ?? 'Guest';
      final hostAvatar = await _authService.getUserAvatar();
      final room = await _roomService.createRoom(
        hostId: user.uid,
        hostName: hostName,
        maxPlayers: 10,
        hostAvatar: hostAvatar,
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LobbyScreen(roomId: room.id)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create room')));
    } finally {
      if (mounted) setState(() => _creatingRoom = false);
    }
  }

  Widget _buildProfileIcon(User? user) {
    if (user == null) {
      return const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    return StreamBuilder<String?>(
      stream: _authService.userAvatarStream(user.uid),
      builder: (context, snapshot) {
        final avatarFileName = snapshot.data;
        
        if (avatarFileName != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'lib/assets/$avatarFileName',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          );
        }
        
        return const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 28,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
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
          // Animated stars
          CustomPaint(
            painter: StarsPainter(stars: _stars),
            size: Size.infinite,
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with profile button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9A223),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFB8891D),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD9A223,
                              ).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openAuth(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _buildProfileIcon(currentUser),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo and title section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate responsive logo height based on available space
                      final logoHeight = (constraints.maxHeight * 0.55).clamp(
                        200.0,
                        400.0,
                      );
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo - sized appropriately
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'lib/assets/quizzly_logo.png',
                              height: logoHeight,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if logo is not found
                                return Container(
                                  height: 180,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4BA4FF),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.quiz_rounded,
                                    size: 90,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tagline
                          Text(
                            'Challenge your friends!',
                            style: GoogleFonts.comicNeue(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE0E0E0),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Menu buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              children: [
                                _buildMenuButton(
                                  context,
                                  icon: Icons.add_circle_outline_rounded,
                                  label: 'Create Room',
                                  isLoading: _creatingRoom,
                                  onTap: _creatingRoom ? null : _createRoom,
                                ),
                                const SizedBox(height: 20),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.groups_rounded,
                                  label: 'Join Room',
                                  onTap: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(JoinRoomScreen.routeName);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Footer with accent yellow
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9A223),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Text(
                    '🎄 Happy Holidays! 🎄',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.comicNeue(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2DD4BF), // Teal/cyan
            Color(0xFF6366F1), // Purple/indigo
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF22D3EE), // Cyan border
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            child: isLoading
                ? const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFE0E0E0),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: const Color(0xFFE0E0E0), size: 26),
                      const SizedBox(width: 12),
                      Text(
                        label.toUpperCase(),
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
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
    );
  }
}

// Custom painter for rendering animated stars
class StarsPainter extends CustomPainter {
  final List<Star> stars;

  StarsPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity)
        ..style = PaintingStyle.fill;

      // Draw star with a subtle glow effect
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final x = star.x * size.width;
      final y = star.y * size.height;

      // Draw glow
      canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      // Draw star
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}
