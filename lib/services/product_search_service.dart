import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/shop.dart';

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
      );

      // Keep best offer/price per shop
      if (bestOfferPercent > agg.bestOfferPercent) agg.bestOfferPercent = bestOfferPercent;
      if (price > 0 && (agg.bestPrice == 0 || price < agg.bestPrice)) agg.bestPrice = price;
      byShop[shopId] = agg;
    }

    // Convert to Shop model, with a synthetic offer for discount display
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
        isOpen: true,
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
  });
}

// (no additional helpers required)

