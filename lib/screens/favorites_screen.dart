import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shop.dart';
import '../services/favorite_shops_service.dart';
import '../widgets/radar_loader.dart';
import '../widgets/voice_search_button.dart';
import 'shop_details_screen.dart';
import 'map_screen_free.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Shop> _favoriteShops = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Shop> favorites;
      if (_searchQuery.trim().isEmpty) {
        favorites = await FavoriteShopsService.getFavoriteShops();
      } else {
        favorites = await FavoriteShopsService.searchFavorites(_searchQuery);
      }

      if (mounted) {
        setState(() {
          _favoriteShops = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoriteShops = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: $e')),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(Shop shop) async {
    final success = await FavoriteShopsService.removeFromFavorites(shop.id);
    if (success && mounted) {
      setState(() {
        _favoriteShops.removeWhere((s) => s.id == shop.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('Are you sure you want to remove all shops from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FavoriteShopsService.clearAllFavorites();
      if (success && mounted) {
        setState(() {
          _favoriteShops.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All favorites cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    final searchController = TextEditingController(text: _searchQuery);

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
            controller: searchController,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: isTablet ? 16 : 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search favorites...',
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
                  searchController.text = result;
                  setState(() {
                    _searchQuery = result;
                  });
                  _loadFavorites();
                },
                iconColor: Colors.grey[600],
                iconSize: isTablet ? 20 : 18,
                tooltip: 'Voice search',
              ),
            ),
            onSubmitted: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _searchQuery = value;
              });
              _loadFavorites();
            },
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadFavorites();
            },
          ),
        ),
        actions: [
          if (_favoriteShops.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllFavorites,
              tooltip: 'Clear all favorites',
            ),
        ],
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: RadarLoader(
                      size: isTablet ? 200 : 180,
                      message: 'Loading Favorites...',
                      useAppColors: true,
                    ),
                  )
                : _favoriteShops.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(isTablet, isLargeScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.favorite_border : Icons.search_off,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'No favorite shops yet'
                : 'No favorites match your search',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add shops to your favorites to see them here'
                : 'Try a different search term',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(bool isTablet, bool isLargeScreen) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: 8,
      ),
      itemCount: _favoriteShops.length,
      itemBuilder: (context, index) {
        final shop = _favoriteShops[index];
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
            title: Text(
              shop.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 18 : 16,
              ),
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
                  ],
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
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFromFavorites(shop),
                      tooltip: 'Remove from favorites',
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
      },
    );
  }
}
