import 'dart:math' as math;
import '../models/shop.dart';

class ShopUtils {
  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000.0; // Earth's radius in meters
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
        (math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (R * c) / 1000.0; // Convert meters to kilometers
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);

  /// Create a Shop with proper distance calculation and opening hours
  static Shop createShopWithDistance({
    required Map<String, dynamic> shopData,
    double? userLatitude,
    double? userLongitude,
    List<ShopOffer> offers = const [],
  }) {
    final String shopId = (shopData['_id'] ?? shopData['id'] ?? '').toString();
    
    // Extract coordinates
    final double latitude = (shopData['latitude'] is num)
        ? (shopData['latitude'] as num).toDouble()
        : (shopData['location']?['coordinates'] is List && (shopData['location']['coordinates'] as List).length >= 2)
            ? ((shopData['location']['coordinates'][1] as num).toDouble())
            : 0.0;

    final double longitude = (shopData['longitude'] is num)
        ? (shopData['longitude'] as num).toDouble()
        : (shopData['location']?['coordinates'] is List && (shopData['location']['coordinates'] as List).length >= 2)
            ? ((shopData['location']['coordinates'][0] as num).toDouble())
            : 0.0;

    // Calculate distance if user location is available
    double distance = 0.0;
    if (userLatitude != null && userLongitude != null && latitude != 0.0 && longitude != 0.0) {
      distance = calculateDistanceKm(userLatitude, userLongitude, latitude, longitude);
    } else {
      // Try to get distance from API response
      distance = (shopData['distanceKm'] as num?)?.toDouble() ?? 
                 (shopData['distance'] as num?)?.toDouble() ?? 0.0;
    }

    // Get opening hours with fallback
    String openingHours = (shopData['openingHours'] ?? '').toString();
    if (openingHours.isEmpty) {
      // Try alternative field names including nested structures
      openingHours = (shopData['hours'] ?? 
                     shopData['businessHours'] ?? 
                     shopData['operatingHours'] ??
                     shopData['info']?['openingHours'] ??
                     shopData['info']?['hours'] ??
                     shopData['info']?['businessHours'] ??
                     shopData['businessInfo']?['openingHours'] ??
                     shopData['businessInfo']?['hours'] ?? '').toString();
    }
    
    // If still empty, provide a default
    if (openingHours.isEmpty) {
      openingHours = 'Mon-Sun: 9:00 AM - 9:00 PM';
    }

    return Shop(
      id: shopId,
      name: (shopData['shopName'] ?? shopData['name'] ?? '').toString(),
      category: (shopData['category'] ?? '').toString(),
      address: (shopData['address'] ?? '').toString(),
      latitude: latitude,
      longitude: longitude,
      rating: (shopData['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (shopData['reviewCount'] as int?) ?? (shopData['reviewsCount'] as int?) ?? 0,
      distance: distance,
      offers: offers,
      isOpen: shopData['isLive'] == true || shopData['isOpen'] == true,
      openingHours: openingHours,
      phone: (shopData['phone'] ?? '').toString(),
      imageUrl: (shopData['imageUrl']?.toString() ??
          (shopData['photoProof'] is Map ? (shopData['photoProof']['url']?.toString()) : null)),
      description: shopData['description']?.toString(),
      amenities: (shopData['amenities'] as List<dynamic>?)
          ?.map((amenity) => amenity.toString())
          .toList() ?? [],
      lastUpdated: shopData['lastUpdated'] != null
          ? DateTime.tryParse(shopData['lastUpdated'].toString())
          : null,
    );
  }

  /// Format opening hours for display
  static String formatOpeningHours(String? hours) {
    if (hours == null || hours.isEmpty) {
      return 'Hours not available';
    }
    
    // Clean up the hours string
    String cleaned = hours.trim();
    
    // If it's a simple time range, format it nicely
    if (cleaned.contains('-') && cleaned.contains(':')) {
      return cleaned;
    }
    
    // If it's a more complex format, return as is
    return cleaned;
  }

  /// Get default opening hours for shops that don't have them
  static String getDefaultOpeningHours() {
    return 'Mon-Sun: 9:00 AM - 9:00 PM';
  }
}
