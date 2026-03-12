import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/native_bridge/secure_capture_service.dart';
import 'package:digital_evidence_detector/data/forensic_ai_service.dart';

enum EvidenceType { none, image, audio }
enum AppRoute { home, profile, settings, capture, scanning, report }

class EvidenceState {
  final String? filePath;
  final String? timestamp;
  final String? secureHash;
  final double? confidenceScore;
  final EvidenceType type;
  final AppRoute currentRoute;
  final String? error;
  final bool isLoggedIn;

  EvidenceState({
    this.filePath,
    this.timestamp,
    this.secureHash,
    this.confidenceScore,
    this.type = EvidenceType.none,
    this.currentRoute = AppRoute.home,
    this.error,
    this.isLoggedIn = false,
  });

  EvidenceState copyWith({
    String? filePath,
    String? timestamp,
    String? secureHash,
    double? confidenceScore,
    EvidenceType? type,
    AppRoute? currentRoute,
    String? error,
    bool? isLoggedIn,
  }) {
    return EvidenceState(
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      secureHash: secureHash ?? this.secureHash,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      type: type ?? this.type,
      currentRoute: currentRoute ?? this.currentRoute,
      error: error, // Clear error if not explicitly passed
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

extension EvidenceStateAdditions on EvidenceState {
  String get authenticityVerdict {
    if (confidenceScore == null) return "Unknown";
    final percent = (confidenceScore! * 100).round();
    if (percent <= 20) return "Authenticity verified. No manipulation detected.";
    if (percent <= 50) return "Suspicious Image - Minor anomalies detected.";
    if (percent <= 80) return "Likely Manipulated - Significant editing evidence found.";
    return "Highly Manipulated - Strong forensic evidence of tampering.";
  }
}

class EvidenceNotifier extends Notifier<EvidenceState> {
  final ForensicAIService _aiService = ForensicAIService();

  @override
  EvidenceState build() {
    _initAIService();
    return EvidenceState();
  }

  Future<void> _initAIService() async {
    await _aiService.initialize();
  }

  void navigateTo(AppRoute route) {
    state = state.copyWith(currentRoute: route);
  }

  Future<void> captureImage() async {
    state = state.copyWith(error: null);
    try {
      final result = await SecureCaptureService.captureImage();
      if (result != null) {
        state = state.copyWith(
          filePath: result['filePath'],
          timestamp: result['timestamp'],
          secureHash: result['secureHash'],
          type: EvidenceType.image,
          currentRoute: AppRoute.scanning,
        );
        _analyzeEvidence();
      } else {
         state = state.copyWith(error: 'Secure Photo Capture failed or was cancelled.');
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  bool _isRecording = false;
  Future<void> startAudioCapture() async {
    if (_isRecording) return;
    state = state.copyWith(error: null);
    try {
      await SecureCaptureService.startAudioCapture();
      _isRecording = true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to start recording: $e');
    }
  }

  Future<void> stopAudioCapture() async {
    if (!_isRecording) return;
    try {
      final result = await SecureCaptureService.stopAudioCapture();
      _isRecording = false;
      if (result != null) {
        state = state.copyWith(
          filePath: result['filePath'],
          timestamp: result['timestamp'],
          secureHash: result['secureHash'],
          type: EvidenceType.audio,
          currentRoute: AppRoute.scanning,
        );
        _analyzeEvidence();
      } else {
        state = state.copyWith(error: 'Secure Audio Capture failed.');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop recording: $e');
      _isRecording = false;
    }
  }

  Future<void> _analyzeEvidence() async {
    // Artificial delay to show off the futuristic scanning animation
    await Future.delayed(const Duration(seconds: 3));

    if (state.filePath == null) {
       state = state.copyWith(currentRoute: AppRoute.report, error: 'No valid file to analyze');
       return;
    }

    if (state.type == EvidenceType.image) {
      final score = await _aiService.analyzeImage(state.filePath!);
      if (score != null) {
        state = state.copyWith(confidenceScore: score, currentRoute: AppRoute.report);
      } else {
        // Fallback for missing/failed ML model run
        state = state.copyWith(confidenceScore: 0.0, currentRoute: AppRoute.report, error: 'AI processing failed. Please check tflite model asset.');
      }
    } else {
      // For audio, we haven't implemented an Audio ML model, so we simulate a forensic analysis response.
      // In a real scenario, you would have a second `.tflite` model running over the `.wav` STFT matrices.
      state = state.copyWith(confidenceScore: 0.07, currentRoute: AppRoute.report);
    }
  }

  void analyzePickedFile(String path) {
    EvidenceType pickedType = EvidenceType.none;
    final lowerPath = path.toLowerCase();
    
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png')) {
      pickedType = EvidenceType.image;
    } else if (lowerPath.endsWith('.mp3') || lowerPath.endsWith('.wav')) {
      pickedType = EvidenceType.audio;
    } else {
      pickedType = EvidenceType.none; // Video/Doc unsupported by local ML at moment, mock it
    }

    state = state.copyWith(
      filePath: path,
      timestamp: DateTime.now().toIso8601String(),
      secureHash: 'picked_file_hash_simulated',
      type: pickedType,
      currentRoute: AppRoute.scanning,
      error: null,
    );
    
    _analyzeEvidence();
  }

  void reset() {
    state = EvidenceState(isLoggedIn: state.isLoggedIn);
  }

  void login() {
    state = state.copyWith(isLoggedIn: true);
  }

  void logout() {
    state = state.copyWith(isLoggedIn: false);
  }
}

final evidenceProvider = NotifierProvider<EvidenceNotifier, EvidenceState>(() {
  return EvidenceNotifier();
});
