import 'package:flutter/material.dart';

class ProfessionalResultScreen extends StatelessWidget {
  const ProfessionalResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Expected to receive file path as route argument, but falling back for testing
    final String? imagePath = ModalRoute.of(context)?.settings.arguments as String?;
    
    // Hardcoded result simulation for demonstration purposes as per Phase 2 requirement
    // In a real integration, this would use the ImageAnalysisService
    // We use a local var (not const) to avoid dead code warnings down the widget tree
    bool isManipulated = imagePath != null; // Simulating manipulation detection simply based on data presence
    int confidenceScore = 82;
    Color themeColor = isManipulated ? const Color(0xFFD32F2F) : const Color(0xFF388E3C);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Forensic Result'),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/professional_dashboard')),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              color: themeColor,
              child: Column(
                children: [
                  Icon(
                    isManipulated ? Icons.warning_amber_rounded : Icons.verified_user,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isManipulated ? "MANIPULATED IMAGE DETECTED" : "AUTHENTIC IMAGE",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AI CONFIDENCE SCORE',
                          style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$confidenceScore%',
                          style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETECTED ANOMALIES',
                    style: TextStyle(
                      color: Color(0xFF1B263B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isManipulated) ...[
                    _buildAnomalyTile('Face Editing', 'Likely warp or liquify applied to facial features.', true),
                    _buildAnomalyTile('Object Removal', 'Inconsistent noise pattern suggests cloning/healing.', true),
                    _buildAnomalyTile('Lighting Manipulation', 'Shadow gradients do not match global light source.', false),
                    _buildAnomalyTile('Metadata Tampering', 'Original EXIF scrubbed, saving software signature found: Photoshop', true),
                  ] else ...[
                     const Padding(
                       padding: EdgeInsets.symmetric(vertical: 24.0),
                       child: Center(child: Text('No manipulation markers detected. Image passes all forensic validation checks.', textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontSize: 16))),
                     )
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share),
                          label: const Text('Share Evidence'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D1B2A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF0D1B2A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/professional_report'),
                          icon: const Icon(Icons.download),
                          label: const Text('Save Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1B2A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyTile(String title, String desc, bool detected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: detected ? Colors.red.shade200 : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            detected ? Icons.warning_rounded : Icons.check_circle_outline, 
            color: detected ? Colors.red : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: detected ? Colors.red.shade900 : Colors.grey.shade700,
                  ),
                ),
                if (detected) ...[
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
