import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'network_config.dart';

class NetworkUtility {
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 5;
  static const Duration _healthCheckInterval = Duration(minutes: 2);
  
  static Timer? _healthCheckTimer;
  static bool _isMonitoring = false;
  
  static Future<void> initialize() async {
    try {
      await NetworkConfig.initialize();
      
      _startHealthMonitoring();
      
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<http.Response> makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    int retries = _maxRetries,
    bool enableFailover = true,
  }) async {
    String currentUrl = '${NetworkConfig.baseUrl}$endpoint';
    
    try {
      final response = await _executeRequest(
        currentUrl,
        method: method,
        headers: headers,
        body: body,
      );
      
      return response;
      
    } catch (e) {
      if (retries > 0) {
        if (enableFailover) {
          final nextUrl = await NetworkConfig.getNextWorkingUrl();
          if (nextUrl != null) {
            currentUrl = '$nextUrl$endpoint';
          }
        }
        
        await Future.delayed(Duration(milliseconds: 1000 * (_maxRetries - retries + 1)));
        
        return makeRequest(
          endpoint,
          method: method,
          headers: headers,
          body: body,
          retries: retries - 1,
          enableFailover: enableFailover,
        );
      }
      
      rethrow;
    }
  }
  
  static Future<http.Response> _executeRequest(
    String url, {
    required String method,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse(url);
    
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'ShopRadar-Flutter/1.0',
      ...?headers,
    };
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: requestHeaders).timeout(_timeout);
        case 'POST':
          return await http.post(uri, headers: requestHeaders, body: body).timeout(_timeout);
        case 'PUT':
          return await http.put(uri, headers: requestHeaders, body: body).timeout(_timeout);
        case 'DELETE':
          return await http.delete(uri, headers: requestHeaders, body: body).timeout(_timeout);
        case 'PATCH':
          return await http.patch(uri, headers: requestHeaders, body: body).timeout(_timeout);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  static Future<bool> testConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('${NetworkConfig.baseUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return true;
      }
      
      final alternativeEndpoints = ['/', '/api', '/api/auth'];
      for (final endpoint in alternativeEndpoints) {
        try {
          final altResponse = await http.get(
            Uri.parse('${NetworkConfig.baseUrl}$endpoint'),
          ).timeout(const Duration(seconds: 3));
          
          if (altResponse.statusCode < 500) {
            return true;
          }
        } catch (e) {
          continue;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    final isConnected = await testConnectivity();
    final networkInfo = NetworkConfig.getNetworkInfo();
    final health = await NetworkConfig.getNetworkHealth();
    
    return {
      'isConnected': isConnected,
      'baseUrl': NetworkConfig.baseUrl,
      'workingUrl': networkInfo['workingBaseUrl'],
      'isInitialized': networkInfo['isInitialized'],
      'currentEnvironment': networkInfo['currentEnvironment'],
      'discoveredIPs': networkInfo['discoveredIPs'],
      'health': health,
      'isMonitoring': _isMonitoring,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  static Future<void> refreshNetwork() async {
    await NetworkConfig.refreshNetworkConfig();
    
    _stopHealthMonitoring();
    _startHealthMonitoring();
  }
  
  static void _startHealthMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) async {
      try {
        final isHealthy = await NetworkConfig.isNetworkHealthy();
        if (!isHealthy) {
          await refreshNetwork();
        }
      } catch (e) {
        // Health check error
      }
    });
  }
  
  static void _stopHealthMonitoring() {
    _healthCheckTimer?.cancel();
    _isMonitoring = false;
  }
  
  static Map<String, dynamic> getTroubleshootingInfo() {
    return {
      'networkInfo': NetworkConfig.getNetworkInfo(),
      'troubleshootingSteps': NetworkConfig.getTroubleshootingSteps(),
      'detailedInfo': NetworkConfig.getDetailedNetworkInfo(),
      'healthMonitoring': {
        'isMonitoring': _isMonitoring,
        'healthCheckInterval': _healthCheckInterval.inMinutes,
      },
    };
  }
  
  static bool get isEmulator {
    return NetworkConfig.isEmulator;
  }
  
  static bool get isPhysicalDevice {
    return NetworkConfig.isPhysicalDevice;
  }
  
  static bool get isSimulator {
    return NetworkConfig.isSimulator;
  }
  
  static Future<String?> getCurrentComputerIP() async {
    return await NetworkConfig.getCurrentComputerIP();
  }
  
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static String getNetworkErrorMessage(dynamic error, {String? endpoint}) {
    String baseMessage = '';
    
    if (error is SocketException) {
      baseMessage = 'Network connection failed. Please check your internet connection and try again.';
    } else if (error is TimeoutException) {
      baseMessage = 'Request timed out. The server may be busy or your connection is slow.';
    } else if (error is HttpException) {
      baseMessage = 'HTTP error occurred. Please try again later.';
    } else {
      baseMessage = 'An unexpected network error occurred. Please try again.';
    }
    
    if (endpoint != null) {
      baseMessage += '\n\nEndpoint: $endpoint';
    }
    
    return baseMessage;
  }
  
  static Map<String, dynamic> getErrorDetails(dynamic error, {String? endpoint}) {
    return {
      'error': error.toString(),
      'errorType': error.runtimeType.toString(),
      'endpoint': endpoint,
      'timestamp': DateTime.now().toIso8601String(),
      'networkStatus': NetworkConfig.getNetworkInfo(),
      'suggestions': _getErrorSuggestions(error),
    };
  }
  
  static List<String> _getErrorSuggestions(dynamic error) {
    if (error is SocketException) {
      return [
        'Check if your device has internet connection',
        'Verify the backend server is running',
        'Check if the IP address is correct',
        'Ensure both devices are on the same network',
      ];
    } else if (error is TimeoutException) {
      return [
        'The server may be overloaded',
        'Check your internet connection speed',
        'Try again in a few moments',
        'Verify the backend server is responsive',
      ];
    } else if (error is HttpException) {
      return [
        'Check if the backend server is running',
        'Verify the API endpoint is correct',
        'Check server logs for errors',
        'Ensure the backend is accessible',
      ];
    }
    
    return [
      'Try refreshing the network configuration',
      'Check if the backend server is running',
      'Verify network connectivity',
      'Try again in a few moments',
    ];
  }
  
  static void dispose() {
    _stopHealthMonitoring();
  }
}
