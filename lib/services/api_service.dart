import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'network_config.dart';

class ApiService {
  static String get baseUrl => NetworkConfig.baseUrl;
  static String get webSocketUrl => NetworkConfig.webSocketUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return _requestWithRetry(
      () => (Duration timeout) => http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(timeout),
    );
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    return _requestWithRetry(
      () => (Duration timeout) => http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(timeout),
    );
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    return _requestWithRetry(
      () => (Duration timeout) => http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(timeout),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _requestWithRetry(
      () => (Duration timeout) => http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(timeout),
    );
  }

  static Future<http.Response> patch(String endpoint, [Map<String, dynamic>? data]) async {
    final headers = await _getHeaders();
    return _requestWithRetry(
      () => (Duration timeout) => http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(timeout),
    );
  }

  // Internal: retry wrapper that adapts timeout based on environment and
  // refreshes network discovery on timeouts (helps with cold-started hosts).
  static Future<http.Response> _requestWithRetry(
    Future<http.Response> Function(Duration timeout) Function() requestBuilder,
  ) async {
    final bool isHosted = baseUrl.startsWith('https://');
    final List<Duration> timeouts = isHosted
        ? <Duration>[
            const Duration(seconds: 75),
            const Duration(seconds: 90),
          ]
        : <Duration>[
            const Duration(seconds: 15),
            const Duration(seconds: 20),
          ];

    Object? lastError;
    for (int attempt = 0; attempt < timeouts.length; attempt++) {
      final Duration timeout = timeouts[attempt];
      try {
        final http.Response response = await requestBuilder()(timeout);
        return response;
      } on TimeoutException catch (e) {
        lastError = e;
        // On first timeout, try to refresh discovery (could switch to working URL)
        if (attempt == 0) {
          try {
            await NetworkConfig.refreshNetworkConfig();
          } catch (_) {}
        }
      } catch (e) {
        lastError = e;
        break; // Non-timeout errors shouldn't endlessly retry
      }
    }
    throw Exception('Network error: ${lastError ?? 'Unknown error'}');
  }
} 