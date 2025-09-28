import 'package:flutter/material.dart';
import '../models/shop.dart';
import '../services/favorite_shops_service.dart';
import '../services/shop_offers_service.dart' as offers_service;
import 'map_screen_free.dart';
import '../widgets/rating_widget.dart';
import '../widgets/review_card.dart';

class ShopDetailsScreen extends StatefulWidget {
  final Shop shop;

  const ShopDetailsScreen({
    super.key,
    required this.shop,
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ShopReview> _reviews = [];
  bool _isLoadingReviews = true;
  double _myRating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isFavorite = false;
  
  // Offer-related state
  List<offers_service.ShopOffer> _offers = [];
  bool _isLoadingOffers = true;
  String? _offersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReviews();
    _loadOffers();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoriteShopsService.isFavorite(widget.shop.id);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      final success = await FavoriteShopsService.removeFromFavorites(widget.shop.id);
      if (success && mounted) {
        setState(() {
          _isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      }
    } else {
      final success = await FavoriteShopsService.addToFavorites(widget.shop);
      if (success && mounted) {
        setState(() {
          _isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    // TODO: Replace with real API call to fetch reviews for widget.shop.id
    setState(() {
      _reviews = [];
      _isLoadingReviews = false;
    });
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingOffers = true;
      _offersError = null;
    });

    try {
      final result = await offers_service.ShopOffersService.getShopOffers(
        shopId: widget.shop.id,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _offers = result['offers'] as List<offers_service.ShopOffer>;
            _offersError = null;
          } else {
            _offers = [];
            _offersError = result['message'] ?? 'Failed to load offers';
          }
          _isLoadingOffers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offers = [];
          _offersError = 'Error loading offers: $e';
          _isLoadingOffers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with shop image
          SliverAppBar(
            expandedHeight: isTablet ? 300 : (isLargeScreen ? 350 : 250),
            pinned: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: isTablet ? 24 : 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                onPressed: _toggleFavorite,
                tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                onPressed: () {
                  // TODO: Share shop
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share functionality coming soon!')),
                  );
                },
                tooltip: 'Share shop',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Shop image placeholder
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2979FF).withValues(alpha: 0.8),
                          const Color(0xFF2979FF).withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.store,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Status overlay
                  Positioned(
                    top: 50,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.shop.isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.shop.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Shop info section
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.shop.name,
                          style: TextStyle(
                            fontSize: isTablet ? 28 : (isLargeScreen ? 32 : 24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      RatingWidget(
                        rating: widget.shop.rating,
                        reviewCount: widget.shop.reviewCount,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Category, distance, and offers indicator
                  Row(
                    children: [
                      Icon(Icons.category, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.shop.category,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.shop.formattedDistance,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      if (!_isLoadingOffers && _offers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${_offers.length} Offers',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.shop.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Phone
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.shop.phone,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Hours
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.shop.openingHours,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MapScreenFree(
                                  shopsOverride: [widget.shop],
                                  routeToShop: widget.shop,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2979FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Call shop
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Calling shop...')),
                            );
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2979FF),
                            side: const BorderSide(color: Color(0xFF2979FF)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2979FF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2979FF),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Offers'),
                        if (!_isLoadingOffers && _offers.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_offers.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Reviews'),
                  const Tab(text: 'Info'),
                ],
              ),
            ),
          ),
          
          // Tab content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOffersTab(),
                _buildReviewsTab(),
                _buildInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersTab() {
    if (_isLoadingOffers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading offers...'),
          ],
        ),
      );
    }

    if (_offersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load offers',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _offersError!,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOffers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No current offers',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new deals!',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOffers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOffers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          return _buildOfferCard(_offers[index]);
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return _buildReviewComposer(emptyState: true);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              return ReviewCard(review: _reviews[index]);
            },
          ),
        ),
        _buildReviewComposer(),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (widget.shop.description != null) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.shop.description!,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
          ],
          
          // Amenities
          if (widget.shop.amenities.isNotEmpty) ...[
            const Text(
              'Amenities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.shop.amenities.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    amenity,
                    style: const TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Business hours
          const Text(
            'Business Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildHoursRow('Monday - Friday', '9:00 AM - 9:00 PM'),
                _buildHoursRow('Saturday', '10:00 AM - 8:00 PM'),
                _buildHoursRow('Sunday', '11:00 AM - 6:00 PM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewComposer({bool emptyState = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (emptyState) ...[
            const SizedBox(height: 24),
            const Icon(Icons.reviews, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No reviews yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 6),
            const Text('Be the first to review this shop!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Text('Your Rating: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              for (int i = 1; i <= 5; i++)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    i <= _myRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _myRating = i.toDouble()),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience... (UI only, no backend)',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2979FF))),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted (UI only).')));
                _reviewController.clear();
              },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Submit Review'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2979FF), foregroundColor: Colors.white),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(offers_service.ShopOffer offer) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final discountedPrice = offer.getDiscountedPrice();
    final hasImage = offer.product.images.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[100]!, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to offer details or product page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Viewing offer: ${offer.title}')),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with offer badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: isTablet ? 80 : 60,
                      height: isTablet ? 80 : 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6B35).withValues(alpha: 0.1),
                            const Color(0xFFFF6B35).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                offer.product.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildOfferIcon(),
                              ),
                            )
                          : _buildOfferIcon(),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Offer title and discount badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  offer.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isTablet ? 18 : 16,
                                    color: Colors.grey[800],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  offer.formattedDiscount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          // Product name
                          Text(
                            offer.product.name,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          // Category and time remaining
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  offer.product.category,
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(width: isTablet ? 8 : 6),
                              if (offer.daysRemaining > 0)
                                Text(
                                  '${offer.daysRemaining} days left',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.orange[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else if (offer.hoursRemaining > 0)
                                Text(
                                  '${offer.hoursRemaining} hours left',
                                  style: TextStyle(
                                    fontSize: isTablet ? 12 : 10,
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 12 : 8),
                // Price section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${offer.product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '₹${discountedPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFF6B35),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward, size: isTablet ? 16 : 14, color: const Color(0xFF2979FF)),
                          SizedBox(width: isTablet ? 4 : 2),
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2979FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Description
                if (offer.description.isNotEmpty) ...[
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    offer.description,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.1),
            const Color(0xFFFF6B35).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.local_offer,
        color: Color(0xFFFF6B35),
        size: 32,
      ),
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(hours, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
