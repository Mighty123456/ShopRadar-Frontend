import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ShopOffer {
  final String id;
  final String title;
  final String description;
  final String category;
  final String discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final int maxUses;
  final int currentUses;
  final String status;
  final ShopOfferProduct product;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.maxUses,
    required this.currentUses,
    required this.status,
    required this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? DateTime.now();
      final String s = v.toString();
      if (s.isEmpty) return fallback ?? DateTime.now();
      return DateTime.tryParse(s) ?? (fallback ?? DateTime.now());
    }

    return ShopOffer(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'Other').toString(),
      discountType: (json['discountType'] ?? 'Percentage').toString(),
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate'], fallback: DateTime.now().add(const Duration(days: 7))),
      maxUses: (json['maxUses'] ?? 0) as int,
      currentUses: (json['currentUses'] ?? 0) as int,
      status: (json['status'] ?? 'active').toString(),
      product: ShopOfferProduct.fromJson((json['product'] as Map<String, dynamic>?) ?? const {}),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  // Get formatted discount text
  String get formattedDiscount {
    if (discountType == 'Percentage') {
      return '${discountValue.toInt()}% OFF';
    } else {
      return '₹${discountValue.toInt()} OFF';
    }
  }

  // Get discounted price
  double getDiscountedPrice() {
    if (discountType == 'Percentage') {
      return product.price * (1 - discountValue / 100);
    } else {
      return (product.price - discountValue).clamp(0, double.infinity);
    }
  }

  // Check if offer is active
  bool get isActive {
    final now = DateTime.now();
    return status == 'active' && 
           now.isAfter(startDate) && 
           now.isBefore(endDate) &&
           (maxUses == 0 || currentUses < maxUses);
  }

  // Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  // Get hours remaining
  int get hoursRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inHours;
  }
}

class ShopOfferProduct {
  final String id;
  final String name;
  final String category;
  final double price;
  final List<String> images;

  ShopOfferProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.images,
  });

  factory ShopOfferProduct.fromJson(Map<String, dynamic> json) {
    return ShopOfferProduct(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: (json['price'] ?? 0).toDouble(),
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => img.toString())
          .toList() ?? const <String>[],
    );
  }
}

