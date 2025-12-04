import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocab_ai/models/vocab_model.dart';
import 'package:vocab_ai/services/chat_service.dart';
import 'package:vocab_ai/widgets/vocab_result_card.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<ChatMessage> _messages = [];

  late GeminiChatService _chatService;

  File? _pendingImage;
  bool _isLoading = false;
  String _textBuffer = '';
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chatService = GeminiChatService();

    _messages.add(ChatMessage(
      text: "👋 Hello! I'm your AI English Tutor.\n\n"
          "📸 Send me a photo to identify objects\n"
          "💬 Ask about any English word or phrase\n"
          "✨ Let's learn together!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pendingImage = File(picked.path);
      });
    }
  }

  void _startTypingTimer(int messageIndex) {
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_textBuffer.isEmpty && !_isLoading) {
        timer.cancel();
        return;
      }
      if (_textBuffer.isNotEmpty) {
        setState(() {
          final char = _textBuffer[0];
          _textBuffer = _textBuffer.substring(1);

          final oldMsg = _messages[messageIndex];
          _messages[messageIndex] = ChatMessage(
            text: oldMsg.text + char,
            isUser: false,
            timestamp: oldMsg.timestamp,
            vocabResult: oldMsg.vocabResult,
          );
        });
        _scrollDown();
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    final image = _pendingImage;

    if ((text.isEmpty && image == null) || _isLoading) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      image: image,
    ));

    _controller.clear();
    setState(() => _pendingImage = null);
    _scrollDown();

    setState(() => _isLoading = true);

    if (image != null) {
      await _handleImageAnalysis(image, text);
    } else {
      final isVocabQuery = await _chatService.shouldReturnVocabCard(text);
      if (isVocabQuery) {
        await _handleVocabQuery(text);
      } else {
        await _streamTextResponse(text);
      }
    }
  }

  Future<void> _handleImageAnalysis(File image, String prompt) async {
    final botIndex = _messages.length;
    _messages.add(ChatMessage(
      isUser: false,
      timestamp: DateTime.now(),
      text: "🔍 Analyzing image...",
    ));

    try {
      final result = await _chatService.analyzeImage(image, prompt);
      if (result != null) {
        final vocabResult = VocabResult.fromJson(result);
        setState(() {
          _isLoading = false;
          _messages[botIndex] = ChatMessage(
            isUser: false,
            timestamp: DateTime.now(),
            vocabResult: vocabResult,
            image: image,
            text: "",
          );
        });
      } else {
        throw Exception("Could not analyze the image");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages[botIndex] = ChatMessage(
          text: "❌ Sorry, I couldn't analyze this image. Please try again with a clearer photo.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }
    _scrollDown();
  }

  Future<void> _handleVocabQuery(String query) async {
    final botIndex = _messages.length;
    _messages.add(ChatMessage(
      isUser: false,
      timestamp: DateTime.now(),
      text: "📖 Analyzing vocabulary...",
    ));

    try {
      final result = await _chatService.analyzeVocabulary(query);
      if (result != null) {
        final vocabResult = VocabResult.fromJson(result);
        setState(() {
          _isLoading = false;
          _messages[botIndex] = ChatMessage(
            isUser: false,
            timestamp: DateTime.now(),
            vocabResult: vocabResult,
            text: "",
          );
        });
      } else {
        throw Exception("Could not analyze vocabulary");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages[botIndex] = ChatMessage(
          text: "❌ Sorry, I couldn't analyze that word. Please rephrase your question.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    }
    _scrollDown();
  }

  Future<void> _streamTextResponse(String userPrompt) async {
    final botIndex = _messages.length;
    _messages.add(ChatMessage(text: "", isUser: false, timestamp: DateTime.now()));
    _textBuffer = '';
    _startTypingTimer(botIndex);

    try {
      final stream = _chatService.sendTextStream(userPrompt);
      await for (final part in stream) {
        _textBuffer += part;
      }
    } catch (e) {
      _textBuffer = '';
      setState(() {
        _messages[botIndex] = ChatMessage(
          text: "❌ Error: Unable to get response. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleAddToVocab(VocabResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text("✅ '${result.word}' added to your vocabulary deck!")),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text("AI Tutor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(children: [Icon(Icons.help_outline, color: Color(0xFF6F47EB)), SizedBox(width: 8), Text("How to use")]),
                  content: const Text(
                    "📸 Send photos to identify objects\n\n💬 Ask about any English word:\n• 'What is serendipity?'\n• 'Hợp tác là gì?'\n\n💡 Chat normally\n\n👆 Long press examples to copy",
                    style: TextStyle(height: 1.5),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _messages.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage m) {
    // SỬA LỖI TRÀN: Sử dụng Flexible cho cả Card và Text Bubble

    // CASE 1: Hiển thị Vocab Card
    if (m.vocabResult != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 8),
          // SỬA: Bọc VocabResultCard bằng Flexible để nó không đẩy Row ra ngoài màn hình
          Flexible(
            child: VocabResultCard(
              result: m.vocabResult!,
              image: m.image,
              onAddToVocab: () => _handleAddToVocab(m.vocabResult!),
            ),
          ),
        ],
      );
    }

    // CASE 2: Hiển thị tin nhắn thông thường
    final isUser = m.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildBotAvatar(),
          if (!isUser) const SizedBox(width: 8),

          // SỬA: Bọc Column bằng Flexible để bubble chat không bị tràn
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (m.image != null && m.vocabResult == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                        child: Image.file(m.image!, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                if (m.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)])
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser ? null : Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? const Color(0xFF6F47EB).withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6F47EB).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.smart_toy_outlined, color: Color(0xFF6F47EB), size: 18),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_pendingImage!, width: 80, height: 80, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IconButton(
                        onPressed: () => setState(() => _pendingImage = null),
                        icon: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: "Ask anything...",
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            onSubmitted: (_) => _handleSend(),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade600),
                          onPressed: _isLoading ? null : _pickImage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _handleSend,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : const LinearGradient(colors: [Color(0xFF6F47EB), Color(0xFF8B5CF6)]),
                      color: _isLoading ? Colors.grey.shade300 : null,
                      shape: BoxShape.circle,
                      boxShadow: _isLoading
                          ? null
                          : [
                        BoxShadow(
                          color: const Color(0xFF6F47EB).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}