import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'api_service.dart';
import '../models/user_model.dart';
import 'network_config.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';

  // Upload license file to backend with retry logic
  static Future<Map<String, dynamic>> _uploadLicenseFile(File file) async {
    const int maxRetries = 2;
    int retryCount = 0;
    
    // Check file size before upload (max 10MB for Vercel compatibility)
    final fileSize = await file.length();
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      return {
        'success': false,
        'message': 'File size too large. Maximum size is 10MB.',
        'maxSize': '10MB',
        'actualSize': '${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB'
      };
    }
    
    while (retryCount <= maxRetries) {
      try {
        debugPrint('Starting license file upload... (attempt ${retryCount + 1}/${maxRetries + 1})');
        
        Future<Map<String, dynamic>> sendTo(String baseUrl) async {
          final Uri uploadUri = Uri.parse('$baseUrl/api/upload/public?folder=shop-docs');
          debugPrint('Uploading license file to: $uploadUri');
          final request = http.MultipartRequest('POST', uploadUri);
        
          // Add file to request (infer contentType; default to application/pdf for .pdf)
          final String filename = file.path.split('/').last;
          final String lower = filename.toLowerCase();
          http.MultipartFile multipartFile;
          if (lower.endsWith('.pdf')) {
            multipartFile = await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: filename,
              contentType: http_parser.MediaType('application', 'pdf'),
            );
          } else if (lower.endsWith('.png')) {
            multipartFile = await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: filename,
              contentType: http_parser.MediaType('image', 'png'),
            );
          } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
            multipartFile = await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: filename,
              contentType: http_parser.MediaType('image', 'jpeg'),
            );
          } else {
            multipartFile = await http.MultipartFile.fromPath(
              'file',
              file.path,
              filename: filename,
            );
          }
          request.files.add(multipartFile);
        
          // Do not set Content-Type manually; let MultipartRequest compute with boundary
        
          // Send with a reduced timeout for Vercel compatibility
          final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
          final response = await http.Response.fromStream(streamedResponse);
          debugPrint('License upload response: ${response.statusCode} ${response.reasonPhrase}');
          final String bodySnippet = response.body.length > 200
              ? '${response.body.substring(0, 200)}…'
              : response.body;
          debugPrint('License upload body: $bodySnippet');
        
          if (response.statusCode == 200 || response.statusCode == 201) {
            Map<String, dynamic> data = {};
            try {
              data = jsonDecode(response.body);
            } catch (_) {}

            // Extract common shapes
            final dynamic dataNode = data['data'] ?? data;
            final String? url = (dataNode is Map && dataNode['url'] != null)
                ? dataNode['url'] as String
                : (dataNode is Map && dataNode['secure_url'] != null)
                    ? dataNode['secure_url'] as String
                    : (data['url'] ?? data['secure_url']) as String?;
            final String? publicId = (dataNode is Map && dataNode['publicId'] != null)
                ? dataNode['publicId'] as String
                : (dataNode is Map && dataNode['public_id'] != null)
                    ? dataNode['public_id'] as String
                    : (data['publicId'] ?? data['public_id']) as String?;
            final String? mimeType = (dataNode is Map && dataNode['mimeType'] != null)
                ? dataNode['mimeType'] as String
                : (dataNode is Map && dataNode['resource_type'] != null)
                    ? (dataNode['resource_type'] == 'image' ? 'image/*' : 'application/octet-stream')
                    : null;

            if (url != null) {
              return {
                'success': true,
                'url': url,
                'publicId': publicId,
                if (mimeType != null) 'mimeType': mimeType,
              };
            }

            // Treat missing url as failure with diagnostics
            return {
              'success': false,
              'message': 'Upload response missing url',
              'status': response.statusCode,
              'raw': bodySnippet,
            };
          } else {
            Map<String, dynamic> error = {};
            try {
              error = jsonDecode(response.body);
            } catch (_) {}
            return {
              'success': false,
              'message': error['message'] ?? 'Upload failed (status ${response.statusCode})',
              'status': response.statusCode,
              'raw': bodySnippet,
            };
          }
        }

        // Try primary, then environment-aware fallbacks
        final Set<String> candidateSet = <String>{ApiService.baseUrl};
        candidateSet.addAll(NetworkConfig.fallbackUrls);
        // Environment-specific options
        if (NetworkConfig.isEmulator) {
          candidateSet.add(NetworkConfig.baseUrls[NetworkConfig.emulator]!); // 10.0.2.2
        } else if (NetworkConfig.isSimulator) {
          candidateSet.add(NetworkConfig.baseUrls[NetworkConfig.simulator]!); // localhost on iOS sim
        } else if (NetworkConfig.isPhysicalDevice) {
          candidateSet.addAll(NetworkConfig.discoveredUrls); // LAN IPs discovered
          candidateSet.removeWhere((u) => u.contains('localhost')); // avoid localhost on device
        }
        final List<String> candidates = candidateSet.toList();

        Map<String, dynamic>? lastFailure;
        for (final base in candidates) {
          final result = await sendTo(base);
          if (result['success'] == true) return result;
          lastFailure = result;
          // If we just tried an https host and got a 5xx, continue to next candidate
        }
        final result = lastFailure ?? {'success': false, 'message': 'Upload failed: no candidates succeeded'};
        
        // If upload succeeded, return the result
        if (result['success'] == true) {
          return result;
        }
        
        // If this is the last attempt, return the error
        if (retryCount >= maxRetries) {
          return result;
        }
        
        // Wait before retrying (exponential backoff)
        debugPrint('Upload failed, retrying in ${(retryCount + 1) * 2} seconds...');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        retryCount++;
      } catch (e) {
        debugPrint('File upload error (attempt ${retryCount + 1}): $e');
        
        // If this is the last attempt, return the error
        if (retryCount >= maxRetries) {
          return {
            'success': false,
            'message': 'Upload error: $e',
          };
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        retryCount++;
      }
    }
    
    return {'success': false, 'message': 'Upload failed after all retries'};
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
      
      // Do not force a short timeout here; hosted backends (e.g., Render) can take
      // longer on cold start or while sending emails. Let ApiService's hosted
      // timeout policy (75s/90s) handle this to avoid false timeouts where data
      // is saved but the client gives up.
      final response = await ApiService.post('/api/auth/register', registrationData);

      debugPrint('Registration response status: ${response.statusCode}');
      debugPrint('Registration response body: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        // Handle non-JSON responses (e.g., HTML error page, empty body)
        final String snippet = response.body.toString().trim();
        final String shortSnippet = snippet.isEmpty
            ? 'Empty response'
            : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
        debugPrint('Registration response is not valid JSON: $e');
        return {
          'success': false,
          'message': 'Network error: Invalid response format (status ${response.statusCode}). $shortSnippet',
          'networkError': true,
        };
      }
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
        // If backend created user but failed to send email (500), allow flow to OTP
        if (response.statusCode == 500 && (data['needsVerification'] == true) && (data['userId'] != null)) {
          return {
            'success': true,
            'message': data['message'] ?? 'Registration created. Proceed to OTP verification.',
            'needsVerification': true,
            'userId': data['userId'],
            'emailSendFailed': true,
          };
        }
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
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Invalid response format (status 200). $shortSnippet'};
        }
        await _saveToken(data['token']);
        await _saveUser(data['user']);
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Request failed (status ${response.statusCode}). $shortSnippet'};
        }
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
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Invalid response format (status 200). $shortSnippet'};
        }
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Request failed (status ${response.statusCode}). $shortSnippet'};
        }
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
    Future<Map<String, dynamic>> doLogin(Duration timeout) async {
      final response = await ApiService.post('/api/auth/login', {
        'email': email,
        'password': password,
      }).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Login request timed out', timeout);
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Invalid response format (status 200). $shortSnippet'};
        }
        await _saveToken(data['token']);
        await _saveUser(data['user']);
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {
            'success': false,
            'message': 'Request failed (status ${response.statusCode}). $shortSnippet',
            'needsVerification': false,
          };
        }
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
          'needsVerification': error['needsVerification'] ?? false,
        };
      }
    }

    try {
      // First attempt with a slightly longer timeout for hosted backends
      return await doLogin(const Duration(seconds: 25));
    } on TimeoutException catch (e) {
      debugPrint('Login timeout (first attempt): $e');
      // Refresh network configuration and retry once with an extended timeout
      try {
        await NetworkConfig.refreshNetworkConfig();
      } catch (_) {}
      try {
        final result = await doLogin(const Duration(seconds: 40));
        result['retried'] = true;
        return result;
      } on TimeoutException catch (e2) {
        debugPrint('Login timeout (retry): $e2');
        return {
          'success': false,
          'message': 'Request timed out. Please check your connection and try again.',
          'timeoutError': true,
          'retried': true,
        };
      }
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
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {
            'success': false,
            'message': 'Invalid response format (status 200). $shortSnippet',
          };
        }
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Request failed (status ${response.statusCode}). $shortSnippet'};
        }
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
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Invalid response format (status 200). $shortSnippet'};
        }
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        Map<String, dynamic> error = {};
        try {
          error = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {'success': false, 'message': 'Request failed (status ${response.statusCode}). $shortSnippet'};
        }
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
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          final String snippet = response.body.toString().trim();
          final String shortSnippet = snippet.isEmpty
              ? 'Empty response'
              : (snippet.length > 140 ? '${snippet.substring(0, 140)}…' : snippet);
          return {
            'success': false, 
            'message': 'Invalid response format (status 200). $shortSnippet',
          };
        }
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