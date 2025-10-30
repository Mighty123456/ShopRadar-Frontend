import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FeaturedOffer {
  final String id;
  final String title;
  final String description;
  final String discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final int maxUses;
  final int currentUses;
  final String status;
  final ShopInfo shop;
  final ProductInfo product;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeaturedOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.maxUses,
    required this.currentUses,
    required this.status,
    required this.shop,
    required this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeaturedOffer.fromJson(Map<String, dynamic> json) {
    return FeaturedOffer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'Percentage',
      discountValue: (json['discountValue'] ?? 0.0).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      maxUses: json['maxUses'] ?? 0,
      currentUses: json['currentUses'] ?? 0,
      status: json['status'] ?? 'active',
      shop: ShopInfo.fromJson(json['shop'] ?? {}),
      product: ProductInfo.fromJson(json['product'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => status == 'active' && !isExpired;
  
  String get formattedDiscount {
    if (discountType == 'Percentage') {
      return '${discountValue.round()}% OFF';
    } else {
      return '\$${discountValue.toStringAsFixed(0)} OFF';
    }
  }

  int get daysRemaining {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inDays;
  }

  double get usagePercentage {
    if (maxUses == 0) return 0.0;
    return (currentUses / maxUses) * 100;
  }
}

class ShopInfo {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double rating;
  final bool isLive;

  ShopInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.isLive,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      isLive: json['isLive'] ?? false,
    );
  }
}

class ProductInfo {
  final String id;
  final String name;
  final String category;
  final double price;
  final List<String> images;

  ProductInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.images,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => img.toString())
          .toList() ?? [],
    );
  }
}

class FeaturedOffersService {
  static final FeaturedOffersService _instance = FeaturedOffersService._internal();
  factory FeaturedOffersService() => _instance;
  FeaturedOffersService._internal();

  List<FeaturedOffer> _offers = [];
  final StreamController<List<FeaturedOffer>> _offersController = StreamController<List<FeaturedOffer>>.broadcast();
  Timer? _pollingTimer;
  bool _isPolling = false;

  // Getters
  List<FeaturedOffer> get offers => List.unmodifiable(_offers);
  Stream<List<FeaturedOffer>> get offersStream => _offersController.stream;
  bool get isConnected => _isPolling;

  // Initialize polling for real-time updates
  Future<void> initializeWebSocket() async {
    try {
      _isPolling = true;
      _startPolling();
      debugPrint('Polling started for featured offers');
    } catch (e) {
      debugPrint('Failed to initialize polling: $e');
      _isPolling = false;
    }
  }

  // Start polling for updates every 30 seconds
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshOffers();
    });
  }

  // Refresh offers from API
  Future<void> _refreshOffers() async {
    try {
      final offers = await fetchFeaturedOffers(limit: 10);
      if (offers.isNotEmpty) {
        _offers = offers;
        if (!_offersController.isClosed) {
          _offersController.add(_offers);
          debugPrint('Refreshed offers via polling: ${offers.length} offers');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing offers: $e');
    }
  }


  // Fetch featured offers from API
  Future<List<FeaturedOffer>> fetchFeaturedOffers({
    double? latitude,
    double? longitude,
    double radius = 8000, // 8km radius for featured offers
    int limit = 10,
  }) async {
    try {
      String url = '/api/offers/featured?limit=$limit&radius=${radius.toInt()}';
      
      if (latitude != null && longitude != null) {
        url += '&latitude=$latitude&longitude=$longitude';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final offersJson = data['data']['offers'] as List<dynamic>;
          final offers = offersJson
              .map((json) => FeaturedOffer.fromJson(json))
              .where((offer) => offer.isActive)
              .toList();
          
          _offers = offers;
          if (!_offersController.isClosed) {
            _offersController.add(_offers);
          }
          
          debugPrint('Fetched ${offers.length} featured offers');
          return offers;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch offers');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching featured offers: $e');
      return [];
    }
  }

  // Get offers by category
  List<FeaturedOffer> getOffersByCategory(String category) {
    return _offers.where((offer) => offer.product.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // Get offers by shop
  List<FeaturedOffer> getOffersByShop(String shopId) {
    return _offers.where((offer) => offer.shop.id == shopId).toList();
  }

  // Get expiring offers (within 24 hours)
  List<FeaturedOffer> getExpiringOffers() {
    final now = DateTime.now();
    final tomorrow = now.add(Duration(hours: 24));
    
    return _offers.where((offer) => 
      offer.endDate.isAfter(now) && 
      offer.endDate.isBefore(tomorrow)
    ).toList();
  }

  // Get high discount offers (50% or more)
  List<FeaturedOffer> getHighDiscountOffers() {
    return _offers.where((offer) => 
      offer.discountType == 'Percentage' && 
      offer.discountValue >= 50
    ).toList();
  }

  // Search offers
  List<FeaturedOffer> searchOffers(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _offers.where((offer) =>
      offer.title.toLowerCase().contains(lowercaseQuery) ||
      offer.description.toLowerCase().contains(lowercaseQuery) ||
      offer.product.name.toLowerCase().contains(lowercaseQuery) ||
      offer.shop.name.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Dispose resources
  void dispose() {
    _pollingTimer?.cancel();
    _isPolling = false;
    if (!_offersController.isClosed) {
      _offersController.close();
    }
  }
  
  // Check if service is properly initialized
  bool get isInitialized => !_offersController.isClosed && _isPolling;
}
