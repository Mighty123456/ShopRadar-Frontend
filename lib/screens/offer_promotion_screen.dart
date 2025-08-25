import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';

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
  
  final List<Map<String, dynamic>> _offers = [
    {
      'id': '1',
      'title': 'Summer Sale',
      'description': 'Get 20% off on all electronics',
      'type': 'Percentage',
      'value': 20,
      'target': 'All Customers',
      'startDate': DateTime.now(),
      'endDate': DateTime.now().add(const Duration(days: 30)),
      'maxUses': 100,
      'currentUses': 45,
      'isActive': true,
    },
    {
      'id': '2',
      'title': 'New Customer Discount',
      'description': 'First-time customers get \$10 off',
      'type': 'Fixed Amount',
      'value': 10,
      'target': 'New Customers',
      'startDate': DateTime.now().subtract(const Duration(days: 5)),
      'endDate': DateTime.now().add(const Duration(days: 25)),
      'maxUses': 50,
      'currentUses': 12,
      'isActive': true,
    },
  ];

  @override
  void dispose() {
    _offerTitleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  void _addNewOffer() {
    setState(() {
      _isEditing = false;
      _editingOfferId = null;
      _clearForm();
    });
    _showOfferDialog();
  }

  void _editOffer(Map<String, dynamic> offer) {
    setState(() {
      _isEditing = true;
      _editingOfferId = offer['id'];
      _offerTitleController.text = offer['title'];
      _descriptionController.text = offer['description'];
      _discountController.text = offer['value'].toString();
      _maxUsesController.text = offer['maxUses'].toString();
      _selectedType = offer['type'];
      _selectedTarget = offer['target'];
      _startDate = offer['startDate'];
      _endDate = offer['endDate'];
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
  }

  void _showOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                      _isEditing ? Icons.edit : Icons.local_offer,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEditing ? 'Edit Offer' : 'Create New Offer',
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
                        
                        Row(
                          children: [
                            Expanded(
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
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
                              ),
                            ),
                          ],
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
                        
                        Row(
                          children: [
                            Expanded(
                              child: Column(
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
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
                              ),
                            ),
                          ],
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

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final offerData = {
        'title': _offerTitleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'value': double.parse(_discountController.text),
        'target': _selectedTarget,
        'startDate': _startDate,
        'endDate': _endDate,
        'maxUses': int.parse(_maxUsesController.text),
      };

      if (_isEditing) {
        final index = _offers.indexWhere((o) => o['id'] == _editingOfferId);
        if (index != -1) {
          setState(() {
            _offers[index]['title'] = offerData['title'];
            _offers[index]['description'] = offerData['description'];
            _offers[index]['type'] = offerData['type'];
            _offers[index]['value'] = offerData['value'];
            _offers[index]['target'] = offerData['target'];
            _offers[index]['startDate'] = offerData['startDate'];
            _offers[index]['endDate'] = offerData['endDate'];
            _offers[index]['maxUses'] = offerData['maxUses'];
          });
        }
      } else {
        final newOffer = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': offerData['title'],
          'description': offerData['description'],
          'type': offerData['type'],
          'value': offerData['value'],
          'target': offerData['target'],
          'startDate': offerData['startDate'],
          'endDate': offerData['endDate'],
          'maxUses': offerData['maxUses'],
          'currentUses': 0,
          'isActive': true,
        };
        
        setState(() {
          _offers.insert(0, newOffer);
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        setState(() {
          _isLoading = false;
        });
        
        MessageHelper.showAnimatedMessage(
          context,
          message: _isEditing 
            ? 'Offer updated successfully!'
            : 'Offer created successfully!',
          type: MessageType.success,
          title: _isEditing ? 'Offer Updated' : 'Offer Created',
        );
        
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        MessageHelper.showAnimatedMessage(
          context,
          message: 'Failed to save offer. Please try again.',
          type: MessageType.error,
          title: 'Save Failed',
        );
      }
    }
  }

  void _toggleOfferStatus(String offerId) {
    setState(() {
      final index = _offers.indexWhere((o) => o['id'] == offerId);
      if (index != -1) {
        _offers[index]['isActive'] = !_offers[index]['isActive'];
      }
    });
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
            onPressed: () {
              setState(() {
                _offers.removeWhere((o) => o['id'] == offerId);
              });
              Navigator.of(context).pop();
              
              MessageHelper.showAnimatedMessage(
                context,
                message: 'Offer deleted successfully!',
                type: MessageType.success,
                title: 'Offer Deleted',
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Offer Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                CustomButton(
                  text: 'Create Offer',
                  onPressed: _addNewOffer,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _offers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
                      return _buildOfferCard(offer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No offers yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating your first offer',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create First Offer',
            onPressed: _addNewOffer,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final isExpired = offer['endDate'].isBefore(DateTime.now());
    final usagePercentage = (offer['currentUses'] / offer['maxUses']) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: offer['isActive'] && !isExpired ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        offer['isActive'] && !isExpired ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  offer['description'],
                  style: TextStyle(
                    fontSize: 14,
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
                        offer['type'] == 'Percentage' 
                          ? '${offer['value'].toStringAsFixed(0)}% OFF'
                          : '\$${offer['value'].toStringAsFixed(2)} OFF',
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
                        offer['target'],
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
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${offer['startDate'].day}/${offer['startDate'].month} - ${offer['endDate'].day}/${offer['endDate'].month}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${offer['currentUses']}/${offer['maxUses']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
                
                const Spacer(),
                
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _toggleOfferStatus(offer['id']),
                      icon: Icon(
                        offer['isActive'] ? Icons.visibility_off : Icons.visibility,
                        color: offer['isActive'] ? Colors.orange : Colors.green,
                      ),
                      tooltip: offer['isActive'] ? 'Deactivate' : 'Activate',
                    ),
                    IconButton(
                      onPressed: () => _editOffer(offer),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteOffer(offer['id']),
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
