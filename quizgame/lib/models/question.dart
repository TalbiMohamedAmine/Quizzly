class Question {
  final String id;
  final String question;
  final String type; // 'yes_no' or 'multiple_choice'
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
  });

  // For storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }

  // For retrieving from Firestore
  factory Question.fromMap(Map<String, dynamic> map, String docId) {
    return Question(
      id: docId,
      question: map['question'] ?? '',
      type: map['type'] ?? 'multiple_choice',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
    );
  }
}
