import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const double _accuracyThreshold = 100.0; // meters
  static const Duration _timeout = Duration(seconds: 30);

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Get current location with high accuracy
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _timeout,
      );

      // Check if accuracy is acceptable
      if (position.accuracy > _accuracyThreshold) {
        debugPrint('Location accuracy is too low: ${position.accuracy}m');
        return null;
      }

      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Convert coordinates to address using reverse geocoding
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build address string
        List<String> addressParts = [];
        
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        
        return addressParts.join(', ');
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }

  /// Compare entered address with GPS location address
  static bool compareAddresses(String enteredAddress, String gpsAddress) {
    if (enteredAddress.isEmpty || gpsAddress.isEmpty) {
      return false;
    }

    // Normalize addresses for comparison
    String normalizedEntered = _normalizeAddress(enteredAddress);
    String normalizedGps = _normalizeAddress(gpsAddress);

    // Check if addresses are similar (at least 70% match)
    double similarity = _calculateSimilarity(normalizedEntered, normalizedGps);
    
    debugPrint('Address similarity: $similarity%');
    debugPrint('Entered: $normalizedEntered');
    debugPrint('GPS: $normalizedGps');
    
    return similarity >= 0.7;
  }

  /// Normalize address for comparison
  static String _normalizeAddress(String address) {
    return address
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Calculate similarity between two strings
  static double _calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    List<String> words1 = str1.split(' ');
    List<String> words2 = str2.split(' ');
    
    int matches = 0;
    int totalWords = words1.length;
    
    for (String word1 in words1) {
      if (words2.any((word2) => word1 == word2 || _isWordSimilar(word1, word2))) {
        matches++;
      }
    }
    
    return matches / totalWords;
  }

  /// Check if two words are similar (for typos, abbreviations, etc.)
  static bool _isWordSimilar(String word1, String word2) {
    if (word1.length < 3 || word2.length < 3) return false;
    
    // Check for common abbreviations
    Map<String, List<String>> abbreviations = {
      'street': ['st', 'str'],
      'road': ['rd'],
      'avenue': ['ave', 'av'],
      'boulevard': ['blvd', 'blv'],
      'lane': ['ln'],
      'drive': ['dr'],
      'circle': ['cir'],
      'court': ['ct'],
      'place': ['pl'],
      'apartment': ['apt'],
      'building': ['bldg'],
      'suite': ['ste'],
    };
    
    for (String key in abbreviations.keys) {
      List<String> abbrevs = abbreviations[key]!;
      if ((word1 == key && abbrevs.contains(word2)) ||
          (word2 == key && abbrevs.contains(word1))) {
        return true;
      }
    }
    
    // Check for edit distance (simple implementation)
    int distance = _levenshteinDistance(word1, word2);
    return distance <= 1 && word1.length > 3;
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String str1, String str2) {
    int m = str1.length;
    int n = str2.length;
    
    List<List<int>> dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (str1[i - 1] == str2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce((a, b) => a < b ? a : b);
        }
      }
    }
    
    return dp[m][n];
  }

  /// Get location coordinates as a map
  static Map<String, double> getLocationMap(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  }
}
