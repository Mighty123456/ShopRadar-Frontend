import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/shop.dart';
import '../models/product_result.dart';

class ProductSearchService {
  // Returns list of shops that sell the product, enriched for ranking
  static Future<List<Shop>> searchProductShops({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final q = query.trim();
    final uri = '/api/products/search?q=${Uri.encodeQueryComponent(q)}&limit=50';
    final http.Response response = await ApiService.get(uri);
    // Debug logs to help diagnose empty results
    // ignore: avoid_print
    print('[ProductSearch] GET $uri -> ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // ignore: avoid_print
        print('[ProductSearch] Error body: ${response.body}');
        throw Exception(body['message'] ?? 'Search failed');
      } catch (_) {
        throw Exception('Search failed with status ${response.statusCode}');
      }
    }

    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = (jsonBody['data'] as List<dynamic>? ) ?? <dynamic>[];
    // ignore: avoid_print
    print('[ProductSearch] Returned items: ${items.length}');

    // Aggregate by shop so each shop appears once with the best matching product/offer
    final Map<String, _ShopAgg> byShop = {};
    for (final dynamic d in items) {
      final Map<String, dynamic> p = d as Map<String, dynamic>;
      final Map<String, dynamic>? shop = p['shop'] as Map<String, dynamic>?;
      if (shop == null) continue;
      final String shopId = (shop['id'] ?? '').toString();
      if (shopId.isEmpty) continue;
      final double lat = (shop['location']?['coordinates'] is List && (shop['location']['coordinates'] as List).length >= 2)
          ? ((shop['location']['coordinates'][1] as num).toDouble())
          : 0.0;
      final double lon = (shop['location']?['coordinates'] is List && (shop['location']['coordinates'] as List).length >= 2)
          ? ((shop['location']['coordinates'][0] as num).toDouble())
          : 0.0;

      final double rating = (shop['rating'] is num) ? (shop['rating'] as num).toDouble() : 0.0;
      final int bestOfferPercent = (p['bestOfferPercent'] as num?)?.toInt() ?? 0;
      final double price = (p['price'] as num?)?.toDouble() ?? 0.0;

      final double distanceKm = (userLatitude != null && userLongitude != null)
          ? _haversineKm(userLatitude, userLongitude, lat, lon)
          : 0.0;

      final agg = byShop[shopId] ?? _ShopAgg(
        id: shopId,
        name: (shop['name'] ?? shop['shopName'] ?? '').toString(),
        address: (shop['address'] ?? '').toString(),
        phone: (shop['phone'] ?? '').toString(),
        latitude: lat,
        longitude: lon,
        rating: rating,
        distanceKm: distanceKm,
        bestOfferPercent: bestOfferPercent,
        bestPrice: price,
        isLive: shop['isLive'] ?? true,
      );

      // Keep best offer/price per shop
      if (bestOfferPercent > agg.bestOfferPercent) agg.bestOfferPercent = bestOfferPercent;
      if (price > 0 && (agg.bestPrice == 0 || price < agg.bestPrice)) agg.bestPrice = price;
      byShop[shopId] = agg;
    }

    // Convert to Shop model, with a synthetic offer for discount display
    // Note: This is still using the best offer approach since we're aggregating from products
    // In a real implementation, you might want to fetch actual offers separately
    final List<Shop> shops = byShop.values.map((a) {
      final offers = a.bestOfferPercent > 0
          ? [ShopOffer(
              id: 'best',
              title: '${a.bestOfferPercent}% OFF',
              description: 'Best current discount',
              discount: a.bestOfferPercent.toDouble(),
              validUntil: DateTime.now().add(const Duration(days: 7)),
            )]
          : const <ShopOffer>[];
      return Shop(
        id: a.id,
        name: a.name,
        category: '',
        address: a.address,
        latitude: a.latitude,
        longitude: a.longitude,
        rating: a.rating,
        reviewCount: 0,
        distance: a.distanceKm,
        offers: offers,
        isOpen: a.isLive,
        openingHours: '',
        phone: a.phone,
        imageUrl: null,
        description: null,
        amenities: const [],
        lastUpdated: null,
      );
    }).toList();

    // Rank: closer, higher discount, better rating
    shops.sort((a, b) {
      double aDiscount = a.offers.isNotEmpty ? a.offers.first.discount : 0.0;
      double bDiscount = b.offers.isNotEmpty ? b.offers.first.discount : 0.0;
      final double aScore = (0.5 * (a.rating / 5.0)) + (0.3 * (aDiscount / 100.0)) + (0.2 * (-a.distance));
      final double bScore = (0.5 * (b.rating / 5.0)) + (0.3 * (bDiscount / 100.0)) + (0.2 * (-b.distance));
      return bScore.compareTo(aScore);
    });

    return shops;
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000.0; // Earth's radius in meters
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (R * c) / 1000.0; // Convert meters to kilometers
  }

