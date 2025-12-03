import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocab_ai/models/vocab_model.dart';

class VocabResultCard extends StatelessWidget {
  final VocabResult result;
  final File? image;
  final VoidCallback onAddToVocab;

  const VocabResultCard({
    Key? key,
    required this.result,
    this.image,
    required this.onAddToVocab,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text("Copied to clipboard!"),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy chiều rộng màn hình để tính toán
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // SỬA LỖI TRÀN: Không dùng width cố định, dùng constraints
      // Giới hạn chiều rộng tối đa là 75% màn hình hoặc 320px (cái nào nhỏ hơn thì lấy)
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F47EB).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Để card co lại theo nội dung
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. HEADER ẢNH (Nếu có)
          if (image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 180,
                ),
                width: double.infinity, // Ảnh full chiều rộng card
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // B. THANH TIÊU ĐỀ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: image == null
                  ? const BorderRadius.vertical(top: Radius.circular(15))
                  : null,
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded( // Thêm Expanded để text không bị tràn nếu quá dài
                  child: Text(
                    image != null ? "Image Recognition" : "Vocabulary Analysis",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // C. NỘI DUNG CHÍNH
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Word & Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6F47EB).withOpacity(0.1),
                            const Color(0xFF8B5CF6).withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_rounded, size: 24, color: Color(0xFF6F47EB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  result.word,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up, color: Color(0xFF6F47EB), size: 22),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Pronunciation feature coming soon!")),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6F47EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              result.type,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6F47EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Definition
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.definition,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Example Sentences
                if (result.exampleEn != null && result.exampleVi != null) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.format_quote, color: Color(0xFF6F47EB), size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Example Sentences",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF6F47EB),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // English Example
                  GestureDetector(
                    onLongPress: () => _copyToClipboard(context, result.exampleEn!),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "EN",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildHighlightedText(result.exampleEn!, result.word),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Vietnamese Example
                  GestureDetector(
                    onLongPress: () => _copyToClipboard(context, result.exampleVi!),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "VI",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.exampleVi!,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Confidence Bar
                if (image != null) ...[
                  Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: result.confidence,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(result.confidence * 100).toInt()}%",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Related Words
                if (result.relatedWords.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.link, color: Color(0xFF6F47EB), size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Related Words",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6F47EB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.relatedWords.map((w) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6F47EB).withOpacity(0.1),
                            const Color(0xFF8B5CF6).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF6F47EB).withOpacity(0.3)),
                      ),
                      child: Text(
                        w,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6F47EB), fontWeight: FontWeight.w500),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddToVocab,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F47EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text("Add to Deck", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF6F47EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, color: Color(0xFF6F47EB), size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Share feature coming soon!")),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String wordToHighlight) {
    final lowerText = text.toLowerCase();
    final lowerWord = wordToHighlight.toLowerCase();
    final index = lowerText.indexOf(lowerWord);

    if (index == -1) {
      return Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + wordToHighlight.length),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6F47EB),
              backgroundColor: Color(0xFFE8DEFE),
            ),
          ),
          TextSpan(text: text.substring(index + wordToHighlight.length)),
        ],
      ),
    );
  }
}