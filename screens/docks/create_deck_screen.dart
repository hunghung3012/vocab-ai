import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({Key? key}) : super(key: key);

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _deckNameController = TextEditingController();

  bool _showCardTypeSelection = false;
  String _selectedCardType = 'flashcard'; // flashcard, multiple_choice, etc.
  List<Map<String, dynamic>> _cards = [];

  void _showDeckNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Create New Deck'),
        content: TextField(
          controller: _deckNameController,
          decoration: InputDecoration(
            hintText: 'Enter deck name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_deckNameController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  _showCardTypeSelection = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDeckNameDialog();
    });
  }

  void _addCard() {
    setState(() {
      _cards.add({
        'word': '',
        'definition': '',
        'example': '',
        'imageUrl': null,
        'imageFile': null,
      });
    });
  }

  Future<void> _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _cards[index]['imageFile'] = File(image.path);
      });
    }
  }

  void _removeCard(int index) {
    setState(() {
      _cards.removeAt(index);
    });
  }

  Future<void> _saveDeck() async {
    if (_deckNameController.text.isEmpty || _cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one card'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all cards have required fields
    for (var card in _cards) {
      if (card['word'].toString().isEmpty ||
          card['definition'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All cards must have word and definition'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create deck
      final deck = Deck(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _deckNameController.text,
        totalWords: _cards.length,
        createdDate: DateTime.now(),
        lastStudiedDate: DateTime.now(), flashcardIds: [],
      );

      await _firebaseService.createDeck(deck);

      // Create flashcards
      for (var cardData in _cards) {
        String? imageUrl;

        // Upload image if exists
        if (cardData['imageFile'] != null) {
          imageUrl = await _firebaseService.uploadImage(
            cardData['imageFile'],
            deck.id,
          );
        }

        final flashcard = Flashcard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          word: cardData['word'],
          definition: cardData['definition'],
          example: cardData['example'].toString().isEmpty
              ? null
              : cardData['example'],
          imageUrl: imageUrl,
        );

        await _firebaseService.createFlashcard(flashcard, deck.id);
      }

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Go back to dashboard

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCardTypeSelection) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _deckNameController.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Card Type Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Card Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardTypeOption(
                        'Flashcard',
                        'flashcard',
                        Icons.style,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardTypeOption(
                        'Multiple Choice',
                        'multiple_choice',
                        Icons.quiz,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardTypeOption(
                        'Fill in Blank',
                        'fill_blank',
                        Icons.edit_note,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cards List
          Expanded(
            child: _cards.isEmpty
                ? Center(
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
                    'No cards yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add cards',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return _buildCardItem(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveDeck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create Deck'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeOption(String label, String type, IconData icon) {
    final isSelected = _selectedCardType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCardType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.purple : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.purple : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(int index) {
    final card = _cards[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeCard(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Word/Term',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              _cards[index]['word'] = value;
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Definition',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
            onChanged: (value) {
              _cards[index]['definition'] = value;
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Example (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
            onChanged: (value) {
              _cards[index]['example'] = value;
            },
          ),
          const SizedBox(height: 12),
          // Image picker
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(index),
                icon: const Icon(Icons.image),
                label: const Text('Add Image'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              if (card['imageFile'] != null) ...[
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(card['imageFile']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    super.dispose();
  }
}