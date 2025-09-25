import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/shop.dart';

class SearchService {
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
          offers: const [],
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
        final int f = doc.where((t) => t == q).length;
        if (f == 0) continue;
        final int n = df[q] ?? 0;
        final double idf = (n == 0)
            ? 0.0
            : ( ( (N - n + 0.5) / (n + 0.5) ).abs() > 0 ? _ln((N - n + 0.5) / (n + 0.5)) : 0.0 );
        final double denom = f + k1 * (1 - b + b * (dl / (avgdl == 0 ? 1 : avgdl)));
        score += idf * ((f * (k1 + 1)) / (denom == 0 ? 1 : denom));
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
      final base = bm25Score(docs[i], terms);
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
    return parts.map((t) => t.endsWith('s') && t.length > 3 ? t.substring(0, t.length - 1) : t).toList();
  }

  static double _ln(double x) {
    return MathHelper.ln(x);
  }
}

class _ScoredShop {
  final Shop shop;
  final double score;
  _ScoredShop(this.shop, this.score);
}

class MathHelper {
  static double ln(double x) {
    return x <= 0 ? 0.0 : (x == 1.0 ? 0.0 : (x > 0 ? _log(x) : 0.0));
  }

  static double _log(double x) {
    // Use natural log via change-of-base from Dart's log in dart:math, but avoid importing to keep snippet simple.
    // If dart:math is available, replace with: return math.log(x);
    // Fallback simple approximation using series around 1 (sufficient here): ln(x) ~ 2 * sum((y^(2n-1))/(2n-1)), y=(x-1)/(x+1)
    final double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double term = y;
    double sum = term;
    for (int n = 2; n < 15; n++) {
      term *= y2;
      sum += term / (2 * n - 1);
    }
    return 2 * sum;
  }
}


