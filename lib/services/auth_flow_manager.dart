import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../widgets/animated_message_dialog.dart';

class AuthFlowManager {
  static const String flowInitial = 'initial';
  static const String flowRegistered = 'registered';
  static const String flowVerified = 'verified';
  static const String flowLoggedIn = 'logged_in';

  static Future<bool> isAuthenticated() async {
    try {
      final token = await AuthService.getToken();
      final user = await AuthService.getUser();
      return token != null && user != null && user.isEmailVerified;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getAuthState() async {
    final token = await AuthService.getToken();
    final user = await AuthService.getUser();
    
    if (token == null || user == null) {
      return flowInitial;
    }
    
    if (!user.isEmailVerified) {
      return flowRegistered;
    }
    
    return flowLoggedIn;
  }

  static Future<void> handleSuccessfulRegistration({
    required BuildContext context,
    required String message,
    required String email,
    required String userId,
  }) async {
    try {
      debugPrint('Handling successful registration for: $email');
      
      _showSuccessMessage(context, message);
      
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        debugPrint('Navigating to OTP verification...');
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/otp-verification',
          (route) => false,
          arguments: {
            'email': email,
            'userId': userId,
          },
        );
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (context.mounted) {
        _showErrorMessage(context, 'Navigation error: $e');
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
      }
    }
  }

  static Future<void> handleSuccessfulVerification({
    required BuildContext context,
    required String message,
  }) async {
    _showSuccessMessage(context, message);
    
    await Future.delayed(const Duration(seconds: 1));
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/verification-success',
        (route) => false,
      );
    }
  }

  static Future<void> handleSuccessfulLogin({
    required BuildContext context,
    required String message,
  }) async {
    _showSuccessMessage(context, message);
    
    await Future.delayed(const Duration(seconds: 1));
    if (context.mounted) {
      final user = await AuthService.getUser();
      final isShopOwner = user?.role == 'shop';
      
      if (context.mounted) {
        if (isShopOwner) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/shop-owner-dashboard',
            (route) => false,
          );
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth-success',
            (route) => false,
          );
        }
      }
    }
  }

  static Future<void> handleLogout({
    required BuildContext context,
  }) async {
    await AuthService.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (route) => false,
      );
    }
  }

  static void _showSuccessMessage(BuildContext context, String message) {
    MessageHelper.showAnimatedMessage(
      context,
      message: message,
      type: MessageType.success,
      title: 'Success',
    );
  }

  static void _showErrorMessage(BuildContext context, String message) {
    MessageHelper.showAnimatedMessage(
      context,
      message: message,
      type: MessageType.error,
      title: 'Error',
    );
  }

  static Future<bool> needsEmailVerification() async {
    try {
      final user = await AuthService.getUser();
      return user != null && !user.isEmailVerified;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getUserEmail() async {
    try {
      final user = await AuthService.getUser();
      return user?.email;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> validateAuthFlow() async {
    final token = await AuthService.getToken();
    final user = await AuthService.getUser();
    
    if (token == null) {
      return true;
    }
    
    if (user == null) {
      await AuthService.logout();
      return true;
    }
    
    if (!user.isEmailVerified) {
      return true;
    }
    
    return true;
  }

  static Future<String> getInitialRoute() async {
    final isAuth = await isAuthenticated();
    
    if (isAuth) {
      final user = await AuthService.getUser();
      final isShopOwner = user?.role == 'shop';
      
      if (isShopOwner) {
        return '/shop-owner-dashboard';
      } else {
        return '/home';
      }
    }
    
    final needsVerification = await needsEmailVerification();
    if (needsVerification) {
      return '/otp-verification';
    }
    
    return '/auth';
  }
} 