import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';
import '../services/shop_service.dart';
import 'unified_product_offer_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingProductId;
  bool _isLoadingProducts = false;
  
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final result = await ShopService.getMyProducts();
      
      if (result['success'] == true) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(result['products'] ?? []);
        });
      } else {
        if (mounted) {
          // Check if the error is due to no shop being registered
          final message = result['message'] ?? 'Failed to load products';
          if (message.contains('No shop found') || message.contains('shop not found')) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'No shop found. Please register your shop first.',
              type: MessageType.warning,
              title: 'Shop Registration Required',
            );
          } else {
            MessageHelper.showAnimatedMessage(
              context,
              message: message,
              type: MessageType.error,
              title: 'Load Failed',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error loading products: ${e.toString()}',
          type: MessageType.error,
          title: 'Load Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  void _addNewProduct() {
    setState(() {
      _isEditing = false;
      _editingProductId = null;
      _clearForm();
    });
    _showProductDialog();
  }

  void _addProductWithOffer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UnifiedProductOfferScreen(),
      ),
    ).then((_) {
      // Refresh the product list when returning from the unified screen
      _loadProducts();
    });
  }

  void _editProduct(Map<String, dynamic> product) {
    setState(() {
      _isEditing = true;
      _editingProductId = product['id'];
      _productNameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = (product['price'] ?? 0).toString();
      _stockController.text = (product['stock'] ?? 0).toString();
      _selectedCategory = product['category'] ?? 'Electronics';
    });
    _showProductDialog();
  }

  void _clearForm() {
    _productNameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear();
    _selectedCategory = 'Electronics';
  }

  void _showProductDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2979FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEditing ? Icons.edit : Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _productNameController,
                          labelText: 'Product Name',
                          hintText: 'Enter product name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          controller: _descriptionController,
                          labelText: 'Description',
                          hintText: 'Enter product description',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter product description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Category Selection
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  hint: const Text('Select category'),
                                  items: const [
                                    DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                                    DropdownMenuItem(value: 'Clothing', child: Text('Clothing')),
                                    DropdownMenuItem(value: 'Food & Beverages', child: Text('Food & Beverages')),
                                    DropdownMenuItem(value: 'Home & Garden', child: Text('Home & Garden')),
                                    DropdownMenuItem(value: 'Sports & Outdoors', child: Text('Sports & Outdoors')),
                                    DropdownMenuItem(value: 'Beauty & Health', child: Text('Beauty & Health')),
                                    DropdownMenuItem(value: 'Books & Media', child: Text('Books & Media')),
                                    DropdownMenuItem(value: 'Automotive', child: Text('Automotive')),
                                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _priceController,
                                labelText: 'Price (\$)',
                                hintText: '0.00',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter price';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter valid price';
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
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter stock';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Please enter valid stock';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomButton(
                                text: _isLoading 
                                  ? 'Saving...' 
                                  : (_isEditing ? 'Update Product' : 'Add Product'),
                                onPressed: _isLoading ? null : _saveProduct,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing && _editingProductId != null) {
        // Update existing product
        final result = await ShopService.updateMyProduct(
          productId: _editingProductId!,
          name: _productNameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
        );

        if (result['success'] == true) {
          if (mounted) {
            Navigator.of(context).pop();
            _loadProducts(); // Refresh the product list
            
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Product updated successfully!',
              type: MessageType.success,
              title: 'Product Updated',
            );
            
            _clearForm();
          }
        } else {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: result['message'] ?? 'Failed to update product',
              type: MessageType.error,
              title: 'Update Failed',
            );
          }
        }
      } else {
        // Create new product using the unified endpoint
        final productData = {
          'name': _productNameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'price': double.parse(_priceController.text),
          'stock': int.parse(_stockController.text),
        };

        final result = await ShopService.createProductWithOffer(
          productData: productData,
        );

        if (result['success'] == true) {
          if (mounted) {
            Navigator.of(context).pop();
            _loadProducts(); // Refresh the product list
            
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Product added successfully!',
              type: MessageType.success,
              title: 'Product Added',
            );
            
            _clearForm();
          }
        } else {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: result['message'] ?? 'Failed to add product',
              type: MessageType.error,
              title: 'Add Failed',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error saving product: ${e.toString()}',
          type: MessageType.error,
          title: 'Save Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleProductStatus(String productId) async {
    try {
      final product = _products.firstWhere((p) => p['id'] == productId);
      final newStatus = product['status'] == 'active' ? 'removed' : 'active';
      
      final result = await ShopService.updateMyProduct(
        productId: productId,
        status: newStatus,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _loadProducts(); // Refresh the product list
        
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Product ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully!',
          type: MessageType.success,
          title: 'Status Updated',
        );
      } else {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to update product status',
          type: MessageType.error,
          title: 'Update Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Error updating product status: ${e.toString()}',
        type: MessageType.error,
        title: 'Update Error',
      );
    }
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete(productId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String productId) async {
    try {
      final result = await ShopService.deleteMyProduct(productId);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        _loadProducts(); // Refresh the product list
        
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Product deleted successfully!',
          type: MessageType.success,
          title: 'Product Deleted',
        );
      } else {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to delete product',
          type: MessageType.error,
          title: 'Delete Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Error deleting product: ${e.toString()}',
        type: MessageType.error,
        title: 'Delete Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Product Management',
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Add Product',
                          onPressed: _addNewProduct,
                          backgroundColor: const Color(0xFF2979FF),
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Add Product + Offer',
                          onPressed: _addProductWithOffer,
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(isTablet ? 24 : 16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _buildProductCard(product, screenSize);
                        },
                      ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: isTablet ? 100 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Start by adding your first product',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            CustomButton(
              text: 'Add First Product',
              onPressed: _addNewProduct,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, Size screenSize) {
    final isTablet = screenSize.width > 600;
    
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    color: Colors.grey[200],
                  ),
                  child: Icon(
                    Icons.inventory,
                    size: isTablet ? 50 : 40,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product['name'],
                              style: TextStyle(
                                fontSize: isTablet ? 22 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                            Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8, 
                              vertical: isTablet ? 6 : 4
                            ),
                            decoration: BoxDecoration(
                              color: product['status'] == 'active' ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            ),
                            child: Text(
                              product['status'] == 'active' ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Text(
                        product['description'],
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        '\$${product['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2979FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16, 
              vertical: isTablet ? 16 : 12
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(isTablet ? 16 : 12),
                bottomRight: Radius.circular(isTablet ? 16 : 12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory, 
                        size: isTablet ? 20 : 16, 
                        color: Colors.grey[600]
                      ),
                      SizedBox(width: isTablet ? 6 : 4),
                      Flexible(
                        child: Text(
                          'Stock: ${product['stock']}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 8),
                
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.category, 
                        size: isTablet ? 20 : 16, 
                        color: Colors.grey[600]
                      ),
                      SizedBox(width: isTablet ? 6 : 4),
                      Flexible(
                        child: Text(
                          product['category'],
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleProductStatus(product['id']),
                      icon: Icon(
                        product['status'] == 'active' ? Icons.visibility_off : Icons.visibility,
                        color: product['status'] == 'active' ? Colors.orange : Colors.green,
                        size: isTablet ? 24 : 20,
                      ),
                      tooltip: product['status'] == 'active' ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      onPressed: () => _editProduct(product),
                      icon: Icon(
                        Icons.edit, 
                        color: Colors.blue,
                        size: isTablet ? 24 : 20,
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteProduct(product['id']),
                      icon: Icon(
                        Icons.delete, 
                        color: Colors.red,
                        size: isTablet ? 24 : 20,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
