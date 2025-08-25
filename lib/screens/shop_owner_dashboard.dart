import 'package:flutter/material.dart';
import '../widgets/animated_message_dialog.dart';
import 'shop_profile_screen.dart';
import 'product_management_screen.dart';
import 'offer_promotion_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'customer_interaction_screen.dart';
import 'ai_insights_screen.dart';
import 'profile_screen.dart';

class ShopOwnerDashboard extends StatefulWidget {
  const ShopOwnerDashboard({super.key});

  @override
  State<ShopOwnerDashboard> createState() => _ShopOwnerDashboardState();
}

class _ShopOwnerDashboardState extends State<ShopOwnerDashboard> {
  int _selectedIndex = 0;
  bool _isShopOpen = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isLargeTablet = screenWidth >= 900;
    
    // Enhanced responsive breakpoints
    final isMedium = screenWidth >= 600 && screenWidth < 768;
    final isLarge = screenWidth >= 768 && screenWidth < 1024;
    final isExtraLarge = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        toolbarHeight: isLargeTablet ? 80 : (isTablet ? 70 : 56),
        title: Row(
          children: [
            Icon(
              Icons.store, 
              color: Colors.white, 
              size: isLargeTablet ? 36 : (isTablet ? 32 : 28)
            ),
            SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
            Flexible(
              child: Text(
                'Business Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Shop Status Toggle - Responsive layout
          Container(
            margin: EdgeInsets.only(right: isSmallScreen ? 8 : 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isSmallScreen) ...[
                  Text(
                    _isShopOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Switch(
                  value: _isShopOpen,
                  onChanged: (value) {
                    setState(() {
                      _isShopOpen = value;
                    });
                    _showStatusChangeMessage(value);
                  },
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHomeTab(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            _buildProductsTab(),
            _buildOffersTab(),
            _buildAnalyticsTab(),
            _buildCustomersTab(),
            _buildInsightsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isSmallScreen, isTablet, isLargeTablet),
    );
  }

  Widget _buildBottomNavigationBar(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    // For very small screens, use a more compact navigation
    if (isSmallScreen) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 20),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory, size: 20),
            label: 'Products',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_offer, size: 20),
            label: 'Offers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics, size: 20),
            label: 'Analytics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 20),
            label: 'Customers',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.psychology, size: 20),
            label: 'AI',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 20),
            label: 'Profile',
          ),
        ],
      );
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      selectedItemColor: const Color(0xFF2979FF),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 8,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Products',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Offers',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Customers',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.psychology),
          label: 'AI Insights',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildHomeTab(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : (isSmallScreen ? 12 : 16)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
          SizedBox(height: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : (isSmallScreen ? 20 : 24)))),
          _buildQuickActions(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
          SizedBox(height: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : (isSmallScreen ? 20 : 24)))),
          _buildRecentActivity(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
          SizedBox(height: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : (isSmallScreen ? 20 : 24)))),
          _buildShopStatusCard(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    // Responsive grid layout
    int crossAxisCount;
    if (isExtraLarge) {
      crossAxisCount = 4;
    } else if (isLarge) {
      crossAxisCount = 3;
    } else if (isMedium) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8)),
      mainAxisSpacing: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8)),
      childAspectRatio: isExtraLarge ? 1.8 : (isLarge ? 1.6 : (isMedium ? 1.4 : 1.2)),
      children: [
        _buildStatCard(
          'Total Products',
          '0',
          Icons.inventory,
          Colors.blue,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
        _buildStatCard(
          'Active Offers',
          '0',
          Icons.local_offer,
          Colors.orange,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
        _buildStatCard(
          'Today\'s Views',
          '0',
          Icons.visibility,
          Colors.green,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
        _buildStatCard(
          'Customer Reviews',
          '0',
          Icons.star,
          Colors.amber,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: isExtraLarge ? 40 : (isLarge ? 36 : (isMedium ? 32 : 28)), 
            color: color
          ),
          SizedBox(height: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
          Text(
            value,
            style: TextStyle(
              fontSize: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : 18)),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isExtraLarge ? 6 : (isLarge ? 5 : (isMedium ? 4 : 3))),
          Text(
            title,
            style: TextStyle(
              fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10)),
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isExtraLarge ? 24 : (isLarge ? 22 : (isMedium ? 20 : 18)),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isExtraLarge ? 4 : (isLarge ? 3 : 2),
          crossAxisSpacing: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8)),
          mainAxisSpacing: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8)),
          childAspectRatio: isExtraLarge ? 3.0 : (isLarge ? 2.8 : 2.5),
          children: [
            _buildActionCard(
              'Add Product',
              Icons.add_box,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductManagementScreen(),
                ),
              ),
              isSmallScreen,
              isTablet,
              isLargeTablet,
              isMedium,
              isLarge,
              isExtraLarge,
            ),
            _buildActionCard(
              'Create Offer',
              Icons.local_offer,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfferPromotionScreen(),
                ),
              ),
              isSmallScreen,
              isTablet,
              isLargeTablet,
              isMedium,
              isLarge,
              isExtraLarge,
            ),
            _buildActionCard(
              'Edit Profile',
              Icons.edit,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopProfileScreen(),
                ),
              ),
              isSmallScreen,
              isTablet,
              isLargeTablet,
              isMedium,
              isLarge,
              isExtraLarge,
            ),
            _buildActionCard(
              'View Analytics',
              Icons.analytics,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboardScreen(),
                ),
              ),
              isSmallScreen,
              isTablet,
              isLargeTablet,
              isMedium,
              isLarge,
              isExtraLarge,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
      child: Container(
        padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : 18)), 
              color: color
            ),
            SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 6))),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 12)),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios, 
              size: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 12)), 
              color: Colors.grey
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: isExtraLarge ? 24 : (isLarge ? 22 : (isMedium ? 20 : 18)),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
        Container(
          padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
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
              _buildActivityItem(
                'New product added: Wireless Headphones',
                '2 hours ago',
                Icons.add_circle,
                Colors.green,
                isSmallScreen,
                isTablet,
                isLargeTablet,
                isMedium,
                isLarge,
                isExtraLarge,
              ),
              const Divider(),
              _buildActivityItem(
                'Offer "Summer Sale" created',
                '4 hours ago',
                Icons.local_offer,
                Colors.orange,
                isSmallScreen,
                isTablet,
                isLargeTablet,
                isMedium,
                isLarge,
                isExtraLarge,
              ),
              const Divider(),
              _buildActivityItem(
                'Customer review received',
                '6 hours ago',
                Icons.star,
                Colors.amber,
                isSmallScreen,
                isTablet,
                isLargeTablet,
                isMedium,
                isLarge,
                isExtraLarge,
              ),
              const Divider(),
              _buildActivityItem(
                'Shop profile updated',
                '1 day ago',
                Icons.edit,
                Colors.blue,
                isSmallScreen,
                isTablet,
                isLargeTablet,
                isMedium,
                isLarge,
                isExtraLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
      child: Row(
        children: [
          Icon(
            icon, 
            size: isExtraLarge ? 24 : (isLarge ? 22 : (isMedium ? 20 : 18)), 
            color: color
          ),
          SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 6))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isExtraLarge ? 4 : 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: isExtraLarge ? 14 : (isLarge ? 13 : (isMedium ? 12 : 10)),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStatusCard(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isShopOpen ? Icons.check_circle : Icons.cancel,
                color: _isShopOpen ? Colors.green : Colors.red,
                size: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : 18)),
              ),
              SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 6))),
              Expanded(
                child: Text(
                  'Shop Status',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 22 : (isLarge ? 20 : (isMedium ? 18 : 16)),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
          Text(
            _isShopOpen 
              ? 'Your shop is currently open and visible to customers. They can view your products and place orders.'
              : 'Your shop is currently closed. Customers cannot place orders or view your products.',
            style: TextStyle(
              fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return const ProductManagementScreen();
  }

  Widget _buildOffersTab() {
    return const OfferPromotionScreen();
  }

  Widget _buildAnalyticsTab() {
    return const AnalyticsDashboardScreen();
  }

  Widget _buildCustomersTab() {
    return const CustomerInteractionScreen();
  }

  Widget _buildInsightsTab() {
    return const AIInsightsScreen();
  }

  Widget _buildProfileTab() {
    return const ProfileScreen();
  }

  void _showStatusChangeMessage(bool isOpen) {
    MessageHelper.showAnimatedMessage(
      context,
      message: isOpen 
        ? 'Your shop is now open and visible to customers!'
        : 'Your shop is now closed. Customers cannot place orders.',
      type: MessageType.success,
      title: isOpen ? 'Shop Opened' : 'Shop Closed',
    );
  }
}
