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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  final bool forceRetryConnection;
  final bool useOfflineMode;

  const SplashScreen({
    Key? key,
    this.forceRetryConnection = false,
    this.useOfflineMode = false,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasSeenOnboarding = false;
  bool _isRetryingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    if (widget.forceRetryConnection) {
      _retryFirebaseConnection();
    } else {
      _checkOnboardingStatus();
    }
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      // Check if user has seen onboarding
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      // Navigate after a short delay to allow the animation to complete
      if (!widget.forceRetryConnection) {
        // Simple timer to navigate after animation
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            _navigateToNextScreen();
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      // Navigate anyway after a longer delay
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _navigateToNextScreen();
        }
      });
    }
  }

  // Add method to retry Firebase connection
  Future<void> _retryFirebaseConnection() async {
    if (mounted) {
      setState(() {
        _isRetryingConnection = true;
        _connectionStatus = 'Checking connection...';
      });
    }

    try {
      // Wait a moment before retry to ensure any previous connection attempts are fully closed
      await Future.delayed(const Duration(seconds: 1));

      debugPrint('Retrying Firebase connection...');

      // Attempt to ping Firestore to check connectivity
      await FirebaseFirestore.instance
          .collection('connectivity_test')
          .doc('ping')
          .set({'timestamp': FieldValue.serverTimestamp()}).timeout(
              const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _connectionStatus = 'Connected successfully!';
          _isRetryingConnection = false;
        });
      }

      // Continue with normal app flow
      await Future.delayed(const Duration(seconds: 1));
      _checkOnboardingStatus();
    } catch (e) {
      debugPrint('Retry connection failed: $e');
      if (mounted) {
        setState(() {
          _connectionStatus = 'Connection failed. Using offline mode.';
          _isRetryingConnection = false;
        });
      }

      // Continue with offline mode after a short delay
      await Future.delayed(const Duration(seconds: 2));
      _checkOnboardingStatus();
    }
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
    const Color primaryGold = Color(0xFFDAA520);
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
                if (_isRetryingConnection || _connectionStatus != null) ...[
                  const SizedBox(height: 40),
                  if (_isRetryingConnection)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryGold),
                    ),
                  if (_connectionStatus != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _connectionStatus!.contains('Connected')
                            ? Colors.green.withOpacity(0.2)
                            : _connectionStatus!.contains('failed')
                                ? Colors.red.withOpacity(0.2)
                                : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _connectionStatus!,
                        style: TextStyle(
                          color: _connectionStatus!.contains('Connected')
                              ? Colors.green[300]
                              : _connectionStatus!.contains('failed')
                                  ? Colors.red[300]
                                  : Colors.amber[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
