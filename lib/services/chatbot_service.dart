// File: lib/services/chatbot_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_env.dart';

class ChatbotService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  ChatbotService() {
    AppEnv.ensureRequired();

    // Inisialisasi model Gemini
    // Kita pakai model 'gemini-1.5-flash' karena responnya super cepat dan cocok buat chatbot
    // 
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppEnv.geminiApiKey,
      systemInstruction: Content.system(
        'Kamu adalah Asisten AI untuk aplikasi Hidayah Hub. '
        'Jawablah pertanyaan pengguna dengan ramah, sopan, dan berikan informasi seputar agama Islam, '
        'jadwal sholat, atau doa sehari-hari jika ditanya. '
        'Selalu gunakan bahasa Indonesia yang baik.',
      ),
    );

    // Memulai sesi obrolan (biar AI ingat riwayat chat)
    _chatSession = _model.startChat();
  }

  Future<String> getBotResponse(String userMessage) async {
    try {
      // Mengirim pesan pengguna ke Gemini
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      // Mengembalikan teks balasan dari Gemini
      return response.text ?? 'Maaf, saya tidak mengerti maksudnya.';
    } catch (e) {
      // Jika terjadi error (misal token salah atau tidak ada internet)
      throw Exception('Gagal menghubungi server AI: $e');
    }
  }
}