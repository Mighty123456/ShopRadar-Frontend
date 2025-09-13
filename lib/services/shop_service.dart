import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  // Create product with optional offer (unified endpoint)
  static Future<Map<String, dynamic>> createProductWithOffer({
    required Map<String, dynamic> productData,
    Map<String, dynamic>? offerData,
  }) async {
    try {
      debugPrint('Creating product with offer...');
      
      // Prepare the request data
      final Map<String, dynamic> requestData = {
        'product': <String, dynamic>{
          'name': productData['name'],
          'description': productData['description'],
          'category': productData['category'],
          'price': productData['price'],
          'stock': productData['stock'],
        },
        'offer': offerData,
      };

      // Upload product image if provided
      if (productData['image'] != null) {
        debugPrint('Uploading product image...');
        final imageUploadResult = await _uploadProductImage(productData['image']);
        if (imageUploadResult['success'] == true) {
          final imageData = imageUploadResult['data'];
          if (imageData != null) {
            (requestData['product'] as Map<String, dynamic>)['image'] = imageData;
          } else {
            return {
              'success': false,
              'message': 'Image upload succeeded but no data returned',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Failed to upload product image: ${imageUploadResult['message']}',
          };
        }
      }

      final response = await ApiService.post('/api/shops/products/unified', requestData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Create product with offer response status: ${response.statusCode}');
      debugPrint('Create product with offer response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true,
          'product': data['product'],
          'offer': data['offer'],
          'message': data['message'] ?? 'Product created successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      debugPrint('Create product with offer error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get shop owner's products
  static Future<Map<String, dynamic>> getMyProducts({
    int page = 1,
    int limit = 10,
    String? category,
    String? status,
    String? search,
  }) async {
    try {
      debugPrint('Fetching shop owner\'s products...');
      
      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final response = await ApiService.get('/api/shops/products?$queryString').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get my products response status: ${response.statusCode}');
      debugPrint('Get my products response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'products': data['data']['products'],
          'pagination': data['data']['pagination'],
          'message': 'Products retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch products',
        };
      }
    } catch (e) {
      debugPrint('Get my products error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update shop owner's product
  static Future<Map<String, dynamic>> updateMyProduct({
    required String productId,
    String? name,
    String? description,
    String? category,
    double? price,
    int? stock,
    String? status,
  }) async {
    try {
      debugPrint('Updating product: $productId');
      
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (price != null) updateData['price'] = price;
      if (stock != null) updateData['stock'] = stock;
      if (status != null) updateData['status'] = status;
      
      final response = await ApiService.put('/api/shops/products/$productId', updateData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Update product response status: ${response.statusCode}');
      debugPrint('Update product response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'product': data['product'],
          'message': data['message'] ?? 'Product updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      debugPrint('Update product error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Delete shop owner's product
  static Future<Map<String, dynamic>> deleteMyProduct(String productId) async {
    try {
      debugPrint('Deleting product: $productId');
      
      final response = await ApiService.delete('/api/shops/products/$productId').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Delete product response status: ${response.statusCode}');
      debugPrint('Delete product response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Product deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      debugPrint('Delete product error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper method to upload product image
  static Future<Map<String, dynamic>> _uploadProductImage(File imageFile) async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/api/upload/public?folder=products'),
      );
      
      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      
      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': {
            'url': data['url'],
            'publicId': data['publicId'],
            'mimeType': data['mimeType'],
          },
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Upload failed',
        };
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      return {
        'success': false,
        'message': 'Upload error: $e',
      };
    }
  }
}
