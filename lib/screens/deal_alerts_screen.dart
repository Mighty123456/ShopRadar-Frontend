import 'package:flutter/material.dart';
import '../services/deal_alerts_service.dart';
import '../widgets/animated_message_dialog.dart';

class DealAlertsScreen extends StatefulWidget {
  const DealAlertsScreen({super.key});

  @override
  State<DealAlertsScreen> createState() => _DealAlertsScreenState();
}

class _DealAlertsScreenState extends State<DealAlertsScreen> {
  List<DealAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
    });

    try {
      await DealAlertsService.initialize();
      final alerts = DealAlertsService.getAllAlerts();
      
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError('Failed to load alerts: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      MessageHelper.showAnimatedMessage(
        context,
        title: 'Error',
        message: message,
        type: MessageType.error,
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      MessageHelper.showAnimatedMessage(
        context,
        title: 'Success',
        message: message,
        type: MessageType.success,
      );
    }
  }

  Future<void> _createNewAlert() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateDealAlertScreen(),
      ),
    );

    if (result == true) {
      _loadAlerts();
    }
  }

  Future<void> _toggleAlertStatus(DealAlert alert) async {
    try {
      await DealAlertsService.updateAlertStatus(alert.id, !alert.isActive);
      _loadAlerts();
      _showSuccess(
        alert.isActive ? 'Alert disabled' : 'Alert enabled',
      );
    } catch (e) {
      _showError('Failed to update alert: $e');
    }
  }

  Future<void> _deleteAlert(DealAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Are you sure you want to delete "${alert.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DealAlertsService.deleteAlert(alert.id);
        _loadAlerts();
        _showSuccess('Alert deleted');
      } catch (e) {
        _showError('Failed to delete alert: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deal Alerts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _createNewAlert,
            icon: const Icon(Icons.add),
            tooltip: 'Create Alert',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Deal Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create alerts to get notified about great deals',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewAlert,
            icon: const Icon(Icons.add),
            label: const Text('Create Alert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(DealAlert alert) {
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
                    alert.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Switch(
                  value: alert.isActive,
                  onChanged: (_) => _toggleAlertStatus(alert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.description,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildInfoChip(
                  Icons.category,
                  alert.category,
                  Colors.blue,
                ),
                _buildInfoChip(
                  Icons.percent,
                  '${alert.minDiscount.toInt()}% - ${alert.maxDiscount.toInt()}%',
                  Colors.green,
                ),
                _buildInfoChip(
                  Icons.location_on,
                  '${alert.maxDistance}km',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created ${_formatDate(alert.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteAlert(alert),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Delete Alert',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class CreateDealAlertScreen extends StatefulWidget {
  const CreateDealAlertScreen({super.key});

  @override
  State<CreateDealAlertScreen> createState() => _CreateDealAlertScreenState();
}

class _CreateDealAlertScreenState extends State<CreateDealAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'All';
  double _minDiscount = 10;
  double _maxDiscount = 100;
  int _maxDistance = 5;

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createAlert() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await DealAlertsService.createAlert(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        minDiscount: _minDiscount,
        maxDiscount: _maxDiscount,
        maxDistance: _maxDistance,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create alert: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Deal Alert'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Alert Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 16),

            // Discount Range
            const Text(
              'Discount Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

            // Max Distance
            const Text(
              'Maximum Distance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _maxDistance.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_maxDistance}km',
              onChanged: (value) {
                setState(() {
                  _maxDistance = value.round();
                });
              },
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Create Alert',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
