import 'package:flutter/material.dart';
import '../widgets/animated_message_dialog.dart';
import 'map_screen.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
  int _unreadNotifications = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _enforceRoleAccess();
    // Show welcome message after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasShownWelcome) {
          _showWelcomeMessage();
        }
      });
    });
  }

  Future<void> _loadNotificationCount() async {
    final count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotifications = count;
      });
    }
  }

  Future<void> _enforceRoleAccess() async {
    try {
      final user = await AuthService.getUser();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
      if (user != null && user.role == 'shop') {
        Navigator.of(context).pushReplacementNamed('/shop-owner-dashboard');
      }
    } catch (_) {}
  }

  void _showComparisonDialog() {
    // Comparison requires real data; navigate to stores or show info
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select shops from Stores to compare')),
    );
    Navigator.of(context).pushNamed('/stores');
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
          children: [
                // Header Section - Fixed height
                Container(
                  padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : (isSmallScreen ? 12 : 16)))),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Top Row - Logo, Notifications, Profile
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo
                          Row(
                            children: [
                              Container(
                                width: isLargeTablet ? 48 : (isTablet ? 40 : 32),
                                height: isLargeTablet ? 48 : (isTablet ? 40 : 32),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2979FF), Color(0xFF2DD4BF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                                ),
                                child: Icon(
                                  Icons.radar,
                                  color: Colors.white,
                                  size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
                                ),
                              ),
                              SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            Text(
              'ShopRadar',
              style: TextStyle(
                fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
                          
                          // Right side icons
                          Row(
                            children: [
                              // Notifications
          Stack(
            children: [
              IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed('/notifications');
                                    },
                                    icon: Icon(
                                      Icons.notifications_outlined,
                                      size: isLargeTablet ? 28 : (isTablet ? 24 : 20),
                                      color: const Color(0xFF6B7280),
                                    ),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                      color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                                          '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
                              
                              SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                              
                              // Profile
                              GestureDetector(
                                onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
                                child: CircleAvatar(
                                  radius: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                                  backgroundColor: const Color(0xFF2979FF),
                                  child: Text(
                                    _currentUser?.fullName?.isNotEmpty == true 
                                        ? _currentUser!.fullName![0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                      
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for products, stores, or deals...',
                            hintStyle: TextStyle(
                              color: const Color(0xFF9CA3AF),
                              fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: const Color(0xFF6B7280),
                              size: isLargeTablet ? 24 : (isTablet ? 20 : 18),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // Voice search functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Voice search coming soon!')),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.mic,
                                    color: const Color(0xFF6B7280),
                                    size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // Filter functionality
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Filter options coming soon!')),
                                    );
                                  },
                                  icon: Icon(
                                    Icons.tune,
                                    color: const Color(0xFF6B7280),
                                    size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                                  ),
                                ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12),
                              vertical: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              Navigator.of(context).pushNamed('/search-results', arguments: {'query': value});
                            }
                          },
                        ),
                      ),
                      
                      SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                      
                      // Quick Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickCategory('Electronics', Icons.devices, false, isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet),
                            SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                            _buildQuickCategory('Fashion', Icons.checkroom, false, isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet),
                            SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                            _buildQuickCategory('Food', Icons.restaurant, false, isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet),
                            SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                            _buildQuickCategory('Health', Icons.health_and_safety, false, isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet),
                            SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                            _buildQuickCategory('Sports', Icons.sports, false, isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isLargeTablet ? 20 : (isTablet ? 16 : 12)),
                      
                      // Action Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Map View',
                              Icons.map,
                              const Color(0xFF2979FF),
                              () {
                                setState(() {
                                  _isMapView = !_isMapView;
                                });
                              },
                              isTablet,
                              isLargeTablet,
                            ),
                          ),
                          SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                          Expanded(
                            child: _buildActionButton(
                              'Compare',
                              Icons.compare,
                              const Color(0xFF2DD4BF),
                              _showComparisonDialog,
                              isTablet,
                              isLargeTablet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Main Content - Flexible and responsive
                Expanded(
                  child: _isMapView ? _buildMapView(isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet, isLandscape, isPhoneLandscape) : _buildListView(isSmallScreen, isMedium, isLarge, isExtraLarge, isTablet, isLargeTablet, isLandscape, isPhoneLandscape, constraints.maxHeight),
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

  Widget _buildQuickCategory(String title, IconData icon, bool isSelected, bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge, bool isTablet, bool isLargeTablet) {
    return GestureDetector(
      onTap: () {
        // Handle category selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Searching for $title...')),
        );
      },
      child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12),
          vertical: isLargeTablet ? 12 : (isTablet ? 10 : 8),
      ),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : Colors.white,
          borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          border: Border.all(
            color: isSelected ? const Color(0xFF2979FF) : const Color(0xFFE5E7EB),
            width: 1,
          ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
          ),
            SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
          Text(
            title,
            style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                fontWeight: FontWeight.w500,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap, bool isTablet, bool isLargeTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isLargeTablet ? 16 : (isTablet ? 14 : 12),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isLargeTablet ? 20 : (isTablet ? 18 : 16)),
            SizedBox(width: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge, bool isTablet, bool isLargeTablet, bool isLandscape, bool isPhoneLandscape) {
    return Container(
      margin: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        child: const MapScreen(),
      ),
    );
  }

  Widget _buildListView(bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge, bool isTablet, bool isLargeTablet, bool isLandscape, bool isPhoneLandscape, double availableHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isExtraLarge ? 40 : (isLarge ? 32 : (isMedium ? 24 : (isSmallScreen ? 16 : 20)))),
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
            
            SizedBox(height: isLargeTablet ? 32 : (isTablet ? 28 : 24)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isTablet, bool isLargeTablet) {
    return Row(
        children: [
          Container(
          padding: EdgeInsets.all(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
          ),
          child: Icon(
            icon,
            color: color,
            size: isLargeTablet ? 24 : (isTablet ? 20 : 18),
          ),
        ),
        SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
        Text(
              title,
              style: TextStyle(
            fontSize: isLargeTablet ? 24 : (isTablet ? 20 : 18),
                fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
    );
  }

  Widget _buildFeaturedOfferCard(int index, bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final offers = [
      {'title': '50% Off Electronics', 'subtitle': 'Limited Time', 'color': Colors.orange},
      {'title': 'Buy 2 Get 1 Free', 'subtitle': 'Fashion Week', 'color': Colors.pink},
      {'title': 'Free Delivery', 'subtitle': 'On Orders \$50+', 'color': Colors.green},
      {'title': 'Flash Sale', 'subtitle': 'Ends Tonight', 'color': Colors.red},
      {'title': 'New Arrivals', 'subtitle': 'Fresh Stock', 'color': Colors.blue},
    ];
    
    final offer = offers[index % offers.length];
    
    return Container(
      width: isLargeTablet ? 280 : (isTablet ? 240 : 200),
      margin: EdgeInsets.only(right: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            offer['color'] as Color,
            (offer['color'] as Color).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
                    borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        boxShadow: [
          BoxShadow(
            color: (offer['color'] as Color).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
              ),
            ],
          ),
            child: Padding(
              padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    offer['title'] as String,
                    style: TextStyle(
                    color: Colors.white,
                      fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                      fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                Text(
                  offer['subtitle'] as String,
                          style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                        ),
                      ),
                    ],
                  ),
                  Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                  'Shop Now',
                        style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNearbyStoresList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final stores = [
      {'name': 'TechMart', 'distance': '0.5 km', 'rating': 4.5, 'category': 'Electronics'},
      {'name': 'Fashion Hub', 'distance': '0.8 km', 'rating': 4.2, 'category': 'Fashion'},
      {'name': 'Fresh Market', 'distance': '1.2 km', 'rating': 4.7, 'category': 'Grocery'},
      {'name': 'Sports Zone', 'distance': '1.5 km', 'rating': 4.3, 'category': 'Sports'},
    ];
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
    return Container(
          margin: EdgeInsets.only(bottom: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
                width: isLargeTablet ? 60 : (isTablet ? 50 : 40),
                height: isLargeTablet ? 60 : (isTablet ? 50 : 40),
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            ),
            child: Icon(
              Icons.store,
              color: const Color(0xFF2979FF),
                  size: isLargeTablet ? 24 : (isTablet ? 20 : 16),
            ),
          ),
              SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store['name'] as String,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: isLargeTablet ? 4 : (isTablet ? 2 : 2)),
                    Text(
                      store['category'] as String,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                Row(
                  children: [
                        Icon(
                          Icons.location_on,
                          color: const Color(0xFF6B7280),
                          size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                        ),
                        SizedBox(width: isLargeTablet ? 4 : (isTablet ? 2 : 2)),
                        Text(
                              store['distance'] as String,
                              style: TextStyle(
                            fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                            color: const Color(0xFF6B7280),
                              ),
                            ),
                    SizedBox(width: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                        ),
                        SizedBox(width: isLargeTablet ? 4 : (isTablet ? 2 : 2)),
                        Text(
                          store['rating'].toString(),
                            style: TextStyle(
                            fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF6B7280),
                size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildCategoriesGrid(bool isSmallScreen, bool isTablet, bool isLandscape, bool isLargeTablet) {
    final categories = [
      {'name': 'Electronics', 'icon': Icons.devices, 'color': Colors.blue},
      {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pink},
      {'name': 'Food', 'icon': Icons.restaurant, 'color': Colors.orange},
      {'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.green},
      {'name': 'Sports', 'icon': Icons.sports, 'color': Colors.purple},
      {'name': 'Books', 'icon': Icons.book, 'color': Colors.brown},
      {'name': 'Home', 'icon': Icons.home, 'color': Colors.teal},
      {'name': 'Beauty', 'icon': Icons.face, 'color': Colors.indigo},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLargeTablet ? 4 : (isTablet ? 3 : 2),
        crossAxisSpacing: isLargeTablet ? 16 : (isTablet ? 12 : 8),
        mainAxisSpacing: isLargeTablet ? 16 : (isTablet ? 12 : 8),
        childAspectRatio: isLargeTablet ? 1.2 : (isTablet ? 1.1 : 1.0),
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Browsing ${category['name']}...')),
            );
          },
          child: Container(
      decoration: BoxDecoration(
          color: (category['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
              border: Border.all(
                color: (category['color'] as Color).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
                  size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
                ),
                SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                Text(
              category['name'] as String,
              style: TextStyle(
                    color: category['color'] as Color,
                    fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
        ],
            ),
      ),
        );
      },
    );
  }

  Widget _buildRecentSearchesList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final searches = [
      'iPhone 15 Pro',
      'Nike Air Max',
      'Organic Vegetables',
      'Gaming Laptop',
      'Yoga Mat',
    ];
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: searches.length,
      itemBuilder: (context, index) {
    return Container(
          margin: EdgeInsets.only(bottom: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
      padding: EdgeInsets.symmetric(
            horizontal: isLargeTablet ? 16 : (isTablet ? 12 : 8),
            vertical: isLargeTablet ? 12 : (isTablet ? 10 : 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history, 
                color: const Color(0xFF6B7280),
                size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
          ),
              SizedBox(width: isLargeTablet ? 12 : (isTablet ? 8 : 6)),
              Expanded(
            child: Text(
                  searches[index],
              style: TextStyle(
                    fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                    color: const Color(0xFF374151),
              ),
            ),
          ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF6B7280),
                size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildAIRecommendationsList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    final recommendations = [
      {'title': 'Based on your location', 'subtitle': 'TechMart - 50% off laptops', 'color': Colors.blue},
      {'title': 'Trending in your area', 'subtitle': 'Fashion Hub - New arrivals', 'color': Colors.pink},
      {'title': 'Personalized for you', 'subtitle': 'Fresh Market - Organic deals', 'color': Colors.green},
    ];
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final rec = recommendations[index];
    return Container(
          margin: EdgeInsets.only(bottom: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
          padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
            border: Border.all(
              color: (rec['color'] as Color).withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: Row(
        children: [
          Container(
                width: isLargeTablet ? 40 : (isTablet ? 36 : 32),
                height: isLargeTablet ? 40 : (isTablet ? 36 : 32),
            decoration: BoxDecoration(
                  color: (rec['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            ),
            child: Icon(
                  Icons.psychology,
                  color: rec['color'] as Color,
                  size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                ),
              ),
              SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
              Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      rec['title'] as String,
                  style: TextStyle(
                        fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: isLargeTablet ? 4 : (isTablet ? 2 : 2)),
                Text(
                      rec['subtitle'] as String,
                  style: TextStyle(
                        fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                        color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
              Icon(
              Icons.arrow_forward_ios, 
                color: const Color(0xFF6B7280),
                size: isLargeTablet ? 16 : (isTablet ? 14 : 12),
          ),
        ],
      ),
        );
      },
    );
  }
} 
