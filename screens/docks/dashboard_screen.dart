import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocab_ai/widgets/DashedButton.dart';
import 'package:vocab_ai/widgets/app_bottom_nav.dart';
import '../../models/deck.dart';
import '../../services/firebase_service.dart';
import 'edit_deck_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _firebaseService.getUserStats();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.book, color: Colors.white),
          ),
        ),
        title: const Text(
          'VocabAI',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Learning Dashboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your vocabulary decks and track your progress',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons - 2 rows
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    // ThÃƒÂªm chÃƒÂºt bÃƒÂ³ng Ã„â€˜Ã¡Â»â€¢ nhÃ¡ÂºÂ¹ cho container nÃ¡Â»â€¢i bÃ¡ÂºÂ­t hÃ†Â¡n (tÃƒÂ¹y chÃ¡Â»Ân)
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Button 1: Create New Deck (MÃƒ u TÃƒÂ­m)
                      DashedButton(
                        text: 'Create New Deck',
                        icon: Icons.add,
                        color: const Color(0xFF9333EA), // MÃƒÂ£ mÃƒ u tÃƒÂ­m giÃ¡Â»â€˜ng design
                        onTap: () {
                          Navigator.pushNamed(context, '/create-deck');
                        },
                      ),

                      const SizedBox(height: 16), // TÃ„Æ’ng khoÃ¡ÂºÂ£ng cÃƒÂ¡ch lÃƒÂªn chÃƒÂºt cho thoÃƒÂ¡ng

                      // Button 2: Import Anki Deck (MÃƒ u Xanh DÃ†Â°Ã†Â¡ng)
                      DashedButton(
                        text: 'Import Anki Deck',
                        icon: Icons.file_upload_outlined, // Icon upload giÃ¡Â»â€˜ng design hÃ†Â¡n
                        color: const Color(0xFF2563EB), // MÃƒÂ£ mÃƒ u xanh dÃ†Â°Ã†Â¡ng giÃ¡Â»â€˜ng design
                        onTap: () {
                          Navigator.pushNamed(context, '/import-anki');
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Words',
                        value: '${_stats['totalWords'] ?? 0}',
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Study Streak',
                        value: '${_stats['studyStreak'] ?? 0} days',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Mastered Words',
                        value: '${_stats['masteredWords'] ?? 0}',
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Decks List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Decks (${_stats['totalDecks'] ?? 0})',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Decks Stream
                StreamBuilder<List<Deck>>(
                  stream: _firebaseService.getDecksStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      children: snapshot.data!.map((deck) {
                        return _buildDeckCard(deck);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),

    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.purple,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h \'hours ago\'');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  deck.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${deck.progress.toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.book, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${deck.totalWords} words',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                timeFormat.format(deck.lastStudiedDate),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Text(
                dateFormat.format(deck.createdDate),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: deck.progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              deck.progress >= 66 ? Colors.purple : Colors.blue,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/study',
                      arguments: deck,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 20),
                      SizedBox(width: 4),
                      Text('Study Now'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/quiz',
                      arguments: deck,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Quiz'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditDeckScreen(deck: deck),
                    ),
                  ).then((_) => _loadStats());
                },
                icon: const Icon(Icons.edit),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No decks yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first deck to get started',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }


}