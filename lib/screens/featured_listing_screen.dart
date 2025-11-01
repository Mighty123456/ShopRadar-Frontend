import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/animated_message_dialog.dart';

class FeaturedListingScreen extends StatefulWidget {
  const FeaturedListingScreen({super.key});

  @override
  State<FeaturedListingScreen> createState() => _FeaturedListingScreenState();
}

class _FeaturedListingScreenState extends State<FeaturedListingScreen> {
  final List<Map<String, dynamic>> _activeListings = [
    {
      'type': 'Search Featured',
      'price': 500,
      'startDate': DateTime.now().subtract(const Duration(days: 4)),
      'endDate': DateTime.now().add(const Duration(days: 3)),
      'status': 'active',
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
          'Get Featured',
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

              // Featured Options
              Text(
                'Featured Listing Options',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildFeaturedOptionCard(
                'Search Featured',
                Icons.search,
                const Color(0xFF2979FF),
                500,
                'Top of search results',
                'Featured badge',
                '7 days duration',
                isTablet,
              ),
              const SizedBox(height: 16),

              _buildFeaturedOptionCard(
                'Category Featured',
                Icons.category,
                const Color(0xFF2DD4BF),
                750,
                'Featured in category',
                'Targeted customers',
                '7 days duration',
                isTablet,
              ),
              const SizedBox(height: 16),

              _buildFeaturedOptionCard(
                'Map Featured Pin',
                Icons.map,
                Colors.orange,
                1000,
                'Larger pin on map',
                'Different color badge',
                '7 days duration',
                isTablet,
              ),
              const SizedBox(height: 16),

              _buildFeaturedOptionCard(
                'Homepage Banner',
                Icons.home,
                const Color(0xFF9C27B0),
                2000,
                'Large banner on homepage',
                'Maximum visibility',
                '7 days duration',
                isTablet,
              ),
              const SizedBox(height: 32),

              // Active Featured Listings
              if (_activeListings.isNotEmpty) ...[
                Text(
                  'Active Featured Listings',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ..._activeListings.map((listing) => _buildActiveListingCard(
                  listing,
                  isTablet,
                )),
                const SizedBox(height: 16),
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
            const Color(0xFF2979FF),
            const Color(0xFF2DD4BF),
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
              Icons.star,
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
                  'Featured Listing',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get 5-10x more visibility!',
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

  Widget _buildFeaturedOptionCard(
    String title,
    IconData icon,
    Color color,
    int price,
    String benefit1,
    String benefit2,
    String duration,
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
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
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                          '₹$price',
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
                            '/week',
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
          Row(
            children: [
              Icon(Icons.check_circle, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefit1,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  benefit2,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  duration,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Select & Pay ₹$price',
            onPressed: () {
              _handlePayment(title, price);
            },
            backgroundColor: color,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveListingCard(Map<String, dynamic> listing, bool isTablet) {
    final daysRemaining = listing['endDate'].difference(DateTime.now()).inDays;
    
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
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
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['type'],
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$daysRemaining days remaining',
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
                  _handleRenew(listing);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Renew', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: () {
                  _handleCancel(listing);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePayment(String type, int price) {
    MessageHelper.showAnimatedMessage(
      context,
      message: 'Payment integration coming soon!\nYou selected: $type for ₹$price/week',
      type: MessageType.info,
      title: 'Payment',
    );
  }

  void _handleRenew(Map<String, dynamic> listing) {
    MessageHelper.showAnimatedMessage(
      context,
      message: 'Renewal functionality will be implemented with payment gateway',
      type: MessageType.info,
      title: 'Renew',
    );
  }

  void _handleCancel(Map<String, dynamic> listing) {
    setState(() {
      _activeListings.remove(listing);
    });
    MessageHelper.showAnimatedMessage(
      context,
      message: 'Featured listing cancelled',
      type: MessageType.success,
      title: 'Cancelled',
    );
  }
}

