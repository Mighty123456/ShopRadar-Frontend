class Product {
  final String id;
  final String shopId;
  final String name;
  final String? description;
  final String category;
  final String brand;
  final String itemName;
  final double price;
  final int stock;
  final List<ProductImage> images;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.description,
    required this.category,
    required this.brand,
    required this.itemName,
    required this.price,
    required this.stock,
    required this.images,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      shopId: json['shopId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      itemName: json['itemName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => ProductImage.fromJson(img))
          .toList() ?? [],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'description': description,
      'category': category,
      'brand': brand,
      'itemName': itemName,
      'price': price,
      'stock': stock,
      'images': images.map((img) => img.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ProductImage {
  final String url;
  final String? publicId;
  final String? mimeType;
  final DateTime uploadedAt;

  ProductImage({
    required this.url,
    this.publicId,
    this.mimeType,
    required this.uploadedAt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] ?? '',
      publicId: json['publicId'],
      mimeType: json['mimeType'],
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
      'mimeType': mimeType,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
