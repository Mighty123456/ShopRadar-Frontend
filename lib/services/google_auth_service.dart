import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'api_service.dart';

class GoogleAuthService {
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }
  }

  static Future<Map<String, dynamic>> signIn() async {
    try {
      debugPrint('Starting Google Sign-In...');
      
      // Ensure GoogleSignIn is initialized
      await _ensureInitialized();
      
      // Check if Google Sign-In is available
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      debugPrint('Google user signed in: ${googleUser.email}');
      
      // Get the authentication details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        debugPrint('Google ID token is null');
        return {
          'success': false,
          'message': 'Failed to get Google authentication token'
        };
      }

      debugPrint('Google ID token obtained, sending to backend...');
      
      // Send the ID token to your backend
      final response = await ApiService.post('/api/auth/google-signin', {
        'idToken': googleAuth.idToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Google Sign-In successful: $data');
        
        return {
          'success': true,
          'message': 'Google sign-in successful',
          'data': data,
        };
      } else {
        debugPrint('Backend Google Sign-In failed: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Google sign-in failed'
        };
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return {
        'success': false, 
        'message': 'Google sign-in error: $e'
      };
    }
  }

  static Future<void> signOut() async {
    try {
      debugPrint('Signing out from Google...');
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
      debugPrint('Google Sign-Out successful');
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }

  static Future<bool> isSignedIn() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
      return account != null;
    } catch (e) {
      debugPrint('Error checking Google sign-in status: $e');
      return false;
    }
  }

  static Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      await _ensureInitialized();
      return await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('Error getting current Google user: $e');
      return null;
    }
  }
} 