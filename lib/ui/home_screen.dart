import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:digital_evidence_detector/services/gemini_service.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';
import 'package:digital_evidence_detector/ui/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<EvidenceState>(evidenceProvider, (previous, next) {
      if (next.latestNotification != null && 
          (previous == null || previous.latestNotification != next.latestNotification)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.latestNotification!),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset('assets/images/app_logo_new.jpeg', height: 32, width: 32),
        ),
        title: const Text(
          'DG-Evi AI',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
              _buildNavItem(Icons.history, "History", 2),
              _buildNavItem(Icons.settings, "Setting", 3),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return const _DashboardSection();
      case 1: return const _AISection();
      case 2: return const _HistorySection();
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
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(evidenceProvider.notifier).navigateTo(AppRoute.upload);
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

class _DashboardSection extends ConsumerStatefulWidget {
  const _DashboardSection();

  @override
  ConsumerState<_DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends ConsumerState<_DashboardSection> {
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentPage = 0;
  final List<Map<String, dynamic>> _carouselItems = [
    {
      "icon": Icons.verified_user,
      "title": "AI Evidence Verification",
      "desc": "Advanced AI model detects digital manipulation and deepfakes instantly.",
      "color": Colors.blue,
    },
    {
      "icon": Icons.camera_alt,
      "title": "Secure Evidence Capture",
      "desc": "Capture image, video, and audio directly in a cryptographically secure environment.",
      "color": Colors.green,
    },
    {
      "icon": Icons.analytics,
      "title": "Forensic AI Analysis",
      "desc": "Analyze metadata, patterns, and structural anomalies beyond the surface.",
      "color": Colors.orange,
    },
    {
      "icon": Icons.lock,
      "title": "Privacy & Security",
      "desc": "100% secure, offline-capable analysis ensuring strict confidentiality.",
      "color": Colors.deepPurple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < 3) { _currentPage++; } else { _currentPage = 0; }
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyzeFile(FileType type, List<String>? allowedExtensions) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: type, allowedExtensions: allowedExtensions);
      if (result != null && result.files.single.path != null) {
        ref.read(evidenceProvider.notifier).analyzePickedFile(result.files.single.path!);
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 24, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemCount: _carouselItems.length,
              itemBuilder: (context, index) {
                final item = _carouselItems[index];
                final color = item["color"] as Color;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(item["icon"] as IconData, size: 48, color: color),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item["title"] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color.withValues(alpha: 0.8))),
                            const SizedBox(height: 4),
                            Text(item["desc"] as String, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_carouselItems.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(color: _currentPage == index ? Colors.blue : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              );
            }),
          ),
          const SizedBox(height: 24),
          const Text("QUICK ACTIONS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard("Capture Image", Icons.camera_alt, Colors.blue, () => ref.read(evidenceProvider.notifier).navigateTo(AppRoute.upload)),
              _buildActionCard("Record Audio", Icons.mic, Colors.orange, () => _pickAndAnalyzeFile(FileType.custom, ['mp3', 'wav'])),
              _buildActionCard("Record Video", Icons.videocam, Colors.red, () => _pickAndAnalyzeFile(FileType.custom, ['mp4', 'mov'])),
              _buildActionCard("Upload Evidence", Icons.upload_file, Colors.green, () => _pickAndAnalyzeFile(FileType.any, null)),
            ],
          ),
          const SizedBox(height: 32),
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
          Visibility(
            visible: false,
            child: Card(
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
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
               Navigator.of(context).pushNamed('/professional_dashboard');
            },
            icon: const Icon(Icons.shield_moon),
            label: const Text('Access Professional Investigation Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D1B2A),
              side: const BorderSide(color: Color(0xFF0D1B2A)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )
        ],
      ),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(evidenceProvider.select((state) => state.history));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          "Evidence History",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (historyList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "No analyses found in history.\nRun a scan to generate a report.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ...historyList.map((item) {
            Color color;
            IconData icon;
            
            if (item.verdict == 'Authentic') color = Colors.green;
            else if (item.verdict == 'Possibly Manipulated') color = Colors.orange;
            else color = Colors.red;

            if (item.type == EvidenceType.image) icon = Icons.image;
            else if (item.type == EvidenceType.audio) icon = Icons.audiotrack;
            else icon = Icons.description;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildHistoryItem(
                context: context,
                fileName: item.fileName,
                type: item.type == EvidenceType.image ? "Image" : (item.type == EvidenceType.audio ? "Audio" : "Document"),
                verdict: item.verdict,
                confidence: item.confidenceScore,
                timestamp: _formatTimestamp(item.timestamp),
                reportPdfPath: item.reportPdfPath,
                color: color,
                icon: icon,
              ),
            );
          }).toList(),
      ],
    );
  }

  String _formatTimestamp(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return "${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildHistoryItem({
    required BuildContext context,
    required String fileName,
    required String type,
    required String verdict,
    required int confidence,
    required String timestamp,
    required String reportPdfPath,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Type: $type • Verdict: $verdict", style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text("Confidence: $confidence% • $timestamp", style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download, color: Colors.blue),
          tooltip: 'Download Report',
          onPressed: () async {
            final file = File(reportPdfPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              await Printing.sharePdf(bytes: bytes, filename: 'Forensic_Report_\$fileName.pdf');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Report file missing or deleted.'))
              );
            }
          },
        ),
        onTap: () async {
            final file = File(reportPdfPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              await Printing.sharePdf(bytes: bytes, filename: 'Forensic_Report_\$fileName.pdf');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Report file missing or deleted.'))
              );
            }
        },
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
  late final GeminiService _geminiService;
  
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hello! I'm the Digital Forensics AI Assistant. I can help you understand digital evidence verification, deepfake detection, metadata, and more.", "isAI": true, "isLoading": false},
  ];

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService();
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final query = _textController.text;
    setState(() {
      _messages.add({"text": query, "isAI": false, "isLoading": false});
      _messages.add({"text": "Thinking...", "isAI": true, "isLoading": true});
    });
    _textController.clear();
    _scrollToBottom();

    final responseText = await _geminiService.askQuestion(query);

    if (mounted) {
      setState(() {
        _messages.removeLast();
        _messages.add({
          "text": responseText,
          "isAI": true,
          "isLoading": false,
        });
      });
      _scrollToBottom();
    }
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
                      return _buildChatBubble(msg["text"], isAI: msg["isAI"], isLoading: msg["isLoading"] ?? false);
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

  Widget _buildChatBubble(String text, {required bool isAI, bool isLoading = false}) {
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
        child: isLoading
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(
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
