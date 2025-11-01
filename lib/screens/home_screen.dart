import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../widgets/minimal_loader.dart';
import '../widgets/interactive_bottom_nav_bar.dart';
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
      // OPTIMIZED: Start fetching offers immediately without waiting for location
      // This prevents blocking the UI while waiting for GPS
      List<FeaturedOffer> offers = [];
      
      // Fetch offers without location first (fast path)
      debugPrint('[Home Screen] Fetching featured offers immediately (no location filter)');
      offers = await FeaturedOffersService().fetchFeaturedOffers(
        radius: 8000, // 8km radius
      );
      
      // Update UI immediately with initial results
      if (mounted) {
        setState(() {
          _featuredOffers = offers;
          _loadingOffers = false;
        });
      }

      // Then try to get location and update with location-based offers in background
      // This allows the UI to show content quickly while location is being fetched
      try {
        final position = await LocationService.getCurrentLocation().timeout(
          const Duration(seconds: 5), // Timeout after 5 seconds
          onTimeout: () {
            debugPrint('[Home Screen] Location fetch timed out, using global offers');
            return null;
          },
        );
        
        if (position != null && mounted) {
          debugPrint('[Home Screen] Updating offers with location: lat=${position.latitude}, lng=${position.longitude}');
          // Fetch location-based offers in background and update
          final locationOffers = await FeaturedOffersService().fetchFeaturedOffers(
            latitude: position.latitude,
            longitude: position.longitude,
            radius: 8000, // 8km radius (8000 meters) - matches backend default
          );
          
          // Only update if we got better results
          if (locationOffers.isNotEmpty && mounted) {
            setState(() {
              _featuredOffers = locationOffers;
            });
            debugPrint('[Home Screen] Updated with ${locationOffers.length} location-based offers');
          }
        }
      } catch (locationError) {
        debugPrint('[Home Screen] Error fetching location for offers: $locationError');
        // Continue with offers already loaded
      }

      debugPrint('[Home Screen] Loaded ${_featuredOffers.length} featured offers');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingOffers = false;
        });
      }
      debugPrint('[Home Screen] Error initializing featured offers: $e');
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
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(isLargeTablet ? 12 : (isTablet ? 10 : 8)),
                                  child: SvgPicture.asset(
                                    'assets/images/shopradar_icon.svg',
                                    width: isLargeTablet ? 48 : (isTablet ? 40 : 32),
                                    height: isLargeTablet ? 48 : (isTablet ? 40 : 32),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(width: isLargeTablet ? 12 : (isTablet ? 10 : 8)),
            Text(
              'ShopRadar',
              style: GoogleFonts.inter(
                fontSize: isLargeTablet ? 28 : (isTablet ? 24 : 20),
                fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                letterSpacing: -0.3,
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
      bottomNavigationBar: InteractiveBottomNavBar(
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
        items: const [
          NavBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          NavBarItem(
            icon: Icons.store_outlined,
            selectedIcon: Icons.store,
            label: 'Stores',
          ),
          NavBarItem(
            icon: Icons.favorite_border,
            selectedIcon: Icons.favorite,
            label: 'Favorites',
          ),
          NavBarItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCategory(String title, IconData icon, bool isSelected, bool isSmallScreen, bool isMedium, bool isLarge, bool isExtraLarge, bool isTablet, bool isLargeTablet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Provide haptic feedback
          HapticFeedback.mediumImpact();
          // Navigate to stores screen with category filter
          Navigator.of(context).pushNamed(
            '/stores',
            arguments: {'category': title},
          );
        },
        borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
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
                height: isLargeTablet ? 360 : (isTablet ? 340 : 320), // Increased height for better content display
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
    
    return _InteractiveOfferCard(
      offer: offer,
      isTablet: isTablet,
      isLargeTablet: isLargeTablet,
      onTap: () {
        // Navigate to shop details or product details
        HapticFeedback.mediumImpact();
        // You can navigate to shop details or search results
        Navigator.of(context).pushNamed('/search-results', arguments: {'query': offer.product.name});
      },
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
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: MinimalLoader()));
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
    return InkWell(
      onTap: () {
        // Navigate to map with directions to the selected store
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MapScreenFree(
              shopsOverride: [shop],
              routeToShop: shop,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(isLargeTablet ? 16 : (isTablet ? 14 : 12)),
      child: Container(
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
            // Navigate to stores screen with category filter
            Navigator.of(context).pushNamed(
              '/stores',
              arguments: {'category': category['name'] as String},
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

// Interactive offer card widget with e-commerce style design
class _InteractiveOfferCard extends StatefulWidget {
  final FeaturedOffer offer;
  final bool isTablet;
  final bool isLargeTablet;
  final VoidCallback onTap;

  const _InteractiveOfferCard({
    required this.offer,
    required this.isTablet,
    required this.isLargeTablet,
    required this.onTap,
  });

  @override
  State<_InteractiveOfferCard> createState() => _InteractiveOfferCardState();
}

class _InteractiveOfferCardState extends State<_InteractiveOfferCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.isLargeTablet ? 220.0 : (widget.isTablet ? 200.0 : 180.0);
    final cardHeight = widget.isLargeTablet ? 340.0 : (widget.isTablet ? 320.0 : 300.0);
    final hasImage = widget.offer.product.images.isNotEmpty;
    final firstImage = hasImage ? widget.offer.product.images[0] : null;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              margin: EdgeInsets.only(right: widget.isLargeTablet ? 16 : (widget.isTablet ? 12 : 8)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isPressed ? 0.1 : 0.15),
                    blurRadius: _isPressed ? 8 : 12,
                    offset: Offset(0, _isPressed ? 2 : 4),
                    spreadRadius: _isPressed ? 0 : 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Section
                  Stack(
                    children: [
                      Container(
                        height: widget.isLargeTablet ? 180 : (widget.isTablet ? 170 : 160),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: firstImage != null
                            ? ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.network(
                                  firstImage,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                                ),
                              )
                            : _buildPlaceholderImage(),
                      ),
                      // Discount Badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.offer.formattedDiscount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Days Remaining Badge
                      if (widget.offer.daysRemaining > 0 && widget.offer.daysRemaining <= 7)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.offer.daysRemaining}d left',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Content Section
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(widget.isLargeTablet ? 14 : (widget.isTablet ? 12 : 10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              Text(
                                widget.offer.product.name,
                                style: TextStyle(
                                  fontSize: widget.isLargeTablet ? 15 : (widget.isTablet ? 14 : 13),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Offer Title
                              Text(
                                widget.offer.title,
                                style: TextStyle(
                                  fontSize: widget.isLargeTablet ? 13 : (widget.isTablet ? 12 : 11),
                                  color: const Color(0xFF6B7280),
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Price and Rating Row
                              Row(
                                children: [
                                  // Original Price (strikethrough)
                                  if (widget.offer.product.price > 0)
                                    Text(
                                      '\$${widget.offer.product.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: widget.isLargeTablet ? 12 : 11,
                                        color: const Color(0xFF9CA3AF),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  if (widget.offer.product.price > 0) const SizedBox(width: 6),
                                  // Discounted Price
                                  if (widget.offer.product.price > 0)
                                    Text(
                                      '\$${(widget.offer.discountType == 'Percentage' 
                                        ? (widget.offer.product.price * (1 - widget.offer.discountValue / 100))
                                        : (widget.offer.product.price - widget.offer.discountValue)).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: widget.isLargeTablet ? 16 : (widget.isTablet ? 15 : 14),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  const Spacer(),
                                  // Shop Rating
                                  if (widget.offer.shop.rating > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          widget.offer.shop.rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: widget.isLargeTablet ? 12 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                          // Shop Name and Action Button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.offer.shop.name,
                                style: TextStyle(
                                  fontSize: widget.isLargeTablet ? 11 : 10,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2979FF), Color(0xFF1E88E5)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View Offer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey[400],
          size: widget.isLargeTablet ? 80 : (widget.isTablet ? 70 : 60),
        ),
      ),
    );
  }
} 
