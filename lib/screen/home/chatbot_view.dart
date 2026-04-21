// File: lib/views/home/chatbot_view.dart

import 'package:flutter/material.dart';

import '../../controllers/chatbot_controller.dart';
import '../../models/chatbot.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({super.key});

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  // Palet Warna Hidayah Hub
  static const _deepTeal = Color(0xFF0F5A4E);
  static const _bg = Color(0xFFF8FAFB);
  static const _botBubble = Color(0xFF1E293B);
  static const _userBubble = Color(0xFF0F8B77);

  late final ChatbotController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ChatbotController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear(); // Kosongin text field

    // Suruh controller proses pesannya
    await _controller.sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Area List Pesan (Baca data dari Controller)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
              itemCount: _controller.messages.length + (_controller.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_controller.isLoading && index == _controller.messages.length) {
                  return _buildTypingBubble();
                }
                final message = _controller.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Area Input Teks
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              const _SenderAvatar(isUser: false),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                decoration: BoxDecoration(
                  color: isUser ? _userBubble : _botBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.8,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              const _SenderAvatar(isUser: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SenderAvatar(isUser: false),
          SizedBox(width: 8),
          _TypingIndicatorBubble(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF4F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: _deepTeal, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Tanya apa saja tentang Islam...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF2F6F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: _userBubble,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  final bool isUser;

  const _SenderAvatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bgColor = isUser ? const Color(0xFFE8F7F4) : const Color(0xFFEDEFF4);
    final iconColor = isUser ? const Color(0xFF0F8B77) : const Color(0xFF1E293B);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 17,
        color: iconColor,
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final t = (_animationController.value - (index * 0.2))
                  .clamp(0.0, 1.0)
                  .toDouble();
              final opacity = 0.35 + (0.65 * (1 - (t - 0.5).abs() * 2));

              return Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity.clamp(0.2, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
