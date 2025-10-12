import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/category.dart' as models;

class CategoryService {
  // Create a new category
  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final response = await ApiService.post('/api/categories', {
        'name': name,
        'description': description,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': models.Category.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create category',
        };
      }
    } catch (e) {
      debugPrint('Create category error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Get all categories for the shop
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await ApiService.get('/api/categories');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = (data['data'] as List<dynamic>)
            .map((cat) => models.Category.fromJson(cat))
            .toList();
        
        return {
          'success': true,
          'data': categories,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get categories',
        };
      }
    } catch (e) {
      debugPrint('Get categories error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Get category hierarchy (categories with brands)
  static Future<Map<String, dynamic>> getCategoryHierarchy() async {
    try {
      final response = await ApiService.get('/api/categories/hierarchy');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = (data['data'] as List<dynamic>)
            .map((cat) => models.Category.fromJson(cat))
            .toList();
        
        return {
          'success': true,
          'data': categories,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get category hierarchy',
        };
      }
    } catch (e) {
      debugPrint('Get category hierarchy error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Add brand to category
  static Future<Map<String, dynamic>> addBrand({
    required String categoryId,
    required String brandName,
    String? brandDescription,
  }) async {
    try {
      final response = await ApiService.post('/api/categories/$categoryId/brands', {
        'categoryId': categoryId,
        'brandName': brandName,
        'brandDescription': brandDescription,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': models.Category.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add brand',
        };
      }
    } catch (e) {
      debugPrint('Add brand error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Get brands for a category
  static Future<Map<String, dynamic>> getBrands(String categoryId) async {
    try {
      final response = await ApiService.get('/api/categories/$categoryId/brands');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final brands = (data['data'] as List<dynamic>)
            .map((brand) => models.Brand.fromJson(brand))
            .toList();
        
        return {
          'success': true,
          'data': brands,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get brands',
        };
      }
    } catch (e) {
      debugPrint('Get brands error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Update category
  static Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    String? name,
    String? description,
  }) async {
    try {
      final response = await ApiService.put('/api/categories/$categoryId', {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': models.Category.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update category',
        };
      }
    } catch (e) {
      debugPrint('Update category error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  // Delete category
  static Future<Map<String, dynamic>> deleteCategory(String categoryId) async {
    try {
      final response = await ApiService.delete('/api/categories/$categoryId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete category',
        };
      }
    } catch (e) {
      debugPrint('Delete category error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }
}
