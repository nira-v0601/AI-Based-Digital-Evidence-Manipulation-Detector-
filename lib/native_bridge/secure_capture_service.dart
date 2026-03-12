import 'package:flutter/services.dart';

class SecureCaptureService {
  static const MethodChannel _channel = MethodChannel('com.evidence.detector/secure_capture');

  /// Captures an image with high-quality and uncompressed format, returning its file path,
  /// ISO 8601 timestamp, and a SHA-256 secure hash generated via Android Keystore.
  static Future<Map<String, dynamic>?> captureImage() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('captureSecureImage');
      // result contains: filePath, timestamp, secureHash
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      print("SecureCapture Error: '${e.message}'.");
    }
    return null;
  }

  /// Starts recording uncompressed PCM 16-bit 44.1kHz audio.
  static Future<void> startAudioCapture() async {
    try {
      await _channel.invokeMethod('startSecureAudio');
    } on PlatformException catch (e) {
      print("SecureCapture startAudio Error: '${e.message}'.");
    }
  }

  /// Stops audio recording, generates a WAV file, and returns its file path,
  /// ISO 8601 timestamp, and a SHA-256 secure hash generated via Android Keystore.
  static Future<Map<String, dynamic>?> stopAudioCapture() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('stopSecureAudio');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      print("SecureCapture stopAudio Error: '${e.message}'.");
    }
    return null;
  }
}
