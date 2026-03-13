import 'package:flutter/material.dart';

class ProfessionalDashboardScreen extends StatelessWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Digital Evidence Analyzer'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               Navigator.pushNamed(context, '/professional_profile');
            },
            tooltip: 'User Profile Dashboard',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'MAIN FEATURES MENU',
                style: TextStyle(
                  color: Color(0xFF1B263B),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Scan Evidence',
                    icon: Icons.document_scanner_outlined,
                    color: const Color(0xFF1B263B),
                    onTap: () => Navigator.pushNamed(context, '/professional_scan'),
                    features: ['Upload Image', 'Take Photo', 'Analyze Image', 'AI Scan'],
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Scan History',
                    icon: Icons.history,
                    color: const Color(0xFF415A77),
                    onTap: () {
                      // History feature stub
                    },
                    features: ['Thumbnail View', 'Status Result', 'AI Confidence', 'Date & Time'],
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'My Reports',
                    icon: Icons.insert_chart_outlined,
                    color: const Color(0xFF415A77),
                    onTap: () => Navigator.pushNamed(context, '/professional_report'),
                    features: ['Case ID Tracking', 'Confidence %', 'Download PDF', 'Share Report'],
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Security Settings',
                    icon: Icons.security,
                    color: const Color(0xFF778DA9),
                    onTap: () {
                       // Settings stub
                    },
                    features: ['Change Password', 'Enable 2FA', 'Encryption Status', 'Privacy'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap, required List<String> features}) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 12, color: color.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade700, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
