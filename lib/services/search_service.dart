import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/shop.dart';
import '../models/product_result.dart';
import 'product_search_service.dart';
// Removed unused import

class SearchService {
  static Future<({List<ProductResult> products, List<Shop> shops})> searchMixed({
    required String query,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return (products: <ProductResult>[], shops: <Shop>[]);

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
        
        // Calculate distances for shops if user location is available
        if (userLatitude != null && userLongitude != null) {
          final List<Shop> shopsWithDistance = shops.map((shop) {
            if (shop.latitude != 0.0 && shop.longitude != 0.0) {
              final distance = _haversineKm(userLatitude, userLongitude, shop.latitude, shop.longitude);
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
            }
            return shop;
          }).toList();
          
          return (products: products, shops: shopsWithDistance);
        }
        
        return (products: products, shops: shops);
      } else {
        debugPrint('Enhanced search failed: ${result['message']}, falling back to original search');
      }
    } catch (e) {
      debugPrint('Enhanced search error: $e, falling back to original search');
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
      }
      return ProductResult(
        id: (p['id'] ?? '').toString(),
        name: (p['name'] ?? '').toString(),
        description: (p['description'] ?? '').toString(),
        imageUrl: (p['image'] ?? p['imageUrl'])?.toString(),
        price: (p['price'] as num?)?.toDouble() ?? 0.0,
        bestOfferPercent: (p['bestOfferPercent'] as num?)?.toInt() ?? 0,
        shopId: (shop?['id'] ?? '').toString(),
        shopName: (shop?['name'] ?? shop?['shopName'] ?? '').toString(),
        shopAddress: (shop?['address'] ?? '').toString(),
        shopLatitude: lat,
        shopLongitude: lon,
        shopRating: (shop?['rating'] as num?)?.toDouble() ?? 0.0,
        distanceKm: distanceKm,
      );
    }).toList();

    // If product hits exist, aggregate shops from product results so each shop appears once
    // with the best offer/lowest price. This ensures multiple shops with offers are shown.
    if (products.isNotEmpty) {
      final Map<String, _ShopAggFromProducts> byShop = {};
      for (final p in products) {
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

      // Rank by discount, rating, and proximity (if available)
      shops.sort((a, b) {
        double aDiscount = a.offers.isNotEmpty ? a.offers.first.discount : 0.0;
        double bDiscount = b.offers.isNotEmpty ? b.offers.first.discount : 0.0;
        final double aScore = (0.5 * (a.rating / 5.0)) + (0.3 * (aDiscount / 100.0)) + (0.2 * (-a.distance));
        final double bScore = (0.5 * (b.rating / 5.0)) + (0.3 * (bDiscount / 100.0)) + (0.2 * (-b.distance));
        return bScore.compareTo(aScore);
      });

      return (products: products, shops: shops);
    }

    // Fallback when no product hits: generic shop search
    final List<Shop> fallbackShops = await searchShops(trimmed);
    return (products: products, shops: fallbackShops);
  }

  static Future<List<Shop>> searchShops(String query) async {
    final trimmed = query.trim();
    // Use correct backend route and parameter name
    final uri = '/api/shops/search?q=${Uri.encodeQueryComponent(trimmed)}';

    final http.Response response = await ApiService.get(uri);

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

      final List<Shop> shops = list.map((e) {
        final Map<String, dynamic> item = e as Map<String, dynamic>;

        final double latitude = (item['latitude'] is num)
            ? (item['latitude'] as num).toDouble()
            : (item['location']?['coordinates'] is List && (item['location']['coordinates'] as List).length >= 2)
                ? ((item['location']['coordinates'][1] as num).toDouble())
                : 0.0;

        final double longitude = (item['longitude'] is num)
            ? (item['longitude'] as num).toDouble()
            : (item['location']?['coordinates'] is List && (item['location']['coordinates'] as List).length >= 2)
                ? ((item['location']['coordinates'][0] as num).toDouble())
                : 0.0;

        // Parse offers from backend response
        final List<ShopOffer> offers = [];
        if (item['offers'] is List) {
          debugPrint('Found ${(item['offers'] as List).length} offers for shop ${item['shopName']}');
          for (final offerData in item['offers'] as List) {
            if (offerData is Map<String, dynamic>) {
              final discountValue = (offerData['discountValue'] as num?)?.toDouble() ?? 0.0;
              final discountType = offerData['discountType']?.toString() ?? 'Percentage';
              
              // Convert to percentage if it's a fixed amount (this is a simplified conversion)
              double discountPercent = discountValue;
              if (discountType == 'Fixed Amount') {
                // For fixed amount, we'll use the raw value as percentage
                // In a real implementation, you'd need the product price to calculate percentage
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
        } else {
          debugPrint('No offers found for shop ${item['shopName']}');
        }

        return Shop(
          id: (item['_id'] ?? item['id'] ?? '').toString(),
          name: (item['shopName'] ?? item['name'] ?? '').toString(),
          category: item['category']?.toString() ?? '',
          address: (item['address'] ?? '').toString(),
          latitude: latitude,
          longitude: longitude,
          rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
          reviewCount: (item['reviewCount'] as int?) ?? (item['reviewsCount'] as int?) ?? 0,
          distance: (item['distanceKm'] as num?)?.toDouble() ?? (item['distance'] as num?)?.toDouble() ?? 0.0,
          offers: offers,
          isOpen: item['isLive'] == true || item['isOpen'] == true,
          openingHours: (item['openingHours'] ?? '').toString(),
          phone: (item['phone'] ?? '').toString(),
          imageUrl: item['imageUrl']?.toString(),
          description: item['description']?.toString(),
          amenities: const [],
          lastUpdated: null,
        );
      }).toList();

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


