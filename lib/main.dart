import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';
import 'package:digital_evidence_detector/ui/capture_screen.dart';
import 'package:digital_evidence_detector/ui/scanning_screen.dart';
import 'package:digital_evidence_detector/ui/report_screen.dart';
import 'package:digital_evidence_detector/ui/home_screen.dart';
import 'package:digital_evidence_detector/ui/profile_screen.dart';
import 'package:digital_evidence_detector/ui/settings_screen.dart';
import 'package:digital_evidence_detector/ui/upload_screen.dart';
import 'package:digital_evidence_detector/ui/processing_screen.dart';
import 'package:digital_evidence_detector/ui/result_screen.dart';
import 'package:digital_evidence_detector/ui/professional_dashboard_screen.dart';
import 'package:digital_evidence_detector/ui/professional_profile_screen.dart';
import 'package:digital_evidence_detector/ui/professional_scan_screen.dart';
import 'package:digital_evidence_detector/ui/professional_result_screen.dart';
import 'package:digital_evidence_detector/ui/professional_report_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DigitalEvidenceApp()));
}

class DigitalEvidenceApp extends StatelessWidget {
  const DigitalEvidenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Evidence Detector',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      routes: {
         '/main': (context) => const MainRouter(),
         '/professional_dashboard': (context) => const ProfessionalDashboardScreen(),
         '/professional_profile': (context) => const ProfessionalProfileScreen(),
         '/professional_scan': (context) => const ProfessionalScanScreen(),
         '/professional_result': (context) => const ProfessionalResultScreen(),
         '/professional_report': (context) => const ProfessionalReportScreen(),
      },
      initialRoute: '/main',
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainRouter extends ConsumerWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(
      evidenceProvider.select((state) => state.currentRoute),
    );

    switch (route) {
      case AppRoute.home:
        return const HomeScreen();
      case AppRoute.profile:
        return const ProfileScreen();
      case AppRoute.settings:
        return const SettingsScreen();
      case AppRoute.capture:
        return const CaptureScreen();
      case AppRoute.scanning:
        return const ScanningScreen();
      case AppRoute.report:
        return const ReportScreen();
      case AppRoute.upload:
        return const UploadScreen();
      case AppRoute.processing:
        return const ProcessingScreen();
      case AppRoute.result:
        return const ResultScreen();
    }
  }
}
