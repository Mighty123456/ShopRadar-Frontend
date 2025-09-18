import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';
import '../services/shop_service.dart';

class OfferPromotionScreen extends StatefulWidget {
  const OfferPromotionScreen({super.key});

  @override
  State<OfferPromotionScreen> createState() => _OfferPromotionScreenState();
}

class _OfferPromotionScreenState extends State<OfferPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offerTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxUsesController = TextEditingController();
  
  String _selectedType = 'Percentage';
  String _selectedTarget = 'All Customers';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingOfferId;
  bool _isLoadingOffers = false;
  
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload products when screen becomes active
    _loadProducts();
  }

  @override
  void dispose() {
    _offerTitleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingOffers = true;
    });

    try {
      final result = await ShopService.getMyOffers();
      if (result['success'] == true) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      } else {
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to load offers',
            type: MessageType.error,
            title: 'Load Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error loading offers: ${e.toString()}',
          type: MessageType.error,
          title: 'Load Error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOffers = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      debugPrint('Loading products for offer creation...');
      // Load all products regardless of status for offer creation
      final result = await ShopService.getMyProducts(
        status: 'all', // Include all statuses
        limit: 100, // Load more products
      );
      debugPrint('Products result: $result');
      
      if (result['success'] == true) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(result['products'] ?? []);
        });
        debugPrint('Loaded ${_products.length} products for offers');
      } else {
        debugPrint('Failed to load products: ${result['message']}');
        if (mounted) {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to load products',
            type: MessageType.error,
            title: 'Load Error',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error loading products: ${e.toString()}',
          type: MessageType.error,
          title: 'Load Error',
        );
      }
    }
  }

  void _addNewOffer() {
    debugPrint('Attempting to add new offer. Products count: ${_products.length}');
    debugPrint('Products list: $_products');
    
    if (_products.isEmpty) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'No products available. Please add a product first before creating offers.',
        type: MessageType.warning,
        title: 'No Products',
      );
      return;
    }
    
    setState(() {
      _isEditing = false;
      _editingOfferId = null;
      _selectedProduct = null;
      _clearForm();
    });
    _showProductSelectionDialog();
  }

  void _editOffer(Map<String, dynamic> offer) {
    setState(() {
      _isEditing = true;
      _editingOfferId = offer['_id'] ?? offer['id'];
      _offerTitleController.text = offer['title'] ?? '';
      _descriptionController.text = offer['description'] ?? '';
      _discountController.text = offer['discountValue']?.toString() ?? '0';
      _maxUsesController.text = offer['maxUses']?.toString() ?? '0';
      _selectedType = offer['discountType'] ?? 'Percentage';
      _selectedTarget = 'All Customers'; // Default since API doesn't have target field
      _startDate = DateTime.parse(offer['startDate']);
      _endDate = DateTime.parse(offer['endDate']);
    });
    _showOfferDialog();
  }

  void _clearForm() {
    _offerTitleController.clear();
    _descriptionController.clear();
    _discountController.clear();
    _maxUsesController.clear();
    _selectedType = 'Percentage';
    _selectedTarget = 'All Customers';
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _selectedProduct = null;
  }

  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Product for Offer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            Icons.inventory_2,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: Text(
                          product['name'] ?? 'Unknown Product',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${product['category'] ?? 'N/A'}'),
                            Text('Price: ₹${product['price']?.toString() ?? '0'}'),
                            Text('Stock: ${product['stock']?.toString() ?? '0'}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          setState(() {
                            _selectedProduct = product;
                          });
                          Navigator.of(context).pop();
                          _showOfferDialog();
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferDialog() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isTablet ? 20 : 16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: isTablet ? 600 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTablet ? 20 : 16),
                    topRight: Radius.circular(isTablet ? 20 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEditing ? Icons.edit : Icons.local_offer,
                      color: Colors.white,
                      size: isTablet ? 28 : 24,
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Text(
                      _isEditing ? 'Edit Offer' : 'Create New Offer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Show selected product information
              if (_selectedProduct != null && !_isEditing)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.inventory_2,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Product',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _selectedProduct!['name'] ?? 'Unknown Product',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '₹${_selectedProduct!['price']?.toString() ?? '0'} • ${_selectedProduct!['category'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedProduct = null;
                          });
                          Navigator.of(context).pop();
                          _showProductSelectionDialog();
                        },
                        child: Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _offerTitleController,
                          labelText: 'Offer Title',
                          hintText: 'Enter offer title',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter offer title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          controller: _descriptionController,
                          labelText: 'Description',
                          hintText: 'Describe your offer',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter offer description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isStack = constraints.maxWidth < 380;
                            final Widget typeField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Discount Type',
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
                                      value: _selectedType,
                                      isExpanded: true,
                                      hint: const Text('Select type'),
                                      items: const [
                                        DropdownMenuItem(value: 'Percentage', child: Text('Percentage (%)')),
                                        DropdownMenuItem(value: 'Fixed Amount', child: Text('Fixed Amount (\$)')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                            final Widget valueField = CustomTextField(
                              controller: _discountController,
                              labelText: _selectedType == 'Percentage' ? 'Discount (%)' : 'Amount (\$)',
                              hintText: _selectedType == 'Percentage' ? '20' : '10',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter value';
                                }
                                final val = double.tryParse(value);
                                if (val == null || val <= 0) {
                                  return 'Please enter valid value';
                                }
                                if (_selectedType == 'Percentage' && val > 100) {
                                  return 'Percentage cannot exceed 100%';
                                }
                                return null;
                              },
                            );
                            if (isStack) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  typeField,
                                  const SizedBox(height: 16),
                                  valueField,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: typeField),
                                const SizedBox(width: 16),
                                Expanded(child: valueField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Target Audience',
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
                                  value: _selectedTarget,
                                  isExpanded: true,
                                  hint: const Text('Select target'),
                                  items: const [
                                    DropdownMenuItem(value: 'All Customers', child: Text('All Customers')),
                                    DropdownMenuItem(value: 'New Customers', child: Text('New Customers')),
                                    DropdownMenuItem(value: 'Returning Customers', child: Text('Returning Customers')),
                                    DropdownMenuItem(value: 'VIP Customers', child: Text('VIP Customers')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTarget = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isStack = constraints.maxWidth < 380;
                            final Widget startField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _startDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                            final Widget endField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate,
                                      firstDate: _startDate,
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _endDate = date;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                            if (isStack) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  startField,
                                  const SizedBox(height: 16),
                                  endField,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: startField),
                                const SizedBox(width: 16),
                                Expanded(child: endField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          controller: _maxUsesController,
                          labelText: 'Maximum Uses',
                          hintText: '100',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter maximum uses';
                            }
                            final val = int.tryParse(value);
                            if (val == null || val <= 0) {
                              return 'Please enter valid number';
                            }
                            return null;
                          },
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
                                  : (_isEditing ? 'Update Offer' : 'Create Offer'),
                                onPressed: _isLoading ? null : _saveOffer,
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

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if products are available for creating offers
    if (_products.isEmpty) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'No products available. Please add a product first before creating offers.',
        type: MessageType.warning,
        title: 'No Products',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing) {
        // Update existing offer
        final result = await ShopService.updateOffer(
          offerId: _editingOfferId!,
          title: _offerTitleController.text.trim(),
          description: _descriptionController.text.trim(),
          discountType: _selectedType,
          discountValue: double.parse(_discountController.text),
          startDate: _startDate,
          endDate: _endDate,
          maxUses: int.parse(_maxUsesController.text),
        );

        if (mounted) {
          if (result['success'] == true) {
            Navigator.of(context).pop();
            await _loadOffers(); // Refresh the offers list
            
            if (!mounted) return;
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Offer updated successfully!',
              type: MessageType.success,
              title: 'Offer Updated',
            );
            _clearForm();
          } else {
            MessageHelper.showAnimatedMessage(
              context,
              message: result['message'] ?? 'Failed to update offer',
              type: MessageType.error,
              title: 'Update Failed',
            );
          }
        }
      } else {
        // Create new offer - use the selected product
        if (_selectedProduct == null) {
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Please select a product for the offer.',
            type: MessageType.warning,
            title: 'No Product Selected',
          );
          return;
        }
        
        final productId = _selectedProduct!['_id'] ?? _selectedProduct!['id'];
        
        final result = await ShopService.createOffer(
          productId: productId,
          title: _offerTitleController.text.trim(),
          description: _descriptionController.text.trim(),
          discountType: _selectedType,
          discountValue: double.parse(_discountController.text),
          startDate: _startDate,
          endDate: _endDate,
          maxUses: int.parse(_maxUsesController.text),
        );

        debugPrint('Offer creation result: $result');
        debugPrint('Success value: ${result['success']}');
        debugPrint('Success type: ${result['success'].runtimeType}');

        if (mounted) {
          if (result['success'] == true) {
            Navigator.of(context).pop();
            await _loadOffers(); // Refresh the offers list
            
            if (!mounted) return;
            MessageHelper.showAnimatedMessage(
              context,
              message: 'Offer created successfully!',
              type: MessageType.success,
              title: 'Offer Created',
            );
            _clearForm();
          } else {
            MessageHelper.showAnimatedMessage(
              context,
              message: result['message'] ?? 'Failed to create offer',
              type: MessageType.error,
              title: 'Creation Failed',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error saving offer: ${e.toString()}',
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

  Future<void> _toggleOfferStatus(String offerId) async {
    try {
      final result = await ShopService.toggleOfferStatus(offerId);
      
      if (mounted) {
        if (result['success'] == true) {
          await _loadOffers(); // Refresh the offers list
          
          if (!mounted) return;
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Offer status updated successfully!',
            type: MessageType.success,
            title: 'Status Updated',
          );
        } else {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to update offer status',
            type: MessageType.error,
            title: 'Update Failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error updating offer status: ${e.toString()}',
          type: MessageType.error,
          title: 'Update Error',
        );
      }
    }
  }

  void _deleteOffer(String offerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete(offerId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String offerId) async {
    try {
      final result = await ShopService.deleteOffer(offerId);
      
      if (mounted) {
        if (result['success'] == true) {
          await _loadOffers(); // Refresh the offers list
          
          if (!mounted) return;
          MessageHelper.showAnimatedMessage(
            context,
            message: 'Offer deleted successfully!',
            type: MessageType.success,
            title: 'Offer Deleted',
          );
        } else {
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to delete offer',
            type: MessageType.error,
            title: 'Delete Failed',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error deleting offer: ${e.toString()}',
          type: MessageType.error,
          title: 'Delete Error',
        );
      }
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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: isTablet ? 28 : 24,
                        ),
                        tooltip: 'Back',
                      ),
                      SizedBox(width: isTablet ? 8 : 4),
                      Expanded(
                        child: Text(
                          'Offer Management',
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
                          text: 'Create Offer',
                          onPressed: _addNewOffer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () async {
                          await _loadProducts();
                          await _loadOffers();
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.blue,
                        ),
                        tooltip: 'Refresh Products',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: _isLoadingOffers
                ? const Center(child: CircularProgressIndicator())
                : _offers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      return _buildOfferCard(offer);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: isTablet ? 100 : 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'No offers yet',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Start by creating your first offer',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          CustomButton(
            text: 'Create First Offer',
            onPressed: _addNewOffer,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    // Parse dates from API response
    final startDate = DateTime.parse(offer['startDate']);
    final endDate = DateTime.parse(offer['endDate']);
    final isExpired = endDate.isBefore(DateTime.now());
    final isActive = offer['status'] == 'active';
    
    // Calculate usage percentage safely
    final currentUses = offer['currentUses'] ?? 0;
    final maxUses = offer['maxUses'] ?? 0;
    final usagePercentage = maxUses > 0 ? (currentUses / maxUses) * 100 : 0;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer['title'] ?? 'Untitled Offer',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive && !isExpired ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive && !isExpired ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show product information if available
                if (offer['productId'] != null && offer['productId']['name'] != null)
                  Container(
                    margin: EdgeInsets.only(top: isTablet ? 8 : 6),
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8, vertical: isTablet ? 6 : 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: isTablet ? 16 : 14,
                          color: Colors.blue.shade700,
                        ),
                        SizedBox(width: isTablet ? 8 : 6),
                        Text(
                          'Product: ${offer['productId']['name']}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  offer['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        offer['discountType'] == 'Percentage' 
                          ? '${offer['discountValue']?.toStringAsFixed(0) ?? '0'}% OFF'
                          : '\$${offer['discountValue']?.toStringAsFixed(2) ?? '0.00'} OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'All Customers', // Default since API doesn't have target field
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$currentUses/$maxUses',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usagePercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                if (isExpired) const SizedBox(width: 8),
                
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleOfferStatus(offer['_id'] ?? offer['id']),
                      icon: Icon(
                        isActive ? Icons.visibility_off : Icons.visibility,
                        color: isActive ? Colors.orange : Colors.green,
                      ),
                      tooltip: isActive ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      onPressed: () => _editOffer(offer),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteOffer(offer['_id'] ?? offer['id']),
                      icon: const Icon(Icons.delete, color: Colors.red),
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
