import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

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

// Avatar picker widget
class AvatarPicker extends StatefulWidget {
  final String? selectedAvatar;
  final ValueChanged<String> onAvatarSelected;
  final bool showLabel;

  const AvatarPicker({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
    this.showLabel = true,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker>
    with TickerProviderStateMixin {
  final Map<String, AnimationController> _bounceControllers = {};
  final Map<String, Animation<double>> _bounceAnimations = {};

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers for each avatar
    for (final avatar in availableAvatars) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _bounceControllers[avatar] = controller;
      _bounceAnimations[avatar] = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
      ]).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    for (final controller in _bounceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAvatarTap(String avatar) {
    // Play bounce animation
    _bounceControllers[avatar]?.forward(from: 0);
    widget.onAvatarSelected(avatar);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLabel) ...[
          Text(
            'Choose Your Avatar',
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A4A6F).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
              scrollbars: true,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: availableAvatars.length,
              itemBuilder: (context, index) {
                final avatar = availableAvatars[index];
                final isSelected = widget.selectedAvatar == avatar;
                return GestureDetector(
                  onTap: () => _onAvatarTap(avatar),
                  child: AnimatedBuilder(
                    animation: _bounceAnimations[avatar]!,
                    builder: (context, child) {
                      final scale = _bounceAnimations[avatar]!.value;
                      return Transform.scale(
                        scale: isSelected ? scale : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF22D3EE)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF22D3EE,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(
                                        0xFF2DD4BF,
                                      ).withValues(alpha: 0.3),
                                      const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.3),
                                    ],
                                  )
                                : null,
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : 0.7,
                            child: Image.asset(
                              'lib/assets/$avatar',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.selectedAvatar == null) ...[
          const SizedBox(height: 8),
          Text(
            'Please select an avatar to continue',
            style: GoogleFonts.comicNeue(
              color: const Color(0xFFFF6B6B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';

  final String? returnTo; // 'join_room', 'create_room', or null
  final String? roomId; // for returning to lobby after creating room

  const AuthScreen({super.key, this.returnTo, this.roomId});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Star> _stars;
  final Random _random = Random();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  User? _user;
  bool _loading = false;
  String? _error;
  String? _success;
  String _authMode = 'login'; // 'signup', 'login', or 'guest'
  String? _selectedAvatar;
  String? _currentAvatar;

  @override
  void initState() {
    super.initState();
    _stars = _generateStars(50);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animController.addListener(_updateStars);
    _user = _authService.currentUser;
    _loadCurrentAvatar();
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

  Future<void> _loadCurrentAvatar() async {
    if (_user != null) {
      final avatar = await _authService.getUserAvatar();
      if (mounted) {
        setState(() {
          _currentAvatar = avatar;
          _selectedAvatar = avatar;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    // Navigate based on where the user came from
    if (widget.returnTo == 'create_room') {
      // Pop auth screen and return to main menu, which will then create the room
      Navigator.of(context).pop(true); // Return true to signal successful auth
    } else if (widget.returnTo == 'join_room') {
      // Pop auth screen to return to join room code input
      Navigator.of(context).pop();
    } else {
      // Default behavior - just pop
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateDisplayName(User user, String name) async {
    if (name.isEmpty) return;
    await user.updateDisplayName(name);
    await user.reload();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _handleAnonymous() async {
    final name = _nameController.text.trim();
    if (_selectedAvatar == null) {
      setState(() => _error = 'Please select an avatar');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final user = await _authService.signInAnonymously();
      if (user != null) {
        if (name.isNotEmpty) {
          await _updateDisplayName(user, name);
        }
        await _authService.saveUserAvatar(_selectedAvatar!);
        _currentAvatar = _selectedAvatar;
        if (mounted) {
          _handleNavigation();
        }
      }
    } catch (e) {
      setState(() => _error = 'Anonymous sign‑in failed');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        // User cancelled
        setState(() => _loading = false);
        return;
      }
      // Check if user has an avatar, if not, prompt to select one
      final existingAvatar = await _authService.getUserAvatar();
      if (existingAvatar == null && _selectedAvatar != null) {
        await _authService.saveUserAvatar(_selectedAvatar!);
        _currentAvatar = _selectedAvatar;
      } else {
        _currentAvatar = existingAvatar;
        _selectedAvatar = existingAvatar;
      }
      if (mounted) {
        _handleNavigation();
      }
    } catch (e) {
      setState(() => _error = 'Google sign‑in failed: $e');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final user = await _authService.signInWithEmail(email, password);
      final name = _nameController.text.trim();
      if (user != null && name.isNotEmpty) {
        await _updateDisplayName(user, name);
      }
      // Load existing avatar
      final existingAvatar = await _authService.getUserAvatar();
      _currentAvatar = existingAvatar;
      _selectedAvatar = existingAvatar;
      if (mounted) {
        _handleNavigation();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Email sign‑in failed');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  Future<void> _handleEmailSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Name, email and password required');
      return;
    }
    if (_selectedAvatar == null) {
      setState(() => _error = 'Please select an avatar');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final user = await _authService.signUpWithEmail(email, password);
      if (user != null) {
        await _updateDisplayName(user, name);
        await _authService.saveUserAvatar(_selectedAvatar!);
        _currentAvatar = _selectedAvatar;
        if (mounted) {
          _handleNavigation();
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Sign up failed');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await _authService.signOut();
    } catch (e) {
      setState(() => _error = 'Sign out failed');
    } finally {
      setState(() {
        _user = null;
        _loading = false;
      });
    }
  }

  Future<void> _handleSendVerificationEmail() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await _authService.sendEmailVerification();
      setState(() => _success = 'Verification email sent! Check your inbox.');
    } catch (e) {
      setState(() => _error = 'Failed to send verification email');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSendPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      setState(() => _error = 'No email associated with this account');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await _authService.sendPasswordResetEmail(email);
      setState(() => _success = 'Password reset email sent to $email');
    } catch (e) {
      setState(() => _error = 'Failed to send password reset email');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleUpdatePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty) {
      setState(() => _error = 'Please enter your current password');
      return;
    }
    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await _authService.updatePassword(oldPassword, newPassword);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _success = 'Password updated successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        setState(() => _error = 'Current password is incorrect');
      } else if (e.code == 'requires-recent-login') {
        setState(
          () => _error = 'Please sign out and sign in again to change password',
        );
      } else {
        setState(() => _error = e.message ?? 'Failed to update password');
      }
    } catch (e) {
      setState(() => _error = 'Failed to update password');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshUser() async {
    try {
      await _user?.reload();
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _success = 'Account info refreshed';
      });
    } catch (e) {
      setState(() => _error = 'Failed to refresh');
    }
  }

  Future<void> _showAvatarChangeDialog() async {
    String? tempSelectedAvatar = _currentAvatar;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A4A6F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF22D3EE), width: 2),
          ),
          title: Text(
            'Change Avatar',
            style: GoogleFonts.comicNeue(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = availableAvatars[index];
                  final isSelected = tempSelectedAvatar == avatar;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() => tempSelectedAvatar = avatar);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: isSelected
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF22D3EE,
                                  ).withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            )
                          : null,
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Image.asset(
                          'lib/assets/$avatar',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.comicNeue(
                  color: const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: tempSelectedAvatar != null
                    ? () => Navigator.of(context).pop(tempSelectedAvatar)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != _currentAvatar) {
      setState(() {
        _loading = true;
        _error = null;
        _success = null;
      });
      try {
        await _authService.saveUserAvatar(result);
        setState(() {
          _currentAvatar = result;
          _selectedAvatar = result;
          _success = 'Avatar updated successfully!';
        });
      } catch (e) {
        setState(() => _error = 'Failed to update avatar');
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildLoggedInView() {
    final displayName =
        _user?.displayName ??
        (_user?.isAnonymous == true ? 'Guest' : _user?.email ?? 'Unknown');
    final isAnonymous = _user?.isAnonymous ?? false;
    final email = _user?.email;
    final emailVerified = _user?.emailVerified ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account Info Card
        _buildThemedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarChangeDialog(),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF22D3EE,
                                ).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF2DD4BF),
                            backgroundImage: _currentAvatar != null
                                ? AssetImage('lib/assets/$_currentAvatar')
                                : null,
                            child: _currentAvatar == null
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.comicNeue(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9A223),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.comicNeue(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                        if (email != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  email,
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 14,
                                    color: const Color(0xFFB0B0B0),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                emailVerified ? Icons.verified : Icons.warning,
                                size: 16,
                                color: emailVerified
                                    ? const Color(0xFF2DD4BF)
                                    : const Color(0xFFD9A223),
                              ),
                            ],
                          ),
                        ],
                        if (isAnonymous)
                          Text(
                            'Guest Account',
                            style: GoogleFonts.comicNeue(
                              fontSize: 14,
                              color: const Color(0xFFB0B0B0),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A4A6F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF22D3EE)),
                      onPressed: _refreshUser,
                      tooltip: 'Refresh',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Email Verification Section (only for non-anonymous, non-verified users)
        if (!isAnonymous && email != null && !emailVerified) ...[
          _buildThemedCard(
            borderColor: const Color(0xFFD9A223),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email, color: Color(0xFFD9A223)),
                    const SizedBox(width: 8),
                    Text(
                      'Email Not Verified',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD9A223),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify your email to secure your account.',
                  style: GoogleFonts.comicNeue(color: const Color(0xFFE0E0E0)),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.send,
                  label: 'Send Verification Email',
                  onTap: _handleSendVerificationEmail,
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Account Settings Section (only for non-anonymous users)
        if (!isAnonymous) ...[
          _buildThemedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Settings',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
                const SizedBox(height: 16),

                // Change Password Section
                Text(
                  'Change Password',
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB0B0B0),
                  ),
                ),
                const SizedBox(height: 12),
                _buildThemedTextField(
                  controller: _oldPasswordController,
                  labelText: 'Current Password',
                  hintText: 'Enter your current password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _buildThemedTextField(
                  controller: _newPasswordController,
                  labelText: 'New Password',
                  hintText: 'Enter new password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _buildThemedTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter new password',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.key,
                  label: 'Update Password',
                  onTap: _handleUpdatePassword,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 16,
                      color: Color(0xFFB0B0B0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Forgot your password? ',
                      style: GoogleFonts.comicNeue(
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                    GestureDetector(
                      onTap: _handleSendPasswordReset,
                      child: Text(
                        'Send Reset Email',
                        style: GoogleFonts.comicNeue(
                          color: const Color(0xFF22D3EE),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Sign Out Button
        _buildActionButton(
          icon: Icons.logout,
          label: 'Sign Out',
          onTap: _handleSignOut,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildLoginView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode: Sign Up
        if (_authMode == 'signup') ...[
          Text(
            'Create Account',
            style: GoogleFonts.comicNeue(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign up to save your progress and compete with friends!',
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: const Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 24),
          _buildThemedTextField(
            controller: _nameController,
            labelText: 'Name (used in game)',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 12),
          _buildThemedTextField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildThemedTextField(
            controller: _passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          AvatarPicker(
            selectedAvatar: _selectedAvatar,
            onAvatarSelected: (avatar) =>
                setState(() => _selectedAvatar = avatar),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.person_add,
            label: 'Sign Up',
            onTap: _handleEmailSignUp,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.comicNeue(color: const Color(0xFFB0B0B0)),
              ),
              GestureDetector(
                onTap: () => setState(() => _authMode = 'login'),
                child: Text(
                  'Log In',
                  style: GoogleFonts.comicNeue(
                    color: const Color(0xFF22D3EE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildSecondaryButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onTap: _handleGoogleSignIn,
          ),
          const SizedBox(height: 12),
          _buildTextButton(
            icon: Icons.person_outline,
            label: 'Continue as Guest',
            onTap: () => setState(() => _authMode = 'guest'),
          ),
        ],

        // Mode: Login
        if (_authMode == 'login') ...[
          Text(
            'Welcome Back',
            style: GoogleFonts.comicNeue(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log in to your account',
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: const Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 24),
          _buildThemedTextField(
            controller: _emailController,
            labelText: 'Email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildThemedTextField(
            controller: _passwordController,
            labelText: 'Password',
            prefixIcon: Icons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.login,
            label: 'Log In',
            onTap: _handleEmailSignIn,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.comicNeue(color: const Color(0xFFB0B0B0)),
              ),
              GestureDetector(
                onTap: () => setState(() => _authMode = 'signup'),
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.comicNeue(
                    color: const Color(0xFF22D3EE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          _buildSecondaryButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onTap: _handleGoogleSignIn,
          ),
          const SizedBox(height: 12),
          _buildTextButton(
            icon: Icons.person_outline,
            label: 'Continue as Guest',
            onTap: () => setState(() => _authMode = 'guest'),
          ),
        ],

        // Mode: Guest
        if (_authMode == 'guest') ...[
          Text(
            'Play as Guest',
            style: GoogleFonts.comicNeue(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a name to use in the game. Your progress won\'t be saved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: const Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 24),
          _buildThemedTextField(
            controller: _nameController,
            labelText: 'Your Name',
            hintText: 'Enter name to show in game',
            prefixIcon: Icons.person,
          ),
          const SizedBox(height: 16),
          AvatarPicker(
            selectedAvatar: _selectedAvatar,
            onAvatarSelected: (avatar) =>
                setState(() => _selectedAvatar = avatar),
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.play_arrow,
            label: 'Continue as Guest',
            onTap: _handleAnonymous,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Want to save progress? ',
                style: GoogleFonts.comicNeue(color: const Color(0xFFB0B0B0)),
              ),
              GestureDetector(
                onTap: () => setState(() => _authMode = 'signup'),
                child: Text(
                  'Create Account',
                  style: GoogleFonts.comicNeue(
                    color: const Color(0xFF22D3EE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.comicNeue(color: const Color(0xFFB0B0B0)),
              ),
              GestureDetector(
                onTap: () => setState(() => _authMode = 'login'),
                child: Text(
                  'Log In',
                  style: GoogleFonts.comicNeue(
                    color: const Color(0xFF22D3EE),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Helper widgets for themed UI
  Widget _buildThemedCard({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A4A6F).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? const Color(0xFF22D3EE).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildThemedTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.comicNeue(
        color: const Color(0xFFE0E0E0),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: GoogleFonts.comicNeue(color: const Color(0xFFB0B0B0)),
        hintStyle: GoogleFonts.comicNeue(color: const Color(0xFF808080)),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF22D3EE))
            : null,
        filled: true,
        fillColor: const Color(0xFF0A4A6F).withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool compact = false,
  }) {
    final gradient = isDestructive
        ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF2DD4BF), Color(0xFF6366F1)],
          );

    final borderColor = isDestructive
        ? const Color(0xFFEF4444)
        : const Color(0xFF22D3EE);

    return Container(
      width: compact ? null : double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 12 : 16,
              horizontal: compact ? 20 : 28,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Icon(icon, color: const Color(0xFFE0E0E0), size: 22),
                const SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.comicNeue(
                    fontSize: compact ? 14 : 16,
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

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF22D3EE).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF22D3EE), size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.comicNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE0E0E0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFB0B0B0), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.comicNeue(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.comicNeue(
              color: const Color(0xFFB0B0B0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(widget.returnTo == 'join_room' && _user == null),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.returnTo == 'join_room' && _user == null) {
          // Go back to main menu instead of join screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
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
                  // Custom app bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A4A6F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF22D3EE,
                              ).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFFE0E0E0),
                            ),
                            onPressed: () {
                              // If coming from join_room without being signed in,
                              // go back to main menu instead of join screen
                              if (widget.returnTo == 'join_room' &&
                                  _user == null) {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _user != null ? 'My Account' : 'Account',
                          style: GoogleFonts.comicNeue(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF22D3EE),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_user != null)
                                  _buildLoggedInView()
                                else
                                  _buildLoginView(),
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error,
                                          color: Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: GoogleFonts.comicNeue(
                                              color: const Color(0xFFEF4444),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_success != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2DD4BF,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF2DD4BF),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF2DD4BF),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _success!,
                                            style: GoogleFonts.comicNeue(
                                              color: const Color(0xFF2DD4BF),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
