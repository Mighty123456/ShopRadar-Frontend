import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/shop_service.dart';
import '../models/shop.dart';
import '../widgets/shop_info_window.dart';
import '../widgets/map_controls.dart';
import '../widgets/search_overlay.dart';
import 'map_screen_free.dart';

class MapScreen extends StatefulWidget {
  final String? searchQuery;
  final String? category;
  final List<Shop>? shopsOverride;
  
  const MapScreen({
    super.key,
    this.searchQuery,
    this.category,
    this.shopsOverride,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<Shop> _shops = [];
  bool _isLoading = true;
  bool _showSearchOverlay = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  LatLng? _currentLocation;
  Shop? _selectedShop;
  bool _showShopDetails = false;
  // Google-specific fields removed for WebView implementation
  
  // Simple distance calculator (Haversine) for non-ML ordering
  double _distanceMeters(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // meters
    final double dLat = _deg2rad(b.latitude - a.latitude);
    final double dLon = _deg2rad(b.longitude - a.longitude);
    final double lat1 = _deg2rad(a.latitude);
    final double lat2 = _deg2rad(b.latitude);
    final double sinHalfDLat = math.sin(dLat / 2);
    final double sinHalfDLon = math.sin(dLon / 2);
    final double h = sinHalfDLat * sinHalfDLat + math.cos(lat1) * math.cos(lat2) * sinHalfDLon * sinHalfDLon;
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadius * c;
  }
  
  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  // Map configuration
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
    if (widget.searchQuery != null) {
      _searchQuery = widget.searchQuery!;
    }
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Ensure we have location permission first
      bool granted = await LocationService.isLocationPermissionGranted();
      if (!granted) {
        granted = await LocationService.requestLocationPermission();
      }
      if (!mounted) return;

      // Get current location (may be null if denied)
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        }
        
        // Move camera to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(_currentLocation!),
          );
        }
      }
      
      // Load nearby shops
      await _loadNearbyShops();
    } catch (e) {
      debugPrint('Error initializing map: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNearbyShops() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // If UI passes in override shops (mock), use them directly
      if (widget.shopsOverride != null && widget.shopsOverride!.isNotEmpty) {
        _shops = widget.shopsOverride!;
        _updateMarkers();
        return;
      }

      if (_currentLocation == null) {
        return;
      }

      final result = await ShopService.getNearbyShops(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radius: 5000,
      );

      if (result['success'] == true) {
        final List<dynamic> raw = result['shops'] as List<dynamic>;
        final List<Shop> shops = raw.map((s) {
          final Map<String, dynamic> shop = s as Map<String, dynamic>;
          final loc = shop['location'] as Map<String, dynamic>?;
          final coords = (loc != null ? loc['coordinates'] : null) as List<dynamic>?;
          final double latitude = coords != null && coords.length == 2 ? (coords[1] as num).toDouble() : 0.0;
          final double longitude = coords != null && coords.length == 2 ? (coords[0] as num).toDouble() : 0.0;
          // Compute rough distance in km if we have current location
          double distanceKm = 0.0;
          if (_currentLocation != null) {
            distanceKm = _distanceMeters(_currentLocation!, LatLng(latitude, longitude)) / 1000.0;
          }
          // Parse offers from backend response
          final List<ShopOffer> offers = [];
          if (shop['offers'] is List) {
            debugPrint('Found ${(shop['offers'] as List).length} offers for shop ${shop['shopName']}');
            for (final offerData in shop['offers'] as List) {
              if (offerData is Map<String, dynamic>) {
                final discountValue = (offerData['discountValue'] as num?)?.toDouble() ?? 0.0;
                final discountType = offerData['discountType']?.toString() ?? 'Percentage';
                
                // Convert to percentage if it's a fixed amount (this is a simplified conversion)
                double discountPercent = discountValue;
                if (discountType == 'Fixed Amount') {
                  // For fixed amount, we'll use the raw value as percentage
                  // In a real implementation, you'd need the product price to calculate percentage
                  discountPercent = discountValue;
                }
                
                offers.add(ShopOffer(
                  id: (offerData['id'] ?? '').toString(),
                  title: (offerData['title'] ?? '').toString(),
                  description: (offerData['description'] ?? '').toString(),
                  discount: discountPercent,
                  validUntil: offerData['endDate'] != null 
                      ? DateTime.parse(offerData['endDate'].toString())
                      : DateTime.now().add(const Duration(days: 7)),
                ));
              }
            }
          } else {
            debugPrint('No offers found for shop ${shop['shopName']}');
          }

          return Shop(
            id: (shop['_id'] ?? shop['id'] ?? '').toString(),
            name: (shop['shopName'] ?? shop['name'] ?? '').toString(),
            category: shop['category']?.toString() ?? '',
            address: (shop['address'] ?? '').toString(),
            latitude: latitude,
            longitude: longitude,
            rating: (shop['rating'] as num?)?.toDouble() ?? 0.0,
            reviewCount: (shop['reviewCount'] as int?) ?? 0,
            distance: distanceKm,
            offers: offers,
            isOpen: shop['isLive'] == true,
            openingHours: '',
            phone: (shop['phone'] ?? '').toString(),
            imageUrl: null,
            description: null,
            amenities: const [],
            lastUpdated: null,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _shops = shops;
          });
        }

        if (_currentLocation != null && _shops.isNotEmpty) {
          _shops.sort((a, b) {
            final da = _distanceMeters(_currentLocation!, LatLng(a.latitude, a.longitude));
            final db = _distanceMeters(_currentLocation!, LatLng(b.latitude, b.longitude));
            return da.compareTo(db);
          });
        }

        _updateMarkers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to load shops')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading shops: $e');
      // Leave list empty on error; do not populate mock data here
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load shops')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  

  void _updateMarkers() {
    _markers.clear();
    
    for (final shop in _shops) {
      _markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          icon: _getMarkerIcon(shop.category),
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: '${shop.rating} ⭐ • ${shop.distance}km',
          ),
          onTap: () => _onMarkerTapped(shop),
        ),
      );
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  BitmapDescriptor _getMarkerIcon(String category) {
    // Return different colored markers based on category
    switch (category.toLowerCase()) {
      case 'electronics':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'fashion':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      case 'home & garden':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'food':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _onMarkerTapped(Shop shop) {
    if (mounted) {
      setState(() {
        _selectedShop = shop;
        _showShopDetails = true;
      });
    }
  }

  void _onSearch(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        _showSearchOverlay = false;
      });
    }
    _loadNearbyShops();
  }

  void _onCategoryChanged(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
      });
    }
    _loadNearbyShops();
  }

  void _onMyLocationPressed() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && _mapController != null) {
      final location = LatLng(position.latitude, position.longitude);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16.0),
      );
    }
  }

  void _onDirectionsPressed(Shop shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreenFree(
          shopsOverride: [shop],
          routeToShop: shop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultLocation,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _mapController!.moveCamera(
                  CameraUpdate.newLatLng(_currentLocation!),
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
          ),
          
          // Back/Exit Button
          Positioned(
            top: MediaQuery.of(context).padding.top + (isTablet ? 20 : 16),
            left: isTablet ? 20 : 16,
            child: Material(
              color: Colors.white,
              elevation: 2,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: isTablet ? 24 : 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
              ),
            ),
          ),
          
          // Search Overlay
          if (_showSearchOverlay)
            SearchOverlay(
              onSearch: _onSearch,
              onCategoryChanged: _onCategoryChanged,
              selectedCategory: _selectedCategory,
              searchQuery: _searchQuery,
              onClose: () {
                setState(() {
                  _showSearchOverlay = false;
                });
              },
            ),
          
          // Map Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + (isTablet ? 20 : 16),
            right: isTablet ? 20 : 16,
            child: MapControls(
              onSearchPressed: () {
                setState(() {
                  _showSearchOverlay = true;
                });
              },
              onMyLocationPressed: _onMyLocationPressed,
              onFilterPressed: () {
                // TODO: Show filter options
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter options coming soon!')),
                );
              },
            ),
          ),
          
          // Shop Details Bottom Sheet
          if (_showShopDetails && _selectedShop != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ShopInfoWindow(
                shop: _selectedShop!,
                onClose: () {
                  if (mounted) {
                    setState(() {
                      _showShopDetails = false;
                      _selectedShop = null;
                    });
                  }
                },
                onDirections: () => _onDirectionsPressed(_selectedShop!),
                onViewDetails: () {
                  // TODO: Navigate to shop details page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening ${_selectedShop!.name} details')),
                  );
                },
              ),
            ),
          
          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
