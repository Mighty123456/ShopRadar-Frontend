import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/shop.dart';
import '../models/product_result.dart';
import 'product_search_service.dart';
import 'shop_offers_service.dart' as offers_service;

class SearchService {
  // ---- Safe parsers ----
  static String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final parsed = double.tryParse(v.toString());
    return parsed ?? fallback;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    final parsed = int.tryParse(v.toString());
    return parsed ?? fallback;
  }
  // Convert offers_service.ShopOffer to models ShopOffer used by Shop
  static ShopOffer _toModelOffer(offers_service.ShopOffer o) {
    final bool isPercentage = o.discountType == 'Percentage';
    final double percent = isPercentage ? o.discountValue : 0.0;
    return ShopOffer(
      id: o.id,
      title: o.title,
      description: o.description,
      discount: percent,
      validUntil: o.endDate,
      imageUrl: null,
      applicableProducts: const <String>[],
      termsAndConditions: null,
    );
  }

  /// Helper method to fetch real offers for a shop from the offers API
  static Future<List<ShopOffer>> _fetchRealOffers(String shopId) async {
    try {
      debugPrint('Fetching real offers for shop: $shopId');
      final offers = await offers_service.ShopOffersService.getActiveShopOffers(
        shopId: shopId,
        limit: 10,
      );
      debugPrint('Found ${offers.length} real offers for shop $shopId');
      final mapped = offers.map(_toModelOffer).toList();
      return mapped;
    } catch (e) {
      debugPrint('Failed to fetch real offers for shop $shopId: $e');
      return <ShopOffer>[];
    }
  }

  static Future<({List<ProductResult> products, List<Shop> shops})> searchMixed({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return (products: <ProductResult>[], shops: <Shop>[]);

    // 0) Try backend ranking first when location is available (mirrors frontend visitPriorityScore)
    List<Shop> rankedShops = <Shop>[];
    if (userLatitude != null && userLongitude != null) {
      try {
        rankedShops = await getRankedShopsSimple(
          latitude: userLatitude,
          longitude: userLongitude,
          maxDistanceKm: 20,
          limit: 20,
        );
        if (rankedShops.isNotEmpty) {
          debugPrint('Ranking API returned ${rankedShops.length} shops');
        }
      } catch (e) {
        debugPrint('Ranking API failed: $e');
      }
    }

    // Try enhanced search first (includes all shops with offers)
    try {
      final result = await ProductSearchService.searchProductsWithShopsAndOffers(
        query: trimmed,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      
      if (result['success'] == true) {
        final List<ProductResult> products = List<ProductResult>.from(result['products'] ?? []);
        final List<Shop> shops = List<Shop>.from(result['shops'] ?? []);
        
        debugPrint('Enhanced search found ${products.length} products and ${shops.length} shops with offers');
        debugPrint('Shops data: ${shops.map((s) => '${s.name} (${s.offers.length} offers)').join(', ')}');
        
        // Calculate distances for shops if user location is available
        if (userLatitude != null && userLongitude != null) {
          debugPrint('Calculating distances for ${shops.length} shops from user location: $userLatitude, $userLongitude');
          final List<Shop> shopsWithDistance = shops.map((shop) {
            if (shop.latitude != 0.0 && shop.longitude != 0.0) {
              final distance = _haversineKm(userLatitude, userLongitude, shop.latitude, shop.longitude);
              debugPrint('Shop ${shop.name}: distance = ${distance.toStringAsFixed(2)}km');
              return Shop(
                id: shop.id,
                name: shop.name,
                category: shop.category,
                address: shop.address,
                latitude: shop.latitude,
                longitude: shop.longitude,
                rating: shop.rating,
                reviewCount: shop.reviewCount,
                distance: distance,
                offers: shop.offers,
                isOpen: shop.isOpen,
                openingHours: shop.openingHours,
                phone: shop.phone,
                imageUrl: shop.imageUrl,
                description: shop.description,
                amenities: shop.amenities,
                lastUpdated: shop.lastUpdated,
              );
            } else {
              debugPrint('Shop ${shop.name}: invalid coordinates (${shop.latitude}, ${shop.longitude})');
            }
            return shop;
          }).toList();
          
          // If we already have ranked shops from backend, prefer that ordering and enrich with offers from enhanced list when possible
          if (rankedShops.isNotEmpty) {
            // Build a map for offers by shop id from enhanced results to enrich ranked shops
            final Map<String, List<ShopOffer>> offersByShop = {
              for (final s in shopsWithDistance) s.id: s.offers,
            };
            final List<Shop> enriched = rankedShops.map((rs) {
              final List<ShopOffer> offers = offersByShop[rs.id] ?? rs.offers;
              return Shop(
                id: rs.id,
                name: rs.name,
                category: rs.category,
                address: rs.address,
                latitude: rs.latitude,
                longitude: rs.longitude,
                rating: rs.rating,
                reviewCount: rs.reviewCount,
                distance: rs.distance,
                offers: offers,
                isOpen: rs.isOpen,
                openingHours: rs.openingHours,
                phone: rs.phone,
                imageUrl: rs.imageUrl,
                description: rs.description,
                amenities: rs.amenities,
                lastUpdated: rs.lastUpdated,
              );
            }).toList();
            debugPrint('Enhanced search returning ${products.length} products and ${enriched.length} ranked shops');
            return (products: products, shops: enriched);
          }
          debugPrint('Enhanced search returning ${products.length} products and ${shopsWithDistance.length} shops with calculated distances');
          return (products: products, shops: shopsWithDistance);
        } else {
          debugPrint('No user location available, returning shops without distance calculation');
        }
        
        return (products: products, shops: shops);
      } else {
        debugPrint('Enhanced search failed: ${result['message']}, falling back to original search');
        debugPrint('Enhanced search result: $result');
      }
    } catch (e) {
      debugPrint('Enhanced search error: $e, falling back to original search');
    }

    // If enhanced search fails or returns no results, try to get shops with offers directly
    debugPrint('Enhanced search failed or returned no shops, trying direct shop search with offers');
    try {
      final List<Shop> shopsWithOffers = await searchShops(trimmed);
      if (shopsWithOffers.isNotEmpty) {
        if (rankedShops.isNotEmpty) {
          // Merge offers into ranked order (fallback path)
          final Map<String, List<ShopOffer>> offersByShop = { for (final s in shopsWithOffers) s.id: s.offers };
          final List<Shop> enriched = rankedShops.map((rs) {
            final List<ShopOffer> offers = offersByShop[rs.id] ?? rs.offers;
            return Shop(
              id: rs.id,
              name: rs.name,
              category: rs.category,
              address: rs.address,
              latitude: rs.latitude,
              longitude: rs.longitude,
              rating: rs.rating,
              reviewCount: rs.reviewCount,
              distance: rs.distance,
              offers: offers,
              isOpen: rs.isOpen,
              openingHours: rs.openingHours,
              phone: rs.phone,
              imageUrl: rs.imageUrl,
              description: rs.description,
              amenities: rs.amenities,
              lastUpdated: rs.lastUpdated,
            );
          }).toList();
          debugPrint('Direct shop search used to enrich ${enriched.length} ranked shops');
          return (products: <ProductResult>[], shops: enriched);
        }
        debugPrint('Direct shop search found ${shopsWithOffers.length} shops with offers');
        return (products: <ProductResult>[], shops: shopsWithOffers);
      }
    } catch (e) {
      debugPrint('Direct shop search also failed: $e');
    }

    // If still no shops with offers found, try to get any shops and add sample offers for testing
    debugPrint('No shops with offers found, trying to get any shops and adding sample offers');
    try {
      final List<Shop> anyShops = await searchShops(trimmed);
      if (anyShops.isNotEmpty) {
        // Add sample offers to shops that don't have any
        final List<Shop> shopsWithSampleOffers = anyShops.map((shop) {
          if (shop.offers.isEmpty) {
            // Create sample offers for testing
            final sampleOffers = [
              ShopOffer(
                id: 'sample_${shop.id}_1',
                title: 'Sample Offer - 20% Off',
                description: 'Get 20% off on selected items!',
                discount: 20.0,
                validUntil: DateTime.now().add(const Duration(days: 30)),
              ),
              ShopOffer(
                id: 'sample_${shop.id}_2',
                title: 'Flash Sale - 15% Off',
                description: 'Limited time offer!',
                discount: 15.0,
                validUntil: DateTime.now().add(const Duration(days: 7)),
              ),
            ];
            
            return Shop(
              id: shop.id,
              name: shop.name,
              category: shop.category,
              address: shop.address,
              latitude: shop.latitude,
              longitude: shop.longitude,
              rating: shop.rating,
              reviewCount: shop.reviewCount,
              distance: shop.distance,
              offers: sampleOffers,
              isOpen: shop.isOpen,
              openingHours: shop.openingHours,
              phone: shop.phone,
              imageUrl: shop.imageUrl,
              description: shop.description,
              amenities: shop.amenities,
              lastUpdated: shop.lastUpdated,
            );
          }
          return shop;
        }).toList();
        
        debugPrint('Added sample offers to ${shopsWithSampleOffers.length} shops');
        return (products: <ProductResult>[], shops: shopsWithSampleOffers);
      }
    } catch (e) {
      debugPrint('Failed to get shops for sample offers: $e');
    }

    // Fallback to original search
    final List<Map<String, dynamic>> rawProducts = await _searchProductsRaw(trimmed);

    final List<ProductResult> products = rawProducts.map((p) {
      final Map<String, dynamic>? shop = p['shop'] as Map<String, dynamic>?;
      final List<dynamic> coords = (shop?['location']?['coordinates'] as List<dynamic>?) ?? const [];
      final double lat = coords.length >= 2 ? (coords[1] as num).toDouble() : 0.0;
      final double lon = coords.length >= 2 ? (coords[0] as num).toDouble() : 0.0;
      double distanceKm = 0.0;
      if (userLatitude != null && userLongitude != null && lat != 0.0 && lon != 0.0) {
        distanceKm = _haversineKm(userLatitude, userLongitude, lat, lon);
        debugPrint('Product ${p['name']}: distance = ${distanceKm.toStringAsFixed(2)}km');
      } else {
        debugPrint('Product ${p['name']}: no distance calculation (user: $userLatitude,$userLongitude, shop: $lat,$lon)');
      }
      // Use actual offer percentage from backend, don't create synthetic ones
      int bestOfferPercent = (p['bestOfferPercent'] as num?)?.toInt() ?? 0;
      
      return ProductResult(
        id: (p['id'] ?? '').toString(),
        name: (p['name'] ?? '').toString(),
        description: (p['description'] ?? '').toString(),
        imageUrl: (p['image'] ?? p['imageUrl'])?.toString(),
        price: (p['price'] as num?)?.toDouble() ?? 0.0,
        bestOfferPercent: bestOfferPercent,
        shopId: (shop?['id'] ?? '').toString(),
        shopName: (shop?['name'] ?? shop?['shopName'] ?? '').toString(),
        shopAddress: (shop?['address'] ?? '').toString(),
        shopLatitude: lat,
        shopLongitude: lon,
        shopRating: (shop?['rating'] as num?)?.toDouble() ?? 0.0,
        distanceKm: distanceKm,
      );
    }).toList();

    // If some products don't include bestOfferPercent, fetch actual offers
    // for their shops and backfill the highest percentage so UI shows real data.
    final Set<String> shopsNeedingOffers = products
        .where((pr) => pr.bestOfferPercent == 0 && pr.shopId.isNotEmpty)
        .map((pr) => pr.shopId)
        .toSet();

    Map<String, int> bestPercentByShop = {};
    if (shopsNeedingOffers.isNotEmpty) {
      try {
        final List<Future<void>> tasks = shopsNeedingOffers.map((shopId) async {
          try {
            final offers = await offers_service.ShopOffersService.getActiveShopOffers(shopId: shopId, limit: 10);
            int best = 0;
            for (final o in offers) {
              if (o.discountType == 'Percentage') {
                best = math.max(best, o.discountValue.round());
              }
            }
            bestPercentByShop[shopId] = best;
          } catch (e) {
            debugPrint('Failed to fetch offers for shop $shopId while backfilling percent: $e');
            bestPercentByShop[shopId] = 0;
          }
        }).toList();
        await Future.wait(tasks);
      } catch (e) {
        debugPrint('Error backfilling bestOfferPercent from offers: $e');
      }
    }

    // Rebuild products with backfilled percentages where available
    final List<ProductResult> productsWithRealPercents = products.map((p) {
      if (p.bestOfferPercent > 0) return p;
      final int backfilled = bestPercentByShop[p.shopId] ?? 0;
      if (backfilled == 0) return p;
      return ProductResult(
        id: p.id,
        name: p.name,
        description: p.description,
        imageUrl: p.imageUrl,
        price: p.price,
        bestOfferPercent: backfilled,
        shopId: p.shopId,
        shopName: p.shopName,
        shopAddress: p.shopAddress,
        shopLatitude: p.shopLatitude,
        shopLongitude: p.shopLongitude,
        shopRating: p.shopRating,
        distanceKm: p.distanceKm,
      );
    }).toList();

    // If product hits exist, aggregate shops from product results so each shop appears once
    // with the best offer/lowest price. This ensures multiple shops with offers are shown.
    debugPrint('Fallback search: Found ${productsWithRealPercents.length} products');
    if (productsWithRealPercents.isNotEmpty) {
      final Map<String, _ShopAggFromProducts> byShop = {};
      for (final p in productsWithRealPercents) {
        if (p.shopId.isEmpty) continue;
        final agg = byShop[p.shopId] ?? _ShopAggFromProducts(
          id: p.shopId,
          name: p.shopName,
          address: p.shopAddress,
          latitude: p.shopLatitude,
          longitude: p.shopLongitude,
          rating: p.shopRating,
          distanceKm: p.distanceKm,
          bestOfferPercent: p.bestOfferPercent,
          bestPrice: p.price,
        );
        if (p.bestOfferPercent > agg.bestOfferPercent) agg.bestOfferPercent = p.bestOfferPercent;
        if (p.price > 0 && (agg.bestPrice == 0 || p.price < agg.bestPrice)) agg.bestPrice = p.price;
        // If distance not computed earlier, keep the first non-zero
        if (agg.distanceKm == 0 && p.distanceKm > 0) agg.distanceKm = p.distanceKm;
        byShop[p.shopId] = agg;
      }

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
          phone: '',
          imageUrl: null,
          description: null,
          amenities: const [],
          lastUpdated: null,
        );
      }).toList();

      debugPrint('Fallback search created ${shops.length} shops from products');
      debugPrint('Fallback shops: ${shops.map((s) => '${s.name} (${s.offers.length} offers)').join(', ')}');

      // Rank by discount, rating, and proximity (if available)
      shops.sort((a, b) {
        double aDiscount = a.offers.isNotEmpty ? a.offers.first.discount : 0.0;
        double bDiscount = b.offers.isNotEmpty ? b.offers.first.discount : 0.0;
        final double aScore = (0.5 * (a.rating / 5.0)) + (0.3 * (aDiscount / 100.0)) + (0.2 * (-a.distance));
        final double bScore = (0.5 * (b.rating / 5.0)) + (0.3 * (bDiscount / 100.0)) + (0.2 * (-b.distance));
        return bScore.compareTo(aScore);
      });

      return (products: productsWithRealPercents, shops: shops);
    }

    // Fallback when no product hits: generic shop search
    debugPrint('No products found, trying shop search fallback');
    final List<Shop> fallbackShops = await searchShops(trimmed);
    debugPrint('Shop search fallback found ${fallbackShops.length} shops');
    if (rankedShops.isNotEmpty) {
      final Map<String, List<ShopOffer>> offersByShop = { for (final s in fallbackShops) s.id: s.offers };
      final List<Shop> enriched = rankedShops.map((rs) {
        final List<ShopOffer> offers = offersByShop[rs.id] ?? rs.offers;
        return Shop(
          id: rs.id,
          name: rs.name,
          category: rs.category,
          address: rs.address,
          latitude: rs.latitude,
          longitude: rs.longitude,
          rating: rs.rating,
          reviewCount: rs.reviewCount,
          distance: rs.distance,
          offers: offers,
          isOpen: rs.isOpen,
          openingHours: rs.openingHours,
          phone: rs.phone,
          imageUrl: rs.imageUrl,
          description: rs.description,
          amenities: rs.amenities,
          lastUpdated: rs.lastUpdated,
        );
      }).toList();
      return (products: productsWithRealPercents, shops: enriched);
    }
    
    // If still no shops found and user has location, try nearby shops
    if (fallbackShops.isEmpty && userLatitude != null && userLongitude != null) {
      debugPrint('No shops found in search, trying nearby shops with offers');
      try {
        final nearbyShops = await _getNearbyShopsWithOffers(userLatitude, userLongitude);
        if (nearbyShops.isNotEmpty) {
          debugPrint('Found ${nearbyShops.length} nearby shops with offers');
          return (products: products, shops: nearbyShops);
        }
      } catch (e) {
        debugPrint('Failed to get nearby shops: $e');
      }
    }
    
    return (products: productsWithRealPercents, shops: fallbackShops);
  }

  // Helper method to get nearby shops with offers
  static Future<List<Shop>> _getNearbyShopsWithOffers(double latitude, double longitude) async {
    try {
      final uri = '/api/shops/nearby?latitude=$latitude&longitude=$longitude&radius=10000';
      debugPrint('Getting nearby shops: $uri');
      
      final response = await ApiService.get(uri);
      debugPrint('Nearby shops response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
        final List<dynamic> shopsData = data['data'];
      final List<Shop> shops = await Future.wait(shopsData.map((shopData) async {
        final Map<String, dynamic> item = (shopData as Map).cast<String, dynamic>();
        final String shopId = _asString(item['_id'] ?? item['id']);
        
        // Fetch real offers from the offers API instead of parsing from shop data
        final List<ShopOffer> offers = await _fetchRealOffers(shopId);
            
            final List<dynamic>? coords = (item['location'] is Map && (item['location'] as Map).containsKey('coordinates'))
                ? (item['location']['coordinates'] as List?)
                : null;
            final double lat = (coords != null && coords.length >= 2)
                ? _asDouble(coords[1])
                : 0.0;
            final double lon = (coords != null && coords.length >= 2)
                ? _asDouble(coords[0])
                : 0.0;
            
            return Shop(
              id: shopId,
              name: _asString(item['name']),
              category: '',
              address: _asString(item['address']),
              latitude: lat,
              longitude: lon,
              rating: _asDouble(item['rating']),
              reviewCount: 0,
              distance: _asDouble(item['distance']),
              offers: offers,
              isOpen: item['isLive'] == true,
              openingHours: '',
              phone: _asString(item['phone']),
              imageUrl: null,
              description: null,
              amenities: const [],
              lastUpdated: null,
            );
          }));
          
          debugPrint('Parsed ${shops.length} nearby shops with offers');
          return shops;
        }
      }
    } catch (e) {
      debugPrint('Error getting nearby shops: $e');
    }
    return <Shop>[];
  }

  static Future<List<Shop>> searchShops(String query) async {
    final trimmed = query.trim();
    // Use the shopController endpoint that includes offers
    final uri = '/api/shops/search?q=${Uri.encodeQueryComponent(trimmed)}';
    
    debugPrint('Searching shops with query: $trimmed');
    debugPrint('Shop search URI: $uri');

    final http.Response response = await ApiService.get(uri);
    
    debugPrint('Shop search response status: ${response.statusCode}');
    debugPrint('Shop search response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final bool success = (jsonBody['success'] as bool?) ?? true; // tolerate different schemas
      if (!success) {
        throw Exception(jsonBody['message'] ?? 'Search failed');
      }

      final dynamic data = jsonBody['data'] ?? jsonBody['results'] ?? jsonBody['shops'] ?? jsonBody['items'];

      final List<dynamic> list = (data is List)
          ? data
          : (data is Map && data['shops'] is List)
              ? (data['shops'] as List)
              : <dynamic>[];

      final List<Shop> shops = await Future.wait(list.map((e) async {
        final Map<String, dynamic> item = (e as Map).cast<String, dynamic>();
        final String shopId = _asString(item['_id'] ?? item['id']);

        final double latitude = (item['latitude'] is num)
            ? _asDouble(item['latitude'])
            : (item['location']?['coordinates'] is List && (item['location']['coordinates'] as List).length >= 2)
                ? _asDouble(item['location']['coordinates'][1])
                : 0.0;

        final double longitude = (item['longitude'] is num)
            ? _asDouble(item['longitude'])
            : (item['location']?['coordinates'] is List && (item['location']['coordinates'] as List).length >= 2)
                ? _asDouble(item['location']['coordinates'][0])
                : 0.0;

        // Fetch real offers from the offers API instead of parsing from shop data
        final List<ShopOffer> offers = await _fetchRealOffers(shopId);

        return Shop(
          id: shopId,
          name: _asString(item['shopName'] ?? item['name']),
          category: _asString(item['category']),
          address: _asString(item['address']),
          latitude: latitude,
          longitude: longitude,
          rating: _asDouble(item['rating']),
          reviewCount: _asInt(item['reviewCount'] ?? item['reviewsCount']),
          distance: _asDouble(item['distanceKm'] ?? item['distance']),
          offers: offers,
          isOpen: item['isLive'] == true || item['isOpen'] == true,
          openingHours: _asString(item['openingHours']),
          phone: _asString(item['phone']),
          imageUrl: item['imageUrl']?.toString(),
          description: item['description']?.toString(),
          amenities: const [],
          lastUpdated: null,
        );
      }));

      // Apply simple BM25-like ranking with small business boosts client-side.
      // This is a lightweight scorer to improve ordering when backend doesn't rank.
      _rankWithBm25AndBoosts(shops, trimmed);
      return shops;
    }

    // Surface backend error message when available
    try {
      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final String msg = (body['message'] ?? body['error'] ?? 'Search failed').toString();
      throw Exception('Search failed with status ${response.statusCode}: $msg');
    } catch (_) {
      throw Exception('Search failed with status ${response.statusCode}');
    }
  }

  static void _rankWithBm25AndBoosts(List<Shop> shops, String query) {
    if (query.isEmpty || shops.isEmpty) return;

    final terms = _tokenize(query);
    final expandedTerms = _expandQueryTerms(terms);
    if (terms.isEmpty) return;

    // Build a tiny corpus over the returned set only
    final List<List<String>> docs = shops.map((s) => _tokenize('${s.name} ${s.category} ${s.description ?? ''}')).toList();
    final int N = docs.length;
    final Map<String, int> df = {};
    for (final doc in docs) {
      final Set<String> seen = {};
      for (final t in doc) {
        if (seen.add(t)) {
          df[t] = (df[t] ?? 0) + 1;
        }
      }
    }

    final double avgdl = docs.map((d) => d.length).fold<double>(0.0, (a, b) => a + b) / N;
    const double k1 = 1.2;
    const double b = 0.75;

    double bm25Score(List<String> doc, List<String> qTerms) {
      final int dl = doc.length;
      double score = 0.0;
      for (final q in qTerms) {
        // Query expansion: include synonyms of q
        final List<String> variants = [q, ..._synonyms[q] ?? const <String>[]];
        // Exact term frequency across any variant
        int exactF = 0;
        for (final v in variants) {
          exactF += doc.where((t) => t == v).length;
        }

        double effectiveF;
        if (exactF > 0) {
          effectiveF = exactF.toDouble();
        } else {
          // Fuzzy fallback: take best similarity to any token, thresholded
          double best = 0.0;
          for (final token in doc) {
            for (final v in variants) {
              final sim = _similarity(token, v);
              if (sim > best) best = sim;
              if (best >= 0.92) break; // early exit on very close match
            }
            if (best >= 0.92) break;
          }
          // Treat near match as fractional term frequency
          effectiveF = best >= 0.8 ? (best * 0.9) : 0.0;
        }

        if (effectiveF == 0) continue;

        // Use document frequency based on the base term if available, otherwise a small df to avoid zero idf
        final int n = df[q] ?? (df[variants.first] ?? 1);
        final double idf = (n == 0)
            ? 0.0
            : (((N - n + 0.5) / (n + 0.5)).abs() > 0 ? _ln((N - n + 0.5) / (n + 0.5)) : 0.0);
        final double denom = effectiveF + k1 * (1 - b + b * (dl / (avgdl == 0 ? 1 : avgdl)));
        score += idf * (((effectiveF) * (k1 + 1)) / (denom == 0 ? 1 : denom));
      }

      // Phrase proximity boost: if concatenated doc contains the raw query phrase
      final String docText = doc.join(' ');
      final String qPhrase = qTerms.join(' ');
      if (qPhrase.isNotEmpty && docText.contains(qPhrase)) {
        score += 0.3;
      }
      return score;
    }

    double businessBoost(Shop s) {
      final double verifiedBoost = s.isOpen ? 0.2 : 0.0; // proxy for verified if not available
      final double discountBoost = s.offers.isNotEmpty ? (s.offers.first.discount.clamp(0, 50) / 100.0) : 0.0;
      final double ratingBoost = (s.rating / 5.0) * 0.3;
      final double distancePenalty = (s.distance).clamp(0.0, 10.0) * 0.05; // up to -0.5 within 10km
      return verifiedBoost + discountBoost + ratingBoost - distancePenalty;
    }

    final List<_ScoredShop> scored = [];
    for (int i = 0; i < shops.length; i++) {
      final base = bm25Score(docs[i], expandedTerms);
      final boosted = base + businessBoost(shops[i]);
      scored.add(_ScoredShop(shops[i], boosted));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < scored.length; i++) {
      shops[i] = scored[i].shop;
    }
  }

  static List<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final parts = normalized.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    // very light stemming: remove plural 's'
    final stemmed = parts.map((t) => t.endsWith('s') && t.length > 3 ? t.substring(0, t.length - 1) : t);
    // stopword removal and short token filter
    return stemmed.where((t) => !_stopwords.contains(t) && t.length >= 2).toList();
  }

  static double _ln(double x) {
    return MathHelper.ln(x);
  }

  // --- NLP helpers ---
  static final Set<String> _stopwords = {
    'the','a','an','and','or','of','to','in','on','for','with','at','by','from','is','are','be','it','this','that','near','me'
  };

  static final Map<String, List<String>> _synonyms = {
    'phone': ['smartphone','mobile','cellphone'],
    'cellphone': ['phone','mobile','smartphone'],
    'sneaker': ['shoe','trainer'],
    'sneakers': ['shoes','trainers','sneaker'],
    'tv': ['television','smarttv'],
    'laptop': ['notebook','ultrabook'],
    'groceri': ['grocery','organic','food'],
    'coffee': ['cafe','espresso','latte'],
    'discount': ['offer','deal','sale'],
  };

  static List<String> _expandQueryTerms(List<String> terms) {
    final Set<String> expanded = {...terms};
    for (final t in terms) {
      final List<String>? syns = _synonyms[t];
      if (syns != null) {
        for (final s in syns) {
          expanded.add(s);
        }
      }
    }
    return expanded.toList();
  }

  static double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final int dist = _levenshtein(a, b);
    final int maxLen = a.length > b.length ? a.length : b.length;
    return 1.0 - (dist / (maxLen == 0 ? 1 : maxLen));
  }

  static int _levenshtein(String s, String t) {
    final int n = s.length;
    final int m = t.length;
    if (n == 0) return m;
    if (m == 0) return n;
    final List<int> prev = List<int>.generate(m + 1, (j) => j);
    final List<int> curr = List<int>.filled(m + 1, 0);
    for (int i = 1; i <= n; i++) {
      curr[0] = i;
      final int siCode = s.codeUnitAt(i - 1);
      for (int j = 1; j <= m; j++) {
        final int cost = (siCode == t.codeUnitAt(j - 1)) ? 0 : 1;
        curr[j] = math.min(
          math.min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      for (int j = 0; j <= m; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[m];
  }

  static Future<List<Map<String, dynamic>>> _searchProductsRaw(String query) async {
    final uri = '/api/products/search?q=${Uri.encodeQueryComponent(query)}&limit=30';
    final http.Response response = await ApiService.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> items = (jsonBody['data'] as List<dynamic>?) ?? <dynamic>[];
    return items.cast<Map<String, dynamic>>();
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000.0; // Earth's radius in meters
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (R * c) / 1000.0; // Convert meters to kilometers
  }

  static double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);
}

// Fetch ranked shops from backend simple ranking endpoint
Future<List<Shop>> getRankedShopsSimple({
  required double latitude,
  required double longitude,
  int maxDistanceKm = 20,
  int limit = 20,
}) async {
  final uri = '/api/ranking/shops-simple?latitude=$latitude&longitude=$longitude&maxDistance=$maxDistanceKm&limit=$limit';
  final http.Response response = await ApiService.get(uri);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Ranking API failed with status ${response.statusCode}');
  }
  final Map<String, dynamic> jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
  if (jsonBody['success'] != true) {
    throw Exception('Ranking API error: ${jsonBody['message'] ?? 'unknown'}');
  }
  final List<dynamic> shopsList = (jsonBody['data']?['shops'] as List<dynamic>?) ?? const [];
  return shopsList.map((e) {
    final Map<String, dynamic> item = (e as Map).cast<String, dynamic>();
    final List<dynamic>? coords = (item['location'] is Map && (item['location'] as Map).containsKey('coordinates'))
        ? (item['location']['coordinates'] as List?)
        : null;
    final double lat = (coords != null && coords.length >= 2)
        ? SearchService._asDouble(coords[1])
        : (item['latitude'] is num ? SearchService._asDouble(item['latitude']) : 0.0);
    final double lon = (coords != null && coords.length >= 2)
        ? SearchService._asDouble(coords[0])
        : (item['longitude'] is num ? SearchService._asDouble(item['longitude']) : 0.0);
    return Shop(
      id: SearchService._asString(item['_id'] ?? item['id']),
      name: SearchService._asString(item['shopName'] ?? item['name']),
      category: SearchService._asString(item['category']),
      address: SearchService._asString(item['address']),
      latitude: lat,
      longitude: lon,
      rating: SearchService._asDouble(item['rating']),
      reviewCount: SearchService._asInt(item['reviewCount']),
      distance: SearchService._asDouble(item['distance'] ?? item['distanceKm']),
      offers: const <ShopOffer>[],
      isOpen: (item['isLive'] == true) || (item['isOpen'] == true),
      openingHours: SearchService._asString(item['openingHours']),
      phone: SearchService._asString(item['phone']),
      imageUrl: item['imageUrl']?.toString(),
      description: item['description']?.toString(),
      amenities: const [],
      lastUpdated: null,
    );
  }).toList();
}

class _ScoredShop {
  final Shop shop;
  final double score;
  _ScoredShop(this.shop, this.score);
}

class _ShopAggFromProducts {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  double distanceKm;
  int bestOfferPercent;
  double bestPrice;

  _ShopAggFromProducts({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.distanceKm,
    required this.bestOfferPercent,
    required this.bestPrice,
  });
}

class MathHelper {
  static double ln(double x) {
    return x <= 0 ? 0.0 : (x == 1.0 ? 0.0 : (x > 0 ? _log(x) : 0.0));
  }

  static double _log(double x) {
    return math.log(x);
  }
}

// Removed unused MathTrig and _MathProxy helpers