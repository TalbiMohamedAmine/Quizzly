import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player_stats.dart';
import '../services/player_stats_service.dart';
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

class PlayerStatsScreen extends StatefulWidget {
  static const routeName = '/player-stats';
  
  final String? userId;
  
  const PlayerStatsScreen({super.key, this.userId});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;
  final Random _random = Random();
  final _statsService = PlayerStatsService();
  final _authService = AuthService();

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
    _controller.dispose();
    super.dispose();
  }

  String? get _targetUserId {
    return widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final userId = _targetUserId;
    
    if (userId == null) {
      return Scaffold(
        body: _buildBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please sign in to view your stats',
                  style: GoogleFonts.comicNeue(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: StreamBuilder<PlayerStats>(
                  stream: _statsService.watchPlayerStats(userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading stats',
                              style: GoogleFonts.comicNeue(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF22D3EE),
                        ),
                      );
                    }

                    final stats = snapshot.data!;
                    return _buildStatsContent(stats);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF05396B), Color(0xFF0E5F88)],
            ),
          ),
        ),
        CustomPaint(
          painter: StarsPainter(stars: _stars),
          size: Size.infinite,
        ),
        child,
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A4A6F).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '📊 My Statistics',
            style: GoogleFonts.comicNeue(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(PlayerStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main stats grid
          _buildMainStatsGrid(stats),
          const SizedBox(height: 24),
          
          // Favorite category card
          _buildFavoriteCategoryCard(stats),
          const SizedBox(height: 24),
          
          // Category breakdown
          if (stats.categoryStats.isNotEmpty) ...[
            _buildCategoryBreakdown(stats),
            const SizedBox(height: 24),
          ],
          
          // Additional info
          _buildAdditionalInfo(stats),
        ],
      ),
    );
  }

  Widget _buildMainStatsGrid(PlayerStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              icon: Icons.sports_esports_rounded,
              label: 'Games Played',
              value: stats.totalGamesPlayed.toString(),
              color: const Color(0xFF22D3EE),
            ),
            _buildStatCard(
              icon: Icons.emoji_events_rounded,
              label: 'Total Wins',
              value: stats.totalWins.toString(),
              color: const Color(0xFFFFD700),
            ),
            _buildStatCard(
              icon: Icons.stars_rounded,
              label: 'Total Points',
              value: _formatNumber(stats.totalPoints),
              color: const Color(0xFF8B5CF6),
            ),
            _buildStatCard(
              icon: Icons.trending_up_rounded,
              label: 'Avg Score',
              value: stats.avgScore.toStringAsFixed(0),
              color: const Color(0xFF10B981),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.comicNeue(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCategoryCard(PlayerStats stats) {
    final favorite = stats.favoriteCategory;
    final winRate = stats.winRate;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD9A223),
            Color(0xFFB8891D),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9A223).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorite Category',
                  style: GoogleFonts.comicNeue(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  favorite ?? 'No games yet',
                  style: GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Win Rate',
                style: GoogleFonts.comicNeue(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${winRate.toStringAsFixed(1)}%',
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(PlayerStats stats) {
    // Sort categories by games played
    final sortedCategories = stats.categoryStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final totalGames = sortedCategories.fold<int>(0, (sum, e) => sum + e.value);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A4A6F).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22D3EE).withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pie_chart_rounded,
                color: Color(0xFF22D3EE),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Category Breakdown',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedCategories.take(6).map((entry) {
            final percentage = totalGames > 0 
                ? (entry.value / totalGames * 100) 
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryRow(
                category: entry.key,
                count: entry.value,
                percentage: percentage,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required String category,
    required int count,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                category,
                style: GoogleFonts.comicNeue(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count games',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(PlayerStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A4A6F).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (stats.lastPlayedAt != null)
            _buildInfoRow(
              icon: Icons.access_time_rounded,
              label: 'Last Played',
              value: _formatDate(stats.lastPlayedAt!),
            ),
          if (stats.totalGamesPlayed > 0) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildInfoRow(
              icon: Icons.check_circle_rounded,
              label: 'Games Won',
              value: '${stats.totalWins} / ${stats.totalGamesPlayed}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.comicNeue(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
  bool shouldRepaint(covariant StarsPainter oldDelegate) => true;
}
