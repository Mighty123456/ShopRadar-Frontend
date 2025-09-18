import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';
import '../services/shop_service.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  bool _isLoading = false;
  bool _isOpenMonday = true;
  bool _isOpenTuesday = true;
  bool _isOpenWednesday = true;
  bool _isOpenThursday = true;
  bool _isOpenFriday = true;
  bool _isOpenSaturday = true;
  bool _isOpenSunday = false;
  
  TimeOfDay _mondayOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _mondayClose = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _tuesdayOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _tuesdayClose = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _wednesdayOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _wednesdayClose = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _thursdayOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _thursdayClose = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _fridayOpen = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _fridayClose = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _saturdayOpen = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _saturdayClose = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _sundayOpen = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _sundayClose = const TimeOfDay(hour: 16, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await ShopService.getMyShop();
      if (!mounted) return;
      if (result['success'] == true && result['shop'] != null) {
        final shop = result['shop'] as Map<String, dynamic>;
        _shopNameController.text = shop['shopName']?.toString() ?? '';
        _addressController.text = shop['address']?.toString() ?? '';
        _phoneController.text = shop['phone']?.toString() ?? '';
        // Email is from owner relation if populated
        final owner = shop['ownerId'];
        if (owner is Map && owner['email'] != null) {
          _emailController.text = owner['email'].toString();
        }
        // Optional fields if your schema includes them
        _categoryController.text = shop['category']?.toString() ?? _categoryController.text;
        _descriptionController.text = shop['description']?.toString() ?? _descriptionController.text;
      } else {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to load shop details',
          type: MessageType.error,
          title: 'Load Failed',
        );
      }
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Error loading shop: ${e.toString()}',
        type: MessageType.error,
        title: 'Load Error',
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ShopService.updateMyShop(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (result['success'] == true) {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Shop profile updated successfully!',
          type: MessageType.success,
          title: 'Profile Updated',
        );
      } else {
        MessageHelper.showAnimatedMessage(
          context,
          message: result['message'] ?? 'Failed to update profile. Please try again.',
          type: MessageType.error,
          title: 'Update Failed',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to update profile. Please try again. ${e.toString()}',
          type: MessageType.error,
          title: 'Update Failed',
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpen, int day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _getOpenTime(day) : _getCloseTime(day),
    );
    
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _setOpenTime(day, picked);
        } else {
          _setCloseTime(day, picked);
        }
      });
    }
  }

  TimeOfDay _getOpenTime(int day) {
    switch (day) {
      case 1: return _mondayOpen;
      case 2: return _tuesdayOpen;
      case 3: return _wednesdayOpen;
      case 4: return _thursdayOpen;
      case 5: return _fridayOpen;
      case 6: return _saturdayOpen;
      case 7: return _sundayOpen;
      default: return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  TimeOfDay _getCloseTime(int day) {
    switch (day) {
      case 1: return _mondayClose;
      case 2: return _tuesdayClose;
      case 3: return _wednesdayClose;
      case 4: return _thursdayClose;
      case 5: return _fridayClose;
      case 6: return _saturdayClose;
      case 7: return _sundayClose;
      default: return const TimeOfDay(hour: 18, minute: 0);
    }
  }

  void _setOpenTime(int day, TimeOfDay time) {
    switch (day) {
      case 1: _mondayOpen = time; break;
      case 2: _tuesdayOpen = time; break;
      case 3: _wednesdayOpen = time; break;
      case 4: _thursdayOpen = time; break;
      case 5: _fridayOpen = time; break;
      case 6: _saturdayOpen = time; break;
      case 7: _sundayOpen = time; break;
    }
  }

  void _setCloseTime(int day, TimeOfDay time) {
    switch (day) {
      case 1: _mondayClose = time; break;
      case 2: _tuesdayClose = time; break;
      case 3: _wednesdayClose = time; break;
      case 4: _thursdayClose = time; break;
      case 5: _fridayClose = time; break;
      case 6: _saturdayClose = time; break;
      case 7: _sundayClose = time; break;
    }
  }

  bool _getDayOpen(int day) {
    switch (day) {
      case 1: return _isOpenMonday;
      case 2: return _isOpenTuesday;
      case 3: return _isOpenWednesday;
      case 4: return _isOpenThursday;
      case 5: return _isOpenFriday;
      case 6: return _isOpenSaturday;
      case 7: return _isOpenSunday;
      default: return true;
    }
  }

  void _setDayOpen(int day, bool value) {
    switch (day) {
      case 1: _isOpenMonday = value; break;
      case 2: _isOpenTuesday = value; break;
      case 3: _isOpenWednesday = value; break;
      case 4: _isOpenThursday = value; break;
      case 5: _isOpenFriday = value; break;
      case 6: _isOpenSaturday = value; break;
      case 7: _isOpenSunday = value; break;
    }
  }

  Widget _buildWorkingHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Working Hours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
                    boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
          ),
          child: Column(
            children: [
              _buildDayRow('Monday', 1),
              const Divider(),
              _buildDayRow('Tuesday', 2),
              const Divider(),
              _buildDayRow('Wednesday', 3),
              const Divider(),
              _buildDayRow('Thursday', 4),
              const Divider(),
              _buildDayRow('Friday', 5),
              const Divider(),
              _buildDayRow('Saturday', 6),
              const Divider(),
              _buildDayRow('Sunday', 7),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(String dayName, int day) {
    final isOpen = _getDayOpen(day);
    final openTime = _getOpenTime(day);
    final closeTime = _getCloseTime(day);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (value) {
              setState(() {
                _setDayOpen(day, value);
              });
            },
            activeThumbColor: Colors.green,
          ),
          const SizedBox(width: 16),
          if (isOpen) ...[
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => _selectTime(context, true, day),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
            const Text(' - ', style: TextStyle(fontSize: 16)),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => _selectTime(context, false, day),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              flex: 4,
              child: Text(
                'Closed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        title: const Text(
          'Shop Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _shopNameController,
                      labelText: 'Shop Name',
                      hintText: 'Enter your shop name',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shop name';
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
                    
                    CustomTextField(
                      controller: _descriptionController,
                      labelText: 'Description',
                      hintText: 'Describe your shop and what you offer',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shop description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      hintText: 'Enter your shop address',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shop address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Working Hours
              _buildWorkingHoursSection(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Saving...' : 'Save Profile',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
