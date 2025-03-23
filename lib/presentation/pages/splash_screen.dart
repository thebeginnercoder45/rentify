import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_event.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:rentapp/presentation/pages/onboarding_page.dart';
import 'package:rentapp/presentation/pages/car_list_screen.dart';
import 'package:rentapp/presentation/pages/auth_screen.dart';
import 'package:rentapp/presentation/pages/admin/admin_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentapp/utils/sample_data_uploader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasSeenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Check onboarding status and load sample data
    _initialize().then((_) {
      // Simple timer to navigate after animation
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    });
  }

  Future<void> _initialize() async {
    try {
      // Check if user has seen onboarding
      await _checkOnboardingStatus();

      // Upload sample data to Firestore if needed
      await _loadSampleData();
    } catch (e) {
      // Error handling is silent
    }
  }

  Future<void> _loadSampleData() async {
    try {
      final uploader = SampleDataUploader(FirebaseFirestore.instance);
      await uploader.uploadSampleCars();
    } catch (e) {
      // Error handling is silent
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    if (!_hasSeenOnboarding) {
      // User hasn't seen onboarding, show it
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
      return;
    }

    // Navigate directly to auth screen, which will handle authentication checks
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryGray = Color(0xFFE0E0E0);
    const Color primaryBlack = Color(0xFF121212);

    return Scaffold(
      backgroundColor: primaryBlack,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 80,
                  color: primaryGray,
                ),
                const SizedBox(height: 16),
                const Text(
                  'RentApp',
                  style: TextStyle(
                    color: primaryGray,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium Car Rentals',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
