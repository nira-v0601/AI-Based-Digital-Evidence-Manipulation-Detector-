import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';
import 'package:digital_evidence_detector/ui/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/app_logo.png', height: 32, width: 32),
            const SizedBox(width: 8),
            Text(_getAppTitle()),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              ref.read(evidenceProvider.notifier).navigateTo(AppRoute.profile);
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadSelection(context),
        backgroundColor: Colors.blue,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, "Dashboard", 0),
              _buildNavItem(Icons.smart_toy, "AI", 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.notifications, "Alert", 2),
              _buildNavItem(Icons.settings, "Setting", 3),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppTitle() {
    switch (_currentIndex) {
      case 0: return 'Digital Evidence AI';
      case 1: return 'AI Assistant';
      case 2: return 'Alerts';
      case 3: return 'Settings';
      default: return 'Digital Evidence AI';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return const _DashboardSection();
      case 1: return const _AISection();
      case 2: return const _AlertSection();
      case 3: return const SettingsList();
      default: return const _DashboardSection();
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.blue : Colors.grey;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Evidence to Upload',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Upload Image'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndAnalyzeFile(FileType.custom, ['jpg', 'jpeg', 'png']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blue),
                title: const Text('Upload Video'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndAnalyzeFile(FileType.custom, ['mp4', 'mov']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.blue),
                title: const Text('Upload Audio'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndAnalyzeFile(FileType.custom, ['mp3', 'wav']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text('Upload Document'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndAnalyzeFile(FileType.custom, ['pdf', 'docx', 'txt']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndAnalyzeFile(FileType type, List<String> allowedExtensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        // Use existing pipeline via notifier
        ref.read(evidenceProvider.notifier).analyzePickedFile(path);
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.security, size: 60, color: Colors.blue),
          const SizedBox(height: 12),
          const Text(
            "AI-powered digital evidence verification for images, videos, and audio.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.blue.shade50,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Project Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Digital Evidence Manipulation Detector is designed to verify the authenticity of multimedia files. "
                    "Using advanced artificial intelligence and EXIF metadata analysis, this tool detects manipulations "
                    "and deepfakes in images, videos, and audio recordings.",
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Features:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "• Secure multi-modal capture (Image, Video, Audio)\n"
                    "• AI verification with a confidence score\n"
                    "• Complete privacy-focused environment\n"
                    "• Instant forensic alert generation",
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "Alerts & Notifications",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAlertTile(
          color: Colors.red.shade100,
          iconColor: Colors.red,
          icon: Icons.warning_amber_rounded,
          title: "Suspicious image detected",
          subtitle: "High probability of face manipulation.",
        ),
        const SizedBox(height: 8),
        _buildAlertTile(
          color: Colors.yellow.shade100,
          iconColor: Colors.orange,
          icon: Icons.privacy_tip_rounded,
          title: "Unverified Metadata",
          subtitle: "Missing EXIF data in recent capture.",
        ),
        const SizedBox(height: 8),
        _buildAlertTile(
          color: Colors.green.shade100,
          iconColor: Colors.green,
          icon: Icons.check_circle_outline,
          title: "Audio recording verified",
          subtitle: "Authenticity score 98% secure.",
        ),
      ],
    );
  }

  Widget _buildAlertTile({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.7)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AISection extends StatefulWidget {
  const _AISection();

  @override
  State<_AISection> createState() => _AISectionState();
}

class _AISectionState extends State<_AISection> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hello! I can help you verify digital evidence.", "isAI": true},
    {"text": "How does deepfake detection work?", "isAI": false},
    {"text": "We analyze visual artifacts and consistency in lighting.", "isAI": true},
  ];

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({"text": _textController.text, "isAI": false});
    });

    final query = _textController.text;
    _textController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            "text": "I received your query regarding: '$query'. As an AI Forensic assistant, I can analyze file metadata and visual anomalies to help.",
            "isAI": true,
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: Colors.blue.shade50,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.smart_toy, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "AI Analysis Assistant",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg["text"], isAI: msg["isAI"]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Ask about your evidence...",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isAI}) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          color: isAI ? Colors.blue.shade100 : Colors.blue,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isAI ? const Radius.circular(0) : const Radius.circular(16),
            bottomRight: isAI ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAI ? Colors.black87 : Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
