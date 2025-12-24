import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/room.dart';
import 'quiz_generation_screen.dart';

class QuizModeSelectionScreen extends StatelessWidget {
  final String roomId;

  const QuizModeSelectionScreen({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF05396B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quiz Mode', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: const Color(0xFF05396B),
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
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'How do you want to create your quiz?',
                      style: GoogleFonts.comicNeue(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Generate Quiz Option
                    SizedBox(
                      width: double.infinity,
                      child: _buildModeCard(
                        context,
                        icon: Icons.auto_awesome,
                        title: 'Generate Quiz',
                        description: 'Let AI generate questions for you',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizGenerationScreen(
                                roomId: roomId,
                              ),
                            ),
                          );
                        },
                        color: const Color(0xFF4BA4FF),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Own Quiz Option
                    SizedBox(
                      width: double.infinity,
                      child: _buildModeCard(
                        context,
                        icon: Icons.edit,
                        title: 'Create My Own Quiz',
                        description: 'Manually add questions and answers',
                        onTap: () {
                          // TODO: Navigate to custom quiz creation screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Custom quiz creation coming soon!'),
                            ),
                          );
                        },
                        color: const Color(0xFFD9A223),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.comicNeue(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
