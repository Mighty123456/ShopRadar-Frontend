import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'network_config.dart';

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
    String? description,
    String? category,
    String? openingHours,
    List<String>? amenities,
  }) async {
    try {
      debugPrint('Updating shop details...');
      final Map<String, dynamic> updateData = {};
      if (shopName != null) updateData['shopName'] = shopName;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (gpsAddress != null) updateData['gpsAddress'] = gpsAddress;
      if (location != null) updateData['location'] = location;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (openingHours != null) updateData['openingHours'] = openingHours;
      if (amenities != null) updateData['amenities'] = amenities;
      final response = await ApiService.put('/api/shops/my-shop', updateData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );
      debugPrint('Update my shop response status:  [32m${response.statusCode} [0m');
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
        'message': 'Network error:  [31m${e.toString()} [0m',
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

  // Upload shop display photo URL (already uploaded to Cloudinary)
  static Future<Map<String, dynamic>> uploadShopPhoto({required String photoUrl}) async {
    try {
      debugPrint('Uploading shop photo URL to backend...');
      final response = await ApiService.post('/api/shops/my-shop/upload-photo', {
        'photoUrl': photoUrl,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );
      debugPrint('Upload shop photo response status: ${response.statusCode}');
      debugPrint('Upload shop photo response body: ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? 'Shop photo uploaded',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload shop photo',
        };
      }
    } catch (e) {
      debugPrint('Upload shop photo error: $e');
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

  // Get nearby shops by category (for customers)
  static Future<Map<String, dynamic>> getNearbyShopsByCategory({
    required double latitude,
    required double longitude,
    required String category,
    int radius = 5000,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      debugPrint('Fetching nearby shops (by category: $category, lat: $latitude, lng: $longitude, radius: $radius)');
      final categoryParam = Uri.encodeComponent(category);
      final response = await ApiService.get(
        '/api/shops/nearby?latitude=$latitude&longitude=$longitude&radius=$radius&category=$categoryParam&page=$page&limit=$limit',
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get nearby shops by category response status: ${response.statusCode}');
      debugPrint('Get nearby shops by category response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'shops': data['shops'],
          'message': 'Nearby shops by category retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch nearby shops by category',
        };
      }
    } catch (e) {
      debugPrint('Get nearby shops by category error: $e');
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
          'brand': productData['brand'],
          'itemName': productData['itemName'],
          'price': productData['price'],
          'stock': productData['stock'],
        },
        'offer': offerData,
      };

      // Upload product image if provided
      if (productData['image'] != null) {
        debugPrint('Uploading product image...');
        final String category = (productData['category'] ?? '').toString();
        final imageUploadResult = await _uploadProductImage(productData['image'], category);
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
      
      debugPrint('Parsed response data: $data');
      debugPrint('Response success field: ${data['success']}');
      debugPrint('Response success type: ${data['success'].runtimeType}');
      
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
    String? brand,
    String? model,
    String? description,
    String? tags,
    String? category,
    double? price,
    int? stock,
    String? unitType,
    String? availabilityStatus,
    String? status,
  }) async {
    try {
      debugPrint('Updating product: $productId');
      
      final Map<String, dynamic> updateData = {};
      
      if (name != null) updateData['name'] = name;
      if (brand != null) updateData['brand'] = brand;
      if (model != null) updateData['model'] = model;
      if (description != null) updateData['description'] = description;
      if (tags != null) updateData['tags'] = tags;
      if (category != null) updateData['category'] = category;
      if (price != null) updateData['price'] = price;
      if (stock != null) updateData['stock'] = stock;
      if (unitType != null) updateData['unitType'] = unitType;
      if (availabilityStatus != null) updateData['availabilityStatus'] = availabilityStatus;
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
      debugPrint('ShopService: Attempting to delete product with ID: $productId');
      
      final response = await ApiService.delete('/api/shops/products/$productId').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('ShopService: Delete request timed out');
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Delete product response status: ${response.statusCode}');
      debugPrint('Delete product response body: ${response.body}');
      debugPrint('ShopService: Delete response status: ${response.statusCode}');
      debugPrint('ShopService: Delete response body: ${response.body}');

      // Handle different response scenarios
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('ShopService: Product deleted successfully');
        
        // Try to parse response body, but don't fail if it's empty
        Map<String, dynamic> data = {};
        try {
          if (response.body.isNotEmpty) {
            data = jsonDecode(response.body);
          }
        } catch (e) {
          debugPrint('ShopService: Could not parse response body, but status indicates success');
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Product deleted successfully',
        };
      } else {
        debugPrint('ShopService: Delete failed with status: ${response.statusCode}');
        debugPrint('ShopService: Response body: ${response.body}');
        
        // Try to parse error message
        Map<String, dynamic> data = {};
        try {
          if (response.body.isNotEmpty) {
            data = jsonDecode(response.body);
          }
        } catch (e) {
          debugPrint('ShopService: Could not parse error response body');
        }
        
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Delete product error: $e');
      debugPrint('ShopService: Delete error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper method to upload product image
  static Future<Map<String, dynamic>> _uploadProductImage(File imageFile, String category) async {
    try {
      // Helper to send to a given base
      Future<Map<String, dynamic>> sendTo(String baseUrl) async {
        // Get auth token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        // Create multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/products/upload-image'),
        );

        // Add headers (do NOT set Content-Type manually; boundary is set by MultipartRequest)
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Add file to request
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        );

        // Include product category so backend organizes into <shopCode>/<category>
        request.fields['category'] = category;

        final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);
      
        if (response.statusCode == 200 || response.statusCode == 201) {
          Map<String, dynamic> data = {};
          try { data = jsonDecode(response.body); } catch (_) {}

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
              'data': {
                'url': url,
                'publicId': publicId,
                if (mimeType != null) 'mimeType': mimeType,
              },
            };
          }

          return {
            'success': false,
            'message': 'Upload response missing url',
          };
        } else {
          Map<String, dynamic> error = {};
          try { error = jsonDecode(response.body); } catch (_) {}
          return {
            'success': false,
            'message': error['message'] ?? 'Upload failed (status ${response.statusCode})',
          };
        }
      }

      final Set<String> candidateSet = <String>{ApiService.baseUrl};
      candidateSet.addAll(NetworkConfig.fallbackUrls);
      if (NetworkConfig.isEmulator) {
        candidateSet.add(NetworkConfig.baseUrls[NetworkConfig.emulator]!);
      } else if (NetworkConfig.isSimulator) {
        candidateSet.add(NetworkConfig.baseUrls[NetworkConfig.simulator]!);
      } else if (NetworkConfig.isPhysicalDevice) {
        candidateSet.addAll(NetworkConfig.discoveredUrls);
        candidateSet.removeWhere((u) => u.contains('localhost'));
      }
      final List<String> candidates = candidateSet.toList();

      Map<String, dynamic>? lastFailure;
      for (final base in candidates) {
        final result = await sendTo(base);
        if (result['success'] == true) return result;
        lastFailure = result;
      }
      return lastFailure ?? {'success': false, 'message': 'Upload failed: no candidates succeeded'};
    } catch (e) {
      debugPrint('Image upload error: $e');
      return {
        'success': false,
        'message': 'Upload error: $e',
      };
    }
  }

  // ==================== OFFER MANAGEMENT ====================

  // Get all offers for the shop
  static Future<Map<String, dynamic>> getMyOffers({int page = 1, int limit = 10}) async {
    try {
      debugPrint('Fetching shop owner\'s offers...');
      
      final response = await ApiService.get('/api/offers?page=$page&limit=$limit').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Get my offers request timed out');
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get my offers response status: ${response.statusCode}');
      debugPrint('Get my offers response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch offers',
        };
      }
    } catch (e) {
      debugPrint('Get my offers error: $e');
      return {
        'success': false,
        'message': 'Error fetching offers: $e',
      };
    }
  }

  // Create a new offer
  static Future<Map<String, dynamic>> createOffer({
    required String productId,
    required String title,
    required String description,
    required String discountType,
    required double discountValue,
    required DateTime startDate,
    required DateTime endDate,
    int maxUses = 0,
  }) async {
    try {
      debugPrint('Creating new offer...');
      
      final offerData = {
        'productId': productId,
        'title': title,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'maxUses': maxUses,
      };

      final response = await ApiService.post('/api/offers', offerData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Create offer request timed out');
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Create offer response status: ${response.statusCode}');
      debugPrint('Create offer response body: ${response.body}');

      final data = jsonDecode(response.body);
      debugPrint('Parsed offer response data: $data');
      debugPrint('Offer response success field: ${data['success']}');
      debugPrint('Offer response success type: ${data['success'].runtimeType}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Offer created successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create offer',
        };
      }
    } catch (e) {
      debugPrint('Create offer error: $e');
      return {
        'success': false,
        'message': 'Error creating offer: $e',
      };
    }
  }

  // Update an offer
  static Future<Map<String, dynamic>> updateOffer({
    required String offerId,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    DateTime? startDate,
    DateTime? endDate,
    int? maxUses,
    String? status,
  }) async {
    try {
      debugPrint('Updating offer: $offerId');
      
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (discountType != null) updateData['discountType'] = discountType;
      if (discountValue != null) updateData['discountValue'] = discountValue;
      if (startDate != null) updateData['startDate'] = startDate.toIso8601String();
      if (endDate != null) updateData['endDate'] = endDate.toIso8601String();
      if (maxUses != null) updateData['maxUses'] = maxUses;
      if (status != null) updateData['status'] = status;

      final response = await ApiService.put('/api/offers/$offerId', updateData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Update offer request timed out');
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Update offer response status: ${response.statusCode}');
      debugPrint('Update offer response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Offer updated successfully',
          'data': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update offer',
        };
      }
    } catch (e) {
      debugPrint('Update offer error: $e');
      return {
        'success': false,
        'message': 'Error updating offer: $e',
      };
    }
  }

  // Delete an offer
  static Future<Map<String, dynamic>> deleteOffer(String offerId) async {
    try {
      debugPrint('Deleting offer: $offerId');
      
      final response = await ApiService.delete('/api/offers/$offerId').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Delete offer request timed out');
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Delete offer response status: ${response.statusCode}');
      debugPrint('Delete offer response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Offer deleted successfully',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to delete offer',
        };
      }
    } catch (e) {
      debugPrint('Delete offer error: $e');
      return {
        'success': false,
        'message': 'Error deleting offer: $e',
      };
    }
  }

  // Toggle offer status (active/inactive)
  static Future<Map<String, dynamic>> toggleOfferStatus(String offerId) async {
    try {
      debugPrint('Toggling offer status: $offerId');
      
      final response = await ApiService.patch('/api/offers/$offerId/toggle-status').timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Toggle offer status request timed out');
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Toggle offer status response status: ${response.statusCode}');
      debugPrint('Toggle offer status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Offer status updated successfully',
          'data': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to toggle offer status',
        };
      }
    } catch (e) {
      debugPrint('Toggle offer status error: $e');
      return {
        'success': false,
        'message': 'Error toggling offer status: $e',
      };
    }
  }

  // Get shops by category (for customers)
  static Future<Map<String, dynamic>> getShopsByCategory({
    required String category,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      debugPrint('Fetching shops by category: $category');
      final categoryParam = Uri.encodeComponent(category);
      final response = await ApiService.get(
        '/api/shops?category=$categoryParam&page=$page&limit=$limit',
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out', const Duration(seconds: 30));
        },
      );

      debugPrint('Get shops by category response status: ${response.statusCode}');
      debugPrint('Get shops by category response body: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'shops': data['data']['shops'],
          'total': data['data']['total'],
          'message': 'Shops retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch shops by category',
        };
      }
    } catch (e) {
      debugPrint('Get shops by category error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
