import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class AudioAnalysisService {
  Future<AnalysisResult> analyzeAudio(File audioFile) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:5000/analyze-audio');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
      ));

      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final score = (data['confidence'] as num).toInt();
        final verdict = data['status'] as String;

        List<dynamic> rawReasons = data['reasons'] ?? [];
        String reason = rawReasons.isNotEmpty
            ? rawReasons.map((e) => '• $e').join('\n')
            : 'No significant audio anomalies detected';

        print('✨ [SUCCESS] Audio Backend Connected! Score: $score | Verdict: $verdict');
        return AnalysisResult(
            result: verdict,
            confidence: score,
            elaScore: 0,
            reason: reason);
      } else {
        print('Audio Backend Error: ${response.statusCode}');
        return _fallback();
      }
    } catch (e) {
      print('Audio backend unavailable: $e');
      return _fallback();
    }
  }

  AnalysisResult _fallback() {
    return AnalysisResult(
        result: 'Authentic',
        confidence: 5,
        elaScore: 0,
        reason: '• No anomalies detected (Simulated Fallback)');
  }
}