  // Enhanced search that includes all shops with offers
  static Future<Map<String, dynamic>> searchProductsWithShopsAndOffers({
    required String query,
    double? userLatitude,
    double? userLongitude,
    int radius = 10000,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      debugPrint('Searching products with shops and offers: $query');
      
      // Build query parameters
      final Map<String, String> queryParams = {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
        'radius': radius.toString(),
      };
      
      if (userLatitude != null && userLongitude != null) {
        queryParams['latitude'] = userLatitude.toString();
        queryParams['longitude'] = userLongitude.toString();
      }
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      final response = await ApiService.get('/api/products/search-with-shops?$queryString');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final productsJson = data['data']['products'] as List<dynamic>;
          final shopsJson = data['data']['shops'] as List<dynamic>;
          
          // Parse products
          final List<ProductResult> products = productsJson.map((p) {
            final Map<String, dynamic> productData = p as Map<String, dynamic>;
            final Map<String, dynamic>? shopData = productData['shop'] as Map<String, dynamic>?;
            
            // Calculate best offer percentage from shop offers
            int bestOfferPercent = 0;
            if (shopData?['offers'] is List) {
              for (final offerData in shopData!['offers'] as List) {
                if (offerData is Map<String, dynamic>) {
                  final discountValue = (offerData['discountValue'] as num?)?.toDouble() ?? 0.0;
                  final discountType = offerData['discountType']?.toString() ?? 'Percentage';
                  
                  int offerPercent = 0;
                  if (discountType == 'Percentage') {
                    offerPercent = discountValue.round();
                  } else if (discountType == 'Fixed Amount') {
                    // For fixed amount, we'll use the raw value as percentage
                    // In a real implementation, you'd need the product price to calculate percentage
                    offerPercent = discountValue.round();
                  }
                  
                  if (offerPercent > bestOfferPercent) {
                    bestOfferPercent = offerPercent;
                  }
                }
              }
            }
            
            return ProductResult(
              id: (productData['id'] ?? '').toString(),
              name: (productData['name'] ?? '').toString(),
              description: (productData['description'] ?? '').toString(),
              price: (productData['price'] as num?)?.toDouble() ?? 0.0,
              imageUrl: productData['image']?.toString(),
              shopId: shopData?['id']?.toString() ?? '',
              shopName: shopData?['name']?.toString() ?? '',
              shopAddress: shopData?['address']?.toString() ?? '',
              shopRating: (shopData?['rating'] as num?)?.toDouble() ?? 0.0,
              shopLatitude: shopData?['location']?['coordinates'] is List && (shopData?['location']['coordinates'] as List).length >= 2
                  ? ((shopData?['location']['coordinates'][1] as num).toDouble())
                  : 0.0,
              shopLongitude: shopData?['location']?['coordinates'] is List && (shopData?['location']['coordinates'] as List).length >= 2
                  ? ((shopData?['location']['coordinates'][0] as num).toDouble())
                  : 0.0,
              bestOfferPercent: bestOfferPercent,
              distanceKm: 0.0, // Will be calculated by the calling code
            );
          }).toList();
          
          // Parse shops with offers
          final List<Shop> shops = shopsJson.map((s) {
            final Map<String, dynamic> shopData = s as Map<String, dynamic>;
            
            // Parse offers
            final List<ShopOffer> offers = [];
            if (shopData['offers'] is List) {
              for (final offerData in shopData['offers'] as List) {
                if (offerData is Map<String, dynamic>) {
                  final discountValue = (offerData['discountValue'] as num?)?.toDouble() ?? 0.0;
                  final discountType = offerData['discountType']?.toString() ?? 'Percentage';
                  
                  double discountPercent = discountValue;
                  if (discountType == 'Fixed Amount') {
                    discountPercent = discountValue;
                  }
                  
                  offers.add(ShopOffer(
                    id: (offerData['id'] ?? '').toString(),
                    title: (offerData['title'] ?? '').toString(),
                    description: (offerData['description'] ?? '').toString(),
                    discount: discountPercent,
                    validUntil: offerData['endDate'] != null 
                        ? DateTime.parse(offerData['endDate'].toString())
                        : DateTime.now().add(const Duration(days: 7)),
                  ));
                }
              }
            }
            
            final double latitude = shopData['location']?['coordinates'] is List && (shopData['location']['coordinates'] as List).length >= 2
                ? ((shopData['location']['coordinates'][1] as num).toDouble())
                : 0.0;
            final double longitude = shopData['location']?['coordinates'] is List && (shopData['location']['coordinates'] as List).length >= 2
                ? ((shopData['location']['coordinates'][0] as num).toDouble())
                : 0.0;
            
            return Shop(
              id: (shopData['id'] ?? '').toString(),
              name: (shopData['name'] ?? '').toString(),
              category: '',
              address: (shopData['address'] ?? '').toString(),
              latitude: latitude,
              longitude: longitude,
              rating: (shopData['rating'] as num?)?.toDouble() ?? 0.0,
              reviewCount: 0,
              distance: 0.0, // Will be calculated by the calling code
              offers: offers,
              isOpen: shopData['isLive'] == true,
              openingHours: '',
              phone: (shopData['phone'] ?? '').toString(),
              imageUrl: null,
              description: null,
              amenities: const [],
              lastUpdated: null,
            );
          }).toList();
          
          return {
            'success': true,
            'products': products,
            'shops': shops,
            'totalProducts': data['data']['totalProducts'] ?? 0,
            'totalShops': data['data']['totalShops'] ?? 0,
            'pagination': data['pagination'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Search failed',
            'products': <ProductResult>[],
            'shops': <Shop>[],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Search request failed',
          'products': <ProductResult>[],
          'shops': <Shop>[],
        };
      }
    } catch (e) {
      debugPrint('Enhanced product search error: $e');
      return {
        'success': false,
        'message': 'Search error: $e',
        'products': <ProductResult>[],
        'shops': <Shop>[],
      };
    }
  }
}

double sin(double x) => math.sin(x);
double cos(double x) => math.cos(x);
double atan2(double y, double x) => math.atan2(y, x);
double sqrt(double x) => math.sqrt(x);
double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

class _ShopAgg {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final double rating;
  final double distanceKm;
  int bestOfferPercent;
  double bestPrice;
  final bool isLive;

  _ShopAgg({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.distanceKm,
    required this.bestOfferPercent,
    required this.bestPrice,
    required this.isLive,
  });
}

// (no additional helpers required)

