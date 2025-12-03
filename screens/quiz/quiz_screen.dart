import 'package:flutter/material.dart';
import 'package:vocab_ai/widgets/app_bottom_nav.dart';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  final Deck? deck;

  const QuizScreen({Key? key, this.deck}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.deck != null) {
      _showQuizTypeSelection(widget.deck!);
    } else {
      _loadDecks();
    }
  }

  Future<void> _loadDecks() async {
    try {
      final decks = await _firebaseService.getDecksStream().first;
      setState(() {
        _decks = decks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showQuizTypeSelection(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizTypeSelectionScreen(deck: deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deck != null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book, color: Colors.white, size: 20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Take a Quiz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your knowledge with interactive quizzes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Select a Deck',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_decks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No decks available. Create a deck first!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                ...(_decks.map((deck) => _buildDeckCard(deck))),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showQuizTypeSelection(deck),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deck.totalWords} words',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.purple,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizTypeSelectionScreen extends StatelessWidget {
  final Deck deck;

  const QuizTypeSelectionScreen({Key? key, required this.deck})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          deck.name,
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Take a Quiz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test your knowledge with interactive quizzes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Quiz Types',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuizTypeCard(
                context,
                title: 'Multiple Choice',
                description: 'Select the correct meaning of each word',
                wordCount: '${deck.totalWords} words',
                difficulty: 'Intermediate',
                difficultyColor: Colors.orange,
                icon: Icons.check_circle_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultipleChoiceQuizScreen(deck: deck),
                    ),
                  );
                },
              ),
              _buildQuizTypeCard(
                context,
                title: 'Fill in the Blank',
                description: 'Complete sentences with the right vocabulary',
                wordCount: '15 words',
                difficulty: 'Advanced',
                difficultyColor: Colors.red,
                icon: Icons.edit_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
              ),
              _buildQuizTypeCard(
                context,
                title: 'Matching',
                description: 'Match words with their definitions',
                wordCount: '25 words',
                difficulty: 'Beginner',
                difficultyColor: Colors.green,
                icon: Icons.compare_arrows,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
              ),
              _buildQuizTypeCard(
                context,
                title: 'Listen & Spell',
                description: 'Hear the word and spell it correctly',
                wordCount: '18 words',
                difficulty: 'Intermediate',
                difficultyColor: Colors.orange,
                icon: Icons.hearing,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTypeCard(
      BuildContext context, {
        required String title,
        required String description,
        required String wordCount,
        required String difficulty,
        required Color difficultyColor,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: Colors.purple),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: difficultyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                difficulty,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: difficultyColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  wordCount,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Multiple Choice Quiz Implementation
class MultipleChoiceQuizScreen extends StatefulWidget {
  final Deck deck;

  const MultipleChoiceQuizScreen({Key? key, required this.deck})
      : super(key: key);

  @override
  State<MultipleChoiceQuizScreen> createState() =>
      _MultipleChoiceQuizScreenState();
}

class _MultipleChoiceQuizScreenState extends State<MultipleChoiceQuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isLoading = true;
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final cards = await _firebaseService.getFlashcardsByDeck(widget.deck.id);
      cards.shuffle();
      setState(() {
        _cards = cards.take(20).toList();
        _isLoading = false;
      });
      _generateOptions();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _generateOptions() {
    if (_cards.isEmpty) return;

    final currentCard = _cards[_currentIndex];
    final correctAnswer = currentCard.definition;

    // Get 3 wrong answers
    final wrongAnswers = _cards
        .where((c) => c.id != currentCard.id)
        .map((c) => c.definition)
        .toList()
      ..shuffle();

    final options = [
      correctAnswer,
      ...wrongAnswers.take(3),
    ]..shuffle();

    setState(() {
      _options = options;
    });
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;

      if (answer == _cards[_currentIndex].definition) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
      _generateOptions();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🎉 Quiz Complete!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '$_score / ${_cards.length}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${((_score / _cards.length) * 100).toInt()}%',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _isAnswered = false;
              });
              _cards.shuffle();
              _generateOptions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
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
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(
          child: Text('No cards available for quiz'),
        ),
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Question ${_currentIndex + 1}/${_cards.length}',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
            minHeight: 6,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'What is the meaning of:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      currentCard.word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ..._options.map((option) {
                    final isCorrect = option == currentCard.definition;
                    final isSelected = option == _selectedAnswer;

                    Color? bgColor;
                    Color? borderColor;

                    if (_isAnswered) {
                      if (isCorrect) {
                        bgColor = Colors.green.shade50;
                        borderColor = Colors.green;
                      } else if (isSelected) {
                        bgColor = Colors.red.shade50;
                        borderColor = Colors.red;
                      }
                    } else if (isSelected) {
                      bgColor = Colors.purple.shade50;
                      borderColor = Colors.purple;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: bgColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _selectAnswer(option),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor ?? Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (_isAnswered && isCorrect)
                                  const Icon(Icons.check, color: Colors.green),
                                if (_isAnswered && isSelected && !isCorrect)
                                  const Icon(Icons.close, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (_isAnswered)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentIndex < _cards.length - 1
                        ? 'Next Question'
                        : 'See Results',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}