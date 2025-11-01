import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shop.dart';
import '../models/product_result.dart';
import '../services/search_service.dart';
import '../services/recent_search_service.dart';
import '../services/connectivity_service.dart';
import '../services/shop_service.dart';
import '../services/featured_offers_service.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'map_screen_free.dart';
import '../widgets/voice_search_button.dart';
import '../widgets/radar_loader.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<Shop>? initialResults;

  const SearchResultsScreen({super.key, required this.query, this.initialResults});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> with TickerProviderStateMixin {
  late TextEditingController _controller;
  List<ProductResult> _productResults = [];
  List<Shop> _shopResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;
  bool _isFromCache = false;
  // Featured offers tracking
  Set<String> _featuredProductIds = {}; // Set of product IDs that are in featured offers
  // Filters
  double _minRating = 0.0; // 0.0 - 5.0
  double? _maxDistanceKm; // null = no cap
  double? _minPrice; // products only
  double? _maxPrice; // products only
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
    _loadFeaturedOffers();
    _checkConnectivityAndSearch();
  }

  Future<void> _loadFeaturedOffers() async {
    try {
      final offers = await FeaturedOffersService().fetchFeaturedOffers(radius: 8000);
      if (mounted) {
        setState(() {
          _featuredProductIds = offers.map((offer) => offer.product.id).toSet();
        });
      }
    } catch (e) {
      debugPrint('[Search Results] Error loading featured offers: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
              HapticFeedback.lightImpact();
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
              HapticFeedback.lightImpact();
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
              HapticFeedback.mediumImpact();
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
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _runSearch(_controller.text);
      },
      color: const Color(0xFF2979FF),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: items[index],
              );
            },
          ),
        ),
      ),
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
    final isFeatured = _featuredProductIds.contains(p.id);
    
    return _InteractiveProductCardWidget(
      product: p,
      isTablet: isTablet,
      discountedPrice: discountedPrice,
      hasOffer: hasOffer,
      isFeatured: isFeatured,
      onTap: () {
        HapticFeedback.mediumImpact();
        // Find the corresponding shop from shop results to get proper shop imageUrl
        final Shop matchingShop = _shopResults.firstWhere(
          (s) => s.id == p.shopId,
          orElse: () => Shop(
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
            imageUrl: null,
            description: p.description,
            amenities: const [],
            lastUpdated: null,
          ),
        );
        
        final Shop shopForDetails = Shop(
          id: matchingShop.id,
          name: matchingShop.name,
          category: matchingShop.category,
          address: matchingShop.address,
          latitude: matchingShop.latitude,
          longitude: matchingShop.longitude,
          rating: matchingShop.rating,
          reviewCount: matchingShop.reviewCount,
          distance: matchingShop.distance,
          offers: matchingShop.offers,
          isOpen: matchingShop.isOpen,
          openingHours: matchingShop.openingHours,
          phone: matchingShop.phone,
          imageUrl: matchingShop.imageUrl,
          description: matchingShop.description ?? p.description,
          amenities: matchingShop.amenities,
          lastUpdated: matchingShop.lastUpdated,
        );
        
        Navigator.of(context).pushNamed('/shop-details', arguments: {
          'shop': shopForDetails,
        });
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _copyProductInfo(p);
      },
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
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFromCache = false;
    });
    // Reset animations for new search
    _fadeController.reset();
    _slideController.reset();

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
      
      // Animate results in
      _fadeController.forward();
      _slideController.forward();

      // Cache the results for offline access
      await RecentSearchService.cacheSearchResults(q, mixed.shops, mixed.products);
      
      if (mixed.products.isNotEmpty || mixed.shops.isNotEmpty) {
        HapticFeedback.selectionClick();
      }
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: isTablet ? 90 : (isLargeScreen ? 100 : 80),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2979FF).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Container(
          height: isTablet ? 48 : 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: isTablet ? 16 : 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search products, shops, or offers...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: isTablet ? 16 : 15,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 14 : 12,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF2979FF),
                size: isTablet ? 22 : 20,
              ),
              suffixIcon: VoiceSearchButton(
                onVoiceResult: (result) {
                  _controller.text = result;
                  _runSearch(result);
                },
                iconColor: Colors.grey[600],
                iconSize: isTablet ? 20 : 18,
                tooltip: 'Voice search',
              ),
            ),
              onSubmitted: (value) {
                HapticFeedback.lightImpact();
                _runSearch(value);
              },
              onChanged: (value) {
                // Clear search when empty
                if (value.isEmpty && _productResults.isNotEmpty && _shopResults.isNotEmpty) {
                  setState(() {
                    _productResults = [];
                    _shopResults = [];
                  });
                }
              },
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFilters();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                Icons.tune,
                size: isTablet ? 22 : 20,
                color: Colors.white,
              ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoading ? null : () {
                  HapticFeedback.mediumImpact();
                  _runSearch(_controller.text);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                Icons.refresh,
                size: isTablet ? 22 : 20,
                color: Colors.white,
              ),
                ),
              ),
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
                color: Colors.white.withValues(alpha: 0.95),
                child: Center(
                  child: RadarLoader(
                    size: 220,
                    message: 'Searching...',
                    useAppColors: true,
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
      onDeleted: () {
        HapticFeedback.lightImpact();
        onClear();
      },
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: const Color(0xFFEFF6FF),
      labelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
    );
  }

  Future<void> _copyProductInfo(ProductResult product) async {
    HapticFeedback.lightImpact();
    final text = '${product.name}\n'
        'Shop: ${product.shopName}\n'
        'Price: ₹${product.price.toStringAsFixed(0)}\n'
        'Rating: ${product.shopRating.toStringAsFixed(1)}/5';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Product info copied'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showShopQuickActions(Shop shop) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Color(0xFF2979FF)),
                title: const Text('Copy Address'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  HapticFeedback.lightImpact();
                  await Clipboard.setData(ClipboardData(text: shop.address));
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Address copied'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF2979FF)),
                title: const Text('Share Shop'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  HapticFeedback.lightImpact();
                  final text = 'Check out ${shop.name}!\n'
                      '📍 ${shop.address}\n'
                      '⭐ Rating: ${shop.rating}/5';
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.share, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Shop details copied! Share it anywhere'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2979FF),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Color(0xFF2979FF)),
                title: const Text('View on Map'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapScreenFree(
                        shopsOverride: [shop],
                        routeToShop: shop,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _minRating = tempRating;
                            _maxDistanceKm = tempMaxDistance == 0.0 ? null : tempMaxDistance;
                            _minPrice = tempPrice.start <= 0 ? null : tempPrice.start;
                            _maxPrice = tempPrice.end >= 100000 ? null : tempPrice.end;
                          });
                          Navigator.of(context).pop();
                          // Trigger haptic on successful filter apply
                          if (_hasActiveFilters()) {
                            HapticFeedback.selectionClick();
                          }
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
            HapticFeedback.mediumImpact();
            Navigator.of(context).pushNamed('/shop-details', arguments: { 'shop': shop });
          },
          onLongPress: () {
            HapticFeedback.heavyImpact();
            _showShopQuickActions(shop);
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
                          HapticFeedback.lightImpact();
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
                          HapticFeedback.mediumImpact();
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

// Interactive Product Card Widget with E-commerce Style Design
class _InteractiveProductCardWidget extends StatefulWidget {
  final ProductResult product;
  final bool isTablet;
  final double discountedPrice;
  final bool hasOffer;
  final bool isFeatured;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _InteractiveProductCardWidget({
    required this.product,
    required this.isTablet,
    required this.discountedPrice,
    required this.hasOffer,
    required this.isFeatured,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_InteractiveProductCardWidget> createState() => _InteractiveProductCardWidgetState();
}

class _InteractiveProductCardWidgetState extends State<_InteractiveProductCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onLongPress: widget.onLongPress,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 16.0 : 12.0,
                vertical: widget.isTablet ? 8.0 : 6.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.12),
                    blurRadius: _isPressed ? 8 : 12,
                    offset: Offset(0, _isPressed ? 2 : 4),
                    spreadRadius: _isPressed ? 0 : 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.grey[100]!,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.isTablet ? 16.0 : 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image Section
                    Stack(
                      children: [
                        Container(
                          width: widget.isTablet ? 120.0 : 100.0,
                          height: widget.isTablet ? 120.0 : 100.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFF3F4F6),
                          ),
                          child: widget.product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildProductPlaceholder(),
                                  ),
                                )
                              : _buildProductPlaceholder(),
                        ),
                        // Discount Badge
                        if (widget.hasOffer)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.product.bestOfferPercent.round()}% OFF',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Featured Badge
                        if (widget.isFeatured)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Featured',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: widget.isTablet ? 16 : 12),
                    // Content Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              Text(
                                widget.product.name,
                                style: TextStyle(
                                  fontSize: widget.isTablet ? 17 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Shop Name
                              Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: widget.isTablet ? 16 : 14,
                                    color: const Color(0xFF2979FF),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.product.shopName,
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 14 : 13,
                                        color: const Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Rating and Distance
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: widget.isTablet ? 16 : 14,
                                    color: Colors.amber[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.product.shopRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: widget.isTablet ? 13 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on,
                                    size: widget.isTablet ? 16 : 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.product.distanceKm < 1
                                        ? '${(widget.product.distanceKm * 1000).round()}m'
                                        : '${widget.product.distanceKm.toStringAsFixed(1)}km',
                                    style: TextStyle(
                                      fontSize: widget.isTablet ? 13 : 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Price and Action Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Original Price (if offer exists)
                                  if (widget.hasOffer && widget.product.price > 0)
                                    Text(
                                      '₹${widget.product.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: widget.isTablet ? 13 : 12,
                                        color: const Color(0xFF9CA3AF),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  if (widget.hasOffer && widget.product.price > 0)
                                    const SizedBox(height: 2),
                                  // Discounted Price
                                  Text(
                                    '₹${widget.discountedPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: widget.isTablet ? 22 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF10B981),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: widget.isTablet ? 14 : 12,
                                  vertical: widget.isTablet ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2979FF), Color(0xFF1E88E5)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: widget.isTablet ? 13 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[400],
          size: widget.isTablet ? 40 : 36,
        ),
      ),
    );
  }
}

