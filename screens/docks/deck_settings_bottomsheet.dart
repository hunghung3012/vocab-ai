// widgets/deck_settings_bottomsheet.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../../models/deck.dart';
import '../../services/firebase_service.dart';

void showDeckSettings(BuildContext context, Deck deck) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DeckSettingsBottomSheet(deck: deck),
  );
}

class DeckSettingsBottomSheet extends StatelessWidget {
  final Deck deck;
  final FirebaseService _firebaseService = FirebaseService();

  DeckSettingsBottomSheet({Key? key, required this.deck}) : super(key: key);

  Future<void> _exportDeck(BuildContext context) async {
    try {
      // Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Load flashcards from Firebase
      final cards = await _firebaseService.getFlashcardsByDeck(deck.id);

      if (cards.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cards to export')),
        );
        return;
      }

      // Prepare temporary directory
      final tempDir = await getTemporaryDirectory();
      final dbPath = path.join(tempDir.path, 'collection.anki2');

      // Create / open SQLite DB
      final db = await openDatabase(dbPath, version: 1);

      // ================================
      // 1) CREATE SCHEMA (FAST MODE)
      // ================================
      await db.transaction((txn) async {
        await txn.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY,
          guid TEXT NOT NULL,
          mid INTEGER NOT NULL,
          mod INTEGER NOT NULL,
          usn INTEGER NOT NULL,
          tags TEXT NOT NULL,
          flds TEXT NOT NULL,
          sfld TEXT NOT NULL,
          csum INTEGER NOT NULL,
          flags INTEGER NOT NULL,
          data TEXT NOT NULL
        );
      ''');

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS cards (
          id INTEGER PRIMARY KEY,
          nid INTEGER NOT NULL,
          did INTEGER NOT NULL,
          ord INTEGER NOT NULL,
          mod INTEGER NOT NULL,
          usn INTEGER NOT NULL,
          type INTEGER NOT NULL,
          queue INTEGER NOT NULL,
          due INTEGER NOT NULL,
          ivl INTEGER NOT NULL,
          factor INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          lapses INTEGER NOT NULL,
          left INTEGER NOT NULL,
          odue INTEGER NOT NULL,
          odid INTEGER NOT NULL,
          flags INTEGER NOT NULL,
          data TEXT NOT NULL
        );
      ''');

        await txn.execute('''
        CREATE TABLE IF NOT EXISTS col (
          id INTEGER PRIMARY KEY,
          crt INTEGER NOT NULL,
          mod INTEGER NOT NULL,
          scm INTEGER NOT NULL,
          ver INTEGER NOT NULL,
          dty INTEGER NOT NULL,
          usn INTEGER NOT NULL,
          ls INTEGER NOT NULL,
          conf TEXT NOT NULL,
          models TEXT NOT NULL,
          decks TEXT NOT NULL,
          dconf TEXT NOT NULL,
          tags TEXT NOT NULL
        );
      ''');

        final now = DateTime.now().millisecondsSinceEpoch;

        // Insert metadata (Anki requires "col" row)
        await txn.insert('col', {
          'id': 1,
          'crt': now ~/ 1000,
          'mod': now,
          'scm': now,
          'ver': 11,
          'dty': 0,
          'usn': 0,
          'ls': 0,
          'conf': '{}',
          'models':
          '{"1":{"id":1,"name":"Basic","type":0,"flds":[{"name":"Front","ord":0},{"name":"Back","ord":1}]}}',
          'decks': '{"1":{"id":1,"name":"${deck.name}"}}',
          'dconf': '{}',
          'tags': '{}'
        });
      });

      // ================================
      // 2) BULK INSERT (VERY FAST) - Using batch for better performance
      // ================================
      final batch = db.batch();
      for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        final noteId = i + 1;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        // Insert "note"
        batch.insert('notes', {
          'id': noteId,
          'guid': card.id,
          'mid': 1,
          'mod': now,
          'usn': -1,
          'tags': '',
          'flds':
          '${card.word}\x1f${card.definition}${card.example != null ? '\x1f${card.example}' : ''}',
          'sfld': card.word,
          'csum': card.word.hashCode,
          'flags': 0,
          'data': ''
        });

        // Insert "card"
        batch.insert('cards', {
          'id': noteId,
          'nid': noteId,
          'did': 1,
          'ord': 0,
          'mod': now,
          'usn': -1,
          'type': 0,
          'queue': 0,
          'due': 0,
          'ivl': 0,
          'factor': 2500,
          'reps': 0,
          'lapses': 0,
          'left': 0,
          'odue': 0,
          'odid': 0,
          'flags': 0,
          'data': ''
        });
      }
      await batch.commit(noResult: true);

      await db.close();

      // ================================
      // 3) ZIP → CREATE .APKG
      // ================================
      final apkgPath =
      path.join(tempDir.path, '${deck.name.replaceAll(" ", "_")}.apkg');

      final encoder = ZipFileEncoder();
      encoder.create(apkgPath, level: ZipFileEncoder.GZIP);
      encoder.addFile(File(dbPath));
      encoder.close();

      // Close loading
      Navigator.pop(context);

      // Share file
      await Share.shareXFiles([
        XFile(apkgPath),
      ], subject: '${deck.name} - Anki Deck');

      // Cleanup
      await File(dbPath).delete();
      await File(apkgPath).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deck exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _deleteDeck(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteDeck(deck.id);
        if (context.mounted) {
          Navigator.pop(context); // Close bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deck deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Deck Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deck.name,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Export Option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.upload, color: Colors.blue),
            ),
            title: const Text(
              'Export Deck',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Export as .apkg file'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              _exportDeck(context);
            },
          ),

          const SizedBox(height: 8),

          // Delete Option
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            title: const Text(
              'Delete Deck',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            subtitle: const Text('This action cannot be undone'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _deleteDeck(context),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}