class AnalysisResult {
  final String result;
  final int confidence;
  final int elaScore;
  final String reason;
  final String? elaImageBase64;

  AnalysisResult({
    required this.result,
    required this.confidence,
    this.elaScore = 0,
    required this.reason,
    this.elaImageBase64,
  });
}
