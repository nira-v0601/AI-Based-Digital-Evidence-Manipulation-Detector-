import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class ImageAnalysisService {
  Future<AnalysisResult> analyzeImage(File imageFile) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:5000/analyze-image');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final score = (data['ela_score'] as num).toInt();
        final verdict = data['verdict'] as String;
        final elaImageBase64 = data['ela_image'] as String?;
        // The backend also provides 'timestamp' and 'hash', but for now we just 
        // need to extract score and verdict for AnalysisResult.
        
        String reason = 'No anomalies detected';
        if (score > 60) {
          reason = 'Strong evidence of manipulation detected via ELA';
        } else if (score >= 40) {
          reason = 'Suspicious compression patterns detected';
        } else if (score > 20) {
           reason = 'Minor anomalies detected';
        }

        print('✨ [SUCCESS] ELA Backend Connected! Returned Score: $score | Verdict: $verdict');
        return AnalysisResult(result: verdict, confidence: score, elaScore: score, reason: reason, elaImageBase64: elaImageBase64);
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        return _performFallbackAnalysis(imageFile);
      }
    } catch (e) {
      print('Failed to connect to backend: $e');
      return _performFallbackAnalysis(imageFile);
    }
  }

  Future<AnalysisResult> _performFallbackAnalysis(File imageFile) async {
      print('Using fallback simulated analysis');
      double score = 0;
      String reason = 'Image appears authentic. (Simulated Fallback)';

      try {
        final bytes = await imageFile.readAsBytes();
        String rawString = String.fromCharCodes(bytes.take(2048)).toLowerCase();
        
        bool softwareDetected = false;
        final softwareList = ['photoshop', 'gimp', 'snapseed', 'lightroom'];
        for (var sw in softwareList) {
          if (rawString.contains(sw)) {
            softwareDetected = true;
            break;
          }
        }

        if (softwareDetected) {
          score += 50;
          reason = 'Editing software detected in metadata';
        }
        
        String result = 'Authentic';
        if (score > 60) {
          result = 'Manipulated';
        } else if (score >= 40) {
          result = 'Suspicious';
        }
        
        return AnalysisResult(result: result, confidence: score.toInt(), elaScore: score.toInt(), reason: reason);
      } catch (e) {
         return AnalysisResult(result: 'Suspicious', confidence: 60, elaScore: 0, reason: 'Failed to fully analyze image metadata');
      }
  }
}

