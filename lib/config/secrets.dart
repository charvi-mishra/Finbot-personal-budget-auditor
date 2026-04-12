import 'package:flutter_dotenv/flutter_dotenv.dart';

class Secrets {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static bool isConfigured() {
    return geminiApiKey.isNotEmpty;
  }
}