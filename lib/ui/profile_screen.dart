import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_evidence_detector/domain/evidence_state.dart';

enum AuthView { login, register, forgotPassword }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  AuthView _currentView = AuthView.login;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(evidenceProvider.select((state) => state.isLoggedIn));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isLoggedIn ? 'User Profile' : _getAuthTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(evidenceProvider.notifier).navigateTo(AppRoute.home);
          },
        ),
      ),
      body: SafeArea(
        child: isLoggedIn ? _buildProfileView() : _buildAuthFlow(),
      ),
    );
  }

  String _getAuthTitle() {
    switch (_currentView) {
      case AuthView.login:
        return 'Login';
      case AuthView.register:
        return 'Create Account';
      case AuthView.forgotPassword:
        return 'Reset Password';
    }
  }

  Widget _buildAuthFlow() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getAuthWidget(),
    );
  }

  Widget _getAuthWidget() {
    switch (_currentView) {
      case AuthView.login:
        return _buildLoginView();
      case AuthView.register:
        return _buildRegisterView();
      case AuthView.forgotPassword:
        return _buildForgotPasswordView();
    }
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      key: const ValueKey('login'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.security, size: 80, color: Colors.blue),
          const SizedBox(height: 32),
          const Text(
            "Welcome Back",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildTextField(label: "Email", icon: Icons.email),
          const SizedBox(height: 16),
          _buildTextField(label: "Password", icon: Icons.lock, obscureText: true),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _currentView = AuthView.forgotPassword),
              child: const Text("Forgot Password?"),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(evidenceProvider.notifier).login();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(
                onPressed: () => setState(() => _currentView = AuthView.register),
                child: const Text("Register"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRegisterView() {
    return SingleChildScrollView(
      key: const ValueKey('register'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.person_add, size: 60, color: Colors.blue),
          const SizedBox(height: 32),
          const Text(
            "Create Account",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildTextField(label: "Full Name", icon: Icons.person),
          const SizedBox(height: 16),
          _buildTextField(label: "Email", icon: Icons.email),
          const SizedBox(height: 16),
          _buildTextField(label: "Password", icon: Icons.lock, obscureText: true),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Simulate registration and auto-login
              ref.read(evidenceProvider.notifier).login();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account?"),
              TextButton(
                onPressed: () => setState(() => _currentView = AuthView.login),
                child: const Text("Login"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildForgotPasswordView() {
    return SingleChildScrollView(
      key: const ValueKey('forgot_password'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 60, color: Colors.blue),
          const SizedBox(height: 32),
          const Text(
            "Reset Password",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Enter your email address and we'll send you a link to reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          _buildTextField(label: "Email", icon: Icons.email),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset link sent!')),
              );
              setState(() => _currentView = AuthView.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Send Reset Link", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _currentView = AuthView.login),
            child: const Text("Back to Login"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required IconData icon, bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.blue.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            "Detective Smith",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "smith.investigations@secure.com",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildProfileOption(Icons.history, "Scan History"),
                _buildProfileOption(Icons.security, "Security Settings"),
                _buildProfileOption(Icons.analytics, "My Reports"),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(evidenceProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.blue,
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title tapped')));
        },
      ),
    );
  }
}
