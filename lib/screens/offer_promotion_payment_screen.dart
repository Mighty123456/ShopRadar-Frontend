import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_message_dialog.dart';

class OfferPromotionPaymentScreen extends StatefulWidget {
  const OfferPromotionPaymentScreen({super.key});

  @override
  State<OfferPromotionPaymentScreen> createState() => _OfferPromotionPaymentScreenState();
}

class _OfferPromotionPaymentScreenState extends State<OfferPromotionPaymentScreen> {
  String? _selectedOffer;
  String? _selectedPromotionType;
  
  final List<Map<String, dynamic>> _offers = [
    {
      'id': '1',
      'title': '50% Off Electronics',
      'discount': '50%',
      'validFrom': 'Jan 15',
      'validTo': 'Jan 22',
      'status': 'active',
    },
    {
      'id': '2',
      'title': 'Buy 1 Get 1 Free',
      'discount': 'BOGO',
      'validFrom': 'Jan 20',
      'validTo': 'Jan 27',
      'status': 'active',
    },
    {
      'id': '3',
      'title': 'Summer Sale - ₹500 Off',
      'discount': '₹500',
      'validFrom': 'Jan 25',
      'validTo': 'Feb 5',
      'status': 'active',
    },
  ];

  final List<Map<String, dynamic>> _promotionTypes = [
    {
      'id': 'standard',
      'name': 'Standard Promotion',
      'price': 199,
      'duration': '7 days',
      'features': [
        'Featured offers section',
        'Push notifications',
        'Higher ranking',
      ],
      'color': const Color(0xFF2979FF),
      'icon': Icons.trending_up,
    },
    {
      'id': 'premium',
      'name': 'Premium Promotion',
      'price': 499,
      'duration': '14 days',
      'features': [
        'Everything in Standard',
        'Homepage banner',
        'Email newsletter',
      ],
      'color': const Color(0xFF9C27B0),
      'icon': Icons.star,
    },
    {
      'id': 'mega',
      'name': 'Mega Promotion',
      'price': 999,
      'duration': '30 days',
      'features': [
        'Everything in Premium',
        'Multiple push notifications',
        'SMS notifications',
      ],
      'color': Colors.orange,
      'icon': Icons.local_fire_department,
    },
  ];

  final List<Map<String, dynamic>> _activePromotions = [
    {
      'offerTitle': '50% Off Electronics',
      'type': 'Premium',
      'daysRemaining': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Promote Offers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(isTablet),
              const SizedBox(height: 24),

              // Select Offer Section
              Text(
                'Select an Offer to Promote',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              ..._offers.map((offer) => _buildOfferCard(offer, isTablet)),
              
              const SizedBox(height: 32),

              // Promotion Types Section
              Text(
                'Promotion Types',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              ..._promotionTypes.map((type) => _buildPromotionTypeCard(type, isTablet)),
              
              const SizedBox(height: 32),

              // Active Promotions
              if (_activePromotions.isNotEmpty) ...[
                Text(
                  'Currently Promoted',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ..._activePromotions.map((promo) => _buildActivePromotionCard(promo, isTablet)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange,
            Colors.deepOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promote Your Offers',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get more customers with featured promotions',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer, bool isTablet) {
    final isSelected = _selectedOffer == offer['id'];
    
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF2979FF).withValues(alpha: 0.5)
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOffer = offer['id'];
          });
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_offer,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title'],
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valid: ${offer['validFrom']} - ${offer['validTo']}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer['status'].toUpperCase(),
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF2979FF),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionTypeCard(Map<String, dynamic> type, bool isTablet) {
    final isSelected = _selectedPromotionType == type['id'];
    final color = type['color'] as Color;
    
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.5) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type['icon'] as IconData,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['name'],
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${type['price']}',
                          style: TextStyle(
                            fontSize: isTablet ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'for ${type['duration']}',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(type['features'] as List<String>).map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Select ${type['name']}',
            onPressed: () {
              setState(() {
                _selectedPromotionType = type['id'];
              });
              _handlePromotionSelection(type);
            },
            backgroundColor: isSelected ? color : null,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildActivePromotionCard(Map<String, dynamic> promo, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            promo['offerTitle'],
                            style: TextStyle(
                              fontSize: isTablet ? 17 : 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            promo['type'],
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${promo['daysRemaining']} days remaining',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () {
                  MessageHelper.showAnimatedMessage(
                    context,
                    message: 'View promotion statistics and performance',
                    type: MessageType.info,
                    title: 'View Stats',
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('View Stats', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () {
                  MessageHelper.showAnimatedMessage(
                    context,
                    message: 'Renewal functionality will be implemented with payment gateway',
                    type: MessageType.info,
                    title: 'Renew',
                  );
                },
                child: const Text('Renew', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePromotionSelection(Map<String, dynamic> type) {
    if (_selectedOffer == null) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'Please select an offer first',
        type: MessageType.warning,
        title: 'Select Offer',
      );
      return;
    }

    final offer = _offers.firstWhere((o) => o['id'] == _selectedOffer);
    
    MessageHelper.showAnimatedMessage(
      context,
      message: 'Payment integration coming soon!\nPromoting: ${offer['title']}\nType: ${type['name']}\nPrice: ₹${type['price']}',
      type: MessageType.info,
      title: 'Payment',
    );
  }
}

