import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../widgets/comparison_card.dart';
import '../widgets/rating_widget.dart';

class ShopComparisonScreen extends StatefulWidget {
  final List<Shop> shops;

  const ShopComparisonScreen({
    super.key,
    required this.shops,
  });

  @override
  State<ShopComparisonScreen> createState() => _ShopComparisonScreenState();
}

class _ShopComparisonScreenState extends State<ShopComparisonScreen> {
  List<Shop> _selectedShops = [];
  String _selectedProduct = '';
  bool _isLoading = false;

  final List<String> _products = [];

  @override
  void initState() {
    super.initState();
    _selectedShops = List.from(widget.shops);
  }

  void _addShop(Shop shop) {
    if (!_selectedShops.contains(shop) && _selectedShops.length < 3) {
      setState(() {
        _selectedShops.add(shop);
      });
    }
  }

  void _removeShop(Shop shop) {
    setState(() {
      _selectedShops.remove(shop);
    });
  }

  void _compareShops() {
    if (_selectedShops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 shops to compare'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement real comparison API call
    setState(() { _isLoading = false; });
    _showComparisonResults();
  }

  void _showComparisonResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildComparisonResultsSheet(),
    );
  }

  Widget _buildComparisonResultsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Comparison Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Results content
          Expanded(
            child: _buildComparisonResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResults() {
    if (_selectedProduct.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Select a product to compare',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Product header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: const Color(0xFF2979FF)),
              const SizedBox(width: 12),
              Text(
                _selectedProduct,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Comparison cards
        ..._selectedShops.map((shop) => _buildShopComparisonCard(shop)),
      ],
    );
  }

  Widget _buildShopComparisonCard(Shop shop) {
    final priceText = '—';
    final availabilityText = '—';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.store,
                  color: Color(0xFF2979FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      shop.formattedDistance,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              RatingWidget(
                rating: shop.rating,
                reviewCount: shop.reviewCount,
                starSize: 14,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price and availability
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Price',
                  priceText,
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Availability',
                  availabilityText,
                  Icons.inventory,
                  Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Offers
          if (shop.offers.isNotEmpty) ...[
            const Text(
              'Current Offers:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...shop.offers.take(2).map((offer) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${offer.formattedDiscount} - ${offer.title}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            )),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to shop details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${shop.name} details')),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2979FF),
                    side: const BorderSide(color: Color(0xFF2979FF)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Get directions
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Getting directions to ${shop.name}')),
                    );
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2979FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Shops'),
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (_selectedShops.length >= 2)
            TextButton(
              onPressed: _isLoading ? null : _compareShops,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Compare',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Product selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Product to Compare',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProduct.isEmpty ? null : _selectedProduct,
                  decoration: InputDecoration(
                    hintText: 'Choose a product...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProduct = value ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Selected shops
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selected Shops (${_selectedShops.length}/3)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedShops.length < 3)
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Show shop selection dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shop selection coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Shop'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedShops.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.store, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No shops selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedShops.map((shop) {
                      return Chip(
                        label: Text(shop.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeShop(shop),
                        backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.1),
                        deleteIconColor: const Color(0xFF2979FF),
                        labelStyle: const TextStyle(
                          color: Color(0xFF2979FF),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          
          // Available shops
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Shops',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.shops.length,
                      itemBuilder: (context, index) {
                        final shop = widget.shops[index];
                        final isSelected = _selectedShops.contains(shop);
                        final canAdd = _selectedShops.length < 3;
                        
                        return ComparisonCard(
                          shop: shop,
                          isSelected: isSelected,
                          canAdd: canAdd,
                          onAdd: () => _addShop(shop),
                          onRemove: () => _removeShop(shop),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
