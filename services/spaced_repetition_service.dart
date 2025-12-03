

import 'package:vocab_ai/models/flashcard.dart';

class SpacedRepetitionService {
  // SM-2 Algorithm implementation (giống Anki)
  // quality: 0-5
  // 0: Không nhớ gì
  // 1: Nhớ sai
  // 2: Nhớ đúng nhưng khó khăn
  // 3: Nhớ đúng với effort
  // 4: Nhớ đúng dễ dàng
  // 5: Nhớ đúng hoàn hảo

  Flashcard updateCard(Flashcard card, int quality) {
    if (quality < 0 || quality > 5) {
      throw ArgumentError('Quality must be between 0 and 5');
    }

    int newRepetitions = card.repetitions;
    double newEaseFactor = card.easeFactor;
    int newInterval = card.interval;
    DateTime newNextReviewDate;
    int newCorrectCount = card.correctCount;
    int newIncorrectCount = card.incorrectCount;

    if (quality >= 3) {
      // Correct answer
      newCorrectCount++;

      if (card.repetitions == 0) {
        newInterval = 1;
      } else if (card.repetitions == 1) {
        newInterval = 6;
      } else {
        newInterval = (card.interval * card.easeFactor).round();
      }

      newRepetitions = card.repetitions + 1;
    } else {
      // Incorrect answer
      newIncorrectCount++;
      newRepetitions = 0;
      newInterval = 1;
    }

    // Update ease factor
    newEaseFactor = card.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    // Calculate next review date
    newNextReviewDate = DateTime.now().add(Duration(days: newInterval));

    return card.copyWith(
      repetitions: newRepetitions,
      easeFactor: newEaseFactor,
      interval: newInterval,
      nextReviewDate: newNextReviewDate,
      lastReviewDate: DateTime.now(),
      correctCount: newCorrectCount,
      incorrectCount: newIncorrectCount,
    );
  }

  // Get cards due for review
  List<Flashcard> getDueCards(List<Flashcard> allCards) {
    final now = DateTime.now();
    return allCards.where((card) {
      if (card.nextReviewDate == null) return true;
      return card.nextReviewDate!.isBefore(now) ||
          card.nextReviewDate!.isAtSameMomentAs(now);
    }).toList();
  }

  // Get new cards (never studied)
  List<Flashcard> getNewCards(List<Flashcard> allCards) {
    return allCards.where((card) => card.repetitions == 0).toList();
  }

  // Get mastered cards (studied multiple times with high ease)
  List<Flashcard> getMasteredCards(List<Flashcard> allCards) {
    return allCards.where((card) =>
    card.repetitions >= 5 && card.easeFactor >= 2.5
    ).toList();
  }

  // Calculate retention rate
  double getRetentionRate(List<Flashcard> cards) {
    if (cards.isEmpty) return 0.0;

    int totalReviews = 0;
    int correctReviews = 0;

    for (var card in cards) {
      totalReviews += card.correctCount + card.incorrectCount;
      correctReviews += card.correctCount;
    }

    if (totalReviews == 0) return 0.0;
    return correctReviews / totalReviews;
  }
}