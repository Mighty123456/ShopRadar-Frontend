import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shop.dart';

class FavoriteShopsService {
  static const String _favoritesKey = 'favorite_shops';
  static const int _maxFavorites = 50; // Limit to prevent storage bloat

  /// Get all favorite shops
  static Future<List<Shop>> getFavoriteShops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        return favoritesList
            .map((json) => Shop.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting favorite shops: $e');
      return [];
    }
  }

  /// Add shop to favorites
  static Future<bool> addToFavorites(Shop shop) async {
    try {
      final favorites = await getFavoriteShops();
      
      // Check if already exists
      if (favorites.any((f) => f.id == shop.id)) {
        return true; // Already exists
      }
      
      // Add to beginning and limit size
      favorites.insert(0, shop);
      if (favorites.length > _maxFavorites) {
        favorites.removeRange(_maxFavorites, favorites.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(
        favorites.map((f) => f.toJson()).toList(),
      );
      await prefs.setString(_favoritesKey, favoritesJson);
      return true;
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove shop from favorites
  static Future<bool> removeFromFavorites(String shopId) async {
    try {
      final favorites = await getFavoriteShops();
      favorites.removeWhere((f) => f.id == shopId);
      
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = jsonEncode(
        favorites.map((f) => f.toJson()).toList(),
      );
      await prefs.setString(_favoritesKey, favoritesJson);
      return true;
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      return false;
    }
  }

  /// Check if shop is favorited
  static Future<bool> isFavorite(String shopId) async {
    try {
      final favorites = await getFavoriteShops();
      return favorites.any((f) => f.id == shopId);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  /// Clear all favorites
  static Future<bool> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
      return false;
    }
  }

  /// Get favorite count
  static Future<int> getFavoriteCount() async {
    try {
      final favorites = await getFavoriteShops();
      return favorites.length;
    } catch (e) {
      debugPrint('Error getting favorite count: $e');
      return 0;
    }
  }

  /// Search favorites by name (offline search)
  static Future<List<Shop>> searchFavorites(String query) async {
    try {
      final favorites = await getFavoriteShops();
      if (query.trim().isEmpty) return favorites;
      
      final lowerQuery = query.toLowerCase();
      return favorites.where((shop) {
        return shop.name.toLowerCase().contains(lowerQuery) ||
               shop.category.toLowerCase().contains(lowerQuery) ||
               (shop.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      debugPrint('Error searching favorites: $e');
      return [];
    }
  }

  /// Update shop data in favorites (when shop details change)
  static Future<bool> updateFavoriteShop(Shop updatedShop) async {
    try {
      final favorites = await getFavoriteShops();
      final index = favorites.indexWhere((f) => f.id == updatedShop.id);
      
      if (index != -1) {
        favorites[index] = updatedShop;
        
        final prefs = await SharedPreferences.getInstance();
        final favoritesJson = jsonEncode(
          favorites.map((f) => f.toJson()).toList(),
        );
        await prefs.setString(_favoritesKey, favoritesJson);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating favorite shop: $e');
      return false;
    }
  }
}
