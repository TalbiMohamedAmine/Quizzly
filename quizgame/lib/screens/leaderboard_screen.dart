import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game.dart';

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

// Confetti particle model for winner celebration
class ConfettiParticle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double rotation;
  double rotationSpeed;
  Color color;
  double opacity;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.opacity,
  });
}

class LeaderboardScreen extends StatefulWidget {
  final List<PlayerScore> leaderboard;
  final String? roomId;
  final bool showBackToLobby;

  const LeaderboardScreen({
    super.key,
    required this.leaderboard,
    this.roomId,
    this.showBackToLobby = true,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

// Animation phase enum for sequenced reveal
enum PodiumPhase {
  initial,
  thirdPlaceLoading,
  thirdPlaceMoving,
  secondPlaceLoading,
  secondPlaceMoving,
  firstPlaceLoading,
  winnerCelebration,
  complete,
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late List<Star> _stars;
  final Random _random = Random();

  // Sequenced podium animation
  PodiumPhase _currentPhase = PodiumPhase.initial;

  // Individual score controllers for each place
  late AnimationController _thirdPlaceScoreController;
  late AnimationController _secondPlaceScoreController;
  late AnimationController _firstPlaceScoreController;

  // Position animation controllers
  late AnimationController _thirdPlacePositionController;
  late AnimationController _secondPlacePositionController;

  // Score animations
  late Animation<double> _thirdPlaceScoreAnimation;
  late Animation<double> _secondPlaceScoreAnimation;
  late Animation<double> _firstPlaceScoreAnimation;

  // Position animations (0 = center, 1 = final position)
  late Animation<double> _thirdPlacePositionAnimation;
  late Animation<double> _secondPlacePositionAnimation;

  // Winner celebration animation
  late AnimationController _winnerCelebrationController;
  late Animation<double> _winnerScaleAnimation;
  late Animation<double> _winnerGlowAnimation;

  // Confetti animation
  late AnimationController _confettiController;
  List<ConfettiParticle> _confettiParticles = [];
  bool _showConfetti = false;
  bool _winnerAnimationTriggered = false;

  // Confetti colors
  final List<Color> _confettiColors = [
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF6B6B), // Red
    const Color(0xFF4ECDC4), // Teal
    const Color(0xFF45B7D1), // Blue
    const Color(0xFFF7DC6F), // Yellow
    const Color(0xFFBB8FCE), // Purple
    const Color(0xFF58D68D), // Green
  ];

  @override
  void initState() {
    super.initState();
    _stars = _generateStars(50);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animController.addListener(_updateStars);

    // Initialize individual score controllers with listeners
    _thirdPlaceScoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _thirdPlaceScoreAnimation = CurvedAnimation(
      parent: _thirdPlaceScoreController,
      curve: Curves.easeOutCubic,
    );
    _thirdPlaceScoreController.addListener(() => setState(() {}));

    _secondPlaceScoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _secondPlaceScoreAnimation = CurvedAnimation(
      parent: _secondPlaceScoreController,
      curve: Curves.easeOutCubic,
    );
    _secondPlaceScoreController.addListener(() => setState(() {}));

    _firstPlaceScoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _firstPlaceScoreAnimation = CurvedAnimation(
      parent: _firstPlaceScoreController,
      curve: Curves.easeOutCubic,
    );
    _firstPlaceScoreController.addListener(() => setState(() {}));

    // Initialize position controllers with listeners
    _thirdPlacePositionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _thirdPlacePositionAnimation = CurvedAnimation(
      parent: _thirdPlacePositionController,
      curve: Curves.easeInOutCubic,
    );
    _thirdPlacePositionController.addListener(() => setState(() {}));

    _secondPlacePositionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _secondPlacePositionAnimation = CurvedAnimation(
      parent: _secondPlacePositionController,
      curve: Curves.easeInOutCubic,
    );
    _secondPlacePositionController.addListener(() => setState(() {}));

    // Initialize winner celebration animation
    _winnerCelebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _winnerScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 10),
        ]).animate(
          CurvedAnimation(
            parent: _winnerCelebrationController,
            curve: Curves.easeInOut,
          ),
        );
    _winnerGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _winnerCelebrationController,
        curve: Curves.easeOut,
      ),
    );

    // Initialize confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _confettiController.addListener(_updateConfetti);

    // Start sequenced animation after a small delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _startSequencedAnimation();
      }
    });
  }

  void _startSequencedAnimation() async {
    final playerCount = widget.leaderboard.length;

    if (playerCount >= 3) {
      // Phase 1: Third place loads in center
      setState(() => _currentPhase = PodiumPhase.thirdPlaceLoading);
      await _thirdPlaceScoreController.forward();

      // Phase 2: Third place moves to right
      setState(() => _currentPhase = PodiumPhase.thirdPlaceMoving);
      await _thirdPlacePositionController.forward();

      // Phase 3: Second place loads in center
      setState(() => _currentPhase = PodiumPhase.secondPlaceLoading);
      await _secondPlaceScoreController.forward();

      // Phase 4: Second place moves to left
      setState(() => _currentPhase = PodiumPhase.secondPlaceMoving);
      await _secondPlacePositionController.forward();

      // Phase 5: First place loads in center
      setState(() => _currentPhase = PodiumPhase.firstPlaceLoading);
      await _firstPlaceScoreController.forward();

      // Phase 6: Winner celebration
      _triggerWinnerCelebration();
    } else if (playerCount == 2) {
      // Phase 1: Second place loads in center
      setState(() => _currentPhase = PodiumPhase.secondPlaceLoading);
      await _secondPlaceScoreController.forward();

      // Phase 2: Second place moves to left
      setState(() => _currentPhase = PodiumPhase.secondPlaceMoving);
      await _secondPlacePositionController.forward();

      // Phase 3: First place loads in center
      setState(() => _currentPhase = PodiumPhase.firstPlaceLoading);
      await _firstPlaceScoreController.forward();

      // Phase 4: Winner celebration
      _triggerWinnerCelebration();
    } else if (playerCount == 1) {
      // Just one player - load and celebrate
      setState(() => _currentPhase = PodiumPhase.firstPlaceLoading);
      await _firstPlaceScoreController.forward();
      _triggerWinnerCelebration();
    }
  }

  void _triggerWinnerCelebration() {
    setState(() => _currentPhase = PodiumPhase.winnerCelebration);
    _winnerAnimationTriggered = true;
    _winnerCelebrationController.forward();
    _startConfetti();
  }

  void _startConfetti() {
    _confettiParticles = _generateConfetti(80);
    _showConfetti = true;
    _confettiController.forward(from: 0);
  }

  List<ConfettiParticle> _generateConfetti(int count) {
    return List.generate(count, (_) => _createConfettiParticle());
  }

  ConfettiParticle _createConfettiParticle() {
    return ConfettiParticle(
      x: 0.3 + _random.nextDouble() * 0.4, // Center area
      y: 0.2 + _random.nextDouble() * 0.1, // Start from top
      size: _random.nextDouble() * 8 + 4,
      speedX: (_random.nextDouble() - 0.5) * 0.015,
      speedY: _random.nextDouble() * 0.008 + 0.003,
      rotation: _random.nextDouble() * 360,
      rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      color: _confettiColors[_random.nextInt(_confettiColors.length)],
      opacity: 1.0,
    );
  }

  void _updateConfetti() {
    if (!_showConfetti) return;
    setState(() {
      for (var particle in _confettiParticles) {
        particle.y += particle.speedY;
        particle.x += particle.speedX;
        particle.rotation += particle.rotationSpeed;
        particle.speedY += 0.0002; // Gravity
        particle.speedX *= 0.99; // Air resistance

        // Fade out as they fall
        if (particle.y > 0.7) {
          particle.opacity = max(0, 1.0 - ((particle.y - 0.7) / 0.3));
        }
      }

      // Remove particles that are off screen
      _confettiParticles.removeWhere((p) => p.y > 1.0 || p.opacity <= 0);

      if (_confettiParticles.isEmpty) {
        _showConfetti = false;
      }
    });
  }

  // Get animated score for each place based on their individual animation
  int _getAnimatedScoreForPlace(int place, int actualScore) {
    switch (place) {
      case 1:
        return (actualScore * _firstPlaceScoreAnimation.value).round();
      case 2:
        return (actualScore * _secondPlaceScoreAnimation.value).round();
      case 3:
        return (actualScore * _thirdPlaceScoreAnimation.value).round();
      default:
        return actualScore;
    }
  }

  // Get bar height progress for each place
  double _getBarProgressForPlace(int place) {
    switch (place) {
      case 1:
        return _firstPlaceScoreAnimation.value.clamp(0.05, 1.0);
      case 2:
        return _secondPlaceScoreAnimation.value.clamp(0.05, 1.0);
      case 3:
        return _thirdPlaceScoreAnimation.value.clamp(0.05, 1.0);
      default:
        return 1.0;
    }
  }

  // Check if a place should be visible
  bool _isPlaceVisible(int place) {
    final playerCount = widget.leaderboard.length;

    if (place == 3 && playerCount >= 3) {
      return _currentPhase.index >= PodiumPhase.thirdPlaceLoading.index;
    } else if (place == 2 && playerCount >= 2) {
      if (playerCount >= 3) {
        return _currentPhase.index >= PodiumPhase.secondPlaceLoading.index;
      } else {
        return _currentPhase.index >= PodiumPhase.secondPlaceLoading.index;
      }
    } else if (place == 1) {
      return _currentPhase.index >= PodiumPhase.firstPlaceLoading.index;
    }
    return false;
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
        star.x += (sin(star.y * 10) * 0.0005);
        if (star.y > 1) {
          star.y = 0;
          star.x = _random.nextDouble();
          star.opacity = _random.nextDouble() * 0.6 + 0.4;
        }
        if (star.x < 0) star.x = 1;
        if (star.x > 1) star.x = 0;
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _thirdPlaceScoreController.dispose();
    _secondPlaceScoreController.dispose();
    _firstPlaceScoreController.dispose();
    _thirdPlacePositionController.dispose();
    _secondPlacePositionController.dispose();
    _winnerCelebrationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Podium for top 3
                  if (widget.leaderboard.isNotEmpty) _buildPodium(),

                  const SizedBox(height: 24),

                  // Full leaderboard
                  Expanded(child: _buildLeaderboardList()),

                  const SizedBox(height: 16),

                  // Back button
                  if (widget.showBackToLobby) _buildBackButton(),
                ],
              ),
            ),
          ),
          // Confetti overlay
          if (_showConfetti)
            CustomPaint(
              painter: ConfettiPainter(particles: _confettiParticles),
              size: Size.infinite,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Trophy animation with winner celebration enhancement
        AnimatedBuilder(
          animation: _winnerCelebrationController,
          builder: (context, child) {
            // Add extra bounce and glow when winner celebration triggers
            final celebrationScale = _winnerAnimationTriggered
                ? 1.0 + sin(_winnerCelebrationController.value * pi * 2) * 0.15
                : 1.0;
            final glowOpacity = _winnerAnimationTriggered
                ? _winnerGlowAnimation.value * 0.6
                : 0.0;

            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _winnerAnimationTriggered
                    ? [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD700,
                          ).withOpacity(glowOpacity),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ]
                    : null,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, _) {
                  return Transform.scale(
                    scale: value * celebrationScale,
                    child: const Text('🏆', style: TextStyle(fontSize: 64)),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Winner announcement text
        AnimatedBuilder(
          animation: _winnerCelebrationController,
          builder: (context, child) {
            if (_winnerAnimationTriggered && widget.leaderboard.isNotEmpty) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      '🎉 WINNER! 🎉',
                      style: GoogleFonts.comicNeue(
                        color: const Color(0xFFFFD700),
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.leaderboard[0].name,
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Text(
                  'Final Results',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Congratulations to all players!',
                  style: GoogleFonts.comicNeue(
                    color: const Color(0xFFB0B0B0),
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPodium() {
    final playerCount = widget.leaderboard.length;

    // Calculate positions based on animation phase
    // Position values: -1 = left, 0 = center, 1 = right

    return SizedBox(
      height: 280, // Fixed height for the podium area
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (moves from center to left)
          if (playerCount > 1 && _isPlaceVisible(2))
            AnimatedBuilder(
              animation: _secondPlacePositionAnimation,
              builder: (context, child) {
                // Fade in from center position
                final opacity = _secondPlacePositionAnimation.value < 1.0
                    ? 1.0
                    : 1.0;
                return Opacity(opacity: opacity, child: child);
              },
              child: _buildPodiumPlace(widget.leaderboard[1], 2, 90),
            )
          else
            const SizedBox(width: 100),

          const SizedBox(width: 8),

          // 1st place (always in center, appears last)
          if (playerCount > 0 && _isPlaceVisible(1))
            _buildPodiumPlace(widget.leaderboard[0], 1, 120)
          else
            const SizedBox(width: 100),

          const SizedBox(width: 8),

          // 3rd place (moves from center to right)
          if (playerCount > 2 && _isPlaceVisible(3))
            AnimatedBuilder(
              animation: _thirdPlacePositionAnimation,
              builder: (context, child) {
                // Fade in from center position
                final opacity = _thirdPlacePositionAnimation.value < 1.0
                    ? 1.0
                    : 1.0;
                return Opacity(opacity: opacity, child: child);
              },
              child: _buildPodiumPlace(widget.leaderboard[2], 3, 70),
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(PlayerScore player, int place, double height) {
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };

    final crownEmoji = place == 1 ? '👑' : '';
    final animatedScore = _getAnimatedScoreForPlace(place, player.score);
    final barProgress = _getBarProgressForPlace(place);
    final isWinner = place == 1;

    // Build the top part (crown, avatar, name) - this gets the winner animation
    Widget topContent = Column(
      children: [
        // Crown for 1st place
        if (place == 1)
          AnimatedBuilder(
            animation: _winnerCelebrationController,
            builder: (context, child) {
              final bounce = _winnerAnimationTriggered
                  ? sin(_winnerCelebrationController.value * pi * 4) * 0.1 + 1.0
                  : 1.0;
              return Transform.scale(scale: bounce, child: child);
            },
            child: Text(crownEmoji, style: const TextStyle(fontSize: 24)),
          ),

        // Avatar with winner glow
        AnimatedBuilder(
          animation: _winnerCelebrationController,
          builder: (context, child) {
            final glowIntensity = isWinner && _winnerAnimationTriggered
                ? _winnerGlowAnimation.value
                : 0.0;
            final scale = isWinner && _winnerAnimationTriggered
                ? _winnerScaleAnimation.value
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isWinner && _winnerAnimationTriggered
                      ? [
                          BoxShadow(
                            color: colors[1]!.withOpacity(0.8 * glowIntensity),
                            blurRadius: 30 * glowIntensity,
                            spreadRadius: 10 * glowIntensity,
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            );
          },
          child: Container(
            width: place == 1 ? 70 : 55,
            height: place == 1 ? 70 : 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors[place]!, width: 4),
              color: const Color(0xFF0E5F88),
              boxShadow: [
                BoxShadow(
                  color: colors[place]!.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: player.avatar != null
                ? ClipOval(
                    child: Image.asset(
                      'lib/assets/${player.avatar}',
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      player.name.isNotEmpty
                          ? player.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: place == 1 ? 28 : 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),

        // Name
        SizedBox(
          width: 100,
          child: Text(
            player.name,
            style: GoogleFonts.comicNeue(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Podium block with animated height growing from bottom
        SizedBox(
          width: 100,
          height: height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Animated bar that grows from bottom
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 100,
                height: height * barProgress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors[place]!, colors[place]!.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: colors[place]!.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[place]!.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              // Content overlay (always visible, centered in full height)
              SizedBox(
                width: 100,
                height: height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$place',
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$animatedScore pts',
                        style: GoogleFonts.comicNeue(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (place * 200)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: topContent,
    );
  }

  Widget _buildLeaderboardList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A4A6F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22D3EE).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.leaderboard.length,
          separatorBuilder: (_, __) => Divider(
            color: const Color(0xFF22D3EE).withOpacity(0.2),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final player = widget.leaderboard[index];
            return _buildLeaderboardRow(player, index + 1);
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(PlayerScore player, int rank) {
    final isTopThree = rank <= 3;
    final rankColors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    // Use animated score for top 3, final score for others
    final displayScore = isTopThree
        ? _getAnimatedScoreForPlace(rank, player.score)
        : player.score;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree
                  ? rankColors[rank]!.withOpacity(0.2)
                  : const Color(0xFF0E5F88),
              border: isTopThree
                  ? Border.all(color: rankColors[rank]!, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.comicNeue(
                  color: isTopThree ? rankColors[rank]! : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0E5F88),
              border: Border.all(
                color: const Color(0xFF22D3EE).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: player.avatar != null
                ? ClipOval(
                    child: Image.asset(
                      'lib/assets/${player.avatar}',
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      player.name.isNotEmpty
                          ? player.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.comicNeue(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Text(
              player.name,
              style: GoogleFonts.comicNeue(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DD4BF), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$displayScore pts',
                  style: GoogleFonts.comicNeue(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${player.correctAnswers}/${player.totalAnswered} correct',
                style: GoogleFonts.comicNeue(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9A223), Color(0xFFB8891D)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD9A223), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9A223).withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  'BACK TO LOBBY',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
        ..color = Colors.white.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(star.opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final x = star.x * size.width;
      final y = star.y * size.height;

      canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      canvas.drawCircle(Offset(x, y), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}

// Custom painter for rendering confetti particles
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation * pi / 180);

      // Draw a small rectangle as confetti
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
