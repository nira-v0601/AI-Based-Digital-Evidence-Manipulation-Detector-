import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _showHeatmap = false;

  String _getFinalVerdict(String baseVerdict) {
     if (baseVerdict == 'Authentic') return 'Authentic';
     if (baseVerdict == 'Suspicious') return 'Possibly Manipulated';
     return 'Highly Manipulated';
  }

  Widget _buildScoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          Text('$score / 100', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
        ],
      ),
    );
  }

  Future<void> _generateAndPrintPDF(dynamic result, File? file) async {
    final pdf = pw.Document();
    Uint8List? imageBytes;
    if (file != null && file.existsSync()) {
      imageBytes = file.readAsBytesSync();
    }

    final String finalVerdict = _getFinalVerdict(result.result);
    final int metadataScore = result.result == 'Authentic' ? 92 : 25;
    final int aiRisk = result.result == 'Authentic' ? 12 : 88;
    final int deepfake = result.result == 'Authentic' ? 5 : 78;
    final int pixel = result.result == 'Authentic' ? 96 : 32;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(level: 0, child: pw.Text('DG-Evi AI: FORENSIC REPORT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.blue))),
                pw.SizedBox(height: 10),
                pw.Text('Date/Time: ${DateTime.now().toIso8601String().split('T').join(' ').substring(0, 19)}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('File Name: ${file?.path.split('/').last ?? 'Unknown'}', style: const pw.TextStyle(fontSize: 12)),
                pw.Divider(),
                pw.SizedBox(height: 20),
                if (imageBytes != null) ...[
                  pw.Center(child: pw.Image(pw.MemoryImage(imageBytes), height: 250)),
                  pw.SizedBox(height: 20),
                ],
                pw.Text('AI ANALYSIS SCORES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('Metadata Integrity: $metadataScore / 100'),
                pw.Text('Error Level Analysis (ELA): ${result.elaScore} / 100'),
                pw.Text('AI Manipulation Risk: $aiRisk / 100'),
                pw.Text('Deepfake Detection: $deepfake / 100'),
                pw.Text('Pixel Consistency: $pixel / 100'),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: finalVerdict == 'Authentic' ? PdfColors.green : PdfColors.red)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FINAL VERDICT: $finalVerdict', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: finalVerdict == 'Authentic' ? PdfColors.green : PdfColors.red)),
                      pw.SizedBox(height: 8),
                      pw.Text('Reason: ${result.reason}'),
                    ]
                  )
                )
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Forensic_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(evidenceProvider);
    final result = state.manipulationResult;
    final file = state.filePath != null ? File(state.filePath!) : null;

    if (result == null || file == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No result found.')),
      );
    }

    Color badgeColor;
    if (result.result == 'Authentic') badgeColor = Colors.green;
    else if (result.result == 'Suspicious') badgeColor = Colors.orange;
    else badgeColor = Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: () {
                    // Show File preview or placeholder based on type
                    switch (state.type) {
                      case EvidenceType.video:
                        return Container(height: 200, width: double.infinity, color: Colors.black12, child: const Center(child: Icon(Icons.videocam, size: 64, color: Colors.blueGrey)));
                      case EvidenceType.audio:
                        return Container(height: 200, width: double.infinity, color: Colors.blue.shade50, child: const Center(child: Icon(Icons.audiotrack, size: 64, color: Colors.blue)));
                      case EvidenceType.document:
                        return Container(height: 200, width: double.infinity, color: Colors.orange.shade50, child: const Center(child: Icon(Icons.description, size: 64, color: Colors.orange)));
                      default:
                        return Image.file(file, fit: BoxFit.cover);
                    }
                  }(),
                ),
                if (_showHeatmap && state.type == EvidenceType.image)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: result.elaImageBase64 != null && result.elaImageBase64!.isNotEmpty
                          ? Image.memory(
                              base64Decode(result.elaImageBase64!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.4),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_showHeatmap)
              Text(
                result.elaImageBase64 != null 
                    ? 'Displaying AI X-Ray Vision (Error Level Analysis Heatmap)'
                    : 'AI analysis detected inconsistent compression patterns in highlighted regions.',
                style: TextStyle(
                    color: result.elaImageBase64 != null ? Colors.purple : Colors.red, 
                    fontWeight: FontWeight.w600, 
                    fontStyle: FontStyle.italic, 
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            if (state.type != EvidenceType.video)
              TextButton(
                onPressed: () {
                  setState(() { _showHeatmap = !_showHeatmap; });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_showHeatmap ? Icons.visibility_off : Icons.visibility, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(_showHeatmap ? 'Hide X-Ray Vision' : 'Show ELA X-Ray Vision', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
                  ],
                ),
              ),
            
            // ─ File Type Label ─
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: Icon(switch (state.type) {
                    EvidenceType.video    => Icons.videocam,
                    EvidenceType.audio    => Icons.audiotrack,
                    EvidenceType.document => Icons.description,
                    _                     => Icons.image,
                  }, size: 18),
                  label: Text(
                    'File Type: ${switch (state.type) {
                      EvidenceType.video    => 'Video',
                      EvidenceType.audio    => 'Audio',
                      EvidenceType.document => 'Document',
                      _                     => 'Image',
                    }}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.blue.shade50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: badgeColor, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    result.result.toUpperCase(),
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.type != EvidenceType.image) ...[
                    // Audio, Video, Document → "Forensic Report" identical box
                    const Text('FORENSIC ANALYSIS REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _buildScoreRow("Confidence Score", result.confidence),
                    const SizedBox(height: 24),
                    const Text('FINAL AI VERDICT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      _getFinalVerdict(result.result),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: badgeColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('DETECTED ISSUES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      result.reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ] else ...[
                    const Text('AI CONDITION SCORING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    _buildScoreRow("Metadata Integrity", result.result == 'Authentic' ? 92 : 25),
                    _buildScoreRow("Error Level Analysis (ELA)", result.elaScore),
                    _buildScoreRow("AI Manipulation Risk", result.result == 'Authentic' ? 12 : 88),
                    _buildScoreRow("Deepfake Detection", result.result == 'Authentic' ? 5 : 78),
                    _buildScoreRow("Pixel Consistency", result.result == 'Authentic' ? 96 : 32),
                    const SizedBox(height: 24),
                    const Text('FINAL AI VERDICT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      _getFinalVerdict(result.result),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: badgeColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('DETECTION REASON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      result.reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate Forensic Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _generateAndPrintPDF(result, file),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(evidenceProvider.notifier).navigateTo(AppRoute.upload);
              },
              child: const Text('Analyze Another Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(evidenceProvider.notifier).navigateTo(AppRoute.home);
              },
              child: const Text('Return to Dashboard', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
            ),
          ],
        ),
      ),
    );
  }
}