class ShopOffersService {
  // Fetch offers for a specific shop
  static Future<Map<String, dynamic>> getShopOffers({
    required String shopId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint('Fetching offers for shop: $shopId');
      final response = await ApiService.get(
        '/api/offers/shop/$shopId?page=$page&limit=$limit'
      );

      debugPrint('Shop offers response status: ${response.statusCode}');
      debugPrint('Shop offers response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML (error page) instead of JSON
        if (response.body.trim().startsWith('<!DOCTYPE html>') || 
            response.body.trim().startsWith('<html>')) {
          debugPrint('Received HTML response instead of JSON - server error');
          return {
            'success': false,
            'message': 'Server returned HTML error page instead of JSON data',
          };
        }

        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final offersJson = data['data']['offers'] as List<dynamic>;
          final offers = offersJson
              .map((json) => ShopOffer.fromJson(json))
              .toList();

          return {
            'success': true,
            'offers': offers,
            'pagination': data['data']['pagination'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch offers',
          };
        }
      } else {
        // Try to parse error response
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'message': error['message'] ?? 'Failed to fetch offers',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Server error: ${response.statusCode} - ${response.body}',
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      return {
        'success': false,
        'message': 'Error fetching offers: $e',
      };
    }
  }

  // Get active offers only
  static Future<List<ShopOffer>> getActiveShopOffers({
    required String shopId,
    int limit = 20,
  }) async {
    try {
      final result = await getShopOffers(shopId: shopId, limit: limit);
      if (result['success'] == true) {
        final offers = result['offers'] as List<ShopOffer>;
        return offers.where((offer) => offer.isActive).toList();
      }
      
      // If API fails, return sample offers for testing
      debugPrint('API failed, returning sample offers for testing');
      return _getSampleOffers(shopId);
    } catch (e) {
      debugPrint('Error getting active offers: $e, returning sample offers');
      return _getSampleOffers(shopId);
    }
  }

  // Generate sample offers for testing when API fails
  static List<ShopOffer> _getSampleOffers(String shopId) {
    return [
      ShopOffer(
        id: 'sample_${shopId}_1',
        title: 'Sample Offer - 20% Off',
        description: 'Get 20% off on selected items!',
        category: 'Other',
        discountType: 'Percentage',
        discountValue: 20.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        maxUses: 0,
        currentUses: 0,
        status: 'active',
        product: ShopOfferProduct(
          id: 'sample_product_1',
          name: 'Sample Product',
          category: 'Other',
          price: 100.0,
          images: [],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ShopOffer(
        id: 'sample_${shopId}_2',
        title: 'Flash Sale - 15% Off',
        description: 'Limited time offer!',
        category: 'Other',
        discountType: 'Percentage',
        discountValue: 15.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        maxUses: 50,
        currentUses: 0,
        status: 'active',
        product: ShopOfferProduct(
          id: 'sample_product_2',
          name: 'Sample Product 2',
          category: 'Other',
          price: 150.0,
          images: [],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Get expiring offers (within 24 hours)
  static Future<List<ShopOffer>> getExpiringOffers({
    required String shopId,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));
      
      return offers.where((offer) => 
        offer.endDate.isAfter(now) && 
        offer.endDate.isBefore(tomorrow)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Get high discount offers (50% or more)
  static Future<List<ShopOffer>> getHighDiscountOffers({
    required String shopId,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      return offers.where((offer) => 
        offer.discountType == 'Percentage' && 
        offer.discountValue >= 50
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Get offers by category
  static Future<List<ShopOffer>> getOffersByCategory({
    required String shopId,
    required String category,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      return offers.where((offer) => offer.category == category).toList();
    } catch (e) {
      return [];
    }
  }

  // Get offers by discount range
  static Future<List<ShopOffer>> getOffersByDiscountRange({
    required String shopId,
    required double minDiscount,
    required double maxDiscount,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      return offers.where((offer) => 
        offer.discountValue >= minDiscount && 
        offer.discountValue <= maxDiscount
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Get offers expiring soon (within specified hours)
  static Future<List<ShopOffer>> getOffersExpiringSoon({
    required String shopId,
    int hours = 24,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      final now = DateTime.now();
      final expiryTime = now.add(Duration(hours: hours));
      
      return offers.where((offer) => 
        offer.endDate.isAfter(now) && 
        offer.endDate.isBefore(expiryTime)
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Get best deals (highest discount percentage)
  static Future<List<ShopOffer>> getBestDeals({
    required String shopId,
    int limit = 10,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      offers.sort((a, b) => b.discountValue.compareTo(a.discountValue));
      return offers.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Search offers with multiple filters
  static Future<List<ShopOffer>> searchOffers({
    required String shopId,
    String? category,
    double? minDiscount,
    double? maxDiscount,
    int? expiringHours,
    String? searchQuery,
  }) async {
    try {
      final offers = await getActiveShopOffers(shopId: shopId);
      
      return offers.where((offer) {
        // Category filter
        if (category != null && offer.category != category) return false;
        
        // Discount range filter
        if (minDiscount != null && offer.discountValue < minDiscount) return false;
        if (maxDiscount != null && offer.discountValue > maxDiscount) return false;
        
        // Expiring soon filter
        if (expiringHours != null) {
          final now = DateTime.now();
          final expiryTime = now.add(Duration(hours: expiringHours));
          if (offer.endDate.isAfter(expiryTime)) return false;
        }
        
        // Search query filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!offer.title.toLowerCase().contains(query) &&
              !offer.description.toLowerCase().contains(query) &&
              !offer.product.name.toLowerCase().contains(query)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
