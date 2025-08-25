import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static Future<Map<String, dynamic>> signIn() async {
    try {
      debugPrint('Google Sign-In is temporarily disabled due to package compatibility issues.');
      
      return {
        'success': false, 
        'message': 'Google Sign-In is temporarily unavailable. Please use email/password authentication.'
      };
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return {'success': false, 'message': 'Google sign in error: $e'};
    }
  }

  static Future<void> signOut() async {
    try {
      debugPrint('Google Sign-Out: No action needed (service disabled)');
    } catch (e) {
      debugPrint('Google Sign-Out Error: $e');
    }
  }
} 