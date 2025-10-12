import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkConfig {
  static const String emulator = 'emulator';
  static const String physicalDevice = 'physical_device';
  static const String simulator = 'simulator';
  
  static String? _currentEnvironment;
  
  static Map<String, String> baseUrls = {
    // Use 10.0.2.2 for emulator (Android emulator's special IP to access host machine's localhost)
    emulator: 'http://10.0.2.2:3000',
    // Use localhost for physical devices temporarily while Render.com is down
    physicalDevice: 'https://shopradarbackend-production.up.railway.app',
    // Use localhost for simulator (iOS simulator can access localhost directly)
    simulator: 'http://localhost:3000',
  };

  // Fallback URLs for when the primary hosted service is down
  static List<String> fallbackUrls = [
    'http://localhost:3000',  // Local development fallback
    'http://10.0.2.2:3000',  // Emulator fallback
  ];

  static Map<String, String> webSocketUrls = {
    // Use 10.0.2.2 for emulator (Android emulator's special IP to access host machine's localhost)
    emulator: 'ws://10.0.2.2:3000',
    // Use hosted API on physical devices so it works off your LAN
    physicalDevice: 'wss://shopradarbackend-production.up.railway.app',
    // Use localhost for simulator (iOS simulator can access localhost directly)
    simulator: 'ws://localhost:3000',
  };
  
  static const List<String> networkPatterns = [
    // Common local network ranges (local subnet is auto-detected and prioritized separately)
    '192.168.1',
    '192.168.0',
    '10.0.0',
    '10.1.0',
    '172.16',
    '172.20.10',
    '172.31',
    // emulator/localhost will be appended conditionally by environment
  ];
  
  static const List<int> alternativePorts = [3000];
  
  static String? _workingBaseUrl;
  static bool _isInitialized = false;
  static final List<String> _discoveredIPs = [];
  static int _currentPortIndex = 0;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _detectEnvironment().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          _currentEnvironment = physicalDevice;
        },
      );
      
      await _comprehensiveNetworkDiscovery().timeout(
        const Duration(seconds: 8),
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
        debugPrint('🔍 Android detected - Environment: $_currentEnvironment');
        debugPrint('🔍 Emulator check result: $isEmulator');
      } else if (Platform.isIOS) {
        _currentEnvironment = simulator;
        debugPrint('🔍 iOS detected - Environment: $_currentEnvironment');
      } else {
        _currentEnvironment = physicalDevice;
        debugPrint('🔍 Other platform detected - Environment: $_currentEnvironment');
      }
    } catch (e) {
      debugPrint('❌ Environment detection error: $e - Defaulting to physical device');
      _currentEnvironment = physicalDevice;
    }
  }
  
  static Future<bool> _checkIfEmulator() async {
    try {
      // For emulator, try 10.0.2.2 first (Android emulator's special IP to access host machine)
      final emulatorUrl = 'http://10.0.2.2:3000/health';
      
      final response = await http.get(Uri.parse(emulatorUrl))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> _comprehensiveNetworkDiscovery() async {
    try {
      // Test relevant base URLs in parallel for faster discovery
      final candidates = <String>[
        baseUrls[emulator]!, // localhost:3000 for emulator
        baseUrls[simulator]!, // localhost:3000 for simulator
        baseUrls[physicalDevice]!, // hosted URL for physical device
        ...fallbackUrls, // Add fallback URLs for better reliability
      ];
      
      debugPrint('🔍 Testing candidate URLs: $candidates');

      final futures = candidates.map((baseUrl) => 
        _testConnection(baseUrl).timeout(
          Duration(seconds: baseUrl.startsWith('https://') ? 60 : 3),
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
      // Skip subnet scanning on physical devices to avoid noisy probing
      if (_currentEnvironment != physicalDevice) {
        await Future.any([
          _discoverNetworkIPs().timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              return;
            },
          ),
          Future.delayed(const Duration(seconds: 6)).then((_) {
            return;
          }),
        ]);
      }
      
    } catch (e) {
      // Network discovery failed
    }
    
    _workingBaseUrl ??= _getFallbackUrl();
  }
  
  static Future<void> _discoverNetworkIPs() async {
    final localSubnet = await _getLocalSubnetPrefix().timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );
    final prioritizedPatterns = <String>[];
    if (localSubnet != null) {
      prioritizedPatterns.add(localSubnet);
    }
    prioritizedPatterns.addAll(networkPatterns);
    if (_currentEnvironment == emulator) {
      prioritizedPatterns.add('10.0.2.2');
    } else if (_currentEnvironment == simulator) {
      prioritizedPatterns.add('localhost');
    }

    for (final pattern in prioritizedPatterns.toSet()) {
      for (final port in alternativePorts) {
        if (pattern == 'localhost' || pattern == '10.0.2.2') {
          final url = 'http://$pattern:$port';
          if (await _testConnection(url).timeout(
            Duration(seconds: url.startsWith('https://') ? 60 : 4),
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
            Duration(seconds: url.startsWith('https://') ? 60 : 4),
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
              !addr.address.startsWith('169.254.') &&
              !addr.address.startsWith('192.0.0.')) {
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
    return await _testConnectionWithRetry(url, maxRetries: 2);
  }

  static Future<bool> _testConnectionWithRetry(String url, {int maxRetries = 2}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔍 Testing connection to: $url (attempt ${attempt + 1}/${maxRetries + 1})');
        // Render can cold-start; allow longer timeout for https hosts
        final isHosted = url.startsWith('https://');
        final response = await http.get(Uri.parse('$url/health'))
            .timeout(Duration(seconds: isHosted ? 60 : 5));
        
        if (response.statusCode == 200) {
          debugPrint('✅ Connection successful to: $url');
          return true;
        } else {
          debugPrint('❌ Connection failed to: $url - Status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Connection error to: $url - $e');
        if (attempt < maxRetries) {
          debugPrint('🔄 Retrying connection to: $url in 2 seconds...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    return false;
  }
  
  static String _getFallbackUrl() {
    if (_currentEnvironment == emulator) {
      debugPrint('🔧 Using emulator fallback URL: ${baseUrls[emulator]} (10.0.2.2:3000)');
      return baseUrls[emulator]!;
    } else if (_currentEnvironment == simulator) {
      debugPrint('🔧 Using simulator fallback URL: ${baseUrls[simulator]} (localhost:3000)');
      return baseUrls[simulator]!;
    } else {
      // For physical device, try discovered IPs first, then your specific IP
      if (_discoveredIPs.isNotEmpty) {
        debugPrint('🔧 Using discovered IP: ${_discoveredIPs.first}');
        return _discoveredIPs.first;
      } else {
        debugPrint('🔧 Using physical device fallback URL: ${baseUrls[physicalDevice]}');
        return baseUrls[physicalDevice]!;
      }
    }
  }
  
  static String get baseUrl {
    if (_workingBaseUrl != null) {
      debugPrint('🌐 Using working base URL: $_workingBaseUrl');
      return _workingBaseUrl!;
    }
    
    final url = _getFallbackUrl();
    debugPrint('🌐 Using fallback base URL: $url');
    return url;
  }

  static String get webSocketUrl {
    final baseUrl = NetworkConfig.baseUrl;
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
  }
  
  static Future<void> refreshNetworkConfig() async {
    debugPrint('🔄 Refreshing network configuration...');
    _isInitialized = false;
    _workingBaseUrl = null;
    _discoveredIPs.clear();
    _currentPortIndex = 0;
    debugPrint('🧹 Cleared all cached network state');
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
    
    final patterns = List<String>.from(networkPatterns);
    if (_currentEnvironment == emulator) {
      patterns.add('10.0.2.2');
    } else if (_currentEnvironment == simulator) {
      patterns.add('localhost');
    }

    for (final pattern in patterns) {
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

  static void setPhysicalDeviceBaseUrl(String url) {
    baseUrls[physicalDevice] = url;
    if (_currentEnvironment == physicalDevice) {
      _workingBaseUrl = null;
      // Clear discovered IPs to force using the new URL
      _discoveredIPs.clear();
      debugPrint('🔄 Cleared cached URLs and set new physical device URL: $url');
    }
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
      '13. Render.com service may be cold-starting (wait 60+ seconds)',
      '14. Try local development server as fallback',
      '15. Check Render.com service status and logs',
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
      final isHosted = baseUrl.startsWith('https://');
      final response = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(Duration(seconds: isHosted ? 60 : 10));
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