import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../data/mock_data.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<Shop>? initialResults;

  const SearchResultsScreen({super.key, required this.query, this.initialResults});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _controller;
  late List<Shop> _results;
  late List<String> _similarTerms;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _runSearch(widget.query);
  }

  void _runSearch(String q) {
    final results = widget.initialResults ?? MockData.search(q);
    final similar = MockData.similarTerms(q);
    setState(() {
      _results = results;
      _similarTerms = similar;
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
            onPressed: () => _runSearch(_controller.text),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_similarTerms.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFF2979FF).withValues(alpha: 0.08),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16, 
                vertical: isTablet ? 16 : 12
              ),
              child: Wrap(
                spacing: isTablet ? 12 : 8,
                children: [
                  Text(
                    'You might also mean:', 
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 16 : 14,
                    )
                  ),
                  ..._similarTerms.map((t) => ActionChip(
                        label: Text(
                          t,
                          style: TextStyle(fontSize: isTablet ? 14 : 12),
                        ),
                        onPressed: () {
                          _controller.text = t;
                          _runSearch(t);
                        },
                      )),
                ],
              ),
            ),

          Expanded(
            child: _results.isEmpty
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


