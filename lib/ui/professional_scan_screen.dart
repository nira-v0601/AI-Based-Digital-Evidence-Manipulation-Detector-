import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfessionalScanScreen extends StatefulWidget {
  const ProfessionalScanScreen({super.key});

  @override
  State<ProfessionalScanScreen> createState() => _ProfessionalScanScreenState();
}

class _ProfessionalScanScreenState extends State<ProfessionalScanScreen> with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isScanning = false;
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isScanning = false;
      });
    }
  }

  void _startAnalysis() {
    if (_selectedImage == null) return;
    setState(() {
      _isScanning = true;
    });

    // Simulate AI scanning from prompt
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/professional_result', arguments: _selectedImage!.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('New Image Analysis'),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _selectedImage == null
                  ? _buildEmptyState()
                  : _buildImagePreview(),
            ),
            const SizedBox(height: 24),
            if (!_isScanning) ...[
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B263B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF415A77)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                   Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capture'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B263B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF415A77)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectedImage == null ? null : _startAnalysis,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Start AI Analysis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
              ),
            ] else ...[
               _buildScanningIndicator()
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No evidence loaded', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Select an image from gallery or capture one \nto begin forensic analysis.', 
               textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          if (_isScanning)
            AnimatedBuilder(
              animation: _scannerController,
              builder: (context, child) {
                return Positioned(
                  top: _scannerController.value * MediaQuery.of(context).size.height * 0.5,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      boxShadow: [
                        BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)
                      ]
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 16),
          const Text('Extracting Metadata & Running Tensor Models...', 
            style: TextStyle(color: Colors.white, fontSize: 14), 
            textAlign: TextAlign.center
          ),
        ],
      ),
    );
  }
}
