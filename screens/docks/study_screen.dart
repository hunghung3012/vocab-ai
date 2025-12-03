import 'package:flutter/material.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';
import '../../services/spaced_repetition_service.dart';

class StudyScreen extends StatefulWidget {
  final Deck deck;

  const StudyScreen({Key? key, required this.deck}) : super(key: key);

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final SpacedRepetitionService _srService = SpacedRepetitionService();

  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;

  int _correct = 0;
  int _incorrect = 0;
  int _skipped = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final allCards = await _firebaseService.getFlashcardsByDeck(widget.deck.id);
      final dueCards = _srService.getDueCards(allCards);

      setState(() {
        _cards = dueCards.isEmpty ? allCards : dueCards;
        _isLoading = false;
      });

      // Update study streak
      await _firebaseService.updateStudyStreak();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  void _handleAnswer(int quality) async {
    if (_currentIndex >= _cards.length) return;

    final currentCard = _cards[_currentIndex];
    final updatedCard = _srService.updateCard(currentCard, quality);

    try {
      // Update in Firebase
      await _firebaseService.updateFlashcard(updatedCard);

      // Update stats
      if (mounted) {
        setState(() {
          if (quality >= 3) {
            _correct++;
          } else {
            _incorrect++;
          }

          _cards[_currentIndex] = updatedCard;
          _showAnswer = false;
          _currentIndex++;
        });

        // Check if finished
        if (_currentIndex >= _cards.length) {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSkip() {
    if (_currentIndex >= _cards.length - 1) {
      // Last card - show completion
      setState(() {
        _skipped++;
      });
      _showCompletionDialog();
    } else {
      setState(() {
        _skipped++;
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Text(
              'Session Complete!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great work! You\'ve reviewed ${_cards.length} cards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Correct', _correct, Colors.green),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem('Incorrect', _incorrect, Colors.red),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.grey[300],
                  ),
                  _buildStatItem('Skipped', _skipped, Colors.orange),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentIndex = 0;
                      _correct = 0;
                      _incorrect = 0;
                      _skipped = 0;
                      _showAnswer = false;
                    });
                    _loadCards();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Study Again',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.deck.name),
          backgroundColor: Colors.purple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'All caught up!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No cards due for review.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentIndex >= _cards.length) {
      // Safety check
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCompletionDialog();
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentCard = _cards[_currentIndex];
    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.deck.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Study Mode',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Card ${_currentIndex + 1} of ${_cards.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Flashcard
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAnswer = !_showAnswer;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_showAnswer) ...[
                          const Text(
                            'WORD',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            currentCard.word,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Tap to reveal definition',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ] else ...[
                          Text(
                            currentCard.word,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            currentCard.definition,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (currentCard.example != null && currentCard.example!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '"${currentCard.example}"',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          if (currentCard.imageUrl != null && currentCard.imageUrl!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                currentCard.imageUrl!,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Session Stats
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSessionStat('Correct', _correct, Colors.green),
                _buildSessionStat('Incorrect', _incorrect, Colors.red),
                _buildSessionStat('Skipped', _skipped, Colors.orange),
              ],
            ),
          ),

          // Answer Buttons
          if (_showAnswer)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAnswerButton(
                      'Again',
                      Colors.red,
                          () => _handleAnswer(0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnswerButton(
                      'Hard',
                      Colors.orange,
                          () => _handleAnswer(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnswerButton(
                      'Good',
                      Colors.blue,
                          () => _handleAnswer(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnswerButton(
                      'Easy',
                      Colors.green,
                          () => _handleAnswer(5),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleSkip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showAnswer = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Show Answer',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}