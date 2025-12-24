import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/question.dart';

class GeminiQuizService {
  // Replace with your own API key from https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBY3OJR-w4vW8ZOOGA-HaODt5Ya6xkoCek';

  late final GenerativeModel _model;

  GeminiQuizService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<List<Question>> generateQuiz({
    required String category,
    required String difficulty,
    required int questionCount,
  }) async {
    try {
      final prompt = _buildPrompt(category, difficulty, questionCount);

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('No response from API');
      }

      final questions = _parseQuestions(response.text!, questionCount);
      return questions;
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }

  String _buildPrompt(String category, String difficulty, int questionCount) {
    return '''Generate exactly $questionCount quiz questions about $category with $difficulty difficulty level.

The response MUST be in this exact JSON format:
{
  "questions": [
    {
      "question": "Question text?",
      "type": "yes_no",
      "options": ["Yes", "No"],
      "correctAnswer": "Yes"
    },
    {
      "question": "Question text?",
      "type": "multiple_choice",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": "Option A"
    }
  ]
}

Important rules:
1. Generate a mix of "yes_no" and "multiple_choice" questions
2. For yes_no questions: options must be ["Yes", "No"]
3. For multiple_choice questions: provide exactly 4 options
4. correctAnswer must match one of the options exactly
5. Use $difficulty difficulty level (Easy/Medium/Hard/Mixed)
6. All about the category: $category
7. Return ONLY valid JSON, no extra text

Generate the questions now:''';
  }

  List<Question> _parseQuestions(String responseText, int expectedCount) {
    try {
      // Extract JSON from response
      String jsonText = responseText;

      // Try to find JSON object in the response
      final startIndex = jsonText.indexOf('{');
      final endIndex = jsonText.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1) {
        jsonText = jsonText.substring(startIndex, endIndex + 1);
      }

      // Parse JSON
      final Map<String, dynamic> jsonData = _parseJson(jsonText);

      if (!jsonData.containsKey('questions')) {
        throw Exception('Invalid response format: missing questions array');
      }

      final List<dynamic> questionsData = jsonData['questions'];
      final List<Question> questions = [];

      for (int i = 0; i < questionsData.length && i < expectedCount; i++) {
        final questionData = questionsData[i];
        final question = Question(
          id: 'q_${i + 1}',
          question: questionData['question'] ?? '',
          type: questionData['type'] ?? 'multiple_choice',
          options: List<String>.from(questionData['options'] ?? []),
          correctAnswer: questionData['correctAnswer'] ?? '',
        );
        questions.add(question);
      }

      return questions;
    } catch (e) {
      throw Exception('Failed to parse quiz response: $e');
    }
  }

  // Simple JSON parser to handle the response
  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      // Remove any BOM or whitespace
      String cleaned = jsonString.trim();

      // Replace problematic escaped characters
      cleaned = cleaned
          .replaceAll('\\"', '"')
          .replaceAll('\\n', '\n')
          .replaceAll('\\/', '/');

      // Manual JSON parsing
      final Map<String, dynamic> result = {};

      // Find questions array
      final questionsStart = cleaned.indexOf('"questions"');
      if (questionsStart == -1) {
        throw Exception('Missing questions key');
      }

      final arrayStart = cleaned.indexOf('[', questionsStart);
      final arrayEnd = cleaned.lastIndexOf(']');

      if (arrayStart == -1 || arrayEnd == -1) {
        throw Exception('Invalid array format');
      }

      final String questionsArray =
          cleaned.substring(arrayStart + 1, arrayEnd).trim();
      final List<dynamic> questions = [];

      // Parse questions - split by }, {
      int braceCount = 0;
      int currentStart = 0;

      for (int i = 0; i < questionsArray.length; i++) {
        if (questionsArray[i] == '{') braceCount++;
        if (questionsArray[i] == '}') {
          braceCount--;
          if (braceCount == 0) {
            String questionStr =
                questionsArray.substring(currentStart, i + 1).trim();
            if (questionStr.startsWith(',')) {
              questionStr = questionStr.substring(1).trim();
            }
            if (questionStr.isNotEmpty) {
              final q = _parseQuestionObject(questionStr);
              questions.add(q);
            }
            currentStart = i + 1;
          }
        }
      }

      result['questions'] = questions;
      return result;
    } catch (e) {
      // Fallback: try using dart:convert if manual parsing fails
      throw Exception('JSON parsing failed: $e');
    }
  }

  Map<String, dynamic> _parseQuestionObject(String questionStr) {
    final Map<String, dynamic> question = {};

    // Extract question text
    final questionMatch = RegExp(r'"question"\s*:\s*"([^"]*)"').firstMatch(questionStr);
    if (questionMatch != null) {
      question['question'] = questionMatch.group(1);
    }

    // Extract type
    final typeMatch = RegExp(r'"type"\s*:\s*"([^"]*)"').firstMatch(questionStr);
    if (typeMatch != null) {
      question['type'] = typeMatch.group(1);
    }

    // Extract options array
    final optionsMatch = RegExp(r'"options"\s*:\s*\[(.*?)\]').firstMatch(questionStr);
    if (optionsMatch != null) {
      final optionsStr = optionsMatch.group(1) ?? '';
      final options = RegExp(r'"([^"]*)"').allMatches(optionsStr)
          .map((m) => m.group(1) ?? '')
          .toList();
      question['options'] = options;
    }

    // Extract correct answer
    final answerMatch = RegExp(r'"correctAnswer"\s*:\s*"([^"]*)"').firstMatch(questionStr);
    if (answerMatch != null) {
      question['correctAnswer'] = answerMatch.group(1);
    }

    return question;
  }
}
