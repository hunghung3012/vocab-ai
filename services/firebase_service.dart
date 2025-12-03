import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // DECK OPERATIONS

  Future<void> createDeck(Deck deck) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deck.id)
        .set(deck.toMap());
  }

  Future<void> updateDeck(Deck deck) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deck.id)
        .update(deck.toMap());
  }

  Future<void> deleteDeck(String deckId) async {
    if (userId == null) throw Exception('User not authenticated');

    // Delete all flashcards in the deck
    final flashcards = await getFlashcardsByDeck(deckId);
    for (var card in flashcards) {
      await deleteFlashcard(card.id);
    }

    // Delete the deck
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .delete();
  }

  Stream<List<Deck>> getDecksStream() {
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .orderBy('lastStudiedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Deck.fromMap(doc.data()))
        .toList());
  }

  Future<Deck?> getDeck(String deckId) async {
    if (userId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('decks')
        .doc(deckId)
        .get();

    if (!doc.exists) return null;
    return Deck.fromMap(doc.data()!);
  }

  // FLASHCARD OPERATIONS

  Future<void> createFlashcard(Flashcard card, String deckId) async {
    if (userId == null) throw Exception('User not authenticated');

    // Save flashcard
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(card.id)
        .set(card.toMap());

    // Update deck's flashcard list
    final deck = await getDeck(deckId);
    if (deck != null) {
      final updatedIds = [...deck.flashcardIds, card.id];
      await updateDeck(deck.copyWith(
        flashcardIds: updatedIds,
        totalWords: updatedIds.length,
      ));
    }
  }

  Future<void> updateFlashcard(Flashcard card) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(card.id)
        .update(card.toMap());
  }

  Future<void> deleteFlashcard(String cardId) async {
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcards')
        .doc(cardId)
        .delete();
  }

  Future<List<Flashcard>> getFlashcardsByDeck(String deckId) async {
    if (userId == null) return [];

    final deck = await getDeck(deckId);
    if (deck == null) return [];

    final List<Flashcard> cards = [];
    for (var cardId in deck.flashcardIds) {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcards')
          .doc(cardId)
          .get();

      if (doc.exists) {
        cards.add(Flashcard.fromMap(doc.data()!));
      }
    }

    return cards;
  }

  // STATISTICS

  Future<Map<String, dynamic>> getUserStats() async {
    if (userId == null) return {};

    final decks = await getDecksStream().first;
    int totalWords = 0;
    int masteredWords = 0;

    for (var deck in decks) {
      totalWords += deck.totalWords;
      masteredWords += deck.masteredWords;
    }

    // Calculate study streak
    final streakDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('studyStreak')
        .get();

    int studyStreak = streakDoc.exists
        ? (streakDoc.data()?['days'] ?? 0)
        : 0;


    return {
      'totalWords': totalWords,
      'masteredWords': masteredWords,
      'studyStreak': studyStreak,
      'totalDecks': decks.length,
    };
  }
  Future<String> uploadImage(File imageFile, String deckId) async {
    // Implement upload to Firebase Storage
    // Return image URL
    return "x";
  }

  Future<void> updateStudyStreak() async {
    if (userId == null) return;

    final streakRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('studyStreak');

    final doc = await streakRef.get();
    final now = DateTime.now();

    if (!doc.exists) {
      await streakRef.set({
        'days': 1,
        'lastStudyDate': now.toIso8601String(),
      });
      return;
    }

    final data = doc.data()!;
    final lastStudy = DateTime.parse(data['lastStudyDate']);
    final difference = now.difference(lastStudy).inDays;

    if (difference == 1) {
      // Consecutive day
      await streakRef.update({
        'days': (data['days'] ?? 0) + 1,
        'lastStudyDate': now.toIso8601String(),
      });
    } else if (difference > 1) {
      // Streak broken
      await streakRef.update({
        'days': 1,
        'lastStudyDate': now.toIso8601String(),
      });
    }
    // Same day, no update needed
  }

}