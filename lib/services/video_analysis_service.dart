import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class VideoAnalysisService {
  Future<AnalysisResult> analyzeVideo(File videoFile) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:5000/analyze-video');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
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
            : 'No significant anomalies detected';

        print('✨ [SUCCESS] Video Backend Connected! Returned Score: $score | Verdict: $verdict');
        return AnalysisResult(
            result: verdict, 
            confidence: score, 
            elaScore: 0, // Not applicable for video in this context, or could be mapped later
            reason: reason);
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        return _performFallbackAnalysis(videoFile);
      }
    } catch (e) {
      print('Failed to connect to backend: $e');
      return _performFallbackAnalysis(videoFile);
    }
  }

  Future<AnalysisResult> _performFallbackAnalysis(File videoFile) async {
      print('Using fallback simulated video analysis');
      // Simulate analysis if backend isn't running
      return AnalysisResult(
          result: 'Authentic', 
          confidence: 12, 
          elaScore: 0,
          reason: 'Video appears authentic. (Simulated Fallback)'
      );
  }
}
