import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'network_config.dart';

class ApiService {
  static String get baseUrl => NetworkConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 45));
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 45));
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 45));
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 45));
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<http.Response> patch(String endpoint, [Map<String, dynamic>? data]) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
      ).timeout(const Duration(seconds: 45));
      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
} 