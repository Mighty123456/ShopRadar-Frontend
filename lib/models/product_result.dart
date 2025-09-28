class ProductResult {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final int bestOfferPercent;
  final String shopId;
  final String shopName;
  final String shopAddress;
  final double shopLatitude;
  final double shopLongitude;
  final double shopRating;
  final double distanceKm; // computed client-side

  ProductResult({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    required this.bestOfferPercent,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.shopRating,
    required this.distanceKm,
  });
}


