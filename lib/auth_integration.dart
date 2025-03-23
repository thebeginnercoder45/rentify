import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Helper class to check Firebase Auth integration
class AuthIntegrationChecker {
  static Future<bool> checkFirebaseAuth() async {
    try {
      // Check if Firebase is initialized
      if (!Firebase.apps.isNotEmpty) {
        debugPrint('❌ Firebase not initialized');
        return false;
      }

      // Access Firebase Auth instance to check connectivity
      final auth = FirebaseAuth.instance;
      debugPrint('✅ Successfully accessed Firebase Auth instance');

      // Check current user (this won't trigger network requests)
      final currentUser = auth.currentUser;
      debugPrint(currentUser != null
          ? '👤 Current user found: ${currentUser.uid}'
          : '👤 No logged in user');

      // Ping Firebase Auth to see if it's responsive
      try {
        // Try a simple API call with a timeout
        final result = await auth
            .fetchSignInMethodsForEmail('test@example.com')
            .timeout(const Duration(seconds: 5));
        debugPrint(
            '✅ Firebase Auth API is responding (fetched sign-in methods)');
        return true;
      } on FirebaseAuthException catch (e) {
        // Expected error for non-existent email
        if (e.code == 'invalid-email') {
          debugPrint('✅ Firebase Auth API responded with expected error');
          return true;
        }
        debugPrint('⚠️ Firebase Auth API error: ${e.code}');
        return true; // Still count as connected if we got a response
      } on SocketException catch (e) {
        debugPrint('❌ Network connection issue: $e');
        return false;
      } on Exception catch (e) {
        debugPrint('⚠️ Error pinging Firebase Auth: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking Firebase Auth integration: $e');
      return false;
    }
  }
}
