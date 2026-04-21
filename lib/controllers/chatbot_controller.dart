// File: lib/controllers/chatbot_controller.dart

import 'package:flutter/material.dart';
import '../models/chatbot.dart';
import '../../services/chatbot_service.dart';

class ChatbotController extends ChangeNotifier {
  final ChatbotService _service = ChatbotService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Assalamu\'alaikum! Saya asisten AI Hidayah Hub. Ada yang bisa saya bantu hari ini?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    );
    _isLoading = true;
    notifyListeners();

    try {
      final responseText = await _service.getBotResponse(text);

      _messages.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: 'Maaf, terjadi kesalahan jaringan: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
