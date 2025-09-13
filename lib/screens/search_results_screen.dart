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
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
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
        )
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.star, 
            size: isTablet ? 18 : 16, 
            color: Colors.amber
          ),
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            '${shop.rating} • ${shop.formattedDistance} • ${shop.category}',
            style: TextStyle(fontSize: isTablet ? 16 : 14),
          ),
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios, 
        size: isTablet ? 18 : 16,
      ),
      onTap: () {
        Navigator.of(context).pushNamed('/shop-details', arguments: { 'shop': shop });
      },
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


