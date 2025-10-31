class Shop {
  final String id;
  final String name;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final double distance; // in kilometers
  final List<ShopOffer> offers;
  final bool isOpen;
  final String openingHours;
  final String phone;
  final String? imageUrl;
  final String? description;
  final List<String> amenities;
  final DateTime? lastUpdated;

  Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.offers,
    required this.isOpen,
    required this.openingHours,
    required this.phone,
    this.imageUrl,
    this.description,
    this.amenities = const [],
    this.lastUpdated,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['shopName'] ?? json['name'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: (json['reviewCount'] ?? 0) as int,
      distance: (json['distanceKm'] ?? json['distance'] ?? 0.0).toDouble(),
      offers: (json['offers'] as List<dynamic>?)
          ?.map((offer) => ShopOffer.fromJson(offer))
          .toList() ?? [],
      isOpen: (json['isOpen'] ?? json['isLive'] ?? false) as bool,
      openingHours: _getOpeningHours(json),
      phone: (json['phone'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString() ?? (json['photoProof'] is Map ? json['photoProof']['url']?.toString() : null),
      description: json['description']?.toString(),
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((amenity) => amenity.toString())
          .toList() ?? [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      'offers': offers.map((offer) => offer.toJson()).toList(),
      'isOpen': isOpen,
      'openingHours': openingHours,
      'phone': phone,
      'imageUrl': imageUrl,
      'description': description,
      'amenities': amenities,
      'lastUpdated': lastUpdated?.toIso8601String(),
      // Expose computed properties for UI sorting/lookup convenience
      'visitPriorityScore': visitPriorityScore,
      'rankingReason': rankingReason,
    };
  }

  String get formattedDistance {
    if (distance == 0.0 || distance.isNaN) {
      return 'Distance N/A';
    }
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  String get statusText {
    return isOpen ? 'Open' : 'Closed';
  }

  String get formattedOpeningHours {
    if (openingHours.isEmpty) {
      return 'Hours not available';
    }
    return openingHours;
  }

  /// Helper method to extract opening hours from various field names
  static String _getOpeningHours(Map<String, dynamic> json) {
    String hours = (json['openingHours'] ?? '').toString();
    if (hours.isEmpty) {
      // Try alternative field names including nested structures
      hours = (json['hours'] ?? 
               json['businessHours'] ?? 
               json['operatingHours'] ??
               json['info']?['openingHours'] ??
               json['info']?['hours'] ??
               json['info']?['businessHours'] ??
               json['businessInfo']?['openingHours'] ??
               json['businessInfo']?['hours'] ?? '').toString();
    }
    
    // If still empty, provide a default
    if (hours.isEmpty) {
      hours = 'Mon-Sun: 9:00 AM - 9:00 PM';
    }
    
    return hours;
  }

  String get statusColor {
    return isOpen ? '#4CAF50' : '#F44336';
  }

  /// Calculate a visit priority score (higher = better to visit first)
  /// Factors: distance (closer better), rating (higher better), offers (more better), open status
  double get visitPriorityScore {
    double score = 0.0;
    
    // Distance factor (closer shops get higher scores)
    // Score decreases as distance increases, max score for very close shops
    if (distance > 0) {
      if (distance < 1.0) {
        score += 40.0; // Very close shops (< 1km)
      } else if (distance < 5.0) {
        score += 30.0; // Close shops (1-5km)
      } else if (distance < 10.0) {
        score += 20.0; // Medium distance (5-10km)
      } else if (distance < 20.0) {
        score += 10.0; // Far shops (10-20km)
      } else {
        score += 5.0; // Very far shops (> 20km)
      }
    } else {
      score += 15.0; // Unknown distance gets medium score
    }
    
    // Rating factor (higher ratings get higher scores)
    score += (rating / 5.0) * 25.0; // Max 25 points for 5-star rating
    
    // Offers factor (shops with offers get bonus points)
    if (offers.isNotEmpty && offers.any((offer) => offer.discount > 0)) {
      // Bonus for having offers
      score += 15.0;
      
      // Additional bonus for better offers
      final validOffers = offers.where((offer) => offer.discount > 0).toList();
      if (validOffers.isNotEmpty) {
        final bestOffer = validOffers.reduce((a, b) => a.discount > b.discount ? a : b);
        score += (bestOffer.discount / 100.0) * 10.0; // Max 10 points for 100% discount
      }
    }
    
    // Open status factor (open shops get bonus)
    if (isOpen) {
      score += 10.0;
    }
    
    // Review count factor (more reviews = more trusted)
    if (reviewCount > 0) {
      score += (reviewCount / 100.0).clamp(0.0, 5.0); // Max 5 points for 100+ reviews
    }
    
    return score;
  }

  /// Get a human-readable ranking reason
  String get rankingReason {
    final List<String> reasons = [];
    
    if (distance > 0 && distance < 1.0) {
      reasons.add('Very close');
    } else if (distance > 0 && distance < 5.0) {
      reasons.add('Close by');
    }
    
    if (rating >= 4.0) {
      reasons.add('Highly rated');
    } else if (rating >= 3.0) {
      reasons.add('Good rating');
    }
    
    if (offers.isNotEmpty && offers.any((offer) => offer.discount > 0)) {
      reasons.add('Has offers');
    }
    
    if (isOpen) {
      reasons.add('Open now');
    }
    
    if (reviewCount > 10) {
      reasons.add('Popular');
    }
    
    return reasons.isEmpty ? 'Available' : reasons.join(' • ');
  }
}

class ShopOffer {
  final String id;
  final String title;
  final String description;
  final double discount; // percentage
  final DateTime validUntil;
  final String? imageUrl;
  final List<String> applicableProducts;
  final String? termsAndConditions;

  ShopOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.validUntil,
    this.imageUrl,
    this.applicableProducts = const [],
    this.termsAndConditions,
  });

  factory ShopOffer.fromJson(Map<String, dynamic> json) {
    return ShopOffer(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      discount: (json['discount'] ?? 0.0).toDouble(),
      validUntil: json['validUntil'] != null 
          ? DateTime.parse(json['validUntil'].toString())
          : DateTime.now().add(const Duration(days: 7)),
      imageUrl: json['imageUrl']?.toString(),
      applicableProducts: (json['applicableProducts'] as List<dynamic>?)
          ?.map((product) => product.toString())
          .toList() ?? [],
      termsAndConditions: json['termsAndConditions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'discount': discount,
      'validUntil': validUntil.toIso8601String(),
      'imageUrl': imageUrl,
      'applicableProducts': applicableProducts,
      'termsAndConditions': termsAndConditions,
    };
  }

  bool get isExpired {
    return DateTime.now().isAfter(validUntil);
  }

  int get daysRemaining {
    final now = DateTime.now();
    final difference = validUntil.difference(now);
    return difference.inDays;
  }

  String get formattedDiscount {
    return '${discount.round()}% OFF';
  }
}

class ShopReview {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;
  final bool isVerified;

  ShopReview({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
    this.isVerified = false,
  });

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    return ShopReview(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image.toString())
          .toList() ?? [],
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'images': images,
      'isVerified': isVerified,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
