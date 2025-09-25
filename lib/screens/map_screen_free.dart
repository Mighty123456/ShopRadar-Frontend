import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/shop_service.dart';
import '../models/shop.dart';
import '../widgets/shop_info_window.dart';
import '../widgets/map_controls.dart';
import '../widgets/search_overlay.dart';
import '../config/mapbox_config.dart';
import '../services/routing_service.dart';
import '../services/geocoding_service.dart';

class MapScreenFree extends StatefulWidget {
  final String? searchQuery;
  final String? category;
  final List<Shop>? shopsOverride;
  final VoidCallback? onBack;
  final bool showOnlyUser; // when true, only show user's current location
  
  const MapScreenFree({
    super.key,
    this.searchQuery,
    this.category,
    this.shopsOverride,
    this.onBack,
    this.showOnlyUser = false,
  });

  @override
  State<MapScreenFree> createState() => _MapScreenFreeState();
}

class _MapScreenFreeState extends State<MapScreenFree> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  List<Shop> _shops = [];
  final List<latlng.LatLng> _routePolyline = [];
  bool _isLoading = true;
  // Removed overlay usage; keeping UI minimal
  // ignore: unused_field
  bool _showSearchOverlay = false;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  latlng.LatLng? _currentLocation;
  Shop? _selectedShop;
  // ignore: unused_field
  bool _showShopDetails = false;
  Shop? _recommendedShop;
  // Google-specific fields removed for WebView implementation
  
  // Simple distance calculator (Haversine)
  double _distanceMeters(latlng.LatLng a, latlng.LatLng b) {
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

  double _deg2rad(double deg) => deg * (math.pi / 180);

  // Map configuration
  static final latlng.LatLng _defaultCenter = latlng.LatLng(MapConfig.defaultLatitude, MapConfig.defaultLongitude);

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
      // Ensure location services are enabled; prompt user to enable if off
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        final shouldOpen = await _askToEnableLocationServices();
        if (shouldOpen == true) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
      }

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
            _currentLocation = latlng.LatLng(position.latitude, position.longitude);
          });
        }
        
        // Move camera to current location
        try {
          _mapController.move(_currentLocation!, MapConfig.defaultZoom);
        } catch (_) {}
      }
      
      // If shops are provided from previous screen, render them
      if (widget.shopsOverride != null && widget.shopsOverride!.isNotEmpty) {
        _shops = widget.shopsOverride!;
        _updateMarkers();
      }
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

  Future<bool?> _askToEnableLocationServices() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Location'),
          content: const Text('Location services are turned off. Enable them to see your current location and nearby shops.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadShops() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // If UI passes in override shops (mock), use them directly
      if (widget.shopsOverride != null && widget.shopsOverride!.isNotEmpty) {
        _shops = widget.shopsOverride!;
        _rankAndRecommend();
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
            distanceKm = _distanceMeters(_currentLocation!, latlng.LatLng(latitude, longitude)) / 1000.0;
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
            offers: const [],
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
            final da = _distanceMeters(_currentLocation!, latlng.LatLng(a.latitude, a.longitude));
            final db = _distanceMeters(_currentLocation!, latlng.LatLng(b.latitude, b.longitude));
            return da.compareTo(db);
          });
        }

        _rankAndRecommend();
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
      final double discount = shop.offers.isNotEmpty ? shop.offers.first.discount : 0.0;
      final double rating = shop.rating;
      Color pinColor = const Color(0xFF2979FF); // default blue
      if (rating >= 4.5 || discount >= 30) {
        pinColor = const Color(0xFFFFB300); // amber for best
      } else if (rating >= 4.0 || discount >= 10) {
        pinColor = const Color(0xFF2E7D32); // green for good
      }
      _markers.add(
        Marker(
          point: latlng.LatLng(shop.latitude, shop.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(shop),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pinColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(Icons.location_on, color: Colors.white),
            ),
          ),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  void _rankAndRecommend() {
    if (_shops.isEmpty) {
      _recommendedShop = null;
      return;
    }
    // Simple weighted score: distance (lower better), discount (higher better), rating (higher better)
    double bestScore = -1e9;
    Shop? best;
    for (final s in _shops) {
      final double distanceScore = -s.distance; // closer better
      final double discount = s.offers.isNotEmpty ? s.offers.map((o) => o.discount).reduce((a, b) => a > b ? a : b) : 0.0;
      final double discountScore = discount / 100.0;
      final double ratingScore = s.rating / 5.0;
      final double score = (0.5 * ratingScore) + (0.3 * discountScore) + (0.2 * distanceScore);
      if (score > bestScore) {
        bestScore = score;
        best = s;
      }
    }
    _recommendedShop = best;
  }

  // For category-based styling we style in builder above; no BitmapDescriptor in flutter_map

  void _onMarkerTapped(Shop shop) {
    if (mounted) {
      setState(() {
        _selectedShop = shop;
        _showShopDetails = true;
        _drawRouteTo(shop);
      });
    }
  }

  void _onSearch(String query) {
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      _showSearchOverlay = false;
    });
    // Test-only: center map using Nominatim forward geocoding
    GeocodingService.forwardSearch(query).then((res) {
      if (!mounted || res == null) {
        _loadShops();
        return;
      }
      _mapController.move(latlng.LatLng(res.center.latitude, res.center.longitude), 14);
      _loadShops();
    }).catchError((_) {
      _loadShops();
    });
  }

  void _onCategoryChanged(String category) {
    if (mounted) {
      setState(() {
        _selectedCategory = category;
      });
    }
    _loadShops();
  }

  void _onMyLocationPressed() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      final shouldOpen = await _askToEnableLocationServices();
      if (shouldOpen == true) {
        await Geolocator.openLocationSettings();
      }
    }
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      final location = latlng.LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = location;
      });
      _mapController.move(location, 16.0);
    }
  }

  void _onDirectionsPressed(Shop shop) {
    // Open Google Maps for directions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${shop.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _drawRouteTo(Shop shop) {
    _routePolyline.clear();
    if (_currentLocation == null) return;
    final start = _currentLocation!;
    final end = latlng.LatLng(shop.latitude, shop.longitude);
    // Try ORS first; fallback to straight line
    RoutingService.getRoute(start: start, end: end).then((route) {
      if (!mounted) return;
      if (route != null && route.points.length >= 2) {
        setState(() {
          _routePolyline
            ..clear()
            ..addAll(route.points);
        });
        final km = (route.distanceMeters / 1000.0).toStringAsFixed(1);
        final min = (route.durationSeconds / 60.0).round();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route: $km km • ~$min min')),
        );
      } else {
        setState(() {
          _routePolyline
            ..clear()
            ..add(start)
            ..add(end);
        });
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _routePolyline
          ..clear()
          ..add(start)
          ..add(end);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultCenter,
              initialZoom: MapConfig.defaultZoom,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.defaultTileLayer,
                userAgentPackageName: 'com.shopr radar.app',
                tileProvider: NetworkTileProvider(),
              ),
              if (_currentLocation != null)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _currentLocation!,
                    color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                    borderStrokeWidth: 2,
                    borderColor: const Color(0xFF2979FF).withValues(alpha: 0.6),
                    radius: 25,
                  ),
                ]),
              if (_currentLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                ]),
              // Removed shop markers - only show user location
              // if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
              // Removed route polylines - no shop routes in map view
              // if (_routePolyline.length >= 2)
              //   PolylineLayer(
              //     polylines: [
              //       Polyline(points: _routePolyline, color: const Color(0xFF2979FF), strokeWidth: 4),
              //     ],
              //   ),
            ],
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
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                tooltip: 'Back',
              ),
            ),
          ),
          
          // Search Overlay
          // Removed search overlay - search moved to stores screen
          if (false)
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
          
          // Map Controls - only show my location button
          if (true)
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filter options coming soon!')),
                  );
                },
              ),
            )
          else
            Positioned(
              top: MediaQuery.of(context).padding.top + (isTablet ? 20 : 16),
              right: isTablet ? 20 : 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: Color(0xFF2979FF)),
                  onPressed: _onMyLocationPressed,
                  tooltip: 'My location',
                ),
              ),
            ),
          
          // Removed shop details - no shop interactions in map view
          if (false)
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
                      _routePolyline.clear();
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

          // Removed recommendation banner - recommendations moved to stores screen
          if (false)
            Positioned(
              top: MediaQuery.of(context).padding.top + (isTablet ? 90 : 80),
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recommended: ${_recommendedShop!.name} — ${_recommendedShop!.offers.isNotEmpty ? _recommendedShop!.offers.first.formattedDiscount : 'Great rating'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _onMarkerTapped(_recommendedShop!);
                        _mapController.move(latlng.LatLng(_recommendedShop!.latitude, _recommendedShop!.longitude), 15);
                      },
                      child: const Text('VIEW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
