import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _systemPrompt =
      '''You are a Digital Forensics AI Assistant integrated into the DG-Evi AI application.

Your job is to help users understand digital evidence verification, deepfake detection, metadata analysis, AI-based manipulation detection, and cyber forensic analysis.

You must ONLY answer questions related to:

• Digital evidence verification
• Deepfake detection
• Image/video/audio manipulation detection
• EXIF metadata analysis
• AI forensic investigation
• Cybercrime evidence validation

If the user asks any unrelated question (for example general knowledge, entertainment, politics, etc.), respond with:

'This AI assistant is designed only to answer questions related to digital evidence verification and forensic analysis.'

Do not provide answers outside this domain.''';

  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = 'AIzaSyBUVXn9q3UugUypd-viHzje-DncQG2D0Xc';

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
  }

  Future<String> askQuestion(String question) async {
    try {
      final response = await _model.generateContent([Content.text(question)]);
      if (response.text == null || response.text!.isEmpty) {
        return "I received an empty response. Please try asking again.";
      }
      return response.text!;
    } catch (e, stackTrace) {
      print('=== GEMINI API ERROR ===');
      print('Exception: $e');
      print('StackTrace: $stackTrace');
      return "Network Error or API Failure:\n$e";
    }
  }
}
