import 'package:flutter/material.dart';

class ProfessionalReportScreen extends StatelessWidget {
  const ProfessionalReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Case Report Generation'),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Export Initiated')));
            },
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'FORENSIC INTELLIGENCE REPORT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF0D1B2A),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildReportField('CASE ID', 'CID-2026-9483-X'),
            _buildReportField('INVESTIGATOR NAME', 'Agent John Doe'),
            _buildReportField('DATE & TIME', DateTime.now().toString()),
            
            const Divider(height: 48, thickness: 2),

            const Text(
              'EVIDENCE ANALYSIS SUMMARY',
               style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                  color: Colors.grey
                ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.red.shade50
              ),
              child: Row(
                children: [
                  const Icon(Icons.dangerous, color: Colors.red, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('AI VERDICT: MANIPULATED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Confidence Score: 82%', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'INVESTIGATION NOTES',
               style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                  color: Colors.grey
                ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: const Text(
                "Image EXIF metadata appears to have been stripped and appended with an Adobe Photoshop marker. "
                "Error Level Analysis indicates heavy modification in the upper right quadrant of the image. "
                "Recommend discarding this evidence from official legal proceedings.",
                style: TextStyle(height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/professional_dashboard'));
              },
              icon: const Icon(Icons.check),
              label: const Text('Close Case Report', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D1B2A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF0D1B2A)),
            ),
          ),
        ],
      ),
    );
  }
}
