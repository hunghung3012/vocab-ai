class Deck {
  final String id;
  final String name;
  final List<String> flashcardIds;
  final DateTime createdDate;
  final DateTime lastStudiedDate;
  final int totalWords;
  final int masteredWords;
  final double progress;

  Deck({
    required this.id,
    required this.name,
    required this.flashcardIds,
    DateTime? createdDate,
    DateTime? lastStudiedDate,
    this.totalWords = 0,
    this.masteredWords = 0,
    this.progress = 0.0,
  })  : createdDate = createdDate ?? DateTime.now(),
        lastStudiedDate = lastStudiedDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'flashcardIds': flashcardIds,
      'createdDate': createdDate.toIso8601String(),
      'lastStudiedDate': lastStudiedDate.toIso8601String(),
      'totalWords': totalWords,
      'masteredWords': masteredWords,
      'progress': progress,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      flashcardIds: List<String>.from(map['flashcardIds'] ?? []),
      createdDate: map['createdDate'] != null
          ? DateTime.parse(map['createdDate'])
          : DateTime.now(),
      lastStudiedDate: map['lastStudiedDate'] != null
          ? DateTime.parse(map['lastStudiedDate'])
          : DateTime.now(),
      totalWords: map['totalWords'] ?? 0,
      masteredWords: map['masteredWords'] ?? 0,
      progress: (map['progress'] ?? 0.0).toDouble(),
    );
  }

  Deck copyWith({
    String? id,
    String? name,
    List<String>? flashcardIds,
    DateTime? createdDate,
    DateTime? lastStudiedDate,
    int? totalWords,
    int? masteredWords,
    double? progress,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      createdDate: createdDate ?? this.createdDate,
      lastStudiedDate: lastStudiedDate ?? this.lastStudiedDate,
      totalWords: totalWords ?? this.totalWords,
      masteredWords: masteredWords ?? this.masteredWords,
      progress: progress ?? this.progress,
    );
  }
}