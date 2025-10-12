import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../models/shop.dart';
import '../services/shop_service.dart';
import '../services/location_service.dart';
import '../services/favorite_shops_service.dart';
import 'shop_details_screen.dart';
import 'map_screen_free.dart';
import '../widgets/voice_search_button.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  List<Shop> _allShops = [];
  List<Shop> _filteredShops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  double _minRating = 0.0;
  double? _maxDistanceKm;
  bool _openNowOnly = false;
  String _sortBy = 'recommended'; // recommended, distance, rating, name

  final List<String> _categories = [
    'All',
    'Electronics',
    'Fashion',
    'Food & Dining',
    'Health & Beauty',
    'Home & Garden',
    'Sports & Fitness',
    'Books & Media',
    'Automotive',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user location for distance calculation
      Position? position;
      try {
        position = await LocationService.getCurrentLocation();
      } catch (_) {
        // Use default location if current location fails
        position = null;
      }

      // Load nearby shops
      final result = await ShopService.getNearbyShops(
        latitude: position?.latitude ?? 28.6139, // Default to Delhi
        longitude: position?.longitude ?? 77.2090,
        radius: 50000, // 50km in meters for stores screen
      );
      
      final shops = (result['shops'] as List)
          .map((shop) {
            try {
              final shopObj = Shop.fromJson(shop);
              
              // If distance is 0 or not provided, calculate it client-side
              if (shopObj.distance == 0.0 && position != null) {
                final calculatedDistance = _calculateDistance(
                  position.latitude, 
                  position.longitude, 
                  shopObj.latitude, 
                  shopObj.longitude
                );
                // Create a new shop object with calculated distance
                return Shop(
                  id: shopObj.id,
                  name: shopObj.name,
                  category: shopObj.category,
                  address: shopObj.address,
                  latitude: shopObj.latitude,
                  longitude: shopObj.longitude,
                  rating: shopObj.rating,
                  reviewCount: shopObj.reviewCount,
                  distance: calculatedDistance,
                  offers: shopObj.offers,
                  isOpen: shopObj.isOpen,
                  openingHours: shopObj.openingHours,
                  phone: shopObj.phone,
                  imageUrl: shopObj.imageUrl,
                  description: shopObj.description,
                  amenities: shopObj.amenities,
                  lastUpdated: shopObj.lastUpdated,
                );
              }
              
              return shopObj;
            } catch (e) {
              debugPrint('Error parsing shop data: $e');
              debugPrint('Shop data: $shop');
              // Return a default shop object to prevent the entire list from failing
              return Shop(
                id: (shop['_id'] ?? shop['id'] ?? 'unknown').toString(),
                name: (shop['shopName'] ?? shop['name'] ?? 'Unknown Shop').toString(),
                category: (shop['category'] ?? 'Other').toString(),
                address: (shop['address'] ?? 'Address not available').toString(),
                latitude: (shop['latitude'] ?? 0.0).toDouble(),
                longitude: (shop['longitude'] ?? 0.0).toDouble(),
                rating: (shop['rating'] ?? 0.0).toDouble(),
                reviewCount: (shop['reviewCount'] ?? 0) as int,
                distance: (shop['distanceKm'] ?? shop['distance'] ?? 0.0).toDouble(),
                offers: const [],
                isOpen: (shop['isOpen'] ?? shop['isLive'] ?? false) as bool,
                openingHours: (shop['openingHours'] ?? '').toString(),
                phone: (shop['phone'] ?? '').toString(),
                imageUrl: shop['imageUrl']?.toString(),
                description: shop['description']?.toString(),
                amenities: const [],
                lastUpdated: null,
              );
            }
          })
          .toList();

      if (mounted) {
        debugPrint('Stores screen: Loaded ${shops.length} shops');
        debugPrint('Shops data: ${shops.map((s) => '${s.name} (${s.distance.toStringAsFixed(2)}km)').join(', ')}');
        setState(() {
          _allShops = shops;
          _filteredShops = shops;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allShops = [];
          _filteredShops = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stores: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Shop> filtered = List.from(_allShops);
    
    debugPrint('Applying filters: ${_allShops.length} total shops');
    debugPrint('Filters: search="$_searchQuery", category="$_selectedCategory", minRating=$_minRating, maxDistance=$_maxDistanceKm, openNow=$_openNowOnly, sortBy="$_sortBy"');

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((shop) {
        return shop.name.toLowerCase().contains(query) ||
               shop.category.toLowerCase().contains(query) ||
               (shop.description?.toLowerCase().contains(query) ?? false);
      }).toList();
      debugPrint('After search filter: ${filtered.length} shops');
    }

    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((shop) => shop.category == _selectedCategory).toList();
      debugPrint('After category filter: ${filtered.length} shops');
    }

    // Rating filter
    if (_minRating > 0.0) {
      filtered = filtered.where((shop) => shop.rating >= _minRating).toList();
      debugPrint('After rating filter: ${filtered.length} shops');
    }

    // Distance filter - only apply if distance is valid (> 0) and within limit
    if (_maxDistanceKm != null) {
      filtered = filtered.where((shop) => shop.distance > 0 && shop.distance <= _maxDistanceKm!).toList();
      debugPrint('After distance filter: ${filtered.length} shops');
    }

    // Open now filter
    if (_openNowOnly) {
      filtered = filtered.where((shop) => shop.isOpen).toList();
      debugPrint('After open now filter: ${filtered.length} shops');
    }

    // Sort
    switch (_sortBy) {
      case 'distance':
        filtered.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'recommended':
      default:
        // Sort by visit priority score (higher score = better to visit first)
        filtered.sort((a, b) => b.visitPriorityScore.compareTo(a.visitPriorityScore));
        break;
    }

    debugPrint('Final filtered shops: ${filtered.length} shops');
    debugPrint('Filtered shop names: ${filtered.map((s) => '${s.name} (${s.distance.toStringAsFixed(2)}km)').join(', ')}');

    setState(() {
      _filteredShops = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        title: const Text('Stores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStores,
            tooltip: 'Refresh stores',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(isTablet),
          
          // Results count
          if (!_isLoading && _filteredShops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filteredShops.length} stores found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                  const Spacer(),
                  if (_hasActiveFilters())
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2979FF),
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredShops.isEmpty
                    ? _buildEmptyState()
                    : _buildStoresList(isTablet, isLargeScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: TextEditingController(text: _searchQuery),
            decoration: InputDecoration(
              hintText: 'Search stores...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VoiceSearchButton(
                    onVoiceResult: (result) {
                      setState(() {
                        _searchQuery = result;
                      });
                      _applyFilters();
                    },
                    iconColor: Colors.grey[600],
                    iconSize: 20,
                    tooltip: 'Voice search',
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Category', _selectedCategory, () => _showCategoryFilter()),
                const SizedBox(width: 8),
                _buildFilterChip('Rating', _minRating > 0 ? '≥${_minRating.toStringAsFixed(1)}' : 'Any', () => _showRatingFilter()),
                const SizedBox(width: 8),
                _buildFilterChip('Distance', _maxDistanceKm != null ? '≤${_maxDistanceKm!.toStringAsFixed(1)}km' : 'Any', () => _showDistanceFilter()),
                const SizedBox(width: 8),
                _buildFilterChip('Sort', _getSortDisplayName(_sortBy), () => _showSortOptions()),
                const SizedBox(width: 8),
                _buildFilterChip('Open Now', _openNowOnly ? 'Yes' : 'All', () {
                  setState(() {
                    _openNowOnly = !_openNowOnly;
                  });
                  _applyFilters();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2979FF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                color: Color(0xFF2979FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF2979FF),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != 'All' || 
           _minRating > 0.0 || 
           _maxDistanceKm != null || 
           _openNowOnly ||
           _sortBy != 'recommended';
  }

  String _getSortDisplayName(String sortKey) {
    switch (sortKey) {
      case 'recommended':
        return 'Recommended';
      case 'distance':
        return 'Distance';
      case 'rating':
        return 'Rating';
      case 'name':
        return 'Name';
      default:
        return 'Recommended';
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _minRating = 0.0;
      _maxDistanceKm = null;
      _openNowOnly = false;
      _sortBy = 'distance';
    });
    _applyFilters();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000.0; // Earth's radius in meters
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (R * c) / 1000.0; // Convert meters to kilometers
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.store_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No stores match your search'
                : 'No stores available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Check back later for new stores',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStoresList(bool isTablet, bool isLargeScreen) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 8,
      ),
      itemCount: _filteredShops.length,
      itemBuilder: (context, index) {
        final shop = _filteredShops[index];
        return _buildStoreCard(shop, isTablet, isLargeScreen);
      },
    );
  }

  Widget _buildStoreCard(Shop shop, bool isTablet, bool isLargeScreen) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(
        bottom: isTablet ? 12 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 8 : 4,
        ),
        leading: CircleAvatar(
          radius: isTablet ? 24 : 20,
          backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.1),
          child: Icon(
            Icons.store,
            color: const Color(0xFF2979FF),
            size: isTablet ? 24 : 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                shop.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
            if (shop.offers.isNotEmpty && shop.offers.first.discount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shop.offers.first.formattedDiscount,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: isTablet ? 18 : 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  '${shop.rating.toStringAsFixed(1)} • ${shop.formattedDistance} • ${shop.category}',
                  style: TextStyle(fontSize: isTablet ? 16 : 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: shop.isOpen ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shop.isOpen ? 'Open' : 'Closed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Ranking reason
            Text(
              shop.rankingReason,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: const Color(0xFF2979FF),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapScreenFree(
                          shopsOverride: [shop],
                          routeToShop: shop,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2979FF),
                    side: const BorderSide(color: Color(0xFF2979FF)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopDetailsScreen(shop: shop),
                      ),
                    );
                  },
                  child: const Text('Details'),
                ),
                const Spacer(),
                FutureBuilder<bool>(
                  future: FavoriteShopsService.isFavorite(shop.id),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        if (isFavorite) {
                          await FavoriteShopsService.removeFromFavorites(shop.id);
                        } else {
                          await FavoriteShopsService.addToFavorites(shop);
                        }
                        setState(() {}); // Refresh the UI
                      },
                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ShopDetailsScreen(shop: shop),
            ),
          );
        },
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _categories.map((category) => ListTile(
                    title: Text(category),
                    trailing: _selectedCategory == category ? const Icon(Icons.check, color: Color(0xFF2979FF)) : null,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRatingFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        double tempRating = _minRating;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Minimum Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('0.0'),
                      Text(tempRating.toStringAsFixed(1)),
                      const Text('5.0'),
                    ],
                  ),
                  Slider(
                    value: tempRating,
                    onChanged: (value) => setState(() => tempRating = value),
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _minRating = tempRating;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDistanceFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        double tempDistance = _maxDistanceKm ?? 0.0;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Maximum Distance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('No limit'),
                      Text(tempDistance == 0.0 ? '—' : '${tempDistance.toStringAsFixed(1)} km'),
                      const Text('50 km'),
                    ],
                  ),
                  Slider(
                    value: tempDistance,
                    onChanged: (value) => setState(() => tempDistance = value),
                    min: 0.0,
                    max: 50.0,
                    divisions: 50,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        this.setState(() {
                          _maxDistanceKm = tempDistance == 0.0 ? null : tempDistance;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sort By', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    {'key': 'recommended', 'label': 'Recommended'},
                    {'key': 'distance', 'label': 'Distance'},
                    {'key': 'rating', 'label': 'Rating'},
                    {'key': 'name', 'label': 'Name'},
                  ].map((sort) => ListTile(
                    title: Text(sort['label']!),
                    trailing: _sortBy == sort['key'] ? const Icon(Icons.check, color: Color(0xFF2979FF)) : null,
                    onTap: () {
                      setState(() {
                        _sortBy = sort['key']!;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
