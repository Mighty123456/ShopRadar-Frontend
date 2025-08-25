import 'package:flutter/material.dart';
import '../widgets/animated_message_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasShownWelcome = false;
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    // Show welcome message after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasShownWelcome) {
          _showWelcomeMessage();
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset selected index to home when returning to this screen
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  void _showWelcomeMessage() {
    setState(() {
      _hasShownWelcome = true;
    });
    
    MessageHelper.showAnimatedMessage(
      context,
      message: 'Welcome to ShopRadar! Discover the best deals around you.',
      type: MessageType.success,
      title: 'Welcome to ShopRadar!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isLargeTablet = screenWidth >= 900;
    final isLandscape = screenWidth > screenHeight;
    final isPhone = screenWidth < 600;
    final isPhoneLandscape = isPhone && isLandscape;
    
    // Enhanced responsive breakpoints for better adaptation
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
            Icon(Icons.radar, color: Colors.white, size: isLargeTablet ? 36 : (isTablet ? 32 : 28)),
            SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
            Text(
              'ShopRadar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map, color: Colors.white),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.store, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/shop-owner-dashboard');
            },
            tooltip: 'Shop Owner Dashboard',
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Search Section - Enhanced responsive design
                Container(
                  padding: EdgeInsets.all(isExtraLarge ? 40 : (isLarge ? 32 : (isMedium ? 24 : (isSmallScreen ? 16 : 20)))),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(isExtraLarge ? 40 : (isLarge ? 32 : (isMedium ? 24 : (isSmallScreen ? 20 : 22)))),
                      bottomRight: Radius.circular(isExtraLarge ? 40 : (isLarge ? 32 : (isMedium ? 24 : (isSmallScreen ? 20 : 22)))),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : (isSmallScreen ? 20 : 22)))),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: isExtraLarge ? 20 : (isLarge ? 15 : (isMedium ? 12 : 10)),
                              offset: Offset(0, isExtraLarge ? 10 : (isLarge ? 8 : (isMedium ? 6 : 5))),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products, stores, or categories...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.filter_list, color: Colors.grey[600]),
                              onPressed: () {
                                // TODO: Show filters
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : (isSmallScreen ? 20 : 22))), 
                              vertical: isExtraLarge ? 26 : (isLarge ? 22 : (isMedium ? 18 : (isSmallScreen ? 15 : 17)))
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : (isSmallScreen ? 16 : 18)))),
                      
                      // Quick Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickCategory('All', Icons.all_inclusive, true, isSmallScreen, isMedium, isLarge, isExtraLarge),
                            _buildQuickCategory('Electronics', Icons.phone_android, false, isSmallScreen, isMedium, isLarge, isExtraLarge),
                            _buildQuickCategory('Fashion', Icons.checkroom, false, isSmallScreen, isMedium, isLarge, isExtraLarge),
                            _buildQuickCategory('Food', Icons.restaurant, false, isSmallScreen, isMedium, isLarge, isExtraLarge),
                            _buildQuickCategory('Home', Icons.home, false, isSmallScreen, isMedium, isLarge, isExtraLarge),
                            _buildQuickCategory('Sports', Icons.sports_soccer, false, isSmallScreen, isMedium, isLarge, isExtraLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content - Flexible and responsive
                Expanded(
                  child: _isMapView ? _buildMapView(isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet, isLandscape, isPhoneLandscape) : _buildListView(isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet, isLandscape, isPhoneLandscape),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index != _selectedIndex) {
            setState(() {
              _selectedIndex = index;
            });
            

            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.of(context).pushNamed('/stores');
                break;
              case 2:
                Navigator.of(context).pushNamed('/favorites');
                break;
              case 3:
                Navigator.of(context).pushNamed('/profile');
                break;
            }
          }
        },
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.transparent,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Stores',
            backgroundColor: Colors.transparent,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
            backgroundColor: Colors.transparent,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategory(String title, IconData icon, bool isSelected, bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      margin: EdgeInsets.only(right: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : (isSmallScreen ? 12 : 14)))),
      padding: EdgeInsets.symmetric(
        horizontal: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : (isSmallScreen ? 16 : 18))), 
        vertical: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 12 : (isSmallScreen ? 8 : 10)))
      ),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : (isSmallScreen ? 16 : 18)))),
        border: isSelected ? Border.all(color: const Color(0xFF2979FF), width: isExtraLarge ? 3 : 2) : null,
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF2979FF).withValues(alpha: 0.2),
            blurRadius: isExtraLarge ? 12 : 8,
            offset: Offset(0, isExtraLarge ? 6 : 4),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isExtraLarge ? 26 : (isLarge ? 22 : (isMedium ? 20 : (isSmallScreen ? 16 : 18))),
            color: isSelected ? const Color(0xFF2979FF) : Colors.white,
          ),
          SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : (isSmallScreen ? 6 : 7)))),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2979FF) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : (isSmallScreen ? 12 : 13))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge, bool isTablet, bool isLargeTablet, bool isLandscape, bool isPhoneLandscape) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isExtraLarge ? 40 : (isLarge ? 32 : (isMedium ? 24 : (isSmallScreen ? 16 : 20)))),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Featured Offers Section
                _buildSectionHeader('Featured Offers', Icons.local_offer, Colors.orange, isTablet, isLargeTablet),
                SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                Container(
                  padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: isLargeTablet ? 320 : (isTablet ? 280 : 240), // Increased height for better content display
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, index) {
                        return _buildFeaturedOfferCard(index, isSmallScreen, isTablet, isLargeTablet);
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: isLargeTablet ? 32 : (isTablet ? 28 : 24)),
                
                // Nearby Stores Section
                _buildSectionHeader('Nearby Stores', Icons.location_on, Colors.red, isTablet, isLargeTablet),
                SizedBox(height: isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                _buildNearbyStoresList(isSmallScreen, isTablet, isLargeTablet),
                
                SizedBox(height: isLargeTablet ? 32 : (isTablet ? 28 : 24)),
                
                // Popular Categories Section
                _buildSectionHeader('Popular Categories', Icons.category, Colors.purple, isTablet, isLargeTablet),
                SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                Container(
                  padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildCategoriesGrid(isSmallScreen, isTablet, isLandscape, isLargeTablet),
                ),
                
                SizedBox(height: isLargeTablet ? 32 : (isTablet ? 28 : 24)),
                
                // Recent Searches Section
                _buildSectionHeader('Recent Searches', Icons.history, Colors.blue, isTablet, isLargeTablet),
                SizedBox(height: isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                _buildRecentSearchesList(isSmallScreen, isTablet, isLargeTablet),
                
                SizedBox(height: isLargeTablet ? 32 : (isTablet ? 28 : 24)),
                
                // AI Recommendations Section
                _buildSectionHeader('AI Recommendations', Icons.psychology, Colors.green, isTablet, isLargeTablet),
                SizedBox(height: isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                _buildAIRecommendationsList(isSmallScreen, isTablet, isLargeTablet),
                
                SizedBox(height: isLargeTablet ? 40 : (isTablet ? 36 : 32)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView(bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge, bool isTablet, bool isLargeTablet, bool isLandscape, bool isPhoneLandscape) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(isExtraLarge ? 40 : (isLarge ? 32 : (isMedium ? 24 : (isSmallScreen ? 16 : 20)))),
          child: Column(
            children: [
              // Map Placeholder - Use Flexible to prevent overflow
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : (isSmallScreen ? 20 : 22)))),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map, 
                          size: isExtraLarge ? 96 : (isLarge ? 80 : (isMedium ? 72 : (isSmallScreen ? 64 : 68))), 
                          color: Colors.grey[400]
                        ),
                        SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 18 : (isSmallScreen ? 16 : 17)))),
                        Text(
                          'Interactive Map View',
                          style: TextStyle(
                            fontSize: isExtraLarge ? 26 : (isLarge ? 22 : (isMedium ? 20 : (isSmallScreen ? 18 : 19))),
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 10 : (isSmallScreen ? 8 : 9)))),
                        Text(
                          'Store locations will be displayed here',
                          style: TextStyle(
                            fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 15 : (isSmallScreen ? 14 : 15))),
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 18 : (isSmallScreen ? 16 : 17)))),
              
              // Map Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMapControlButton('My Location', Icons.my_location, isSmallScreen, isMedium, isLarge, isExtraLarge),
                  _buildMapControlButton('Filters', Icons.filter_list, isSmallScreen, isMedium, isLarge, isExtraLarge),
                  _buildMapControlButton('Directions', Icons.directions, isSmallScreen, isMedium, isLarge, isExtraLarge),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapControlButton(String label, IconData icon, bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 20 : (isSmallScreen ? 16 : 18))), 
        vertical: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : (isSmallScreen ? 12 : 14)))
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 40 : (isLarge ? 35 : (isMedium ? 30 : (isSmallScreen ? 25 : 28)))),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isExtraLarge ? 8 : 5,
            offset: Offset(0, isExtraLarge ? 4 : 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: isExtraLarge ? 28 : (isLarge ? 24 : (isMedium ? 22 : (isSmallScreen ? 18 : 20))), 
            color: const Color(0xFF2979FF)
          ),
          SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : (isSmallScreen ? 6 : 7)))),
          Text(
            label,
            style: TextStyle(
              fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 15 : (isSmallScreen ? 12 : 14))),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2979FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isTablet, bool isLargeTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: isLargeTablet ? 28 : (isTablet ? 24 : 20)),
          ),
          SizedBox(width: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isLargeTablet ? 26 : (isTablet ? 22 : 18),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
              border: Border.all(
                color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to see all
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12),
                  vertical: isLargeTablet ? 12 : (isTablet ? 8 : 6),
                ),
              ),
              child: Text(
                'See All',
                style: TextStyle(
                  color: const Color(0xFF2979FF),
                  fontWeight: FontWeight.w600,
                  fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedOfferCard(int index, bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final offers = [
      {'title': '50% Off Electronics', 'store': 'TechMart', 'rating': 4.5, 'distance': '0.5km', 'discount': '50%'},
      {'title': 'Buy 2 Get 1 Free', 'store': 'FashionHub', 'rating': 4.2, 'distance': '1.2km', 'discount': '33%'},
      {'title': 'Weekend Sale', 'store': 'HomeStore', 'rating': 4.7, 'distance': '0.8km', 'discount': '25%'},
      {'title': 'Student Discount', 'store': 'BookWorld', 'rating': 4.3, 'distance': '1.5km', 'discount': '20%'},
      {'title': 'Flash Sale', 'store': 'SportsZone', 'rating': 4.6, 'distance': '2.1km', 'discount': '40%'},
    ];
    
    final offer = offers[index];
    final cardWidth = isLargeTablet ? 360 : (isTablet ? 320 : 280);
    
    return Container(
      width: cardWidth.toDouble(),
      margin: EdgeInsets.only(right: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offer Image Placeholder with Discount Badge
          Stack(
            children: [
              Container(
                height: isLargeTablet ? 160 : (isTablet ? 140 : 120),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(isLargeTablet ? 24 : (isTablet ? 20 : 16))),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_offer, 
                    size: isLargeTablet ? 60 : (isTablet ? 56 : 48), 
                    color: Colors.orange
                  ),
                ),
              ),
              // Discount Badge
              Positioned(
                top: isLargeTablet ? 16 : (isTablet ? 12 : 8),
                right: isLargeTablet ? 16 : (isTablet ? 12 : 8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeTablet ? 12 : (isTablet ? 8 : 6),
                    vertical: isLargeTablet ? 6 : (isTablet ? 4 : 3),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                  ),
                  child: Text(
                    offer['discount'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content Section - Flexible height with proper spacing
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    offer['title'] as String,
                    style: TextStyle(
                      fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
                  
                  // Store info
                  Row(
                    children: [
                      Icon(Icons.store, size: isLargeTablet ? 18 : (isTablet ? 16 : 14), color: Colors.grey[600]),
                      SizedBox(width: isLargeTablet ? 6 : (isTablet ? 4 : 3)),
                      Expanded(
                        child: Text(
                          offer['store'] as String,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                  
                  // Rating and distance
                  Row(
                    children: [
                      Icon(Icons.star, size: isLargeTablet ? 18 : (isTablet ? 16 : 14), color: Colors.amber),
                      SizedBox(width: isLargeTablet ? 6 : (isTablet ? 4 : 3)),
                      Text(
                        '${offer['rating']}',
                        style: TextStyle(
                          fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                      Icon(Icons.location_on, size: isLargeTablet ? 18 : (isTablet ? 16 : 14), color: Colors.grey[600]),
                      SizedBox(width: isLargeTablet ? 6 : (isTablet ? 4 : 3)),
                      Expanded(
                        child: Text(
                          offer['distance'] as String,
                          style: TextStyle(
                            fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStoresList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final stores = [
      {'name': 'TechMart', 'category': 'Electronics', 'rating': 4.5, 'distance': '0.5km', 'offers': 3},
      {'name': 'FashionHub', 'category': 'Fashion', 'rating': 4.2, 'distance': '1.2km', 'offers': 5},
      {'name': 'HomeStore', 'category': 'Home & Garden', 'rating': 4.7, 'distance': '0.8km', 'offers': 2},
    ];
    
    return Column(
      children: stores.map((store) => _buildStoreCard(store, isSmallScreen, isTablet, isLargeTablet)).toList(),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store, bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
      padding: EdgeInsets.all(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Icon
          Container(
            width: isLargeTablet ? 96 : (isTablet ? 80 : 60),
            height: isLargeTablet ? 96 : (isTablet ? 80 : 60),
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
            ),
            child: Icon(
              Icons.store,
              color: const Color(0xFF2979FF),
              size: isLargeTablet ? 48 : (isTablet ? 40 : 30),
            ),
          ),
          
          SizedBox(width: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          
          // Store Info - Flexible height for better responsiveness
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Store name and category
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store['name'] as String,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 24 : (isTablet ? 20 : 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                    Text(
                      store['category'] as String,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                
                // Store details - Flexible height row
                Row(
                  children: [
                    Icon(Icons.star, size: isLargeTablet ? 20 : (isTablet ? 18 : 16), color: Colors.amber),
                    SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                    Text(
                      '${store['rating']}',
                      style: TextStyle(
                        fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                    Icon(Icons.location_on, size: isLargeTablet ? 20 : (isTablet ? 18 : 16), color: Colors.grey[600]),
                    SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                    Expanded(
                      child: Text(
                        store['distance'] as String,
                        style: TextStyle(
                          fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
                    Icon(Icons.local_offer, size: isLargeTablet ? 20 : (isTablet ? 18 : 16), color: Colors.orange),
                    SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                    Text(
                      '${store['offers']} offers',
                      style: TextStyle(
                        fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons - Flexible height column
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.favorite_border, 
                  color: Colors.grey[600],
                  size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
                ),
                onPressed: () {
                  // TODO: Add to favorites
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.directions, 
                  color: const Color(0xFF2979FF),
                  size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
                ),
                onPressed: () {
                  // TODO: Get directions
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(bool isSmallScreen, bool isTablet, bool isLandscape, bool isLargeTablet) {
    final categories = [
      {'name': 'Electronics', 'icon': Icons.phone_android, 'color': Colors.blue},
      {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pink},
      {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Home', 'icon': Icons.home, 'color': Colors.green},
      {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': Colors.purple},
      {'name': 'Books', 'icon': Icons.book, 'color': Colors.brown},
      {'name': 'Beauty', 'icon': Icons.face, 'color': Colors.red},
      {'name': 'Automotive', 'icon': Icons.directions_car, 'color': Colors.grey},
    ];
    
    // Improved responsive grid layout
    int crossAxisCount;
    if (isLargeTablet) {
      crossAxisCount = isLandscape ? 6 : 4;
    } else if (isTablet) {
      crossAxisCount = isLandscape ? 4 : 3;
    } else {
      crossAxisCount = isLandscape ? 3 : 2;
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isLargeTablet ? 20 : (isTablet ? 16 : 12),
        mainAxisSpacing: isLargeTablet ? 20 : (isTablet ? 16 : 12),
        childAspectRatio: isLargeTablet ? 1.1 : (isTablet ? 1.0 : 0.9),
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category, isSmallScreen, isTablet, isLargeTablet);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: (category['color'] as Color).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
            decoration: BoxDecoration(
              color: (category['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
            ),
            child: Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
              size: isLargeTablet ? 48 : (isTablet ? 40 : 32),
            ),
          ),
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
            child: Text(
              category['name'] as String,
              style: TextStyle(
                fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
        ],
      ),
    );
  }

  Widget _buildRecentSearchesList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final searches = [
      'iPhone 15 Pro',
      'Nike running shoes',
      'Coffee shops near me',
      'Gaming laptops',
      'Organic groceries',
    ];
    
    return Column(
      children: searches.map((search) => _buildSearchItem(search, isSmallScreen, isTablet, isLargeTablet)).toList(),
    );
  }

  Widget _buildSearchItem(String search, bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      padding: EdgeInsets.symmetric(
        horizontal: isLargeTablet ? 24 : (isTablet ? 20 : 16), 
        vertical: isLargeTablet ? 18 : (isTablet ? 16 : 12)
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history, 
            size: isLargeTablet ? 28 : (isTablet ? 24 : 20), 
            color: Colors.grey[600]
          ),
          SizedBox(width: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
          Expanded(
            child: Text(
              search,
              style: TextStyle(
                fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search, 
              size: isLargeTablet ? 28 : (isTablet ? 24 : 20), 
              color: const Color(0xFF2979FF)
            ),
            onPressed: () {
              // TODO: Perform search
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationsList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final recommendations = [
      {'title': 'Based on your location', 'description': 'Stores within 2km radius', 'icon': Icons.location_on},
      {'title': 'Price comparison', 'description': 'Best deals for electronics', 'icon': Icons.compare_arrows},
      {'title': 'Personalized picks', 'description': 'Based on your preferences', 'icon': Icons.psychology},
    ];
    
    return Column(
      children: recommendations.map((rec) => _buildRecommendationCard(rec, isSmallScreen, isTablet, isLargeTablet)).toList(),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
      padding: EdgeInsets.all(isLargeTablet ? 24 : (isTablet ? 20 : 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
            ),
            child: Icon(
              rec['icon'] as IconData,
              color: const Color(0xFF2979FF),
              size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
            ),
          ),
          
          SizedBox(width: isLargeTablet ? 24 : (isTablet ? 20 : 16)),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['title']!,
                  style: TextStyle(
                    fontSize: isLargeTablet ? 22 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                Text(
                  rec['description']!,
                  style: TextStyle(
                    fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios, 
              color: Colors.grey[400],
              size: isLargeTablet ? 28 : (isTablet ? 24 : 24),
            ),
            onPressed: () {
              // TODO: Navigate to recommendations
            },
          ),
        ],
      ),
    );
  }
} 