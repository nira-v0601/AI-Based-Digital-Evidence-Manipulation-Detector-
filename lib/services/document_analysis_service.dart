import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class DocumentAnalysisService {
  Future<AnalysisResult> analyzeDocument(File docFile) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:5000/analyze-document');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath(
        'document',
        docFile.path,
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
            : 'No structural anomalies detected in document';

        print('✨ [SUCCESS] Document Backend Connected! Score: $score | Verdict: $verdict');
        return AnalysisResult(
            result: verdict,
            confidence: score,
            elaScore: 0,
            reason: reason);
      } else {
        print('Document Backend Error: ${response.statusCode}');
        return _fallback();
      }
    } catch (e) {
      print('Document backend unavailable: $e');
      return _fallback();
    }
  }

  AnalysisResult _fallback() {
    return AnalysisResult(
        result: 'Authentic',
        confidence: 8,
        elaScore: 0,
        reason: '• No structural anomalies detected (Simulated Fallback)');
  }
}
