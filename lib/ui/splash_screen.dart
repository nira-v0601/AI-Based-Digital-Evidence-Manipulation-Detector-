import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the main app after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // Light Blue
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/app_logo_new.jpeg',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 16),
            const Text(
              'DG-Evi AI',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto', // Clean modern sans-serif
                fontSize: 28,
                fontWeight: FontWeight.w600, // SemiBold
                color: Color(0xFF1565C0), // Deep blue
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
