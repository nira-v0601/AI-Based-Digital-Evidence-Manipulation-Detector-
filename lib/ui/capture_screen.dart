import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _isAudioRecording = false;

  void _onPhotoCapture() {
    ref.read(evidenceProvider.notifier).captureImage();
  }

  void _onAudioToggle() async {
    final notifier = ref.read(evidenceProvider.notifier);
    if (!_isAudioRecording) {
      await notifier.startAudioCapture();
      if (!mounted) return;
      setState(() {
        _isAudioRecording = true;
      });
    } else {
      await notifier.stopAudioCapture();
      if (!mounted) return;
      setState(() {
        _isAudioRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Authentication Node',
          style: TextStyle(color: Colors.greenAccent, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.greenAccent.withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _isAudioRecording ? null : _onPhotoCapture,
                icon: const Icon(Icons.camera_alt_outlined, size: 28),
                label: const Text(
                  'SECURE PHOTO CAPTURE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.cyan,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _onAudioToggle,
                icon: Icon(
                  _isAudioRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined,
                  size: 28,
                ),
                label: Text(
                  _isAudioRecording
                      ? 'STOP SECURE AUDIO (RECORDING...)'
                      : 'SECURE AUDIO CAPTURE',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: _isAudioRecording
                      ? Colors.redAccent
                      : Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: _isAudioRecording ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 50),
              Opacity(
                opacity: 0.6,
                child: const Text(
                  'Hardware Enclave Secured.\n16-Bit PCM | Max Q-Factor PNG\nAES / SHA-256 HMAC Active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.5,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
