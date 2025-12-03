import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../services/firebase_service.dart';

class EditDeckScreen extends StatefulWidget {
  final Deck deck;

  const EditDeckScreen({Key? key, required this.deck}) : super(key: key);

  @override
  State<EditDeckScreen> createState() => _EditDeckScreenState();
}

class _EditDeckScreenState extends State<EditDeckScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  Flashcard? _editingCard;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _firebaseService.getFlashcardsByDeck(widget.deck.id);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cards: $e')),
        );
      }
    }
  }

  void _showEditDialog(Flashcard card) {
    setState(() => _editingCard = card);
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final wordController = TextEditingController();
        final definitionController = TextEditingController();
        final exampleController = TextEditingController();
        File? selectedImage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Add New Word'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Word',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: wordController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Eloquent',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Definition',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: definitionController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Speaking fluently',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Example (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: exampleController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g., Her speech was eloquent',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Image (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null) {
                              setDialogState(() {
                                selectedImage = File(image.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                        ),
                        if (selectedImage != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(selectedImage!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (wordController.text.isEmpty ||
                        definitionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter word and definition'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      // Show loading
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      String? imageUrl;
                      if (selectedImage != null) {
                        imageUrl = await _firebaseService.uploadImage(
                          selectedImage!,
                          widget.deck.id,
                        );
                      }

                      final newCard = Flashcard(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        word: wordController.text,
                        definition: definitionController.text,
                        example: exampleController.text.isEmpty
                            ? null
                            : exampleController.text,
                        imageUrl: imageUrl,
                      );

                      await _firebaseService.createFlashcard(
                        newCard,
                        widget.deck.id,
                      );
                      await _loadCards();

                      Navigator.pop(context); // Close loading

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Word added successfully'),
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateCard(Flashcard card) async {
    try {
      await _firebaseService.updateFlashcard(card);
      await _loadCards();
      setState(() => _editingCard = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Word updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating card: $e')),
        );
      }
    }
  }

  Future<void> _deleteCard(Flashcard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Word'),
        content: Text('Are you sure you want to delete "${card.word}"?'),
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
        await _firebaseService.deleteFlashcard(card.id);
        await _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Word deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting card: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.deck.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Words (${_cards.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Cards List
              Expanded(
                child: _cards.isEmpty
                    ? const Center(
                  child: Text('No words in this deck'),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return _buildWordCard(card);
                  },
                ),
              ),
            ],
          ),

          // Edit Dialog Overlay
          if (_editingCard != null) _buildEditOverlay(_editingCard!),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWordDialog,
        backgroundColor: const Color(0xFF7C3AED),
        child: const Icon(Icons.add),
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
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Done'),
        ),
      ),
    );
  }

  Widget _buildWordCard(Flashcard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  card.word,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                    child: InkWell(
                      onTap: () => _showEditDialog(card),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _deleteCard(card),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.definition,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (card.example != null && card.example!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${card.example}"',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (card.imageUrl != null && card.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                card.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditOverlay(Flashcard card) {
    final wordController = TextEditingController(text: card.word);
    final definitionController = TextEditingController(text: card.definition);
    final exampleController = TextEditingController(text: card.example ?? '');

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Word',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Word',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: wordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Definition',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: definitionController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Example',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: exampleController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _editingCard = null);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        onPressed: () {
                          final updatedCard = card.copyWith(
                            word: wordController.text,
                            definition: definitionController.text,
                            example: exampleController.text.isEmpty
                                ? null
                                : exampleController.text,
                          );
                          _updateCard(updatedCard);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}