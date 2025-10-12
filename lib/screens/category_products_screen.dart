import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/shop_service.dart';
import '../widgets/animated_message_dialog.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> allProducts;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.allProducts,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<String> _availableBrands = [];
  String? _selectedBrand;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  
  // Add product form state
  bool _showAddProductForm = false;
  final _addProductFormKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productStockController = TextEditingController();
  final _productBrandController = TextEditingController();
  String? _selectedProductBrand;
  bool _isCreatingProduct = false;

  @override
  void initState() {
    super.initState();
    _loadFreshProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _productPriceController.dispose();
    _productStockController.dispose();
    _productBrandController.dispose();
    super.dispose();
  }

  Future<void> _loadFreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ShopService.getMyProducts(limit: 100);
      
      if (result['success'] == true) {
        setState(() {
          _allProducts = List<Map<String, dynamic>>.from(result['products'] ?? []);
        });
        _filterProducts();
        _extractBrands();
      } else {
        // Fallback to passed products if API call fails
        setState(() {
          _allProducts = widget.allProducts;
        });
        _filterProducts();
        _extractBrands();
      }
    } catch (e) {
      // Fallback to passed products if API call fails
      setState(() {
        _allProducts = widget.allProducts;
      });
      _filterProducts();
      _extractBrands();
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterProducts() {
    setState(() {
      // Filter products by category
      _filteredProducts = _allProducts
          .where((product) => 
              product['category']?.toString().toLowerCase() == 
              widget.categoryName.toLowerCase())
          .toList();

      // Apply brand filter if selected
      if (_selectedBrand != null) {
        _filteredProducts = _filteredProducts
            .where((product) {
              // First try direct brand field from API
              final directBrand = product['brand']?.toString().toLowerCase();
              if (directBrand == _selectedBrand!.toLowerCase()) {
                return true;
              }
              
              // Fallback to comprehensive brand resolution
              final resolvedBrand = _getBrandName(product).toLowerCase();
              return resolvedBrand == _selectedBrand!.toLowerCase();
            })
            .toList();
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _filteredProducts = _filteredProducts
            .where((product) => 
                (product['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (product['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _extractBrands() {
    final categoryProducts = _allProducts
        .where((product) => 
            product['category']?.toString().toLowerCase() == 
            widget.categoryName.toLowerCase())
        .toList();

    debugPrint('=== EXTRACTING BRANDS ===');
    debugPrint('Category: ${widget.categoryName}');
    debugPrint('Category products count: ${categoryProducts.length}');
    
    final brands = <String>{};
    
    for (final product in categoryProducts) {
      debugPrint('Product: ${product['name']}');
      debugPrint('Product brand field: ${product['brand']}');
      
      // First try to get brand directly from the API response
      final directBrand = product['brand']?.toString();
      if (directBrand != null && directBrand.isNotEmpty && directBrand != 'N/A') {
        brands.add(directBrand);
        debugPrint('Added direct brand: $directBrand');
        continue;
      }
      
      // Fallback to comprehensive brand resolution logic
      final brand = _getBrandName(product);
      if (brand != 'N/A' && brand.isNotEmpty) {
        brands.add(brand);
        debugPrint('Added resolved brand: $brand');
      }
    }
    
    final brandsList = brands.toList()..sort();
    debugPrint('Final brands list: $brandsList');
    debugPrint('=======================');
    
    setState(() {
      _availableBrands = brandsList;
    });
  }

  void _onBrandFilterChanged(String? brand) {
    setState(() {
      _selectedBrand = brand;
    });
    _filterProducts();
  }

  void _toggleAddProductForm() {
    setState(() {
      _showAddProductForm = !_showAddProductForm;
      if (!_showAddProductForm) {
        _clearAddProductForm();
      }
    });
  }

  void _clearAddProductForm() {
    _productNameController.clear();
    _productDescriptionController.clear();
    _productPriceController.clear();
    _productStockController.clear();
    _productBrandController.clear();
    _selectedProductBrand = null;
  }

  Future<void> _createProduct() async {
    if (!_addProductFormKey.currentState!.validate()) return;
    if (_selectedProductBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand')),
      );
      return;
    }

    setState(() {
      _isCreatingProduct = true;
    });

    final productData = {
      'name': _productNameController.text.trim(),
      'description': _productDescriptionController.text.trim(),
      'category': widget.categoryName,
      'brand': _selectedProductBrand!,
      'itemName': _productNameController.text.trim(),
      'price': double.parse(_productPriceController.text),
      'stock': int.parse(_productStockController.text),
    };

    try {
      final result = await ShopService.createProductWithOffer(
        productData: productData,
        offerData: null,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          _toggleAddProductForm();
          await _loadFreshProducts();
          
          // Also refresh brands immediately to ensure new brand appears in dropdown
          _extractBrands();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isCreatingProduct = false;
    });
  }

  // Delete product functionality
  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Try different possible ID field names
        final productId = product['_id'] ?? product['id'] ?? product['productId'];
        
        if (productId == null) {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Product ID not found',
              type: MessageType.error,
            );
          }
          return;
        }
        
        final result = await ShopService.deleteMyProduct(productId);
        
        if (result['success']) {
          // Remove product from the list
          setState(() {
            _filteredProducts.removeWhere((p) => (p['_id'] ?? p['id'] ?? p['productId']) == productId);
            widget.allProducts.removeWhere((p) => (p['_id'] ?? p['id'] ?? p['productId']) == productId);
          });
          
          // Show success message
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Product deleted successfully',
              type: MessageType.success,
            );
            
            // Check if this was the last product in the category
            final remainingProductsInCategory = _filteredProducts.where((p) => p['category'] == widget.categoryName).length;
            if (remainingProductsInCategory == 0) {
              // Show additional message about category being empty
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  MessageHelper.showAnimatedMessage(
                    context,
                    message: 'Category "${widget.categoryName}" is now empty. You can delete it from the main product screen.',
                    type: MessageType.info,
                  );
                }
              });
            }
          }
        } else {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: result['message'] ?? 'Failed to delete product',
              type: MessageType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Error deleting product: $e',
            type: MessageType.error,
          );
        }
      }
    }
  }

  // Edit product functionality
  Future<void> _editProduct(Map<String, dynamic> product) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditProductDialog(product: product),
    );

    if (result != null) {
      try {
        // Try different possible ID field names
        final productId = product['_id'] ?? product['id'] ?? product['productId'];
        
        if (productId == null) {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Product ID not found',
              type: MessageType.error,
            );
          }
          return;
        }
        
        final updateResult = await ShopService.updateMyProduct(
          productId: productId,
          name: result['name'],
          description: result['description'],
          price: result['price'],
          stock: result['stock'],
          status: result['status'],
        );

        if (updateResult['success']) {
          // Update the product in the list
          setState(() {
            final index = _filteredProducts.indexWhere((p) => (p['_id'] ?? p['id'] ?? p['productId']) == productId);
            if (index != -1) {
              _filteredProducts[index] = {
                ..._filteredProducts[index],
                'name': result['name'],
                'description': result['description'],
                'price': result['price'],
                'stock': result['stock'],
                'status': result['status'],
              };
            }
            
            // Also update in the main list
            final mainIndex = widget.allProducts.indexWhere((p) => (p['_id'] ?? p['id'] ?? p['productId']) == productId);
            if (mainIndex != -1) {
              widget.allProducts[mainIndex] = {
                ...widget.allProducts[mainIndex],
                'name': result['name'],
                'description': result['description'],
                'price': result['price'],
                'stock': result['stock'],
                'status': result['status'],
              };
            }
          });

          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Product updated successfully',
              type: MessageType.success,
            );
          }
        } else {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: updateResult['message'] ?? 'Failed to update product',
              type: MessageType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Error updating product: $e',
            type: MessageType.error,
          );
        }
      }
    }
  }

  // View product details functionality
  Future<void> _viewProductDetails(Map<String, dynamic> product) async {
    // Debug: Print all available fields
    debugPrint('Product data fields: ${product.keys.toList()}');
    debugPrint('Product data: $product');
    
    // Try to enhance product data with brand information if missing
    final enhancedProduct = Map<String, dynamic>.from(product);
    if (enhancedProduct['brand'] == null || enhancedProduct['brand'] == 'N/A') {
      final extractedBrand = _getBrandName(product);
      if (extractedBrand != 'N/A') {
        enhancedProduct['brand'] = extractedBrand;
        debugPrint('Enhanced product with brand: $extractedBrand');
      }
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name'] ?? 'Product Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image (if available)
              if (product['images'] != null && (product['images'] as List).isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      (product['images'] as List).first['url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              
              if (product['images'] != null && (product['images'] as List).isNotEmpty)
                const SizedBox(height: 16),
              
              // Product Information - Use enhanced product data
              _buildDetailRow('Category', enhancedProduct['category'] ?? 'N/A'),
              _buildDetailRow('Brand', _getBrandName(enhancedProduct)),
              _buildDetailRow('Item Name', _getItemName(enhancedProduct)),
              _buildDetailRow('Price', '₹${enhancedProduct['price']?.toString() ?? '0'}'),
              _buildDetailRow('Stock', enhancedProduct['stock']?.toString() ?? '0'),
              _buildDetailRow('Status', enhancedProduct['status']?.toString().toUpperCase() ?? 'N/A'),
              
              if (enhancedProduct['description'] != null && enhancedProduct['description'].isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  enhancedProduct['description'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: product['status'] == 'active'
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: product['status'] == 'active' ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product['status'] == 'active' ? Icons.check_circle : Icons.cancel,
                      color: product['status'] == 'active' ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product['status'] == 'active' ? 'Active Product' : 'Inactive Product',
                      style: TextStyle(
                        color: product['status'] == 'active' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editProduct(product);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getBrandName(Map<String, dynamic> product) {
    // Debug: Print all product data for comprehensive analysis
    debugPrint('=== COMPREHENSIVE BRAND DEBUG ===');
    debugPrint('Product name: ${product['name']}');
    debugPrint('Product category: ${product['category']}');
    debugPrint('All product keys: ${product.keys.toList()}');
    debugPrint('Full product data: $product');
    
    // First priority: Direct brand field from API (should now be available)
    final directBrand = product['brand']?.toString();
    if (directBrand != null && directBrand.isNotEmpty && directBrand != 'N/A') {
      debugPrint('Found direct brand from API: $directBrand');
      return directBrand;
    }
    
    // Try other possible brand field variations
    final possibleBrandFields = [
      'brandName', 'productBrand', 'brand_name', 'product_brand',
      'brandId', 'brand_id', 'brandInfo', 'brand_info', 'manufacturer',
      'company', 'vendor', 'supplier', 'make', 'model'
    ];
    
    for (final field in possibleBrandFields) {
      final value = product[field];
      if (value != null && value.toString().isNotEmpty) {
        debugPrint('Found brand in field "$field": $value');
        return value.toString();
      }
    }
    
    // Try nested brand objects
    if (product['brand'] is Map) {
      final brandMap = product['brand'] as Map<String, dynamic>;
      debugPrint('Brand is a Map: $brandMap');
      for (final key in ['name', 'title', 'label', 'value']) {
        if (brandMap[key] != null && brandMap[key].toString().isNotEmpty) {
          debugPrint('Found brand in nested field "$key": ${brandMap[key]}');
          return brandMap[key].toString();
        }
      }
    }
    
    // Try to find brand from available brands list
    for (final availableBrand in _availableBrands) {
      if (product.toString().toLowerCase().contains(availableBrand.toLowerCase())) {
        debugPrint('Found brand from available brands: $availableBrand');
        return availableBrand;
      }
    }
    
    // Try to extract brand from product name (common brand names)
    final productName = product['name']?.toString().toLowerCase() ?? '';
    final commonBrands = ['boat', 'sony', 'samsung', 'apple', 'xiaomi', 'oneplus', 'realme', 'oppo', 'vivo', 'huawei', 'lg', 'panasonic', 'jbl', 'bose', 'sennheiser', 'audio-technica', 'shure', 'akg', 'marshall', 'beats'];
    
    for (final brand in commonBrands) {
      if (productName.contains(brand)) {
        debugPrint('Found brand from product name: $brand');
        return brand.toUpperCase();
      }
    }
    
    // Final fallback: Try to extract brand from product name using more sophisticated logic
    final productNameForBrand = product['name']?.toString() ?? '';
    if (productNameForBrand.isNotEmpty) {
      // Try to find brand at the beginning of the product name
      final words = productNameForBrand.split(' ');
      if (words.isNotEmpty) {
        final firstWord = words[0].toLowerCase();
        // Check if first word is a known brand
        for (final brand in commonBrands) {
          if (firstWord.contains(brand) || brand.contains(firstWord)) {
            debugPrint('Found brand from first word: $brand');
            return brand.toUpperCase();
          }
        }
      }
    }
    
    debugPrint('No brand found - returning N/A');
    debugPrint('===============================');
    return 'N/A';
  }

  String _getItemName(Map<String, dynamic> product) {
    // Try different possible field names for item name
    final itemName = product['itemName'] ?? 
                     product['productName'] ?? 
                     product['name'];
    
    if (itemName != null && itemName.toString().isNotEmpty) {
      return itemName.toString();
    }
    
    return 'N/A';
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _clearFilters() {
    setState(() {
      _selectedBrand = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _filterProducts();
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          CustomTextField(
            controller: _searchController,
            labelText: 'Search products',
            hintText: 'Search by name or description...',
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          
          // Brand Filter
          Row(
            children: [
              const Text(
                'Filter by Brand:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:                 DropdownButtonFormField<String>(
                  initialValue: _selectedBrand,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: 'All Brands',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Brands'),
                    ),
                    ..._availableBrands.map((brand) {
                      return DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand),
                      );
                    }),
                  ],
                  onChanged: _onBrandFilterChanged,
                ),
              ),
              const SizedBox(width: 16),
              if (_selectedBrand != null || _searchQuery.isNotEmpty)
                IconButton(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear filters',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Form(
        key: _addProductFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Product',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _toggleAddProductForm,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close form',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Product Name
            CustomTextField(
              controller: _productNameController,
              labelText: 'Product Name',
              hintText: 'Enter product name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Brand Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedProductBrand,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Select a brand'),
              items: _availableBrands.map((brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(brand),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProductBrand = newValue;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a brand';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Product Description
            CustomTextField(
              controller: _productDescriptionController,
              labelText: 'Description',
              hintText: 'Enter product description',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Price and Stock Row
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _productPriceController,
                    labelText: 'Price (₹)',
                    hintText: '0.00',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _productStockController,
                    labelText: 'Stock',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Stock is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter valid stock';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreatingProduct ? null : _toggleAddProductForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreatingProduct ? null : _createProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isCreatingProduct
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create Product'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${product['price']?.toString() ?? '0'}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Brand Badge
            Builder(
              builder: (context) {
                final brand = _getBrandName(product);
                if (brand != 'N/A' && brand.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      brand,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            
            // Description
            if (product['description'] != null && product['description'].isNotEmpty)
              Text(
                product['description'],
                style: const TextStyle(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            
            // Stock and Status
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${product['stock']?.toString() ?? '0'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product['status'] == 'active'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: product['status'] == 'active'
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Action buttons
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Edit button (left corner)
                  ElevatedButton.icon(
                    onPressed: () => _editProduct(product),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(80, 36),
                    ),
                  ),
                  
                  // Eye button (middle) - View product details
                  IconButton(
                    onPressed: () => _viewProductDetails(product),
                    icon: Icon(
                      product['status'] == 'active' ? Icons.visibility : Icons.visibility_off,
                      color: product['status'] == 'active' ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                    tooltip: product['status'] == 'active' ? 'Product is active' : 'Product is inactive',
                    style: IconButton.styleFrom(
                      backgroundColor: product['status'] == 'active' 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  
                  // Delete button (right side)
                  ElevatedButton.icon(
                    onPressed: () => _deleteProduct(product),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(80, 36),
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

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedBrand != null
                  ? 'No products found matching your filters'
                  : 'No products found in this category',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty || _selectedBrand != null)
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add New Product',
            onPressed: _toggleAddProductForm,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh products',
            onPressed: _loadFreshProducts,
          ),
          if (_availableBrands.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by brand',
              onSelected: _onBrandFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: null,
                  child: Text('All Brands'),
                ),
                ..._availableBrands.map((brand) {
                  return PopupMenuItem<String>(
                    value: brand,
                    child: Text(brand),
                  );
                }),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFilterSection(),
            if (_showAddProductForm) _buildAddProductForm(),
            _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildProductsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAddProductForm,
        tooltip: 'Add New Product',
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Edit Product Dialog
class _EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const _EditProductDialog({required this.product});

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.product['description'] ?? '');
    _priceController = TextEditingController(text: widget.product['price']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product['stock']?.toString() ?? '');
    _status = widget.product['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Name
              CustomTextField(
                controller: _nameController,
                labelText: 'Product Name',
                hintText: 'Enter product name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Enter product description',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Price and Stock Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      labelText: 'Price (₹)',
                      hintText: '0.00',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter valid price';
                        }
                        if (double.parse(value) < 0) {
                          return 'Price cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _stockController,
                      labelText: 'Stock',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Stock is required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter valid stock';
                        }
                        if (int.parse(value) < 0) {
                          return 'Stock cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final result = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'status': _status,
      };
      Navigator.of(context).pop(result);
    }
  }
}
