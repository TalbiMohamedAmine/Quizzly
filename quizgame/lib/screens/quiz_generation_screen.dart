import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_quiz_service.dart';
import '../models/question.dart';
import 'quiz_play_screen.dart';

class QuizGenerationScreen extends StatefulWidget {
  final String roomId;

  const QuizGenerationScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<QuizGenerationScreen> createState() => _QuizGenerationScreenState();
}

class _QuizGenerationScreenState extends State<QuizGenerationScreen> {
  String _selectedCategory = 'General Knowledge';
  String? _customCategory;
  int _numberOfQuestions = 10;
  String _difficulty = 'Medium';
  bool _isGenerating = false;
  bool _showCustomCategoryInput = false;

  final List<String> _categories = [
    'General Knowledge',
    'Science',
    'History',
    'Geography',
    'Sports',
    'Entertainment',
    'Technology',
    'Arts',
    'Literature',
    'Mathematics',
  ];

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard', 'Mixed'];

  Future<void> _generateQuiz() async {
    setState(() => _isGenerating = true);

    try {
      final geminiService = GeminiQuizService();
      final category =
          _showCustomCategoryInput && _customCategory != null && _customCategory!.isNotEmpty
              ? _customCategory!
              : _selectedCategory;

      final questions = await geminiService.generateQuiz(
        category: category,
        difficulty: _difficulty,
        questionCount: _numberOfQuestions,
      );

      if (mounted) {
        // Navigate to QuizPlayScreen with the generated questions
        Navigator.of(context).pushReplacementNamed(
          'quiz_play',
          arguments: {
            'roomId': widget.roomId,
            'questions': questions,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate quiz: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

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
        title: const Text('Generate Quiz', style: TextStyle(color: Colors.white)),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Quiz Settings',
                    style: GoogleFonts.comicNeue(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // White container card
                  Container(
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Title
                        Text(
                          'Quiz Settings',
                          style: GoogleFonts.comicNeue(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D3748),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Category Section
                        Text(
                          'Category',
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 24),

                        // Number of Questions Section
                        Text(
                          'Number & Questions',
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuestionCountControl(),
                        const SizedBox(height: 24),

                        // Difficulty Section
                        Text(
                          'Difficulty',
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDifficultySelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // START GAME Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2DD4BF),
                          Color(0xFF6366F1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isGenerating ? null : _generateQuiz,
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 28,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isGenerating
                                    ? 'GENERATING...'
                                    : 'START GAME',
                                style: GoogleFonts.comicNeue(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.sports_esports,
                                color: Colors.white,
                                size: 24,
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
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E5F88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: DropdownButton<String>(
            value: _showCustomCategoryInput ? 'custom' : _selectedCategory,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
            ),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  if (newValue == 'custom') {
                    _showCustomCategoryInput = true;
                    _customCategory = '';
                  } else {
                    _selectedCategory = newValue;
                    _showCustomCategoryInput = false;
                    _customCategory = null;
                  }
                });
              }
            },
            items: [
              ..._categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }),
              DropdownMenuItem<String>(
                value: 'custom',
                child: Text(
                  '+ Create Custom Category',
                  style: TextStyle(
                    color: const Color(0xFF4BA4FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_showCustomCategoryInput) ...[
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Enter Your Category',
              labelStyle: const TextStyle(color: Color(0xFF2D3748)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Color(0xFF2D3748)),
            onChanged: (value) {
              setState(() => _customCategory = value.trim());
            },
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selectedCategory.replaceAll('General Knowledge', 'Knowledge')}',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDifficultyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF05396B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22D3EE), width: 1),
      ),
      child: DropdownButton<String>(
        value: _difficulty,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF0E5F88),
        style: const TextStyle(color: Colors.white),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() => _difficulty = newValue);
          }
        },
        items: _difficulties
            .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            })
            .toList(),
      ),
    );
  }

  Widget _buildQuestionCountControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Minus button
        GestureDetector(
          onTap: _numberOfQuestions > 5
              ? () => setState(() => _numberOfQuestions--)
              : null,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _numberOfQuestions > 5
                  ? const Color(0xFF9333EA)
                  : Colors.grey,
              boxShadow: [
                if (_numberOfQuestions > 5)
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.remove,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        // Number display
        Column(
          children: [
            Text(
              '$_numberOfQuestions',
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Plus button
        GestureDetector(
          onTap: _numberOfQuestions < 50
              ? () => setState(() => _numberOfQuestions++)
              : null,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _numberOfQuestions < 50
                  ? const Color(0xFF9333EA)
                  : Colors.grey,
              boxShadow: [
                if (_numberOfQuestions < 50)
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      children: [
        // Easy button
        Expanded(
          child: _buildDifficultyButton('Easy'),
        ),
        const SizedBox(width: 12),
        // Medium button
        Expanded(
          child: _buildDifficultyButton('Medium'),
        ),
        const SizedBox(width: 12),
        // Hard button
        Expanded(
          child: _buildDifficultyButton('Hard'),
        ),
        const SizedBox(width: 12),
        // Mixed button
        Expanded(
          child: _buildDifficultyButton('Mixed'),
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(String label, {bool isFullWidth = false}) {
    final isSelected = _difficulty == label;
    final button = GestureDetector(
      onTap: () => setState(() => _difficulty = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9333EA) : const Color(0xFF22D3EE),
          border: Border.all(
            color: isSelected ? const Color(0xFF9333EA) : const Color(0xFF22D3EE),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );

    if (isFullWidth) {
      return button;
    }
    return button;
  }

  Widget _buildQuestionCountSlider() {
    return Column(
      children: [
        Slider(
          value: _numberOfQuestions.toDouble(),
          min: 5,
          max: 50,
          divisions: 9,
          activeColor: const Color(0xFF4BA4FF),
          inactiveColor: Colors.grey,
          onChanged: (double value) {
            setState(() => _numberOfQuestions = value.toInt());
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF05396B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_numberOfQuestions Questions',
            style: const TextStyle(
              color: Color(0xFF4BA4FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
