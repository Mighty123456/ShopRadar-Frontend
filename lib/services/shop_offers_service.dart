import 'dart:convert';
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
    return ShopOffer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Other',
      discountType: json['discountType'] ?? 'Percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      maxUses: json['maxUses'] ?? 0,
      currentUses: json['currentUses'] ?? 0,
      status: json['status'] ?? 'active',
      product: ShopOfferProduct.fromJson(json['product'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => img.toString())
          .toList() ?? [],
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
      final response = await ApiService.get(
        '/api/offers/shop/$shopId?page=$page&limit=$limit'
      );

      if (response.statusCode == 200) {
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
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to fetch offers',
        };
      }
    } catch (e) {
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
      return [];
    } catch (e) {
      return [];
    }
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
