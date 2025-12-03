import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocab_ai/widgets/app_bottom_nav.dart';
import '../../models/deck.dart';
import '../../services/firebase_service.dart';
import 'edit_deck_screen.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({Key? key}) : super(key: key);

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';

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
            child: const Icon(Icons.style, color: Colors.white),
          ),
        ),
        title: const Text(
          'My Decks',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.purple),
            onPressed: () {
              Navigator.pushNamed(context, '/create-deck');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search decks...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Decks List
          Expanded(
            child: StreamBuilder<List<Deck>>(
              stream: _firebaseService.getDecksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter decks by search query
                final decks = snapshot.data!.where((deck) {
                  return deck.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (decks.isEmpty) {
                  return Center(
                    child: Text(
                      'No decks found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    return _buildDeckCard(decks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Created: ${dateFormat.format(deck.createdDate)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
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
                      Text('Study'),
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
                  ).then((_) => setState(() {}));
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/create-deck');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Deck'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}