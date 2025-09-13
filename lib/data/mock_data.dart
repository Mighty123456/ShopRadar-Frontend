import 'package:flutter/material.dart';
import '../models/shop.dart';

class MockData {
  static final List<Shop> shops = [
    Shop(
      id: 's1',
      name: 'TechMart',
      category: 'Electronics',
      address: '123 Market St, Downtown',
      latitude: 37.7749,
      longitude: -122.4194,
      rating: 4.5,
      reviewCount: 128,
      distance: 0.5,
      offers: [
        ShopOffer(
          id: 'o1',
          title: '20% off Smartphones',
          description: 'Limited time discount on select models',
          discount: 20,
          validUntil: DateTime.now().add(const Duration(days: 7)),
          imageUrl: null,
          applicableProducts: const ['iPhone', 'Galaxy', 'Pixel'],
          termsAndConditions: 'While stocks last',
        ),
      ],
      isOpen: true,
      openingHours: '9:00 AM - 9:00 PM',
      phone: '+1 555-1234',
      imageUrl: null,
      description: 'Your one-stop shop for the latest electronics and gadgets.',
      amenities: const ['Parking', 'Wheelchair Accessible', 'Card Accepted'],
      lastUpdated: DateTime.now(),
    ),
    Shop(
      id: 's2',
      name: 'FashionHub',
      category: 'Fashion',
      address: '456 Style Ave, Midtown',
      latitude: 37.7799,
      longitude: -122.4294,
      rating: 4.2,
      reviewCount: 92,
      distance: 1.2,
      offers: [
        ShopOffer(
          id: 'o2',
          title: 'Buy 2 Get 1 Free',
          description: 'Applicable on select apparel',
          discount: 33,
          validUntil: DateTime.now().add(const Duration(days: 3)),
        ),
      ],
      isOpen: true,
      openingHours: '10:00 AM - 8:00 PM',
      phone: '+1 555-5678',
      imageUrl: null,
      description: 'Trendy fashion at affordable prices.',
      amenities: const ['Card Accepted', 'Fitting Rooms'],
      lastUpdated: DateTime.now(),
    ),
    Shop(
      id: 's3',
      name: 'HomeStore',
      category: 'Home & Garden',
      address: '789 Comfort Rd, Uptown',
      latitude: 37.7699,
      longitude: -122.4094,
      rating: 4.7,
      reviewCount: 210,
      distance: 0.8,
      offers: [],
      isOpen: false,
      openingHours: '11:00 AM - 7:00 PM',
      phone: '+1 555-9876',
      imageUrl: null,
      description: 'Furniture and decor to elevate your living spaces.',
      amenities: const ['Parking', 'Delivery'],
      lastUpdated: DateTime.now(),
    ),
  ];

  static const List<String> recentSearches = [
    'iPhone 15 Pro',
    'Nike running shoes',
    'Coffee shops near me',
    'Gaming laptops',
    'Organic groceries',
  ];

  static const List<Map<String, dynamic>> aiSuggestions = [
    {
      'title': 'Best deals near you',
      'description': 'Personalized picks within 2km',
      'icon': Icons.local_offer,
    },
    {
      'title': 'Recently searched',
      'description': 'Quick access to your last searches',
      'icon': Icons.history,
    },
    {
      'title': 'Seasonal offers',
      'description': 'Festive discounts predicted to trend',
      'icon': Icons.psychology,
    },
  ];

  static List<Shop> search(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return shops;
    return shops.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.category.toLowerCase().contains(q) ||
      s.offers.any((o) => o.title.toLowerCase().contains(q) || o.description.toLowerCase().contains(q))
    ).toList();
  }

  static List<String> similarTerms(String query) {
    final synonyms = {
      'sneakers': ['shoes', 'trainers'],
      'jeans': ['trousers', 'denim'],
      'phone': ['smartphone', 'mobile'],
    };
    final key = query.toLowerCase();
    return synonyms[key] ?? [];
  }
}


