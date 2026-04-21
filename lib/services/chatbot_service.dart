// File: lib/services/chatbot_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_env.dart';

class ChatbotService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  ChatbotService() {
    AppEnv.ensureRequired();

    // Inisialisasi model Gemini
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: AppEnv.geminiApiKey,
      systemInstruction: Content.system(
        'Kamu adalah Asisten AI untuk aplikasi Hidayah Hub. '
        'Jawablah pertanyaan pengguna dengan ramah, sopan, dan berikan informasi seputar agama Islam, '
        'jadwal sholat, atau doa sehari-hari jika ditanya. '
        'Selalu gunakan bahasa Indonesia yang baik.'
        'Jika kamu tidak tahu jawabannya, katakan "Maaf, saya tidak tahu jawabannya."'
        'Jangan pernah memberikan informasi yang salah atau menyesatkan. '
        'Fokuslah untuk membantu pengguna dengan informasi yang akurat dan bermanfaat seputar agama Islam.'
        'Jangan memberikan informasi yang tidak relevan atau di luar topik agama Islam. '
        'Jangan pernah memberikan saran medis, hukum, atau keuangan. '
        'Jika pengguna bertanya tentang topik yang tidak sesuai, katakan "Maaf, saya hanya bisa membantu dengan informasi seputar agama Islam."',
      ),
    );
    _chatSession = _model.startChat();
  }

  Future<String> getBotResponse(String userMessage) async {
    try {
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
