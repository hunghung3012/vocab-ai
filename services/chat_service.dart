import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiChatService {
  late final GenerativeModel _textModel;
  late final GenerativeModel _imageModel;
  late final GenerativeModel _vocabModel;
  late final GenerativeModel _intentModel;

  GeminiChatService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null) {
      throw Exception('Chưa cấu hình API Key trong file .env');
    }

    // =========================
    // MODEL CHAT
    // =========================
    _textModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are a friendly English tutor. Answer questions naturally, "
              "politely, and concisely. Keep responses helpful and easy to read."
      ),
    );

    // =========================
    // MODEL NHẬN DIỆN ẢNH
    // =========================
    _imageModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are an expert at identifying objects in images. "
              "Return ONLY a valid JSON object:\n"
              "{\"word\": \"object_name\", \"definition\": \"clear definition\", "
              "\"type\": \"noun/verb/adjective\", "
              "\"related\": [\"w1\", \"w2\", \"w3\"], \"confidence\": 0.95}"
      ),
    );

    // =========================
    // MODEL PHÂN TÍCH TỪ VỰNG
    // =========================
    _vocabModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "You are an English vocabulary expert. Always analyze the user's word "
              "and return ONLY JSON:\n"
              "{"
              "\"word\": \"the_word\", "
              "\"definition\": \"clear definition\", "
              "\"type\": \"noun/verb/etc\", "
              "\"related\": [\"syn1\", \"syn2\", \"rel\"], "
              "\"example_en\": \"English example sentence\", "
              "\"example_vi\": \"Vietnamese example translation\", "
              "\"confidence\": 0.98"
              "}"
      ),
    );

    // =========================
    // MODEL PHÂN LOẠI INTENT
    // =========================
    _intentModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
          "Classify the user's message into EXACTLY one label: "
              "\"vocab_query\" OR \"normal_chat\".\n"
              "Return ONLY JSON:\n"
              "{\"label\": \"vocab_query\"}\n"
              "OR\n"
              "{\"label\": \"normal_chat\"}\n\n"
              "A vocab_query means the user is asking for definition, meaning, "
              "explanation, synonyms, usage, or vocabulary info of a word/phrase — "
              "even if misspelled."
      ),
    );
  }

  // --------------------------------------------------
  // 🔍 HÀM PHÂN LOẠI Ý ĐỊNH
  // --------------------------------------------------
  Future<bool> _isVocabIntent(String message) async {
    try {
      final resp = await _intentModel.generateContent([
        Content.text(message)
      ]);

      if (resp.text == null) return false;

      final jsonText = resp.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final result = jsonDecode(jsonText);
      return result['label'] == 'vocab_query';
    } catch (e) {
      print("Intent classification error: $e");
      return false;
    }
  }

  // API PUBLIC
  Future<bool> shouldReturnVocabCard(String message) async {
    return await _isVocabIntent(message);
  }

  // --------------------------------------------------
  // CHAT STREAM
  // --------------------------------------------------
  Stream<String> sendTextStream(String message) async* {
    final response = _textModel.generateContentStream([
      Content.text(message),
    ]);

    await for (final chunk in response) {
      if (chunk.text != null) yield chunk.text!;
    }
  }

  // --------------------------------------------------
  // PHÂN TÍCH TỪ VỰNG
  // --------------------------------------------------
  Future<Map<String, dynamic>?> analyzeVocabulary(String message) async {
    try {
      final resp = await _vocabModel.generateContent([
        Content.text("Analyze this word: $message")
      ]);

      if (resp.text == null) return null;

      final jsonText = resp.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonText);
    } catch (e) {
      print("Vocab error: $e");
      return null;
    }
  }

  // --------------------------------------------------
  // NHẬN DIỆN ẢNH
  // --------------------------------------------------
  Future<Map<String, dynamic>?> analyzeImage(File image, String prompt) async {
    try {
      final bytes = await image.readAsBytes();

      final finalPrompt = prompt.isEmpty
          ? "Identify the main object in this image."
          : prompt;

      final resp = await _imageModel.generateContent([
        Content.multi([
          TextPart(finalPrompt),
          DataPart("image/jpeg", bytes),
        ])
      ]);

      if (resp.text == null) return null;

      final jsonText = resp.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonText);
    } catch (e) {
      print("Image error: $e");
      return null;
    }
  }
}
