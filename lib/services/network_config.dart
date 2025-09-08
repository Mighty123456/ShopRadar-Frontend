import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkConfig {
  static const String emulator = 'emulator';
  static const String physicalDevice = 'physical_device';
  static const String simulator = 'simulator';
  
  static String? _currentEnvironment;
  
  static const Map<String, String> baseUrls = {
    emulator: 'http://10.0.2.2:3000',
    physicalDevice: 'http://10.154.51.145:3000', // Your actual IP
    simulator: 'http://localhost:3000',
  };
  
  static const List<String> networkPatterns = [
    '10.154.51', // Your network range
    '192.168.1',
    '192.168.0',
    '10.0.0',
    '10.1.0',
    '172.16',
    '172.20.10',
    '172.31',
    '10.0.2.2',
    'localhost',
  ];
  
  static const List<int> alternativePorts = [3000, 3001, 8080, 8000, 5000];
  
  static String? _workingBaseUrl;
  static bool _isInitialized = false;
  static final List<String> _discoveredIPs = [];
  static int _currentPortIndex = 0;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _detectEnvironment().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _currentEnvironment = physicalDevice;
        },
      );
      
      await _comprehensiveNetworkDiscovery().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          _workingBaseUrl = _getFallbackUrl();
        },
      );
      
      _isInitialized = true;
      
    } catch (e) {
      _workingBaseUrl = _getFallbackUrl();
      _isInitialized = true;
    }
  }
  
  static Future<void> _detectEnvironment() async {
    try {
      if (Platform.isAndroid) {
        final isEmulator = await _checkIfEmulator();
        _currentEnvironment = isEmulator ? emulator : physicalDevice;
        debugPrint('Android detected - Environment: $_currentEnvironment');
      } else if (Platform.isIOS) {
        _currentEnvironment = simulator;
        debugPrint('iOS detected - Environment: $_currentEnvironment');
      } else {
        _currentEnvironment = physicalDevice;
        debugPrint('Other platform detected - Environment: $_currentEnvironment');
      }
    } catch (e) {
      debugPrint('Environment detection error: $e - Defaulting to physical device');
      _currentEnvironment = physicalDevice;
    }
  }
  
  static Future<bool> _checkIfEmulator() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:3000/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> _comprehensiveNetworkDiscovery() async {
    try {
      // Test all base URLs in parallel for faster discovery
      final futures = baseUrls.values.map((baseUrl) => 
        _testConnection(baseUrl).timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        ).then((isWorking) => isWorking ? baseUrl : null)
      );
      
      final results = await Future.wait(futures);
      final workingUrl = results.firstWhere((url) => url != null, orElse: () => null);
      
      if (workingUrl != null) {
        _workingBaseUrl = workingUrl;
        _discoveredIPs.add(workingUrl);
        return;
      }
      
      await Future.any([
        _discoverNetworkIPs().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            return;
          },
        ),
        Future.delayed(const Duration(seconds: 15)).then((_) {
          return;
        }),
      ]);
      
    } catch (e) {
      // Network discovery failed
    }
    
    _workingBaseUrl ??= _getFallbackUrl();
  }
  
  static Future<void> _discoverNetworkIPs() async {
    final localSubnet = await _getLocalSubnetPrefix().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
    final prioritizedPatterns = <String>[];
    if (localSubnet != null) {
      prioritizedPatterns.add(localSubnet);
    }
    prioritizedPatterns.addAll(networkPatterns);

    for (final pattern in prioritizedPatterns.toSet()) {
      for (final port in alternativePorts) {
        if (pattern == 'localhost' || pattern == '10.0.2.2') {
          final url = 'http://$pattern:$port';
          if (await _testConnection(url).timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          )) {
            _workingBaseUrl = url;
            _discoveredIPs.add(url);
            return;
          }
          continue;
        }
        
        for (int i = 1; i <= 20; i++) {
          final ip = '$pattern.$i';
          final url = 'http://$ip:$port';
          
          if (await _testConnection(url).timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          )) {
            _workingBaseUrl = url;
            _discoveredIPs.add(url);
            return;
          }
        }
      }
    }
  }

  static Future<String?> _getLocalSubnetPrefix() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              return '${parts[0]}.${parts[1]}.${parts[2]}';
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
  
  static Future<bool> _testConnection(String url) async {
    try {
      debugPrint('Testing connection to: $url');
      final response = await http.get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        debugPrint('Connection successful to: $url');
        return true;
      } else {
        debugPrint('Connection failed to: $url - Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Connection error to: $url - $e');
    }
    return false;
  }
  
  static String _getFallbackUrl() {
    if (_currentEnvironment == emulator) {
      debugPrint('Using emulator fallback URL: ${baseUrls[emulator]}');
      return baseUrls[emulator]!;
    } else if (_currentEnvironment == simulator) {
      debugPrint('Using simulator fallback URL: ${baseUrls[simulator]}');
      return baseUrls[simulator]!;
    } else {
      // For physical device, try discovered IPs first, then your specific IP
      if (_discoveredIPs.isNotEmpty) {
        debugPrint('Using discovered IP: ${_discoveredIPs.first}');
        return _discoveredIPs.first;
      } else {
        debugPrint('Using physical device fallback URL: ${baseUrls[physicalDevice]}');
        return baseUrls[physicalDevice]!;
      }
    }
  }
  
  static String get baseUrl {
    if (_workingBaseUrl != null) {
      return _workingBaseUrl!;
    }
    
    final url = _getFallbackUrl();
    return url;
  }
  
  static Future<void> refreshNetworkConfig() async {
    _isInitialized = false;
    _workingBaseUrl = null;
    _discoveredIPs.clear();
    _currentPortIndex = 0;
    await initialize();
  }
  
  static Future<String?> getNextWorkingUrl() async {
    if (_discoveredIPs.isEmpty) {
      await refreshNetworkConfig();
    }
    
    if (_discoveredIPs.isNotEmpty) {
      _currentPortIndex = (_currentPortIndex + 1) % _discoveredIPs.length;
      return _discoveredIPs[_currentPortIndex];
    }
    
    return null;
  }
  
  static List<String> get discoveredUrls => List.unmodifiable(_discoveredIPs);
  
  // Manual environment override for testing
  static void setEnvironment(String environment) {
    if ([emulator, physicalDevice, simulator].contains(environment)) {
      _currentEnvironment = environment;
      debugPrint('Environment manually set to: $environment');
    }
  }
  
  static String? get currentEnvironment => _currentEnvironment;
  
  static List<String> get alternativeUrls {
    final urls = <String>[];
    
    urls.addAll(_discoveredIPs);
    
    for (final pattern in networkPatterns) {
      if (pattern == 'localhost' || pattern == '10.0.2.2') {
        for (final port in alternativePorts) {
          urls.add('http://$pattern:$port');
        }
      } else {
        urls.add('http://$pattern.1:3000');
        urls.add('http://$pattern.100:3000');
        urls.add('http://$pattern.254:3000');
      }
    }
    
    return urls.toSet().toList();
  }
  
  static bool get isPhysicalDevice {
    return _currentEnvironment == physicalDevice;
  }
  
  static bool get isEmulator {
    return _currentEnvironment == emulator;
  }
  
  static bool get isSimulator {
    return _currentEnvironment == simulator;
  }
  
  
  static Map<String, dynamic> getNetworkInfo() {
    return {
      'currentEnvironment': currentEnvironment,
      'baseUrl': baseUrl,
      'workingBaseUrl': _workingBaseUrl,
      'isInitialized': _isInitialized,
      'discoveredIPs': _discoveredIPs,
      'alternativeUrls': alternativeUrls,
      'isPhysicalDevice': isPhysicalDevice,
      'isEmulator': isEmulator,
      'isSimulator': isSimulator,
    };
  }
  
  static Map<String, dynamic> getDetailedNetworkInfo() {
    return {
      'currentEnvironment': currentEnvironment,
      'baseUrl': baseUrl,
      'workingBaseUrl': _workingBaseUrl,
      'isInitialized': _isInitialized,
      'discoveredIPs': _discoveredIPs,
      'alternativeUrls': alternativeUrls,
      'isPhysicalDevice': isPhysicalDevice,
      'isEmulator': isEmulator,
      'isSimulator': isSimulator,
      'suggestions': [
        'Make sure backend server is running on port 3000',
        'Check if IP address is correct for your network',
        'Try alternative IPs if current one fails',
        'For emulator, use 10.0.2.2:3000',
        'For physical device, use your computer\'s IP address',
        'Run: cd backend_node && npm start',
        'Check if port 3000 is not blocked by firewall',
        'Ensure MongoDB is running and accessible',
        'Call NetworkConfig.refreshNetworkConfig() to retry discovery',
        'Use NetworkConfig.getNextWorkingUrl() for failover',
      ],
    };
  }
  
  static List<String> getTroubleshootingSteps() {
    return [
      '1. Start backend server: cd backend_node && npm start',
      '2. Check if MongoDB is running and accessible',
      '3. Verify network configuration in network_config.dart',
      '4. For emulator: use 10.0.2.2:3000',
      '5. For physical device: use your computer\'s IP address',
      '6. Check firewall settings and allow port 3000',
      '7. Ensure device and server are on same network',
      '8. Check if .env file is properly configured',
      '9. Call NetworkConfig.refreshNetworkConfig() to retry',
      '10. Check CORS settings in backend/app.js',
      '11. Use NetworkConfig.getNextWorkingUrl() for failover',
      '12. Check discovered IPs: ${_discoveredIPs.join(", ")}',
    ];
  }
  
  static Future<String?> getCurrentComputerIP() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      // Error getting IP
    }
    return null;
  }
  
  static Future<bool> isNetworkHealthy() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  static Future<Map<String, dynamic>> getNetworkHealth() async {
    final isHealthy = await isNetworkHealthy();
    return {
      'isHealthy': isHealthy,
      'baseUrl': baseUrl,
      'workingUrl': _workingBaseUrl,
      'discoveredIPs': _discoveredIPs,
      'environment': currentEnvironment,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
} 