import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(evidenceProvider.notifier).navigateTo(AppRoute.home);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection("General"),
          _buildSettingsTile(Icons.tune, "App preferences", context),
          _buildSettingsTile(
            Icons.notifications,
            "Notification settings",
            context,
          ),

          const SizedBox(height: 24),
          _buildSettingsSection("Security & Data"),
          _buildSettingsTile(Icons.lock, "Data privacy", context),
          _buildSettingsTile(Icons.memory, "AI analysis preferences", context),

          const SizedBox(height: 24),
          _buildSettingsSection("Support"),
          _buildSettingsTile(Icons.help_outline, "Help & support", context),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.black54,
        ),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title tapped')));
        },
      ),
    );
  }
}

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSettingsSection("General"),
        _buildSettingsTile(Icons.tune, "App preferences", context),
        _buildSettingsTile(
          Icons.notifications,
          "Notification settings",
          context,
        ),

        const SizedBox(height: 24),
        _buildSettingsSection("Security & Data"),
        _buildSettingsTile(Icons.lock, "Data privacy", context),
        _buildSettingsTile(Icons.memory, "AI analysis preferences", context),

        const SizedBox(height: 24),
        _buildSettingsSection("Support"),
        _buildSettingsTile(Icons.help_outline, "Help & support", context),
      ],
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.black54,
        ),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title tapped')));
        },
      ),
    );
  }
}
