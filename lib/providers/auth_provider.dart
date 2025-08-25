import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;

  UserModel? get user => _user;
  String? get token => _token;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );
      
      if (result['success']) {
        _token = result['token'];
        _user = result['user'] as UserModel;
        notifyListeners();
        return result;
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during login',
      };
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullName, String role) async {
    try {
      final result = await AuthService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      
      if (result['success']) {
        return result;
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during registration',
      };
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final result = await AuthService.verifyOTP(
        email: email,
        otp: otp,
      );
      
      if (result['success']) {
        _token = result['token'];
        _user = result['user'] as UserModel;
        notifyListeners();
        return result;
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during OTP verification',
      };
    }
  }

  Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      final result = await AuthService.resendOTP(email: email);
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while resending OTP',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final result = await AuthService.forgotPassword(email: email);
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while sending reset email',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final result = await AuthService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred while resetting password',
      };
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }
    
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        _user = user;
        _token = await AuthService.getToken();
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<bool> isLoggedIn() async {
    return await AuthService.isLoggedIn();
  }

  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }
} 