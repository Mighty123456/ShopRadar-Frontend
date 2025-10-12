import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/animated_message_dialog.dart';
import 'map_screen_free.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/shop_service.dart';
import '../services/recent_search_service.dart';
import '../services/featured_offers_service.dart';
import '../models/shop.dart';
import '../services/realtime_service.dart';
import '../widgets/voice_search_button.dart';
import '../utils/shop_utils.dart';

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
  List<Shop> _nearbyShops = const [];
  bool _loadingNearby = false;
  List<String> _recentSearches = const [];
  List<FeaturedOffer> _featuredOffers = [];
  bool _loadingOffers = false;
  StreamSubscription<List<FeaturedOffer>>? _offersSubscription;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
    _enforceRoleAccess();
    _loadRecentSearches();
    _loadNearbyStores();
    _initializeFeaturedOffers();
    _initializeRealtimeNotifications();
    // Show welcome message after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_hasShownWelcome) {
          _showWelcomeMessage();
        }
      });
    });
  }

  void _initializeRealtimeNotifications() {
    _realtimeSubscription = RealtimeService().events.listen((event) async {
      try {
        if (!mounted) return;
        if (event['type'] == 'new_shop_notification' && event['notification'] != null) {
          final AppNotification n = event['notification'] as AppNotification;
          MessageHelper.showAnimatedMessage(
            context,
            title: n.title,
            message: n.message,
            type: MessageType.info,
            duration: const Duration(seconds: 5),
          );
          await _loadNotificationCount();
        }
      } catch (_) {}
    });
  }
  Future<void> _loadRecentSearches() async {
    final List<String> recents = await RecentSearchService.getRecentSearches();
    if (!mounted) return;
    setState(() {
      _recentSearches = recents;
    });
  }

  Future<void> _initializeFeaturedOffers() async {
    setState(() {
      _loadingOffers = true;
    });

    try {
      // Initialize WebSocket connection
      await FeaturedOffersService().initializeWebSocket();
      
      // Listen to real-time updates
      _offersSubscription = FeaturedOffersService().offersStream.listen((offers) {
        if (mounted) {
          setState(() {
            _featuredOffers = offers;
            _loadingOffers = false;
          });
        }
      });

      // Fetch initial offers
      try {
        final position = await LocationService.getCurrentLocation();
        if (position != null) {
          await FeaturedOffersService().fetchFeaturedOffers(
            latitude: position.latitude,
            longitude: position.longitude,
            limit: 10,
          );
        } else {
          // If location is null, fetch offers without location filter
          await FeaturedOffersService().fetchFeaturedOffers(limit: 10);
        }
      } catch (e) {
        // If location fails, fetch offers without location filter
        await FeaturedOffersService().fetchFeaturedOffers(limit: 10);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingOffers = false;
        });
      }
      debugPrint('Error initializing featured offers: $e');
    }
  }

  Future<void> _loadNearbyStores() async {
    setState(() {
      _loadingNearby = true;
    });
    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          setState(() {
            _nearbyShops = const [];
            _loadingNearby = false;
          });
        }
        return;
      }
      final result = await ShopService.getNearbyShops(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      if (result['success'] == true && result['shops'] is List) {
        final List<dynamic> list = result['shops'] as List<dynamic>;
        final shops = list.map((e) => ShopUtils.createShopWithDistance(
          shopData: e,
          userLatitude: position.latitude,
          userLongitude: position.longitude,
          offers: const [],
        )).toList();
        setState(() {
          _nearbyShops = shops;
        });
      } else {
        setState(() {
          _nearbyShops = const [];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearbyShops = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingNearby = false;
        });
      }
    }
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
                            suffixIcon: VoiceSearchButton(
                              onVoiceResult: (result) {
                                _searchController.text = result;
                                // Automatically trigger search
                                if (result.isNotEmpty) {
                                  final navigator = Navigator.of(context);
                                  RecentSearchService.addSearch(result);
                                  _loadRecentSearches();
                                  navigator.pushNamed('/search-results', arguments: {'query': result});
                                }
                              },
                              iconColor: const Color(0xFF6B7280),
                              iconSize: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                              tooltip: 'Voice search',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isLargeTablet ? 20 : (isTablet ? 16 : 12),
                              vertical: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                            ),
                          ),
                          onSubmitted: (value) async {
                            if (value.isNotEmpty) {
                              final navigator = Navigator.of(context);
                              await RecentSearchService.addSearch(value);
                              await _loadRecentSearches();
                              navigator.pushNamed('/search-results', arguments: {'query': value});
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
        child: MapScreenFree(
          onBack: () {
            setState(() {
              _isMapView = false;
            });
          },
        ),
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
                  itemCount: _loadingOffers ? 3 : (_featuredOffers.isEmpty ? 1 : _featuredOffers.length),
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
    // Use real data if available, otherwise show loading or fallback
    if (_loadingOffers) {
      return _buildLoadingOfferCard(isSmallScreen, isTablet, isLargeTablet);
    }
    
    if (_featuredOffers.isEmpty) {
      return _buildEmptyOfferCard(isSmallScreen, isTablet, isLargeTablet);
    }
    
    final offer = _featuredOffers[index % _featuredOffers.length];
    final colors = [Colors.orange, Colors.pink, Colors.green, Colors.red, Colors.blue, Colors.purple, Colors.teal];
    final color = colors[index % colors.length];
    
    return Container(
      width: isLargeTablet ? 280 : (isTablet ? 240 : 200),
      margin: EdgeInsets.only(right: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
                  offer.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
                Text(
                  offer.formattedDiscount,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isLargeTablet ? 4 : 2),
                Text(
                  offer.shop.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (offer.daysRemaining > 0) ...[
                  SizedBox(height: isLargeTablet ? 4 : 2),
                  Text(
                    '${offer.daysRemaining} days left',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: isLargeTablet ? 10 : (isTablet ? 8 : 6),
                    ),
                  ),
                ],
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

  Widget _buildLoadingOfferCard(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    return Container(
      width: isLargeTablet ? 280 : (isTablet ? 240 : 200),
      margin: EdgeInsets.only(right: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: isLargeTablet ? 20 : (isTablet ? 16 : 14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            Container(
              height: isLargeTablet ? 16 : (isTablet ? 14 : 12),
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            Container(
              height: isLargeTablet ? 14 : (isTablet ? 12 : 10),
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOfferCard(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    return Container(
      width: isLargeTablet ? 280 : (isTablet ? 240 : 200),
      margin: EdgeInsets.only(right: isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLargeTablet ? 20 : (isTablet ? 16 : 12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: Colors.grey[400],
              size: isLargeTablet ? 32 : (isTablet ? 28 : 24),
            ),
            SizedBox(height: isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            Text(
              'No offers available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isLargeTablet ? 14 : (isTablet ? 12 : 10),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isLargeTablet ? 4 : 2),
            Text(
              'Check back later',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: isLargeTablet ? 12 : (isTablet ? 10 : 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyStoresList(bool isSmallScreen, bool isTablet, bool isLargeTablet) {
    if (_loadingNearby) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (_nearbyShops.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _nearbyShops.length,
      itemBuilder: (context, index) {
        final shop = _nearbyShops[index];
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
                    shop.name,
                      style: TextStyle(
                        fontSize: isLargeTablet ? 18 : (isTablet ? 16 : 14),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: isLargeTablet ? 4 : (isTablet ? 2 : 2)),
                    Text(
                    shop.category,
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
                        shop.formattedDistance,
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
                        shop.rating.toStringAsFixed(1),
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
    if (_recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentSearches.length,
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
                  _recentSearches[index],
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
    if (_nearbyShops.isEmpty) {
      return const SizedBox.shrink();
    }
    // Simple heuristic: top 3 by rating from nearby
    final List<Shop> top = List<Shop>.from(_nearbyShops)..sort((a, b) => b.rating.compareTo(a.rating));
    final recs = top.take(3).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recs.length,
      itemBuilder: (context, index) {
        final Shop shop = recs[index];
    return Container(
          margin: EdgeInsets.only(bottom: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
          padding: EdgeInsets.all(isLargeTablet ? 16 : (isTablet ? 12 : 8)),
      decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isLargeTablet ? 8 : (isTablet ? 6 : 4)),
            ),
            child: Icon(
                  Icons.psychology,
                  color: const Color(0xFF2DD4BF),
                  size: isLargeTablet ? 20 : (isTablet ? 18 : 16),
                ),
              ),
              SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
              Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      'Recommended nearby',
                  style: TextStyle(
                        fontSize: isLargeTablet ? 16 : (isTablet ? 14 : 12),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: isLargeTablet ? 4 : (isTablet ? 2 : 2)),
                Text(
                      '${shop.name} • ${shop.category} • ${shop.rating.toStringAsFixed(1)} ★',
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

  @override
  void dispose() {
    _offersSubscription?.cancel();
    _realtimeSubscription?.cancel();
    // Don't dispose the singleton service as other screens might need it
    super.dispose();
  }
} 
