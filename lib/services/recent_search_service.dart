import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shop.dart';
import '../models/product_result.dart';

class RecentSearchService {
  static const String _key = 'recent_searches';
  static const String _cachedResultsKey = 'cached_search_results';
  static const int _maxItems = 10;
  static const int _maxCachedResults = 20; // Cache up to 20 search results

  static Future<List<String>> getRecentSearches() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_key);
    return stored ?? <String>[];
  }

  static Future<void> addSearch(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> current = List<String>.from(prefs.getStringList(_key) ?? <String>[]);
    current.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);
    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }
    await prefs.setStringList(_key, current);
  }

  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Cache search results for offline access
  static Future<void> cacheSearchResults(String query, List<Shop> shops, List<ProductResult> products) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> cachedResults = {
        'query': query,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'shops': shops.map((s) => s.toJson()).toList(),
        'products': products.map((p) => {
          'id': p.id,
          'name': p.name,
          'description': p.description,
          'imageUrl': p.imageUrl,
          'price': p.price,
          'bestOfferPercent': p.bestOfferPercent,
          'shopId': p.shopId,
          'shopName': p.shopName,
          'shopAddress': p.shopAddress,
          'shopLatitude': p.shopLatitude,
          'shopLongitude': p.shopLongitude,
          'shopRating': p.shopRating,
          'distanceKm': p.distanceKm,
        }).toList(),
      };

      // Get existing cached results
      final String? existingJson = prefs.getString(_cachedResultsKey);
      Map<String, dynamic> allCached = {};
      if (existingJson != null) {
        allCached = Map<String, dynamic>.from(jsonDecode(existingJson));
      }

      // Add new result
      allCached[query.toLowerCase()] = cachedResults;

      // Limit cache size
      if (allCached.length > _maxCachedResults) {
        final sortedEntries = allCached.entries.toList()
          ..sort((a, b) => (b.value['timestamp'] as int).compareTo(a.value['timestamp'] as int));
        allCached = Map.fromEntries(sortedEntries.take(_maxCachedResults));
      }

      await prefs.setString(_cachedResultsKey, jsonEncode(allCached));
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Get cached search results for offline access
  static Future<({List<Shop> shops, List<ProductResult> products})?> getCachedResults(String query) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_cachedResultsKey);
      
      if (cachedJson != null) {
        final Map<String, dynamic> allCached = Map<String, dynamic>.from(jsonDecode(cachedJson));
        final Map<String, dynamic>? result = allCached[query.toLowerCase()];
        
        if (result != null) {
          // Check if cache is not too old (24 hours)
          final int timestamp = result['timestamp'] as int;
          final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (DateTime.now().difference(cacheTime).inHours < 24) {
            final List<Shop> shops = (result['shops'] as List)
                .map((s) => Shop.fromJson(s))
                .toList();
            
            final List<ProductResult> products = (result['products'] as List)
                .map((p) => ProductResult(
                  id: p['id'],
                  name: p['name'],
                  description: p['description'],
                  imageUrl: p['imageUrl'],
                  price: (p['price'] as num).toDouble(),
                  bestOfferPercent: p['bestOfferPercent'],
                  shopId: p['shopId'],
                  shopName: p['shopName'],
                  shopAddress: p['shopAddress'],
                  shopLatitude: (p['shopLatitude'] as num).toDouble(),
                  shopLongitude: (p['shopLongitude'] as num).toDouble(),
                  shopRating: (p['shopRating'] as num).toDouble(),
                  distanceKm: (p['distanceKm'] as num).toDouble(),
                ))
                .toList();
            
            return (shops: shops, products: products);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all cached search queries
  static Future<List<String>> getCachedQueries() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_cachedResultsKey);
      
      if (cachedJson != null) {
        final Map<String, dynamic> allCached = Map<String, dynamic>.from(jsonDecode(cachedJson));
        return allCached.keys.toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Clear all cached results
  static Future<void> clearCachedResults() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedResultsKey);
  }

  /// Get cache size info
  static Future<({int totalQueries, int totalShops, int totalProducts})> getCacheInfo() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_cachedResultsKey);
      
      if (cachedJson != null) {
        final Map<String, dynamic> allCached = Map<String, dynamic>.from(jsonDecode(cachedJson));
        int totalShops = 0;
        int totalProducts = 0;
        
        for (final result in allCached.values) {
          totalShops += (result['shops'] as List).length;
          totalProducts += (result['products'] as List).length;
        }
        
        return (
          totalQueries: allCached.length,
          totalShops: totalShops,
          totalProducts: totalProducts
        );
      }
      
      return (totalQueries: 0, totalShops: 0, totalProducts: 0);
    } catch (e) {
      return (totalQueries: 0, totalShops: 0, totalProducts: 0);
    }
  }
}


