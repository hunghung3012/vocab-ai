import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';

class ImportAnkiScreen extends StatefulWidget {
  const ImportAnkiScreen({Key? key}) : super(key: key);

  @override
  State<ImportAnkiScreen> createState() => _ImportAnkiScreenState();
}

class _ImportAnkiScreenState extends State<ImportAnkiScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isImporting = false;
  String? _selectedFileName;

  Future<void> _pickAndImportAnkiFile() async {
    try {
      // Dùng FileType.any để tránh lỗi Unsupported filter trên Android
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path!;
      final fileName = result.files.first.name;

      // Tự kiểm tra extension .apkg
      if (!fileName.toLowerCase().endsWith('.apkg')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a valid .apkg file."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isImporting = true;
        _selectedFileName = fileName;
      });

      final file = File(filePath);

      await _importAnkiDeck(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }


  Future<void> _importAnkiDeck(File apkgFile) async {
    try {
      // Read and extract .apkg file (it's a zip)
      final bytes = await apkgFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find collection.anki2 database
      final dbFile = archive.firstWhere(
            (file) => file.name == 'collection.anki2',
      );

      // Extract to temp directory
      final tempDir = Directory.systemTemp;
      final dbPath = path.join(tempDir.path, 'temp_anki.db');
      final dbFileOutput = File(dbPath);
      await dbFileOutput.writeAsBytes(dbFile.content as List<int>);

      // Open SQLite database
      final db = await openDatabase(dbPath);

      // Query notes and cards
      final notes = await db.query('notes');
      final cards = await db.query('cards');

      if (notes.isEmpty) {
        throw Exception('No cards found in Anki deck');
      }

      // Create deck
      final deckId = DateTime.now().millisecondsSinceEpoch.toString();
      final deckName = _selectedFileName?.replaceAll('.apkg', '') ?? 'Imported Deck';

      final deck = Deck(
        id: deckId,
        name: deckName,
        flashcardIds: [],
        totalWords: notes.length,
      );

      await _firebaseService.createDeck(deck);

      // Import flashcards
      int imported = 0;
      for (var note in notes) {
        final fields = (note['flds'] as String).split('\x1f');

        if (fields.length >= 2) {
          final cardId = DateTime.now().millisecondsSinceEpoch.toString() +
              imported.toString();

          final flashcard = Flashcard(
            id: cardId,
            word: _cleanHtml(fields[0]),
            definition: _cleanHtml(fields[1]),
            example: fields.length > 2 ? _cleanHtml(fields[2]) : null,
          );

          await _firebaseService.createFlashcard(flashcard, deckId);
          imported++;
        }
      }

      // Cleanup
      await db.close();
      await dbFileOutput.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $imported cards!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing Anki deck: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .trim();
  }

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
        title: const Text(
          'VocabAI',
          style: TextStyle(
            color: Colors.purple,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Import Anki Deck',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your Anki deck (.apkg file) to import',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Import Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.purple,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        size: 64,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Drop your Anki file here',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isImporting ? null : _pickAndImportAnkiFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isImporting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Browse Files',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.file_present,
                              color: Colors.purple,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'How to export from Anki',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '1',
                      'Open Anki desktop application',
                    ),
                    _buildInstructionStep(
                      '2',
                      'Select your deck',
                    ),
                    _buildInstructionStep(
                      '3',
                      'Click File → Export',
                    ),
                    _buildInstructionStep(
                      '4',
                      'Choose "Anki Deck Package (*.apkg)"',
                    ),
                    _buildInstructionStep(
                      '5',
                      'Save and upload here',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Supported formats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Supported Format',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '.apkg',
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Anki Deck Package',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}