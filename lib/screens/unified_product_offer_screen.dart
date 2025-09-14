import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';
import '../services/shop_service.dart';

class UnifiedProductOfferScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedProduct;
  
  const UnifiedProductOfferScreen({super.key, this.selectedProduct});

  @override
  State<UnifiedProductOfferScreen> createState() => _UnifiedProductOfferScreenState();
}

class _UnifiedProductOfferScreenState extends State<UnifiedProductOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _offerTitleController = TextEditingController();
  final _offerDescriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxUsesController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  String _selectedUnitType = 'Piece';
  String _selectedAvailabilityStatus = 'In Stock';
  String _selectedDiscountType = 'Percentage';
  DateTime _offerStartDate = DateTime.now();
  DateTime _offerEndDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  bool _hasOffer = false;
  bool _isEditingExisting = false;
  File? _productImage;
  String? _productImageName;
  File? _productVideo;
  String? _productVideoName;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Food & Beverages',
    'Home & Garden',
    'Sports & Outdoors',
    'Books & Media',
    'Health & Beauty',
    'Automotive',
    'Toys & Games',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedProduct != null) {
      _isEditingExisting = true;
      _hasOffer = true; // If editing existing product, assume we're adding an offer
      _populateExistingProduct();
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _offerTitleController.dispose();
    _offerDescriptionController.dispose();
    _discountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  void _populateExistingProduct() {
    final product = widget.selectedProduct!;
    _productNameController.text = product['name'] ?? '';
    _brandController.text = product['brand'] ?? '';
    _modelController.text = product['model'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _tagsController.text = product['tags'] ?? '';
    _priceController.text = (product['price'] ?? 0).toString();
    _stockController.text = (product['stock'] ?? 0).toString();
    _selectedCategory = product['category'] ?? 'Electronics';
    _selectedUnitType = product['unitType'] ?? 'Piece';
    _selectedAvailabilityStatus = product['availabilityStatus'] ?? 'In Stock';
  }

  double _calculateFinalPrice() {
    try {
      final originalPrice = double.parse(_priceController.text);
      final discountValue = double.parse(_discountController.text);
      
      if (_selectedDiscountType == 'Percentage') {
        return originalPrice - (originalPrice * discountValue / 100);
      } else {
        return originalPrice - discountValue;
      }
    } catch (e) {
      return 0.0;
    }
  }

  String _getOfferStatusText() {
    final now = DateTime.now();
    if (_offerStartDate.isAfter(now)) {
      return 'Upcoming';
    } else if (_offerEndDate.isBefore(now)) {
      return 'Expired';
    } else {
      return 'Active';
    }
  }

  Color _getOfferStatusColor() {
    final now = DateTime.now();
    if (_offerStartDate.isAfter(now)) {
      return Colors.orange;
    } else if (_offerEndDate.isBefore(now)) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  IconData _getOfferStatusIcon() {
    final now = DateTime.now();
    if (_offerStartDate.isAfter(now)) {
      return Icons.schedule;
    } else if (_offerEndDate.isBefore(now)) {
      return Icons.cancel;
    } else {
      return Icons.check_circle;
    }
  }

  Future<void> _pickProductImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _productImage = File(file.path!);
            _productImageName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error picking image: $e',
          type: MessageType.error,
          title: 'Image Error',
        );
      }
    }
  }

  Future<void> _pickProductVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _productVideo = File(file.path!);
            _productVideoName = file.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Error picking video: $e',
          type: MessageType.error,
          title: 'Video Error',
        );
      }
    }
  }

  Future<void> _selectOfferStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _offerStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _offerStartDate = date;
        if (_offerEndDate.isBefore(_offerStartDate)) {
          _offerEndDate = _offerStartDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _selectOfferEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _offerEndDate,
      firstDate: _offerStartDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _offerEndDate = date;
      });
    }
  }

  Future<void> _saveProductWithOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare product data
      final productData = {
        'name': _productNameController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tags': _tagsController.text.trim(),
        'category': _selectedCategory,
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'unitType': _selectedUnitType,
        'availabilityStatus': _selectedAvailabilityStatus,
        'image': _productImage,
        'video': _productVideo,
      };

      // Prepare offer data if offer is enabled
      Map<String, dynamic>? offerData;
      if (_hasOffer) {
        offerData = {
          'title': _offerTitleController.text.trim(),
          'description': _offerDescriptionController.text.trim(),
          'discountType': _selectedDiscountType,
          'discountValue': double.parse(_discountController.text),
          'maxUses': int.parse(_maxUsesController.text),
          'startDate': _offerStartDate.toIso8601String(),
          'endDate': _offerEndDate.toIso8601String(),
        };
      }

      // Call the unified API endpoint
      final result = await ShopService.createProductWithOffer(
        productData: productData,
        offerData: offerData,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          MessageHelper.showAnimatedMessage(
            context,
            message: _hasOffer 
              ? 'Product with offer created successfully!'
              : 'Product created successfully!',
            type: MessageType.success,
            title: 'Success',
          );
          
          // Navigate back to product management
          Navigator.of(context).pop();
        } else {
          // Add debug logging to understand what's happening
          debugPrint('Product creation failed. Result: $result');
          debugPrint('Success value: ${result['success']}');
          debugPrint('Success type: ${result['success'].runtimeType}');
          MessageHelper.showAnimatedMessage(
            context,
            message: result['message'] ?? 'Failed to create product',
            type: MessageType.error,
            title: 'Error',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to save product. Please try again.',
          type: MessageType.error,
          title: 'Save Failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        toolbarHeight: isTablet ? 70 : (isLargeScreen ? 80 : 56),
        title: Text(
          _isEditingExisting ? 'Add Offer to Product' : 'Add Product',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 24 : (isLargeScreen ? 28 : 20),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: Colors.white,
            size: isTablet ? 24 : 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Details Section
              _buildSectionHeader(
                'Product Details',
                Icons.inventory_2,
                const Color(0xFF2979FF),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              
              CustomTextField(
                controller: _productNameController,
                labelText: 'Product Name',
                hintText: 'e.g., Headphone, Rice Bag, Shirt',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _brandController,
                      labelText: 'Brand',
                      hintText: 'e.g., Sony, Boat, Samsung',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter brand';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _modelController,
                      labelText: 'Model / Variant',
                      hintText: 'e.g., Boat T800, iPhone 15 Pro',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Short details (e.g., "Noise-cancelling wireless headphones, 30 hrs battery")',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _tagsController,
                labelText: 'Tags / Keywords',
                hintText: 'e.g., "wireless, headphones, bluetooth, Sony"',
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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      labelText: 'Original Price (₹)',
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
                      labelText: 'Stock Quantity',
                      hintText: 'e.g., 10, 50, 100',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Unit Type and Availability Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedUnitType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Piece', child: Text('Piece')),
                            DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                            DropdownMenuItem(value: 'Liter', child: Text('Liter')),
                            DropdownMenuItem(value: 'Pack', child: Text('Pack')),
                            DropdownMenuItem(value: 'Box', child: Text('Box')),
                            DropdownMenuItem(value: 'Set', child: Text('Set')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedUnitType = value!;
                            });
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
                        const Text(
                          'Availability Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAvailabilityStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                            DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAvailabilityStatus = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Media Section
              _buildSectionHeader(
                'Media (Optional)',
                Icons.perm_media,
                const Color(0xFF9C27B0),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              
              // Product Image
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Product Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickProductImage,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: _productImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _productImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add product image',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_productImageName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _productImageName!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Product Video
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Product Video',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickProductVideo,
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: _productVideo != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  size: 40,
                                  color: Colors.blue[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _productVideoName!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.video_call,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add product video',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Offer Section Toggle
              _buildSectionHeader(
                'Discount Offer (Optional)',
                Icons.local_offer,
                const Color(0xFF4CAF50),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              
              Row(
                children: [
                  Switch(
                    value: _hasOffer,
                    onChanged: (value) {
                      setState(() {
                        _hasOffer = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditingExisting 
                        ? 'Add discount offer to this product'
                        : 'Add discount offer for this product',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _hasOffer ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Offer Fields (only show if offer is enabled)
              if (_hasOffer) ...[
                CustomTextField(
                  controller: _offerTitleController,
                  labelText: 'Offer Title',
                  hintText: 'e.g., Festive Sale, Weekend Deal, Back to School Offer',
                  validator: (value) {
                    if (_hasOffer && (value == null || value.isEmpty)) {
                      return 'Please enter offer title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _offerDescriptionController,
                  labelText: 'Offer Description',
                  hintText: 'e.g., "Flat 15% off on Sony WH-1000XM5"',
                  maxLines: 2,
                  validator: (value) {
                    if (_hasOffer && (value == null || value.isEmpty)) {
                      return 'Please enter offer description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Discount Type and Value
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
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
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDiscountType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Percentage',
                                child: Text('Percentage (%)'),
                              ),
                              DropdownMenuItem(
                                value: 'Fixed Amount',
                                child: Text('Fixed Amount (₹)'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDiscountType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: CustomTextField(
                        controller: _discountController,
                        labelText: _selectedDiscountType == 'Percentage' ? 'Discount (%)' : 'Discount (₹)',
                        hintText: _selectedDiscountType == 'Percentage' ? '15' : '2000',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_hasOffer && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          if (_hasOffer && double.tryParse(value!) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Trigger rebuild to update final price
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Final Price Display
                if (_hasOffer && _priceController.text.isNotEmpty && _discountController.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.green[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Final Price (Auto-calculated)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${_calculateFinalPrice().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                
                // Offer Dates
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Valid From',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectOfferStartDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_offerStartDate.day}/${_offerStartDate.month}/${_offerStartDate.year}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Valid To',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectOfferEndDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_offerEndDate.day}/${_offerEndDate.month}/${_offerEndDate.year}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Offer Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getOfferStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getOfferStatusColor().withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getOfferStatusIcon(),
                        color: _getOfferStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Offer Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getOfferStatusText(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getOfferStatusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _maxUsesController,
                  labelText: 'Maximum Uses',
                  hintText: '100',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_hasOffer && (value == null || value.isEmpty)) {
                      return 'Please enter maximum uses';
                    }
                    if (_hasOffer && int.tryParse(value!) == null) {
                      return 'Please enter valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              const SizedBox(height: 32),
              
              // Save Button
              CustomButton(
                text: _isEditingExisting 
                  ? (_hasOffer ? 'Add Offer to Product' : 'Update Product')
                  : (_hasOffer ? 'Create Product with Offer' : 'Create Product'),
                onPressed: _isLoading ? null : _saveProductWithOffer,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon, 
            color: color, 
            size: isTablet ? 28 : (isLargeScreen ? 32 : 24)
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 22 : (isLargeScreen ? 24 : 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
