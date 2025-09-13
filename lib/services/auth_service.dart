import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';

  // Upload license file to backend
  static Future<Map<String, dynamic>> _uploadLicenseFile(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/upload/public?folder=shop-docs'),
      );
      
      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
        ),
      );
      
      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
          'publicId': data['publicId'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      return {
        'success': false,
        'message': 'Upload error: $e',
      };
    }
  }



  // Register user and send OTP
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? shopName,
    String? licenseNumber,
    String? state,
    String? phone,
    String? address,
    File? licenseFile,
    Map<String, double>? location,
    String? gpsAddress,
    bool? isLocationVerified,
  }) async {
    try {
      debugPrint('Starting registration for email: $email');
      
      // Upload license file first if provided
      Map<String, dynamic>? licenseDocumentData;
      if (role == 'shop' && licenseFile != null) {
        debugPrint('Uploading license file...');
        final uploadResult = await _uploadLicenseFile(licenseFile);
        if (uploadResult['success']) {
          licenseDocumentData = {
            'url': uploadResult['url'],
            'publicId': uploadResult['publicId'],
            'mimeType': uploadResult['mimeType'] ?? 'application/pdf',
          };
          debugPrint('License file uploaded successfully: ${uploadResult['url']}');
        } else {
          return {
            'success': false,
            'message': 'Failed to upload license file: ${uploadResult['message']}',
          };
        }
      }
      
      debugPrint('Sending registration request...');
      // Prepare registration data
      final Map<String, dynamic> registrationData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'role': role,
      };
      
      // Add shop owner specific data if role is shop
      if (role == 'shop') {
        registrationData.addAll({
          'shopName': shopName,
          'licenseNumber': licenseNumber,
          'phone': phone,
          'address': address,
        });
        
        // Add license document data if uploaded
        if (licenseDocumentData != null) {
          registrationData['licenseDocument'] = licenseDocumentData;
        }
        
        // Add location verification data
        if (location != null) {
          registrationData['location'] = location;
        }
        if (gpsAddress != null) {
          registrationData['gpsAddress'] = gpsAddress;
        }
        if (isLocationVerified != null) {
          registrationData['isLocationVerified'] = isLocationVerified;
        }
      }
      
      final response = await ApiService.post('/api/auth/register', registrationData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Registration request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response body: ${response.body}');

      final data = jsonDecode(response.body);
      debugPrint('Backend registration response: $data');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // For registration, we expect needsVerification to be true
        // and no token until OTP is verified
        debugPrint('Registration successful, returning success response');
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'needsVerification': data['needsVerification'] ?? true, // Default to true for registration
          'userId': data['userId'],
        };
      } else {
        debugPrint('Registration failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'needsVerification': data['needsVerification'] ?? false,
        };
      }
    } on TimeoutException catch (e) {
      debugPrint('Registration timeout: $e');
      return {
        'success': false,
        'message': 'Request timed out. Please check your connection and try again.',
        'timeoutError': true,
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'networkError': true,
      };
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/verify-otp', {
        'email': email,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        await _saveUser(data['user']);
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'OTP verification failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOTP({
    required String email,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/resend-otp', {
        'email': email,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Failed to resend OTP'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/login', {
        'email': email,
        'password': password,
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Login request timed out', const Duration(seconds: 15));
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        await _saveUser(data['user']);
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false, 
          'message': error['message'] ?? 'Login failed',
          'needsVerification': error['needsVerification'] ?? false,
        };
      }
    } on TimeoutException catch (e) {
      debugPrint('Login timeout: $e');
      return {
        'success': false,
        'message': 'Request timed out. Please check your connection and try again.',
        'timeoutError': true,
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Forgot password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/forgot-password', {
        'email': email,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Failed to send reset email'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Reset password with OTP
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post('/api/auth/reset-password', {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Password reset failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Google Sign In
  static Future<Map<String, dynamic>> googleSignIn() async {
    try {
      // This will be implemented with the google_sign_in package
      // For now, we'll return a placeholder
      return {'success': false, 'message': 'Google sign in not implemented yet'};
    } catch (e) {
      return {'success': false, 'message': 'Google sign in error: $e'};
    }
  }

  // Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      await ApiService.post('/api/auth/logout', {});
      await _clearToken();
      await _clearUser();
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Logout error: $e'};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await ApiService.get('/api/auth/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true, 
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        return {'success': false, 'message': 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user
  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      if (userString != null && userString.isNotEmpty) {
        final userData = jsonDecode(userString);
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      // If there's an error parsing the user data, clear it and return null
      await _clearUser();
      return null;
    }
  }

  // Private methods for token and user management
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user);
      await prefs.setString(_userKey, userJson);
    } catch (e) {
      // If there's an error saving user data, clear it
      await _clearUser();
    }
  }

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
} 