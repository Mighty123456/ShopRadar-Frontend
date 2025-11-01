import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_message_dialog.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String? _selectedPlan;
  final String _currentPlan = 'free'; // Get from shop data

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'free',
      'name': 'Free',
      'price': 0,
      'period': 'Forever',
      'features': [
        'Up to 5 products',
        'Up to 2 offers',
        'Basic shop listing',
        'Standard visibility',
      ],
      'color': Colors.grey,
      'popular': false,
    },
    {
      'id': 'basic',
      'name': 'Basic',
      'price': 499,
      'period': 'month',
      'features': [
        'Up to 20 products',
        'Up to 5 offers',
        'Basic analytics',
        'Email support',
      ],
      'color': const Color(0xFF2979FF),
      'popular': false,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': 1999,
      'period': 'month',
      'features': [
        'Unlimited products',
        'Unlimited offers',
        'Featured listing',
        'Advanced analytics',
        'Priority support',
        'Banner ads',
        'Up to 3 locations',
      ],
      'color': const Color(0xFF9C27B0),
      'popular': true,
    },
    {
      'id': 'enterprise',
      'name': 'Enterprise',
      'price': 4999,
      'period': 'month',
      'features': [
        'Everything in Premium',
        'Unlimited locations',
        'API access',
        'Dedicated manager',
        'Custom integrations',
        'White-label options',
      ],
      'color': const Color(0xFF1565C0),
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;

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
          'Choose Your Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Plan Status Card
              _buildCurrentPlanCard(isTablet),
              const SizedBox(height: 24),

              // Title
              Text(
                'Subscription Plans',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upgrade to unlock more features and grow your business',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Plan Cards
              if (isLargeTablet)
                _buildGridPlans(isTablet)
              else
                _buildScrollPlans(isTablet),

              const SizedBox(height: 32),

              // Enterprise Contact Card
              _buildEnterpriseCard(isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(bool isTablet) {
    final currentPlanData = _plans.firstWhere((p) => p['id'] == _currentPlan);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: const Color(0xFF2979FF).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isSmallScreen && _currentPlan == 'free'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        color: Color(0xFF2979FF),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Plan: ${currentPlanData['name'].toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No expiry date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Upgrade Now',
                    onPressed: () {
                      MessageHelper.showAnimatedMessage(
                        context,
                        message: 'Choose a plan below to upgrade',
                        type: MessageType.info,
                        title: 'Select Plan',
                      );
                    },
                    height: 44,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    color: Color(0xFF2979FF),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan: ${currentPlanData['name'].toUpperCase()}',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPlan == 'free' 
                          ? 'No expiry date' 
                          : 'Renews monthly',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentPlan == 'free') ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: isTablet ? 150 : 130,
                    child: CustomButton(
                      text: 'Upgrade Now',
                      onPressed: () {
                        MessageHelper.showAnimatedMessage(
                          context,
                          message: 'Choose a plan below to upgrade',
                          type: MessageType.info,
                          title: 'Select Plan',
                        );
                      },
                      height: isTablet ? 44 : 42,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildGridPlans(bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _plans.length,
      itemBuilder: (context, index) => _buildPlanCard(_plans[index], isTablet),
    );
  }

  Widget _buildScrollPlans(bool isTablet) {
    return SizedBox(
      height: isTablet ? 500 : 480,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _plans.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) => SizedBox(
          width: isTablet ? 280 : 260,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildPlanCard(_plans[index], isTablet),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isTablet) {
    final isSelected = _selectedPlan == plan['id'];
    final isCurrentPlan = _currentPlan == plan['id'];
    final isPopular = plan['popular'] == true;
    final planColor = plan['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: isSelected
              ? planColor.withValues(alpha: 0.5)
              : (isPopular ? planColor.withValues(alpha: 0.3) : Colors.grey[300]!),
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
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Popular Badge
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isPopular) const SizedBox(height: 8),

                // Plan Name
                Text(
                  plan['name'],
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${plan['price']}',
                      style: TextStyle(
                        fontSize: isTablet ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: planColor,
                      ),
                    ),
                    if (plan['price'] > 0) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '/${plan['period']}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Features List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (plan['features'] as List<String>).map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: planColor,
                              size: 20,
                            ),
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
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Button
                if (isCurrentPlan)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Current Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  CustomButton(
                    text: plan['price'] == 0 ? 'Current' : 'Select Plan',
                    onPressed: () {
                      setState(() {
                        _selectedPlan = plan['id'];
                      });
                      _handlePlanSelection(plan);
                    },
                    backgroundColor: isSelected ? planColor : null,
                    width: double.infinity,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterpriseCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF2979FF),
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
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enterprise Plan',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'For large businesses and chains',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Contact Sales',
            onPressed: () {
              // Open contact form or email
              MessageHelper.showAnimatedMessage(
                context,
                message: 'Contact us at enterprise@shopradar.com',
                type: MessageType.info,
                title: 'Enterprise Support',
              );
            },
            backgroundColor: Colors.white,
            textColor: const Color(0xFF1565C0),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  void _handlePlanSelection(Map<String, dynamic> plan) {
    if (plan['id'] == 'enterprise') {
      _buildEnterpriseCard(true);
      return;
    }

    if (_currentPlan == plan['id']) {
      MessageHelper.showAnimatedMessage(
        context,
        message: 'You are already on this plan',
        type: MessageType.info,
        title: 'Current Plan',
      );
      return;
    }

    // Navigate to payment screen
    Navigator.of(context).pushNamed(
      '/subscription-payment',
      arguments: plan,
    );
  }
}

