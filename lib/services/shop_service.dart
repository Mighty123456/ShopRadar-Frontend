import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ShopService {
  // Get shop owner's own shop details
  static Future<Map<String, dynamic>> getMyShop() async {
    try {
      debugPrint('Fetching shop owner\'s shop details...');
      
      final response = await ApiService.get('/api/shops/my-shop').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get my shop response status: ${response.statusCode}');
      debugPrint('Get my shop response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'shop': data['shop'],
          'message': data['message'] ?? 'Shop details retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch shop details',
        };
      }
    } catch (e) {
      debugPrint('Get my shop error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update shop owner's shop details
  static Future<Map<String, dynamic>> updateMyShop({
    String? shopName,
    String? phone,
    String? address,
    String? gpsAddress,
    Map<String, double>? location,
  }) async {
    try {
      debugPrint('Updating shop details...');
      
      final Map<String, dynamic> updateData = {};
      
      if (shopName != null) updateData['shopName'] = shopName;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (gpsAddress != null) updateData['gpsAddress'] = gpsAddress;
      if (location != null) updateData['location'] = location;
      
      final response = await ApiService.put('/api/shops/my-shop', updateData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Update my shop response status: ${response.statusCode}');
      debugPrint('Update my shop response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'shop': data['shop'],
          'message': data['message'] ?? 'Shop details updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update shop details',
        };
      }
    } catch (e) {
      debugPrint('Update my shop error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update shop status (open/closed)
  static Future<Map<String, dynamic>> updateShopStatus({required bool isLive}) async {
    try {
      debugPrint('Updating shop status to: ${isLive ? 'open' : 'closed'}');
      
      final response = await ApiService.put('/api/shops/my-shop/status', {
        'isLive': isLive,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Update shop status response status: ${response.statusCode}');
      debugPrint('Update shop status response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'shop': data['shop'],
          'message': data['message'] ?? 'Shop status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update shop status',
        };
      }
    } catch (e) {
      debugPrint('Update shop status error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get shop statistics
  static Future<Map<String, dynamic>> getShopStats() async {
    try {
      debugPrint('Fetching shop statistics...');
      
      final response = await ApiService.get('/api/shops/my-shop/stats').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get shop stats response status: ${response.statusCode}');
      debugPrint('Get shop stats response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'stats': data['stats'],
          'message': data['message'] ?? 'Shop statistics retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch shop statistics',
        };
      }
    } catch (e) {
      debugPrint('Get shop stats error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get shop verification status
  static Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      debugPrint('Fetching shop verification status...');
      
      final response = await ApiService.get('/api/shops/my-shop/verification').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get verification status response status: ${response.statusCode}');
      debugPrint('Get verification status response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'verification': data['verification'],
          'message': data['message'] ?? 'Verification status retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch verification status',
        };
      }
    } catch (e) {
      debugPrint('Get verification status error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get nearby shops (for customers)
  static Future<Map<String, dynamic>> getNearbyShops({
    required double latitude,
    required double longitude,
    int radius = 5000,
  }) async {
    try {
      debugPrint('Fetching nearby shops...');
      
      final response = await ApiService.get(
        '/api/shops/nearby?latitude=$latitude&longitude=$longitude&radius=$radius'
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get nearby shops response status: ${response.statusCode}');
      debugPrint('Get nearby shops response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'shops': data['shops'],
          'message': 'Nearby shops retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch nearby shops',
        };
      }
    } catch (e) {
      debugPrint('Get nearby shops error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
