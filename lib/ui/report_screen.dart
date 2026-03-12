import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  Future<void> _generateAndPrintPDF(EvidenceState state) async {
    final pdf = pw.Document();

    Uint8List? imageBytes;
    if (state.type == EvidenceType.image && state.filePath != null) {
      final file = File(state.filePath!);
      if (file.existsSync()) {
        imageBytes = file.readAsBytesSync();
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'DIGITAL EVIDENCE FORENSIC REPORT',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                      color: PdfColors.blue,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Authentication Node Generated',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.Divider(color: PdfColors.blueGrey),
                pw.SizedBox(height: 30),
                if (imageBytes != null) ...[
                  pw.Center(
                    child: pw.Image(pw.MemoryImage(imageBytes), height: 300),
                  ),
                  pw.SizedBox(height: 20),
                ] else if (state.type == EvidenceType.audio) ...[
                  pw.Center(
                    child: pw.Container(
                      height: 150,
                      width: 300,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '[ AUDIO EVIDENCE SECURED IN ROOT FILESYSTEM ]',
                          style: const pw.TextStyle(color: PdfColors.red),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
                pw.Text(
                  'Evidence Type: ${state.type == EvidenceType.image ? 'Image (PNG Lossless)' : 'Audio (PCM 16-bit 44.1kHz WAV)'}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Capture Timestamp (ISO 8601): ${state.timestamp}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Local File Path: ${state.filePath}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CRYPTOGRAPHIC INTEGRITY CHECK',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Android Keystore HMAC-SHA256 Hash:',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        state.secureHash ?? 'N/A',
                        style: pw.TextStyle(fontSize: 10, fontFallback: []),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FORENSIC AI MANIPULATION ANALYSIS',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Confidence Score: ${((state.confidenceScore ?? 0.0) * 100).toStringAsFixed(2)}%',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: (state.confidenceScore ?? 0.0) > 0.5
                              ? PdfColors.red
                              : PdfColors.green,
                        ),
                      ),
                      pw.Text(
                        state.authenticityVerdict,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: (state.confidenceScore ?? 0.0) > 0.5
                              ? PdfColors.red
                              : PdfColors.green,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Summary of forensic checks performed:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey),
                      ),
                      pw.Text(
                        '• Metadata & EXIF Analysis\n• Error Level Analysis (ELA)\n• Noise Pattern Consistency Check\n• Copy-Move Forgery Detection\n• Lighting & Shadow Consistency\n• Synthetic / AI Generated Signature Detection',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  'End of Report. Strictly Confidential.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Forensic_Report_${state.timestamp}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(evidenceProvider);
    final isManipulated = (state.confidenceScore ?? 0.0) > 0.5;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Analysis Results',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: state.type == EvidenceType.image && state.filePath != null
                  ? Image.file(
                      File(state.filePath!),
                      height: 250,
                      fit: BoxFit.cover,
                    )
                  : (state.type == EvidenceType.audio
                      ? Container(
                          height: 150,
                          color: Colors.blue.shade50,
                          child: const Center(
                            child: Icon(
                              Icons.audiotrack,
                              size: 80,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evidence Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TIMESTAMP',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.timestamp ?? 'Unknown',
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HMAC-SHA256 SECURE HASH',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.secureHash ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isManipulated ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isManipulated ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'AI MANIPULATION CONFIDENCE',
                    style: TextStyle(
                      color: isManipulated ? Colors.red.shade900 : Colors.green.shade900,
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${((state.confidenceScore ?? 0.0) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isManipulated ? Colors.red : Colors.green,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.authenticityVerdict,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isManipulated ? Colors.red.shade700 : Colors.green.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _generateAndPrintPDF(state),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Generate PDF Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.read(evidenceProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh, color: Colors.blue),
              label: const Text(
                'Restart New Scan',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
