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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      distance: (json['distance'] ?? 0.0).toDouble(),
      offers: (json['offers'] as List<dynamic>?)
          ?.map((offer) => ShopOffer.fromJson(offer))
          .toList() ?? [],
      isOpen: (json['isOpen'] ?? json['isLive'] ?? false) as bool,
      openingHours: json['openingHours'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['imageUrl'],
      description: json['description'],
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((amenity) => amenity.toString())
          .toList() ?? [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
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
    };
  }

  String get formattedDistance {
    if (distance == 0.0) {
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

  String get statusColor {
    return isOpen ? '#4CAF50' : '#F44336';
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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discount: (json['discount'] ?? 0.0).toDouble(),
      validUntil: DateTime.parse(json['validUntil']),
      imageUrl: json['imageUrl'],
      applicableProducts: (json['applicableProducts'] as List<dynamic>?)
          ?.map((product) => product.toString())
          .toList() ?? [],
      termsAndConditions: json['termsAndConditions'],
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
