// Widget for deck card with settings icon
// Add this to your deck card in dashboard_screen.dart and decks_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vocab_ai/screens/docks/deck_settings_bottomsheet.dart';
import '../../models/deck.dart';


Widget buildDeckCardWithSettings(
    BuildContext context,
    Deck deck,
    VoidCallback onUpdate,
    ) {
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
            Row(
              children: [
                // Settings Icon Button
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  onPressed: () {
                    showDeckSettings(context, deck);
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 8),
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
                  ).then((_) => onUpdate());
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
          ],
        ),
      ],
    ),
  );
}