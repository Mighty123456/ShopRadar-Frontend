import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/shop_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';
import 'category_products_screen.dart';
import 'offer_promotion_screen.dart';

class HierarchicalProductScreen extends StatefulWidget {
  const HierarchicalProductScreen({super.key});

  @override
  State<HierarchicalProductScreen> createState() => _HierarchicalProductScreenState();
}

class _HierarchicalProductScreenState extends State<HierarchicalProductScreen> {
  // Form keys for each step
  final _categoryFormKey = GlobalKey<FormState>();
  final _brandFormKey = GlobalKey<FormState>();
  final _itemFormKey = GlobalKey<FormState>();
  
  // Controllers
  final _categoryNameController = TextEditingController();
  final _categoryDescriptionController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _brandDescriptionController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  // State variables
  List<Category> _categories = [];
  Category? _selectedCategory;
  Brand? _selectedBrand;
  bool _isLoading = false;
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  int _currentStep = 0; // 0: Category, 1: Brand, 2: Item
  bool _showProductList = true; // Show product list by default
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescriptionController.dispose();
    _brandNameController.dispose();
    _brandDescriptionController.dispose();
    _itemNameController.dispose();
    _itemDescriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    final result = await CategoryService.getCategoryHierarchy();
    
    if (result['success'] == true) {
      setState(() {
        // Remove duplicates by converting to Set and back to List
        final List<Category> categories = result['data'] as List<Category>;
        _categories = categories.toSet().toList();
      });
    } else {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to load categories',
          type: MessageType.error,
          title: 'Error',
        );
      }
    }

    setState(() {
      _isLoadingCategories = false;
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final result = await ShopService.getMyProducts(limit: 100); // Get more products
      
      if (result['success'] == true) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(result['products'] ?? []);
        });
      } else {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to load products',
            type: MessageType.error,
            title: 'Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to load products',
          type: MessageType.error,
          title: 'Error',
        );
      }
    }

    setState(() {
      _isLoadingProducts = false;
    });
  }

  // Check if category has products
  bool _categoryHasProducts(String categoryName) {
    return _products.any((product) => product['category'] == categoryName);
  }

  // Delete category functionality
  Future<void> _deleteCategory(Category category) async {
    // Check if category has products
    if (_categoryHasProducts(category.name)) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Cannot delete category "${category.name}" because it contains products. Please delete all products in this category first.',
        type: MessageType.warning,
        title: 'Cannot Delete Category',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete the category "${category.name}"? This action cannot be undone.'),
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
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await CategoryService.deleteCategory(category.id);
        
        if (result['success']) {
          // Remove category from the list
          setState(() {
            _categories.removeWhere((c) => c.id == category.id);
          });
          
          // Show success message
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Category deleted successfully',
              type: MessageType.success,
            );
          }
        } else {
          if (mounted) {
            MessageHelper.showAnimatedMessage(
              context,
              message: result['message'] ?? 'Failed to delete category',
              type: MessageType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Error deleting category: $e',
            type: MessageType.error,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createCategory() async {
    if (!_categoryFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await CategoryService.createCategory(
      name: _categoryNameController.text.trim(),
      description: _categoryDescriptionController.text.trim().isEmpty 
          ? null 
          : _categoryDescriptionController.text.trim(),
    );

    if (result['success'] == true) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Category created successfully!',
          type: MessageType.success,
          title: 'Success',
        );
        
        final categoryName = _categoryNameController.text.trim();
        _categoryNameController.clear();
        _categoryDescriptionController.clear();
        await _loadCategories();
        
        // Auto-select the newly created category and advance to next step
        setState(() {
          _selectedCategory = _categories.firstWhere(
            (cat) => cat.name == categoryName,
            orElse: () => _categories.isNotEmpty ? _categories.first : Category(
              id: '',
              shopId: '',
              name: categoryName,
              brands: [],
              status: 'active',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          _currentStep = 1;
        });
      }
    } else {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to create category',
          type: MessageType.error,
          title: 'Error',
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addBrand() async {
    if (!_brandFormKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() {
      _isLoading = true;
    });

    final result = await CategoryService.addBrand(
      categoryId: _selectedCategory!.id,
      brandName: _brandNameController.text.trim(),
      brandDescription: _brandDescriptionController.text.trim().isEmpty 
          ? null 
          : _brandDescriptionController.text.trim(),
    );

    if (result['success'] == true) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Brand added successfully!',
          type: MessageType.success,
          title: 'Success',
        );
        
        _brandNameController.clear();
        _brandDescriptionController.clear();
        await _loadCategories();
        
        // Auto-advance to next step
        setState(() {
          _currentStep = 2;
        });
      }
    } else {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to add brand',
          type: MessageType.error,
          title: 'Error',
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createItem() async {
    if (!_itemFormKey.currentState!.validate() || _selectedCategory == null || _selectedBrand == null) return;

    setState(() {
      _isLoading = true;
    });

    final productData = {
      'name': _itemNameController.text.trim(),
      'description': _itemDescriptionController.text.trim(),
      'category': _selectedCategory!.name,
      'brand': _selectedBrand!.name,
      'itemName': _itemNameController.text.trim(),
      'price': double.parse(_priceController.text),
      'stock': int.parse(_stockController.text),
    };

    final result = await ShopService.createProductWithOffer(
      productData: productData,
      offerData: null, // No offer data for this flow
    );

    if (result['success'] == true) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Product created successfully! To make it visible to shoppers with offers, use the "Create Offer" button or go to the dashboard.',
          type: MessageType.success,
          title: 'Success',
        );
        
        _clearForm();
        setState(() {
          _currentStep = 0;
          _selectedCategory = null;
          _selectedBrand = null;
          _showProductList = true; // Show product list after creating item
        });
        await _loadProducts(); // Refresh product list
      }
    } else {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to create product',
          type: MessageType.error,
          title: 'Error',
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _clearForm() {
    _categoryNameController.clear();
    _categoryDescriptionController.clear();
    _brandNameController.clear();
    _brandDescriptionController.clear();
    _itemNameController.clear();
    _itemDescriptionController.clear();
    _priceController.clear();
    _stockController.clear();
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= 2) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  void _toggleView() {
    setState(() {
      _showProductList = !_showProductList;
      if (!_showProductList) {
        _currentStep = 0; // Reset to category step when showing creation interface
      }
    });
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Category'),
          _buildStepLine(),
          _buildStepCircle(1, 'Brand'),
          _buildStepLine(),
          _buildStepCircle(2, 'Item'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted 
                ? Theme.of(context).primaryColor 
                : Colors.grey[300],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 60,
      height: 2,
      color: _currentStep > 0 ? Theme.of(context).primaryColor : Colors.grey[300],
    );
  }

  Widget _buildCategoryStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1: Create Category',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new product category (e.g., Headphones, Laptops, etc.)',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Form(
            key: _categoryFormKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _categoryNameController,
                  labelText: 'Category Name',
                  hintText: 'e.g., Headphones',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _categoryDescriptionController,
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of the category',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Create Category',
                  onPressed: _isLoading ? null : _createCategory,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: Add Brand',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a brand to an existing category',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Category Selection
          if (_categories.isNotEmpty) ...[
            const Text('Select Category:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Category>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Choose a category'),
              items: _categories.map((category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (Category? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  _selectedBrand = null; // Reset brand selection
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Brand Creation Form
          if (_selectedCategory != null) ...[
            Form(
              key: _brandFormKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _brandNameController,
                    labelText: 'Brand Name',
                    hintText: 'e.g., Boat',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Brand name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _brandDescriptionController,
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of the brand',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Add Brand',
                    onPressed: _isLoading ? null : _addBrand,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ] else if (_categories.isEmpty) ...[
            const Center(
              child: Text(
                'No categories found. Please create a category first.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ] else ...[
            const Center(
              child: Text(
                'Please select a category above to add a brand.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3: Create Item',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a product item under a specific brand',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Category and Brand Selection
          if (_categories.isNotEmpty) ...[
            // Use Column for small screens, Row for larger screens
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Small screens: Stack vertically
                  return Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<Category>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Choose category'),
                            items: _categories.map((category) {
                              return DropdownMenuItem<Category>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (Category? newValue) {
                              setState(() {
                                _selectedCategory = newValue;
                                _selectedBrand = null; // Reset brand selection
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Brand:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<Brand>(
                            initialValue: _selectedBrand,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            hint: const Text('Choose brand'),
                            items: _selectedCategory?.brands.map((brand) {
                              return DropdownMenuItem<Brand>(
                                value: brand,
                                child: Text(brand.name),
                              );
                            }).toList() ?? [],
                            onChanged: (Brand? newValue) {
                              setState(() {
                                _selectedBrand = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a brand';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Large screens: Side by side
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                            const SizedBox(height: 4),
                      DropdownButtonFormField<Category>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Choose category'),
                        items: _categories.map((category) {
                          return DropdownMenuItem<Category>(
                            value: category,
                            child: Text(category.name),
                          );
                        }).toList(),
                              onChanged: (Category? newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                  _selectedBrand = null; // Reset brand selection
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Brand:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                            const SizedBox(height: 4),
                      DropdownButtonFormField<Brand>(
                        initialValue: _selectedBrand,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('Choose brand'),
                        items: _selectedCategory?.brands.map((brand) {
                          return DropdownMenuItem<Brand>(
                            value: brand,
                            child: Text(brand.name),
                          );
                        }).toList() ?? [],
                              onChanged: (Brand? newValue) {
                                setState(() {
                                  _selectedBrand = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a brand';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          // Item Creation Form
          if (_selectedCategory != null && _selectedBrand != null) ...[
            Form(
              key: _itemFormKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _itemNameController,
                    labelText: 'Item Name',
                    hintText: 'e.g., Boat Rockerz 450',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Item name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _itemDescriptionController,
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of the item',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
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
                              return 'Enter a valid price';
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
                              return 'Enter a valid stock';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Create Item',
                    onPressed: _isLoading ? null : _createItem,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ] else if (_categories.isEmpty) ...[
            const Center(
              child: Text(
                'No categories found. Please create a category first.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ] else if (_selectedCategory == null) ...[
            const Center(
              child: Text(
                'Please select a category first.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ] else if (_selectedBrand == null) ...[
            const Center(
              child: Text(
                'Please select a brand first.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductList() {
    // Group products by category
    Map<String, List<Map<String, dynamic>>> groupedProducts = {};
    
    for (var product in _products) {
      final category = product['category'] ?? 'Uncategorized';
      
      if (!groupedProducts.containsKey(category)) {
        groupedProducts[category] = [];
      }
      groupedProducts[category]!.add(product);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'My Products',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: CustomButton(
                        text: 'Create Offer',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OfferPromotionScreen(),
                            ),
                          );
                        },
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: CustomButton(
                        text: 'New Add Product',
                        onPressed: _toggleView,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingProducts)
            const Center(child: CircularProgressIndicator())
          else if (_products.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first product using the "Add New Product" button',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Add notice about offers
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make your products visible to shoppers!',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create offers for your products to appear in search results and attract customers.',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
              child: ListView.builder(
                itemCount: groupedProducts.length,
                itemBuilder: (context, categoryIndex) {
                  final categoryName = groupedProducts.keys.elementAt(categoryIndex);
                  final categoryProducts = groupedProducts[categoryName]!;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Icon(
                        _getCategoryIcon(categoryName),
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      title: Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${categoryProducts.length} products',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                              '${categoryProducts.length} items',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete category button
                          IconButton(
                            onPressed: () {
                              // Find the category object
                              final category = _categories.firstWhere(
                                (cat) => cat.name == categoryName,
                                orElse: () => Category(
                                  id: '',
                                  shopId: '',
                                  name: categoryName,
                                  brands: [],
                                  status: 'active',
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );
                              _deleteCategory(category);
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            tooltip: 'Delete Category',
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryProductsScreen(
                              categoryName: categoryName,
                              allProducts: _products,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'headphones':
      case 'audio':
        return Icons.headphones;
      case 'electronics':
        return Icons.devices;
      case 'clothing':
        return Icons.checkroom;
      case 'books':
        return Icons.menu_book;
      case 'food':
        return Icons.restaurant;
      case 'sports':
        return Icons.sports;
      case 'beauty':
        return Icons.face;
      case 'home':
        return Icons.home;
      case 'automotive':
        return Icons.directions_car;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showProductList ? 'My Products' : 'Add Product'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_showProductList) ...[
            if (_currentStep > 0)
              TextButton(
                onPressed: () => _goToStep(_currentStep - 1),
                child: const Text(
                  'Previous',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            if (_currentStep < 2)
              TextButton(
                onPressed: () => _goToStep(_currentStep + 1),
                child: const Text(
                  'Next',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
          IconButton(
            onPressed: _toggleView,
            icon: Icon(_showProductList ? Icons.add : Icons.list),
            tooltip: _showProductList ? 'Add Product' : 'View Products',
          ),
        ],
      ),
      body: _showProductList
          ? _buildProductList()
          : _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStepIndicator(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _currentStep == 0
                            ? _buildCategoryStep()
                            : _currentStep == 1
                                ? _buildBrandStep()
                                : _buildItemStep(),
                      ),
                    ),
                  ],
                ),
    );
  }
}