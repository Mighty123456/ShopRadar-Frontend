import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../models/product_result.dart';
import '../services/search_service.dart';
import '../services/recent_search_service.dart';
import '../services/connectivity_service.dart';
import '../services/shop_service.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'map_screen_free.dart';
import '../widgets/voice_search_button.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<Shop>? initialResults;

  const SearchResultsScreen({super.key, required this.query, this.initialResults});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _controller;
  List<ProductResult> _productResults = [];
  List<Shop> _shopResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;
  bool _isFromCache = false;
  // Filters
  double _minRating = 0.0; // 0.0 - 5.0
  double? _maxDistanceKm; // null = no cap
  double? _minPrice; // products only
  double? _maxPrice; // products only

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _checkConnectivityAndSearch();
  }

  Future<void> _checkConnectivityAndSearch() async {
    final connectivityService = ConnectivityService();
    await connectivityService.initialize();
    
    setState(() {
      _isOffline = !connectivityService.isOnline;
    });

    if (_isOffline) {
      // Try to get cached results first
      await _tryCachedSearch();
    } else {
      // Online - do normal search
      await _runSearch(widget.query);
    }
  }

  Future<void> _tryCachedSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cachedResults = await RecentSearchService.getCachedResults(widget.query);
      if (cachedResults != null) {
        setState(() {
          _productResults = cachedResults.products;
          _shopResults = cachedResults.shops;
          _isFromCache = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _productResults = [];
          _shopResults = [];
          _errorMessage = 'No cached results available. Please check your internet connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _productResults = [];
        _shopResults = [];
        _errorMessage = 'Error loading cached results: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildMixedList() {
    final items = <Widget>[];
    final List<Shop> shops = _filteredShops();
    final List<ProductResult> products = _filteredProducts();
    
    // Debug logging
    debugPrint('Building mixed list: ${products.length} products, ${shops.length} shops');
    debugPrint('Raw shop results: ${_shopResults.length} shops');
    debugPrint('Active filters: minRating=$_minRating, maxDistanceKm=$_maxDistanceKm, minPrice=$_minPrice, maxPrice=$_maxPrice');
    debugPrint('Shop distances: ${_shopResults.map((s) => '${s.name}: ${s.distance.toStringAsFixed(2)}km').join(', ')}');
    debugPrint('Filtered shops: ${shops.map((s) => '${s.name} (${s.offers.length} offers, ${s.distance.toStringAsFixed(2)}km)').join(', ')}');
    
    if (products.isNotEmpty) {
      items.add(_buildSectionHeader(
        'Products',
        '${products.length} found',
        Icons.shopping_bag,
        const Color(0xFF2979FF),
      ));
      for (final p in products) {
        items.add(_buildProductTile(p));
      }
    }
    if (shops.isNotEmpty) {
      // 1) Recommended shops
      final List<Shop> recommended = _recommendShops(shops);
      items.add(_buildSectionHeader(
        'Recommended Shops',
        '${recommended.length} best matches',
        Icons.star,
        const Color(0xFFFF6B35),
        action: TextButton.icon(
          onPressed: shops.isEmpty ? null : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MapScreenFree(
                  shopsOverride: shops,
                  drawRoutesForAll: true,
                ),
              ),
            );
          },
          icon: const Icon(Icons.map, size: 16),
          label: const Text('View all shops on map'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2979FF),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ));
      for (final s in recommended) {
        items.add(_buildShopTile(s));
      }

      // 2) All shops list
      items.add(_buildSectionHeader(
        'All Shops',
        '${shops.length} total',
        Icons.store,
        Colors.grey[600]!,
        action: TextButton.icon(
          onPressed: shops.isEmpty ? null : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MapScreenFree(
                  shopsOverride: shops,
                  drawRoutesForAll: true,
                ),
              ),
            );
          },
          icon: const Icon(Icons.map, size: 16),
          label: const Text('View all shops on map'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2979FF),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ));
      for (final s in shops) {
        items.add(_buildShopTile(s));
      }

      // 3) Button to open map with all routes
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MapScreenFree(
                    shopsOverride: shops,
                    drawRoutesForAll: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.directions),
            label: const Text('View all shops on map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2979FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  List<Shop> _recommendShops(List<Shop> shops) {
    if (shops.isEmpty) return const [];
    // Use the new visit priority score for better recommendations
    final List<MapEntry<Shop, double>> scored = shops.map((s) {
      return MapEntry(s, s.visitPriorityScore);
    }).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(3).map((e) => e.key).toList();
  }

  Widget _buildProductTile(ProductResult p) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final hasOffer = p.bestOfferPercent > 0;
    final discountedPrice = hasOffer ? p.price * (1 - p.bestOfferPercent / 100) : p.price;
    
    // Debug logging
    debugPrint('Building product tile for ${p.name}: bestOfferPercent=${p.bestOfferPercent}, hasOffer=$hasOffer');
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pushNamed('/shop-details', arguments: {
              'shop': Shop(
                id: p.shopId,
                name: p.shopName,
                category: '',
                address: p.shopAddress,
                latitude: p.shopLatitude,
                longitude: p.shopLongitude,
                rating: p.shopRating,
                reviewCount: 0,
                distance: p.distanceKm,
                offers: const [],
                isOpen: true,
                openingHours: '',
                phone: '',
                imageUrl: p.imageUrl,
                description: p.description,
                amenities: const [],
                lastUpdated: null,
              ),
            });
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with offer badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image placeholder
                    Container(
                      width: isTablet ? 80 : 60,
                      height: isTablet ? 80 : 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2979FF).withValues(alpha: 0.1),
                            const Color(0xFF2979FF).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: p.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                p.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildProductIcon(),
                              ),
                            )
                          : _buildProductIcon(),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name and offer badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isTablet ? 18 : 16,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          // Shop info
                          Row(
                            children: [
                              Icon(Icons.store, size: isTablet ? 16 : 14, color: const Color(0xFF2979FF)),
                              SizedBox(width: isTablet ? 6 : 4),
                              Expanded(
                                child: Text(
                                  p.shopName,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          // Rating and distance
                          Row(
                            children: [
                              Icon(Icons.star, size: isTablet ? 16 : 14, color: Colors.amber[600]),
                              SizedBox(width: isTablet ? 4 : 2),
                              Text(
                                p.shopRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              Icon(Icons.location_on, size: isTablet ? 16 : 14, color: Colors.grey[500]),
                              SizedBox(width: isTablet ? 4 : 2),
                              Text(
                                p.distanceKm < 1 
                                    ? '${(p.distanceKm * 1000).round()}m'
                                    : '${p.distanceKm.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 8),
                // Price section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Original price strikethrough removed with offer tag
                        Text(
                          '₹${discountedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2979FF),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward, size: isTablet ? 16 : 14, color: const Color(0xFF2979FF)),
                          SizedBox(width: isTablet ? 4 : 2),
                          Text(
                            'View Shop',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2979FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2979FF).withValues(alpha: 0.1),
            const Color(0xFF2979FF).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.shopping_bag,
        color: Color(0xFF2979FF),
        size: 32,
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color, {Widget? action}) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      margin: EdgeInsets.fromLTRB(
        isTablet ? 16 : 12,
        isTablet ? 20 : 16,
        isTablet ? 16 : 12,
        isTablet ? 8 : 6,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.05),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isTablet ? 20 : 18),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 18 : 16,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: isTablet ? 2 : 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }
  Future<void> _runSearch(String q) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFromCache = false;
    });

    try {
      // Mixed search: products + shops
      Position? pos;
      try {
        // Prefer robust helper which handles permissions/accuracy
        pos = await LocationService.getCurrentLocation();
      } catch (_) {}
      // Fallback to last known location if current precise fix is unavailable
      if (pos == null) {
        try { pos = await Geolocator.getLastKnownPosition().timeout(const Duration(seconds: 3)); } catch (_) {}
      }
      final mixed = await SearchService.searchMixed(
        query: q,
        userLatitude: pos?.latitude,
        userLongitude: pos?.longitude,
      );
      if (!mounted) return;
      
      // Debug logging
      debugPrint('Search results: ${mixed.products.length} products, ${mixed.shops.length} shops');
      debugPrint('Shops: ${mixed.shops.map((s) => '${s.name} (${s.offers.length} offers)').join(', ')}');
      
      // If no shops returned, try to get nearby shops as fallback
      if (mixed.shops.isEmpty && pos != null) {
        debugPrint('No shops returned, trying nearby shops fallback');
        try {
          final nearbyShops = await SearchService.searchShops(q);
          if (nearbyShops.isNotEmpty) {
            debugPrint('Found ${nearbyShops.length} nearby shops as fallback');
            setState(() {
              _productResults = mixed.products;
              _shopResults = nearbyShops;
            });
            return;
          }
        } catch (e) {
          debugPrint('Nearby shops fallback failed: $e');
        }
        
        // If still no shops, try to get any nearby shops without search query
        debugPrint('Still no shops, trying to get any nearby shops');
        try {
          final result = await ShopService.getNearbyShops(
            latitude: pos.latitude,
            longitude: pos.longitude,
            radius: 50000, // 50km radius
          );
          if (result['success'] == true && result['shops'] is List) {
            final List<dynamic> shopsData = result['shops'] as List<dynamic>;
            final List<Shop> nearbyShops = shopsData.map((shopData) {
              final Map<String, dynamic> shop = shopData as Map<String, dynamic>;
              return Shop.fromJson(shop);
            }).toList();
            
            if (nearbyShops.isNotEmpty) {
              debugPrint('Found ${nearbyShops.length} nearby shops without search query');
              setState(() {
                _productResults = mixed.products;
                _shopResults = nearbyShops;
              });
              return;
            }
          }
        } catch (e) {
          debugPrint('Failed to get nearby shops: $e');
        }
      }
      
      setState(() {
        _productResults = mixed.products;
        _shopResults = mixed.shops;
      });

      // Cache the results for offline access
      await RecentSearchService.cacheSearchResults(q, mixed.shops, mixed.products);
    } catch (e) {
      if (!mounted) return;
      
      // If online search fails, try cached results
      final cachedResults = await RecentSearchService.getCachedResults(q);
      if (cachedResults != null) {
        setState(() {
          _productResults = cachedResults.products;
          _shopResults = cachedResults.shops;
          _isFromCache = true;
          _errorMessage = 'Using cached results (network error)';
        });
      } else {
        setState(() {
          _productResults = [];
          _shopResults = [];
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        toolbarHeight: isTablet ? 80 : (isLargeScreen ? 90 : 70),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2979FF), Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Container(
          height: isTablet ? 45 : 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _controller,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search products, shops, or offers...',
              hintStyle: TextStyle(
                color: Colors.white70,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 10,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white70,
                size: isTablet ? 20 : 18,
              ),
              suffixIcon: VoiceSearchButton(
                onVoiceResult: (result) {
                  _controller.text = result;
                  _runSearch(result);
                },
                iconColor: Colors.white70,
                iconSize: isTablet ? 20 : 18,
                tooltip: 'Voice search',
              ),
            ),
            onSubmitted: (value) => _runSearch(value),
          ),
        ),
        actions: [
          if (_isOffline || _isFromCache)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isOffline ? Colors.orange[600] : Colors.blue[600],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isOffline ? Colors.orange : Colors.blue).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOffline ? Icons.wifi_off : Icons.cached,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOffline ? 'Offline' : 'Cached',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune,
                size: isTablet ? 22 : 20,
                color: Colors.white,
              ),
              tooltip: 'Filters',
              onPressed: _showFilters,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                size: isTablet ? 22 : 20,
                color: Colors.white,
              ),
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : () => _runSearch(_controller.text),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_hasActiveFilters()) _buildActiveFiltersRow(isTablet),
              if (_isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: (_isLoading && _productResults.isEmpty && _shopResults.isEmpty)
                    ? const SizedBox.shrink()
                    : (_productResults.isEmpty && _shopResults.isEmpty)
                        ? _buildEmptyState()
                        : _buildMixedList(),
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.6),
                child: const Center(
                  child: SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF2979FF)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Filter helpers
  bool _hasActiveFilters() {
    return _minRating > 0.0 || _maxDistanceKm != null || _minPrice != null || _maxPrice != null;
  }

  List<Shop> _filteredShops() {
    return _shopResults.where((s) {
      if (_minRating > 0.0 && s.rating < _minRating) return false;
      // Only apply distance filter if distance is valid (> 0) and within limit
      if (_maxDistanceKm != null && s.distance > 0 && s.distance > _maxDistanceKm!) return false;
      return true;
    }).toList();
  }

  List<ProductResult> _filteredProducts() {
    return _productResults.where((p) {
      if (_minRating > 0.0 && p.shopRating < _minRating) return false;
      // Only apply distance filter if distance is valid (> 0) and within limit
      if (_maxDistanceKm != null && p.distanceKm > 0 && p.distanceKm > _maxDistanceKm!) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      return true;
    }).toList();
  }

  Widget _buildActiveFiltersRow(bool isTablet) {
    final List<Widget> chips = [];
    if (_minRating > 0.0) {
      chips.add(_buildFilterChip('Rating ≥ ${_minRating.toStringAsFixed(1)}', () {
        setState(() => _minRating = 0.0);
      }));
    }
    if (_maxDistanceKm != null) {
      chips.add(_buildFilterChip('≤ ${_maxDistanceKm!.toStringAsFixed(1)} km', () {
        setState(() => _maxDistanceKm = null);
      }));
    }
    if (_minPrice != null) {
      chips.add(_buildFilterChip('Min ₹${_minPrice!.toStringAsFixed(0)}', () {
        setState(() => _minPrice = null);
      }));
    }
    if (_maxPrice != null) {
      chips.add(_buildFilterChip('Max ₹${_maxPrice!.toStringAsFixed(0)}', () {
        setState(() => _maxPrice = null);
      }));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(isTablet ? 16 : 12, 8, isTablet ? 16 : 12, 4),
      child: Row(
        children: chips
            .map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c))
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onClear) {
    return InputChip(
      label: Text(label),
      onDeleted: onClear,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: const Color(0xFFEFF6FF),
      labelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double tempRating = _minRating;
        double tempMaxDistance = _maxDistanceKm ?? 0.0; // 0 = no limit
        RangeValues tempPrice = RangeValues((_minPrice ?? 0).toDouble(), (_maxPrice ?? 100000).toDouble());
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Minimum Rating'),
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
                      onChanged: (v) => setModalState(() => tempRating = v),
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: tempRating.toStringAsFixed(1),
                    ),
                    const SizedBox(height: 12),
                    const Text('Max Distance (km)'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('No limit'),
                        Text(tempMaxDistance == 0.0 ? '—' : tempMaxDistance.toStringAsFixed(1)),
                        const Text('20'),
                      ],
                    ),
                    Slider(
                      value: tempMaxDistance,
                      onChanged: (v) => setModalState(() => tempMaxDistance = v),
                      min: 0.0,
                      max: 20.0,
                      divisions: 40,
                      label: tempMaxDistance == 0.0 ? 'No limit' : '${tempMaxDistance.toStringAsFixed(1)} km',
                    ),
                    const SizedBox(height: 12),
                    const Text('Price Range (₹) – products only'),
                    RangeSlider(
                      values: tempPrice,
                      onChanged: (v) => setModalState(() => tempPrice = v),
                      min: 0,
                      max: 100000,
                      divisions: 100,
                      labels: RangeLabels('₹${tempPrice.start.toStringAsFixed(0)}', '₹${tempPrice.end.toStringAsFixed(0)}'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _minRating = tempRating;
                            _maxDistanceKm = tempMaxDistance == 0.0 ? null : tempMaxDistance;
                            _minPrice = tempPrice.start <= 0 ? null : tempPrice.start;
                            _maxPrice = tempPrice.end >= 100000 ? null : tempPrice.end;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Apply Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopTile(Shop shop) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final hasOffers = shop.offers.isNotEmpty;
    final bestOffer = hasOffers ? shop.offers.first : null;
    
    // Debug logging
    debugPrint('Building shop tile for ${shop.name}: ${shop.offers.length} offers');
    if (hasOffers) {
      debugPrint('Best offer: ${bestOffer?.title} - ${bestOffer?.formattedDiscount}');
    }
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pushNamed('/shop-details', arguments: { 'shop': shop });
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with shop info and offer badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop avatar
                    Container(
                      width: isTablet ? 60 : 50,
                      height: isTablet ? 60 : 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2979FF).withValues(alpha: 0.1),
                            const Color(0xFF2979FF).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: shop.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                shop.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildShopIcon(),
                              ),
                            )
                          : _buildShopIcon(),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shop name and offer badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isTablet ? 18 : 16,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (hasOffers && bestOffer != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    bestOffer.formattedDiscount,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          // Category and status
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  shop.category.isNotEmpty ? shop.category : 'General',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: shop.isOpen ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      shop.isOpen ? Icons.circle : Icons.circle_outlined,
                                      size: isTablet ? 12 : 10,
                                      color: shop.isOpen ? Colors.green[600] : Colors.red[600],
                                    ),
                                    SizedBox(width: isTablet ? 4 : 2),
                                    Text(
                                      shop.isOpen ? 'Open' : 'Closed',
                                      style: TextStyle(
                                        fontSize: isTablet ? 12 : 10,
                                        color: shop.isOpen ? Colors.green[600] : Colors.red[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          // Rating and distance
                          Row(
                            children: [
                              Icon(Icons.star, size: isTablet ? 16 : 14, color: Colors.amber[600]),
                              SizedBox(width: isTablet ? 4 : 2),
                              Text(
                                shop.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              Icon(Icons.location_on, size: isTablet ? 16 : 14, color: Colors.grey[500]),
                              SizedBox(width: isTablet ? 4 : 2),
                              Text(
                                shop.formattedDistance,
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              if (hasOffers && bestOffer != null && bestOffer.discount > 0)
                                Text(
                                  'Best Deal Available',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: const Color(0xFFFF6B35),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          // Ranking reason
                          Text(
                            shop.rankingReason,
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              color: const Color(0xFF2979FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 8),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MapScreenFree(
                                searchQuery: _controller.text,
                                shopsOverride: _shopResults,
                                routeToShop: shop,
                                drawRoutesForAll: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('View on Map'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2979FF),
                          side: const BorderSide(color: Color(0xFF2979FF)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/shop-details', arguments: { 'shop': shop });
                        },
                        icon: const Icon(Icons.store, size: 16),
                        label: const Text('Shop Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2979FF).withValues(alpha: 0.1),
            const Color(0xFF2979FF).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.store,
        color: Color(0xFF2979FF),
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: isTablet ? 80 : 64,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              ElevatedButton.icon(
                onPressed: () => _runSearch(_controller.text),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 24,
                    vertical: isTablet ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(
                Icons.search_off,
                size: isTablet ? 80 : 64,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Try searching with different keywords or check your spelling',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb, color: const Color(0xFF2979FF), size: isTablet ? 20 : 18),
                  SizedBox(width: isTablet ? 8 : 6),
                  Text(
                    'Try: "electronics", "clothing", "food"',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: const Color(0xFF2979FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


