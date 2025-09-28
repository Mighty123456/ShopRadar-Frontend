import 'package:flutter/material.dart';

class OfferFilterWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> initialFilters;

  const OfferFilterWidget({
    super.key,
    required this.onFiltersChanged,
    this.initialFilters = const {},
  });

  @override
  State<OfferFilterWidget> createState() => _OfferFilterWidgetState();
}

class _OfferFilterWidgetState extends State<OfferFilterWidget> {
  String _selectedCategory = 'All';
  double _minDiscount = 0;
  double _maxDiscount = 100;
  int _expiringHours = 0;
  String _searchQuery = '';
  String _sortBy = 'discount';

  final List<String> _categories = [
    'All',
    'Food & Dining',
    'Electronics & Gadgets',
    'Fashion & Clothing',
    'Health & Beauty',
    'Home & Garden',
    'Sports & Fitness',
    'Books & Education',
    'Automotive',
    'Entertainment',
    'Services',
    'Other',
  ];

  final List<String> _sortOptions = [
    'discount',
    'expiring',
    'newest',
    'alphabetical',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilters['category'] ?? 'All';
    _minDiscount = widget.initialFilters['minDiscount']?.toDouble() ?? 0;
    _maxDiscount = widget.initialFilters['maxDiscount']?.toDouble() ?? 100;
    _expiringHours = widget.initialFilters['expiringHours'] ?? 0;
    _searchQuery = widget.initialFilters['searchQuery'] ?? '';
    _sortBy = widget.initialFilters['sortBy'] ?? 'discount';
  }

  void _applyFilters() {
    final filters = {
      'category': _selectedCategory == 'All' ? null : _selectedCategory,
      'minDiscount': _minDiscount,
      'maxDiscount': _maxDiscount,
      'expiringHours': _expiringHours == 0 ? null : _expiringHours,
      'searchQuery': _searchQuery.isEmpty ? null : _searchQuery,
      'sortBy': _sortBy,
    };
    widget.onFiltersChanged(filters);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _minDiscount = 0;
      _maxDiscount = 100;
      _expiringHours = 0;
      _searchQuery = '';
      _sortBy = 'discount';
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Query
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search offers...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Category Filter
          const Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Discount Range
          const Text(
            'Discount Range',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Min: ${_minDiscount.toInt()}%'),
              ),
              Expanded(
                flex: 3,
                child: RangeSlider(
                  values: RangeValues(_minDiscount, _maxDiscount),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (values) {
                    setState(() {
                      _minDiscount = values.start;
                      _maxDiscount = values.end;
                    });
                  },
                ),
              ),
              Expanded(
                child: Text('Max: ${_maxDiscount.toInt()}%'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Expiring Soon Filter
          const Text(
            'Expiring Soon',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _expiringHours == 0,
                onSelected: (selected) {
                  setState(() {
                    _expiringHours = 0;
                  });
                },
              ),
              FilterChip(
                label: const Text('24 Hours'),
                selected: _expiringHours == 24,
                onSelected: (selected) {
                  setState(() {
                    _expiringHours = 24;
                  });
                },
              ),
              FilterChip(
                label: const Text('3 Days'),
                selected: _expiringHours == 72,
                onSelected: (selected) {
                  setState(() {
                    _expiringHours = 72;
                  });
                },
              ),
              FilterChip(
                label: const Text('1 Week'),
                selected: _expiringHours == 168,
                onSelected: (selected) {
                  setState(() {
                    _expiringHours = 168;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sort Options
          const Text(
            'Sort By',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Highest Discount'),
                selected: _sortBy == 'discount',
                onSelected: (selected) {
                  setState(() {
                    _sortBy = 'discount';
                  });
                },
              ),
              FilterChip(
                label: const Text('Expiring Soon'),
                selected: _sortBy == 'expiring',
                onSelected: (selected) {
                  setState(() {
                    _sortBy = 'expiring';
                  });
                },
              ),
              FilterChip(
                label: const Text('Newest'),
                selected: _sortBy == 'newest',
                onSelected: (selected) {
                  setState(() {
                    _sortBy = 'newest';
                  });
                },
              ),
              FilterChip(
                label: const Text('A-Z'),
                selected: _sortBy == 'alphabetical',
                onSelected: (selected) {
                  setState(() {
                    _sortBy = 'alphabetical';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
