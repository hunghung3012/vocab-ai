import 'dart:io';

class VocabResult {
  final String word;
  final String definition;
  final String type;
  final List<String> relatedWords;
  final double confidence;
  final String? exampleEn;  // Câu ví dụ tiếng Anh
  final String? exampleVi;  // Câu ví dụ tiếng Việt

  VocabResult({
    required this.word,
    required this.definition,
    required this.type,
    required this.relatedWords,
    this.confidence = 1.0,
    this.exampleEn,
    this.exampleVi,
  });

  factory VocabResult.fromJson(Map<String, dynamic> json) {
    return VocabResult(
      word: json['word'] ?? '',
      definition: json['definition'] ?? '',
      type: json['type'] ?? 'noun',
      relatedWords: (json['related'] as List?)?.map((e) => e.toString()).toList() ?? [],
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      exampleEn: json['example_en'],
      exampleVi: json['example_vi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'definition': definition,
      'type': type,
      'related': relatedWords,
      'confidence': confidence,
      'example_en': exampleEn,
      'example_vi': exampleVi,
    };
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final File? image;
  final VocabResult? vocabResult;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.image,
    this.vocabResult,
  });
}