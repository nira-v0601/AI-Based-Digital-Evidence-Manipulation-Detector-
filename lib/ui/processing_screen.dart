import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';
import 'package:digital_evidence_detector/models/analysis_result.dart';
import 'package:digital_evidence_detector/services/image_analysis_service.dart';
import 'package:digital_evidence_detector/services/video_analysis_service.dart';
import 'package:digital_evidence_detector/services/audio_analysis_service.dart';
import 'package:digital_evidence_detector/services/document_analysis_service.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    // 2-3 sec delay minimum as per prompt
    await Future.delayed(const Duration(seconds: 3));
    
    final state = ref.read(evidenceProvider);

    if (state.filePath != null) {
      AnalysisResult result;
      switch (state.type) {
        case EvidenceType.video:
          result = await VideoAnalysisService().analyzeVideo(File(state.filePath!));
          break;
        case EvidenceType.audio:
          result = await AudioAnalysisService().analyzeAudio(File(state.filePath!));
          break;
        case EvidenceType.document:
          result = await DocumentAnalysisService().analyzeDocument(File(state.filePath!));
          break;
        default:
          result = await ImageAnalysisService().analyzeImage(File(state.filePath!));
      }
      
      // Update the global state with result and navigate
      ref.read(evidenceProvider.notifier).updateManipulationResult(result);
    } else {
      ref.read(evidenceProvider.notifier).navigateTo(AppRoute.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 30),
            Consumer(builder: (context, ref, child) {
              final evidenceType = ref.watch(evidenceProvider).type;
              final label = switch (evidenceType) {
                EvidenceType.video    => 'Analyzing Video for Digital Manipulation...',
                EvidenceType.audio    => 'Analyzing Audio for Digital Manipulation...',
                EvidenceType.document => 'Analyzing Document for Digital Manipulation...',
                _                     => 'Analyzing Image for Digital Manipulation...',
              };
              return Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
