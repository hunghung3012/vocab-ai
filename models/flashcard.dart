class Flashcard {
  final String id;
  final String word;
  final String definition;
  final String? example;
  final String? pronunciation;
  final String? imageUrl; // New field for image

  // Spaced Repetition Algorithm (SM-2)
  int repetitions;
  double easeFactor;
  int interval;
  DateTime? nextReviewDate;
  DateTime lastReviewDate;
  int correctCount;
  int incorrectCount;

  Flashcard({
    required this.id,
    required this.word,
    required this.definition,
    this.example,
    this.pronunciation,
    this.imageUrl,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.nextReviewDate,
    DateTime? lastReviewDate,
    this.correctCount = 0,
    this.incorrectCount = 0,
  }) : lastReviewDate = lastReviewDate ?? DateTime.now();

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'definition': definition,
      'example': example,
      'pronunciation': pronunciation,
      'imageUrl': imageUrl,
      'repetitions': repetitions,
      'easeFactor': easeFactor,
      'interval': interval,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'lastReviewDate': lastReviewDate.toIso8601String(),
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
    };
  }

  // Convert from Firestore
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] ?? '',
      word: map['word'] ?? '',
      definition: map['definition'] ?? '',
      example: map['example'],
      pronunciation: map['pronunciation'],
      imageUrl: map['imageUrl'],
      repetitions: map['repetitions'] ?? 0,
      easeFactor: (map['easeFactor'] ?? 2.5).toDouble(),
      interval: map['interval'] ?? 0,
      nextReviewDate: map['nextReviewDate'] != null
          ? DateTime.parse(map['nextReviewDate'])
          : null,
      lastReviewDate: map['lastReviewDate'] != null
          ? DateTime.parse(map['lastReviewDate'])
          : DateTime.now(),
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
    );
  }

  Flashcard copyWith({
    String? id,
    String? word,
    String? definition,
    String? example,
    String? pronunciation,
    String? imageUrl,
    int? repetitions,
    double? easeFactor,
    int? interval,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    int? correctCount,
    int? incorrectCount,
  }) {
    return Flashcard(
      id: id ?? this.id,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      pronunciation: pronunciation ?? this.pronunciation,
      imageUrl: imageUrl ?? this.imageUrl,
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
    );
  }
}