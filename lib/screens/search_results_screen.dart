import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../services/product_search_service.dart';
import 'package:geolocator/geolocator.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<Shop>? initialResults;

  const SearchResultsScreen({super.key, required this.query, this.initialResults});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _controller;
  List<Shop> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _runSearch(widget.query);
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try product-centric search that aggregates shops by product
      Position? pos;
      try { pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 5)); } catch (_) {}
      final results = await ProductSearchService.searchProductShops(
        query: q,
        userLatitude: pos?.latitude,
        userLongitude: pos?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _errorMessage = e.toString();
      });
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        toolbarHeight: isTablet ? 70 : (isLargeScreen ? 80 : 56),
        title: TextField(
          controller: _controller,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 18 : 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search products or shops...',
            hintStyle: TextStyle(
              color: Colors.white70,
              fontSize: isTablet ? 18 : 16,
            ),
            border: InputBorder.none,
          ),
          onSubmitted: (value) => _runSearch(value),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              size: isTablet ? 24 : 20,
            ),
            onPressed: _isLoading ? null : () => _runSearch(_controller.text),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isLoading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: (_isLoading && _results.isEmpty)
                    ? const SizedBox.shrink()
                    : _results.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final shop = _results[index];
                          return _buildShopTile(shop);
                        },
                      ),
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

  Widget _buildShopTile(Shop shop) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 6 : 2,
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
            if (shop.offers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shop.offers.first.formattedDiscount,
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, size: isTablet ? 18 : 16, color: Colors.amber),
                SizedBox(width: isTablet ? 6 : 4),
                Text('${shop.rating} • ${shop.formattedDistance} • ${shop.category}', style: TextStyle(fontSize: isTablet ? 16 : 14)),
              ],
            ),
            SizedBox(height: 6),
            Row(
        children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/map', arguments: {
                      'searchQuery': _controller.text,
                      'shops': _results,
                      'showOnlyUser': false,
                    });
                  },
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('View on Map'),
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
                    Navigator.of(context).pushNamed('/shop-details', arguments: { 'shop': shop });
                  },
                  child: const Text('Details'),
          ),
        ],
      ),
          ],
      ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.of(context).pushNamed('/shop-details', arguments: { 'shop': shop });
      },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
              const SizedBox(height: 12),
              const Text('Something went wrong'),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _runSearch(_controller.text),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('No results found'),
          const SizedBox(height: 8),
          const Text('Try a different keyword or check similar terms'),
        ],
      ),
    );
  }
}


