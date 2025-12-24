import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question.dart';

class QuizPlayScreen extends StatefulWidget {
  final String roomId;
  final List<Question> questions;

  const QuizPlayScreen({
    super.key,
    required this.roomId,
    required this.questions,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  bool _showAllQuestions = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF05396B),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Quiz Lobby', style: TextStyle(color: Colors.white)),
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
                    // Room Code Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5F88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Room Code',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.roomId,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF22D3EE),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Share this code with other players',
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quiz Info
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5F88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            'Questions',
                            '${widget.questions.length}',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: const Color(0xFF22D3EE),
                          ),
                          _buildInfoItem(
                            'Players',
                            '1',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start Game Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllQuestions = !_showAllQuestions;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _showAllQuestions
                                ? [const Color(0xFF9333EA), const Color(0xFFC084FC)]
                                : [const Color(0xFFD9A223), const Color(0xFFF4A33C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_esports, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              _showAllQuestions ? 'Hide Questions' : 'Start Game',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Questions List
                    if (_showAllQuestions) ...[
                      const Text(
                        'Questions Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.questions.length,
                        itemBuilder: (context, index) {
                          final question = widget.questions[index];
                          return _buildQuestionCard(question, index + 1);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF22D3EE),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, int questionNumber) {
    final isYesNo = question.type == 'yes_no';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E5F88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22D3EE), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number and type badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Q$questionNumber',
                style: const TextStyle(
                  color: Color(0xFF22D3EE),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isYesNo ? const Color(0xFF9333EA) : const Color(0xFFD9A223),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isYesNo ? 'Yes/No' : 'Multiple Choice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question text
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Options
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isCorrect = option == question.correctAnswer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF22D3EE) : const Color(0xFF05396B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? const Color(0xFF22D3EE) : const Color(0xFF22D3EE),
                      width: isCorrect ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${String.fromCharCode(65 + index)}.', // A, B, C, D
                        style: TextStyle(
                          color: isCorrect ? const Color(0xFF05396B) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isCorrect ? const Color(0xFF05396B) : Colors.white,
                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF05396B),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
