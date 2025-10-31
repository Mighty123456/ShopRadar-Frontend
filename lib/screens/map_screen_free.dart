import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
 
import '../models/shop.dart';
import '../widgets/map_controls.dart';
import '../widgets/directions_panel.dart';
import '../config/mapbox_config.dart';
import '../services/routing_service.dart';
import '../services/search_service.dart';
import 'dart:math' as math;
import 'dart:async';
 

class MapScreenFree extends StatefulWidget {
  final String? searchQuery;
  final String? category;
  final List<Shop>? shopsOverride;
  final VoidCallback? onBack;
  final bool showOnlyUser; // when true, only show user's current location
  final Shop? routeToShop; // if provided, draw route immediately
  final bool drawRoutesForAll; // when true, draw routes for all shopsOverride (up to 5)
  
  const MapScreenFree({
    super.key,
    this.searchQuery,
    this.category,
    this.shopsOverride,
    this.onBack,
    this.showOnlyUser = false,
    this.routeToShop,
    this.drawRoutesForAll = false,
  });

  @override
  State<MapScreenFree> createState() => _MapScreenFreeState();
}

class _MapScreenFreeState extends State<MapScreenFree> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  List<Shop> _shops = [];
  final List<latlng.LatLng> _routePolyline = [];
  final List<Marker> _routeArrows = [];
  final List<Marker> _routeLabels = [];
  double _lastRouteKm = 0.0;
  int _lastRouteMin = 0;
  String _routeMode = 'driving'; // 'driving' | 'foot' | 'cycling' (motorcycle -> driving)
  bool _isLoading = true;
  Timer? _routeUpdateTimer;
  bool _showSearchOverlay = false;
  bool _isNavigating = false;
  bool _showDirectionsPanel = false;
  bool _showArrivalAnimation = false;
  late final AnimationController _arrivalController;
  late final Animation<double> _arrivalScale;
  late final Animation<double> _arrivalOpacity;
  
  latlng.LatLng? _currentLocation;
  Shop? _selectedShop;
  double _minRating = 0.0;
  bool _openNowOnly = false;
  latlng.LatLng? _customDestination;
  StreamSubscription<Position>? _positionSub;
  bool _followUser = true;
  
  // Navigation tracking
  double? _userHeading; // User's current heading in degrees (0-360)
  final List<latlng.LatLng> _locationHistory = []; // Track recent positions for heading calculation
  Map<String, dynamic>? _nextTurnInstruction; // Current/upcoming turn instruction
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  late final AnimationController _recommendController;
  late final Animation<double> _recommendScale;
  static final latlng.LatLng _defaultCenter = latlng.LatLng(MapConfig.defaultLatitude, MapConfig.defaultLongitude);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulse = Tween<double>(begin: 0.9, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    _recommendController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _recommendScale = Tween<double>(begin: 0.95, end: 1.08).animate(CurvedAnimation(parent: _recommendController, curve: Curves.easeInOut));
    _recommendController.repeat(reverse: true);
    
    // Arrival animation controller
    _arrivalController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _arrivalScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _arrivalController, curve: Curves.elasticOut));
    _arrivalOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _arrivalController, curve: Curves.easeIn));
    
    _initializeMap();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _routeUpdateTimer?.cancel();
    _pulseController.dispose();
    _recommendController.dispose();
    _arrivalController.dispose();
    super.dispose();
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

        // Start live location updates
        _startPositionStream();
      }
      
      // If shops are provided from previous screen, render them
      if (widget.shopsOverride != null && widget.shopsOverride!.isNotEmpty) {
        _shops = widget.shopsOverride!;
        _updateMarkers();
        
        // Wait a bit for map to initialize before fitting view
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          
          // If a specific destination was provided, draw route immediately if location is available
          if (widget.routeToShop != null && _currentLocation != null) {
            _selectedShop = widget.routeToShop!;
            _drawRouteTo(_selectedShop!);
          }
          // If routeToShop is set but location not yet available, it will be drawn when location becomes available (in _startPositionStream)
          // If asked to draw routes for all shops
          else if (widget.drawRoutesForAll && _currentLocation != null) {
            final List<Shop> sorted = List<Shop>.from(_shops);
            sorted.sort((a, b) => _haversineMeters(_toLL(a), _currentLocation!).compareTo(_haversineMeters(_toLL(b), _currentLocation!)));
            final List<Shop> subset = sorted.take(5).toList();
            // Draw routes to up to 5 closest shops
            _routePolyline.clear();
            for (final shop in subset) {
              RoutingService.getRoute(start: _currentLocation!, end: _toLL(shop)).then((route) {
                if (!mounted) return;
                if (route != null && route.points.length >= 2) {
                  setState(() {
                    _routePolyline.addAll(route.points);
                  });
                } else {
                  setState(() {
                    _routePolyline..add(_currentLocation!)..add(_toLL(shop));
                  });
                }
                // Fit view after routes are drawn
                if (mounted) {
                  _fitAllShopsToView();
                }
              }).catchError((_) {
                if (mounted) {
                  setState(() {
                    _routePolyline..add(_currentLocation!)..add(_toLL(shop));
                  });
                  _fitAllShopsToView();
                }
              });
            }
            // Fit view immediately (will update when routes load)
            _fitAllShopsToView();
          }
          // If no specific route requested, fit all shops in view
          else if (widget.routeToShop == null) {
            _fitAllShopsToView();
          }
        });
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

  

  void _updateMarkers() {
    _markers.clear();
    final Iterable<Shop> source = _shops.where((s) {
      if (_openNowOnly && !s.isOpen) return false;
      if (s.rating < _minRating) return false;
      return true;
    });
    // Determine recommended shop (highest visitPriorityScore)
    Shop? recommended;
    if (source.isNotEmpty) {
      recommended = source.reduce((a, b) => a.visitPriorityScore >= b.visitPriorityScore ? a : b);
    }
    // Build markers: non-recommended first, recommended last (so it renders on top)
    final List<Shop> ordered = [
      ...source.where((s) => s != recommended),
      if (recommended != null) recommended,
    ];
    for (final shop in ordered) {
      final bool isRecommended = shop == recommended;
      _markers.add(
        Marker(
          point: latlng.LatLng(shop.latitude, shop.longitude),
          width: 64,
          height: 74,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(shop),
            child: _buildShopMarker(shop, isRecommended: isRecommended),
          ),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  int _bestOfferPercent(Shop shop) {
    if (shop.offers.isEmpty) return 0;
    int best = 0;
    for (final o in shop.offers) {
      best = math.max(best, o.discount.round());
    }
    return best;
  }

  Widget _buildShopMarker(Shop shop, {required bool isRecommended}) {
    final int offer = _bestOfferPercent(shop);
    final double rating = shop.rating;
    Color pinColor = const Color(0xFF2979FF);
    if (isRecommended) {
      pinColor = const Color(0xFFFF6B35);
    } else if (rating >= 4.5 || offer >= 30) {
      pinColor = const Color(0xFFFFB300);
    } else if (rating >= 4.0 || offer >= 10) {
      pinColor = const Color(0xFF2E7D32);
    }

    final Widget pin = Stack(
      alignment: Alignment.center,
      children: [
        // subtle shadow/glow
        if (isRecommended)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: pinColor.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 6),
              ],
            ),
          ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Center(
            child: offer > 0
                ? Text(
                    '$offer%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  )
                : const Icon(Icons.store, color: Colors.white, size: 20),
          ),
        ),
        // small label
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isRecommended ? const Color(0xFFFF6B35) : Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isRecommended ? 'TOP' : rating.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );

    if (isRecommended) {
      return ScaleTransition(scale: _recommendScale, child: pin);
    }
    return pin;
  }


  void _onMarkerTapped(Shop shop) {
    if (mounted) {
      setState(() {
        _selectedShop = shop;
        _drawRouteTo(shop);
      });
    }
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
        _followUser = true;
      });
      // Use smooth animation for better UX (like Google Maps)
      try {
        _mapController.move(location, 16.0);
      } catch (_) {
        _mapController.move(location, MapConfig.defaultZoom);
      }
      if (_selectedShop != null) {
        _drawRouteTo(_selectedShop!);
      } else if (_shops.isNotEmpty && !widget.drawRoutesForAll) {
        // If shops are shown, refit view to include user location
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _fitAllShopsToView();
          }
        });
      }
    }
  }

  void _onRecenterPressed() {
    if (_currentLocation != null) {
      setState(() {
        _followUser = true;
      });
      // Use higher zoom level for better view of user location (like Google Maps)
      try {
        _mapController.move(_currentLocation!, 16.0);
      } catch (_) {
        _mapController.move(_currentLocation!, MapConfig.defaultZoom);
      }
    }
  }
  
  void _fitAllShopsToView() {
    if (_shops.isEmpty) return;
    
    // Create bounds from all shops
    final bounds = LatLngBounds(
      latlng.LatLng(_shops.first.latitude, _shops.first.longitude),
      latlng.LatLng(_shops.first.latitude, _shops.first.longitude),
    );
    
    // Extend bounds to include all shops
    for (final shop in _shops) {
      bounds.extend(latlng.LatLng(shop.latitude, shop.longitude));
    }
    
    // Include user location if available for better context
    if (_currentLocation != null) {
      bounds.extend(_currentLocation!);
    }
    
    try {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(80, 120, 80, 200), // Extra padding for controls
      ));
    } catch (_) {
      // Fallback: center on first shop with default zoom
      if (_shops.isNotEmpty) {
        _mapController.move(latlng.LatLng(_shops.first.latitude, _shops.first.longitude), MapConfig.defaultZoom);
      }
    }
  }

  void _onStartNavigation() {
    setState(() {
      _isNavigating = true;
      _showDirectionsPanel = false; // hide menu after starting navigation
      _followUser = true; // follow user location
      _nextTurnInstruction = null; // Reset turn instructions
      _locationHistory.clear(); // Clear location history for fresh heading calculation
      _userHeading = null; // Reset heading
    });

    // Restart position stream with better accuracy for navigation
    if (_currentLocation != null) {
      _startPositionStream();
      // Immediately update turn instructions
      _updateTurnByTurnInstructions(_currentLocation!);
    }

    // Center camera on current user immediately
    if (_currentLocation != null) {
      try {
        _mapController.move(_currentLocation!, MapConfig.defaultZoom);
      } catch (_) {}
    }
    
    // Optionally fit route shortly after start for context, then resume follow
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_selectedShop != null || _customDestination != null) {
        _fitRouteToView();
      }
    });
  }

  void _onEndNavigation() {
    setState(() {
      _isNavigating = false;
      _showDirectionsPanel = false;
      _nextTurnInstruction = null;
      _routePolyline.clear();
      _routeArrows.clear();
      _routeLabels.clear();
    });
    
    // Restart position stream with standard accuracy
    if (_currentLocation != null) {
      _startPositionStream();
    }
  }

  void _onRouteModeChanged() {
    // Cycle through route modes
    setState(() {
      switch (_routeMode) {
        case 'driving':
          _routeMode = 'foot';
          break;
        case 'foot':
          _routeMode = 'cycling';
          break;
        case 'cycling':
          _routeMode = 'driving';
          break;
      }
    });
    
    // Redraw route with new mode
    if (_selectedShop != null) {
      _drawRouteTo(_selectedShop!);
    } else if (_customDestination != null) {
      _drawRouteToPoint(_customDestination!);
    }
  }

  void _checkForArrival(latlng.LatLng userLocation) {
    if (_selectedShop == null) return;
    
    final double distanceToShop = _haversineMeters(userLocation, latlng.LatLng(_selectedShop!.latitude, _selectedShop!.longitude));
    
    // Consider arrived if within 50 meters
    if (distanceToShop <= 50 && !_showArrivalAnimation) {
      _showArrivalSuccess();
    }
  }

  void _checkForArrivalAtPoint(latlng.LatLng userLocation) {
    if (_customDestination == null) return;
    
    final double distanceToDestination = _haversineMeters(userLocation, _customDestination!);
    
    // Consider arrived if within 50 meters
    if (distanceToDestination <= 50 && !_showArrivalAnimation) {
      _showArrivalSuccess();
    }
  }

  void _showArrivalSuccess() {
    setState(() {
      _showArrivalAnimation = true;
    });
    
    _arrivalController.forward().then((_) {
      // Keep animation visible for 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showArrivalAnimation = false;
          });
          _arrivalController.reset();
        }
      });
    });
  }

  void _drawRouteTo(Shop shop) {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      _drawRouteToImmediate(shop);
    });
  }

  void _drawRouteToImmediate(Shop shop) {
    _routePolyline.clear();
    _routeArrows.clear();
    if (_currentLocation == null) return;
    final start = _currentLocation!;
    final end = latlng.LatLng(shop.latitude, shop.longitude);
    // Try ORS first; fallback to straight line
    RoutingService.getRoute(start: start, end: end, mode: _routeMode).then((route) {
      if (!mounted) return;
      if (route != null && route.points.length >= 2) {
        setState(() {
          _routePolyline
            ..clear()
            ..addAll(route.points);
          _ensureRouteAnchors(start, end);
          _lastRouteKm = (route.distanceMeters / 1000.0);
          _lastRouteMin = (route.durationSeconds / 60.0).round();
          _buildRouteArrows();
          _showDirectionsPanel = true;
        });
        _fitRouteToView();
      } else {
        setState(() {
          _routePolyline
            ..clear()
            ..add(start)
            ..add(end);
          _lastRouteKm = _haversineMeters(start, end) / 1000.0;
          _lastRouteMin = 0;
          _buildRouteArrows();
          _showDirectionsPanel = true;
        });
        _fitRouteToView();
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _routePolyline
          ..clear()
          ..add(start)
          ..add(end);
        _lastRouteKm = _haversineMeters(start, end) / 1000.0;
        _lastRouteMin = 0;
        _buildRouteArrows();
      });
      _fitRouteToView();
    });
  }

  void _drawRouteToPoint(latlng.LatLng point) {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      _drawRouteToPointImmediate(point);
    });
  }

  void _drawRouteToPointImmediate(latlng.LatLng point) {
    _routePolyline.clear();
    _routeArrows.clear();
    if (_currentLocation == null) return;
    final start = _currentLocation!;
    final end = point;
    RoutingService.getRoute(start: start, end: end, mode: _routeMode).then((route) {
      if (!mounted) return;
      if (route != null && route.points.length >= 2) {
        setState(() {
          _routePolyline
            ..clear()
            ..addAll(route.points);
          _ensureRouteAnchors(start, end);
          _lastRouteKm = (route.distanceMeters / 1000.0);
          _lastRouteMin = (route.durationSeconds / 60.0).round();
          _buildRouteArrows();
          _showDirectionsPanel = true;
        });
        _fitRouteToView();
      } else {
        setState(() {
          _routePolyline
            ..clear()
            ..add(start)
            ..add(end);
          _lastRouteKm = _haversineMeters(start, end) / 1000.0;
          _lastRouteMin = 0;
          _buildRouteArrows();
          _showDirectionsPanel = true;
        });
        _fitRouteToView();
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _routePolyline
          ..clear()
          ..add(start)
          ..add(end);
        _lastRouteKm = _haversineMeters(start, end) / 1000.0;
        _lastRouteMin = 0;
        _buildRouteArrows();
      });
      _fitRouteToView();
    });
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    // Use best accuracy for navigation, high accuracy for regular tracking
    final LocationSettings settings = LocationSettings(
      accuracy: _isNavigating ? LocationAccuracy.best : LocationAccuracy.high,
      distanceFilter: _isNavigating ? 5 : 10, // More frequent updates when navigating
      timeLimit: _isNavigating ? const Duration(seconds: 5) : const Duration(seconds: 10),
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen((Position pos) {
      final latlng.LatLng newLoc = latlng.LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      
      double distance = 0.0;
      latlng.LatLng? previousLocation = _currentLocation;
      
      // Only update if location changed significantly
      if (previousLocation != null) {
        distance = _haversineMeters(previousLocation, newLoc);
        // Use smaller threshold when navigating for better tracking
        final threshold = _isNavigating ? 5.0 : 10.0;
        if (distance < threshold) return;
        
        // Calculate heading from movement
        _calculateUserHeading(previousLocation, newLoc);
      }
      
      // Update location history (keep last 10 positions for smoothing)
      _locationHistory.add(newLoc);
      if (_locationHistory.length > 10) {
        _locationHistory.removeAt(0);
      }
      
      setState(() {
        _currentLocation = newLoc;
      });
      
      // If routeToShop was provided but route wasn't drawn yet (location wasn't available initially), draw it now
      if (widget.routeToShop != null && _selectedShop == null && _routePolyline.isEmpty) {
        _selectedShop = widget.routeToShop!;
        _drawRouteTo(_selectedShop!);
      }
      
      // When navigating, always follow user and keep map centered
      if (_isNavigating) {
        _followUser = true;
        try {
          // Use bearing if available for smoother camera movement
          if (_userHeading != null) {
            _mapController.move(newLoc, _mapController.camera.zoom);
            // Optionally rotate map to match heading (like Google Maps)
            // This would require map rotation support in flutter_map
          } else {
            _mapController.move(newLoc, _mapController.camera.zoom);
          }
        } catch (_) {}
        
        // Update turn-by-turn instructions
        _updateTurnByTurnInstructions(newLoc);
      } else if (_followUser) {
        try {
          // Maintain current zoom when following user (unless zoom is too far out)
          final currentZoom = _mapController.camera.zoom;
          final zoom = currentZoom < 12.0 ? 16.0 : currentZoom;
          _mapController.move(newLoc, zoom);
        } catch (_) {
          _mapController.move(newLoc, MapConfig.defaultZoom);
        }
      }
      
      // Redraw routes when navigating and moved significantly
      if (_followUser && _selectedShop != null && distance >= (_isNavigating ? 5 : 10)) {
        _drawRouteTo(_selectedShop!);
      } else if (_followUser && _customDestination != null && distance >= (_isNavigating ? 5 : 10)) {
        _drawRouteToPoint(_customDestination!);
      }
      
      // Check for arrival at destination
      if (_isNavigating && _selectedShop != null) {
        _checkForArrival(newLoc);
      } else if (_isNavigating && _customDestination != null) {
        _checkForArrivalAtPoint(newLoc);
      }
    });
  }
  
  void _calculateUserHeading(latlng.LatLng from, latlng.LatLng to) {
    // Calculate bearing from previous to current location
    final bearingRad = _bearingRadians(from, to);
    final bearingDeg = (bearingRad * 180.0 / 3.141592653589793);
    // Normalize to 0-360
    final normalizedHeading = (bearingDeg + 360.0) % 360.0;
    
    setState(() {
      _userHeading = normalizedHeading;
    });
  }
  
  void _updateTurnByTurnInstructions(latlng.LatLng currentLoc) {
    if (_routePolyline.length < 2) return;
    
    // Find the closest point on the route to current location
    int closestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < _routePolyline.length; i++) {
      final distance = _haversineMeters(currentLoc, _routePolyline[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    // Find next turn ahead (within 200m)
    for (int i = closestIndex + 1; i < _routePolyline.length - 1; i++) {
      final distance = _haversineMeters(currentLoc, _routePolyline[i]);
      if (distance > 200) break; // Only show turns within 200m
      
      final prev = _routePolyline[i - 1];
      final curr = _routePolyline[i];
      final next = _routePolyline[i + 1];
      
      final bearing1 = _bearingRadians(prev, curr) * 180.0 / 3.141592653589793;
      final bearing2 = _bearingRadians(curr, next) * 180.0 / 3.141592653589793;
      
      double delta = (bearing2 - bearing1);
      while (delta > 180) { delta -= 360; }
      while (delta < -180) { delta += 360; }
      
      final absDelta = delta.abs();
      
      if (absDelta >= 30.0) { // Turn detected
        String instruction;
        IconData icon;
        Color color;
        
        if (absDelta >= 150.0) {
          instruction = delta > 0 ? 'U-turn right' : 'U-turn left';
          icon = delta > 0 ? Icons.u_turn_right : Icons.u_turn_left;
          color = const Color(0xFFEF4444);
        } else if (absDelta >= 90.0) {
          instruction = delta > 0 ? 'Sharp right' : 'Sharp left';
          icon = delta > 0 ? Icons.turn_right : Icons.turn_left;
          color = const Color(0xFFFF6B35);
        } else if (absDelta >= 45.0) {
          instruction = delta > 0 ? 'Turn right' : 'Turn left';
          icon = delta > 0 ? Icons.turn_right : Icons.turn_left;
          color = const Color(0xFF2979FF);
        } else {
          instruction = delta > 0 ? 'Slight right' : 'Slight left';
          icon = delta > 0 ? Icons.subdirectory_arrow_right : Icons.subdirectory_arrow_left;
          color = const Color(0xFF2979FF);
        }
        
        setState(() {
          _nextTurnInstruction = {
            'instruction': instruction,
            'icon': icon,
            'color': color,
            'distance': distance,
            'point': curr,
          };
        });
        return;
      }
    }
    
    // No turn found ahead, show "Continue straight"
    setState(() {
      _nextTurnInstruction = {
        'instruction': 'Continue straight',
        'icon': Icons.straight,
        'color': const Color(0xFF2979FF),
        'distance': null,
      };
    });
  }

  void _ensureRouteAnchors(latlng.LatLng start, latlng.LatLng end) {
    if (_routePolyline.isEmpty) return;
    final latlng.LatLng first = _routePolyline.first;
    final latlng.LatLng last = _routePolyline.last;
    const double tol = 1e-6; // ~0.1m tolerance
    bool firstMatches = (first.latitude - start.latitude).abs() < tol && (first.longitude - start.longitude).abs() < tol;
    bool lastMatches = (last.latitude - end.latitude).abs() < tol && (last.longitude - end.longitude).abs() < tol;
    if (!firstMatches) {
      _routePolyline.insert(0, start);
    }
    if (!lastMatches) {
      _routePolyline.add(end);
    }
  }

  void _fitRouteToView() {
    if (_routePolyline.length < 2) return;
    
    // Create bounds that include both user location and destination
    final bounds = LatLngBounds(_routePolyline.first, _routePolyline.first);
    
    // Add all route points
    for (final p in _routePolyline.skip(1)) {
      bounds.extend(p);
    }
    
    // Ensure user location is included in bounds
    if (_currentLocation != null) {
      bounds.extend(_currentLocation!);
    }
    
    // Ensure destination is included in bounds
    if (_selectedShop != null) {
      bounds.extend(latlng.LatLng(_selectedShop!.latitude, _selectedShop!.longitude));
    } else if (_customDestination != null) {
      bounds.extend(_customDestination!);
    }
    
    try {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 200), // Increased bottom padding for directions panel
      ));
    } catch (_) {}
  }

  void _buildRouteArrows() {
    _routeArrows.clear();
    _routeLabels.clear();
    if (_routePolyline.length < 3) return;

    // Detect turns by comparing successive segment bearings
    const double turnThresholdDeg = 30.0; // minimal angle change to consider a turn
    const double uTurnThresholdDeg = 150.0; // angle change for U-turn

    double toDeg(double rad) => rad * 180.0 / 3.141592653589793;
    double norm180(double deg) {
      double d = deg;
      while (d > 180) { d -= 360; }
      while (d < -180) { d += 360; }
      return d;
    }

    for (int i = 1; i < _routePolyline.length - 1; i++) {
      final prev = _routePolyline[i - 1];
      final curr = _routePolyline[i];
      final next = _routePolyline[i + 1];

      final double bearing1 = toDeg(_bearingRadians(prev, curr));
      final double bearing2 = toDeg(_bearingRadians(curr, next));
      final double delta = norm180(bearing2 - bearing1);
      final double absDelta = delta.abs();

      if (absDelta >= turnThresholdDeg) {
        IconData icon;
        Color color;
        if (absDelta >= uTurnThresholdDeg) {
          // U-turn
          icon = delta > 0 ? Icons.u_turn_right : Icons.u_turn_left;
          color = const Color(0xFFEF4444); // red for U-turn
        } else {
          // Left or Right turn
          icon = delta > 0 ? Icons.turn_right : Icons.turn_left;
          color = const Color(0xFF2979FF); // primary for normal turns
        }

        _routeArrows.add(
          Marker(
            point: curr,
            width: 28,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        );
      }
    }

    // As a fallback, also add sparse forward arrows along the path for direction sense
    if (_routeArrows.isEmpty) {
      const int step = 12; // place arrow about every 12 points
      for (int i = 0; i < _routePolyline.length - 1; i += step) {
        final a = _routePolyline[i];
        final b = _routePolyline[(i + 1).clamp(0, _routePolyline.length - 1)];
        final double bearingRad = _bearingRadians(a, b);
        _routeArrows.add(
          Marker(
            point: a,
            width: 20,
            height: 20,
            child: Transform.rotate(
              angle: bearingRad,
              child: const Icon(Icons.navigation, size: 16, color: Color(0xFF2979FF)),
            ),
          ),
        );
      }
    }

    // Add distance label at midpoint
    final int mid = (_routePolyline.length / 2).floor();
    final latlng.LatLng midPoint = _routePolyline[mid];
    _routeLabels.add(
      Marker(
        point: midPoint,
        width: 160,
        height: 44,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3)),
            ],
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Center(
            child: Text('${_formatDistanceKm(_lastRouteKm)} • ${_lastRouteMin > 0 ? '~$_lastRouteMin min' : 'ETA n/a'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  double _bearingRadians(latlng.LatLng a, latlng.LatLng b) {
    final double lat1 = a.latitude * 3.141592653589793 / 180.0;
    final double lat2 = b.latitude * 3.141592653589793 / 180.0;
    final double dLon = (b.longitude - a.longitude) * 3.141592653589793 / 180.0;
    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  double _haversineMeters(latlng.LatLng a, latlng.LatLng b) {
    const double R = 6371000.0; // meters
    final double dLat = (b.latitude - a.latitude) * 3.141592653589793 / 180.0;
    final double dLon = (b.longitude - a.longitude) * 3.141592653589793 / 180.0;
    final double lat1 = a.latitude * 3.141592653589793 / 180.0;
    final double lat2 = b.latitude * 3.141592653589793 / 180.0;
    final double sinDLat = math.sin(dLat / 2);
    final double sinDLon = math.sin(dLon / 2);
    final double h = sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return R * c;
  }

  String _formatDistanceKm(double km) {
    if (km < 1.0) {
      final int meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  Polyline _buildRoutePolyline() {
    Color routeColor;
    double strokeWidth;
    
    switch (_routeMode) {
      case 'foot':
        routeColor = const Color(0xFF10B981); // Green for walking
        strokeWidth = 6;
        break;
      case 'cycling':
        routeColor = const Color(0xFFF59E0B); // Orange for cycling
        strokeWidth = 6;
        break;
      case 'driving':
      default:
        routeColor = const Color(0xFF2979FF); // Blue for driving
        strokeWidth = 8;
        break;
    }

    return Polyline(
      points: _routePolyline,
      color: routeColor,
      strokeWidth: strokeWidth,
      borderStrokeWidth: strokeWidth + 4,
      borderColor: Colors.white.withValues(alpha: 0.8),
    );
  }

  latlng.LatLng _toLL(Shop s) => latlng.LatLng(s.latitude, s.longitude);

  void _showSearchDialog() {
    setState(() {
      _showSearchOverlay = true;
    });
  }

  Widget _buildNavigationBanner(bool isTablet) {
    final instruction = _nextTurnInstruction!;
    final distance = instruction['distance'] as double?;
    
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (instruction['color'] as Color).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Turn icon
            Container(
              width: isTablet ? 56 : 48,
              height: isTablet ? 56 : 48,
              decoration: BoxDecoration(
                color: (instruction['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                instruction['icon'] as IconData,
                color: instruction['color'] as Color,
                size: isTablet ? 28 : 24,
              ),
            ),
            const SizedBox(width: 16),
            // Instruction text and distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instruction['instruction'] as String,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (distance != null)
                    Text(
                      'In ${_formatDistanceKm(distance / 1000.0)}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'Continue on current route',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            // Remaining distance to destination
            if (_currentLocation != null && _selectedShop != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 10,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDistanceKm(_haversineMeters(_currentLocation!, latlng.LatLng(_selectedShop!.latitude, _selectedShop!.longitude)) / 1000.0),
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2979FF),
                      ),
                    ),
                    Text(
                      'to go',
                      style: TextStyle(
                        fontSize: isTablet ? 10 : 9,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent(bool isTablet) {
    final TextEditingController controller = TextEditingController();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search stores or products...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  // Use existing SearchService to find shops
                  try {
                    final results = await SearchService.searchShops(value);
                    setState(() {
                      _shops = results;
                      _selectedShop = null;
                      _routePolyline.clear();
                      _updateMarkers();
                      _showSearchOverlay = false;
                    });
                    if (_shops.isNotEmpty) {
                      // Center on first result
                      _mapController.move(latlng.LatLng(_shops.first.latitude, _shops.first.longitude), 15.0);
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search failed')),
                      );
                    }
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
              onPressed: () => setState(() => _showSearchOverlay = false),
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double tempMin = _minRating;
        bool tempOpen = _openNowOnly;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum Rating'),
                      Text(tempMin.toStringAsFixed(1)),
                    ],
                  ),
                  Slider(
                    value: tempMin,
                    onChanged: (v) => setModalState(() => tempMin = v),
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    label: tempMin.toStringAsFixed(1),
                  ),
                  SwitchListTile(
                    value: tempOpen,
                    onChanged: (v) => setModalState(() => tempOpen = v),
                    title: const Text('Open now only'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _minRating = tempMin;
                          _openNowOnly = tempOpen;
                          _updateMarkers();
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                scrollWheelVelocity: 0.005, // Reduce scroll sensitivity
                pinchZoomWinGestures: MultiFingerGesture.none, // Disable pinch zoom on Windows
              ),
              onTap: (tapPosition, point) {
                if (!mounted) return;
                // Only clear routes if user taps on empty area (not on markers)
                // This prevents accidental clearing when interacting with map elements
                setState(() {
                  _selectedShop = null;
                  _customDestination = null;
                  _routePolyline.clear();
                  _routeArrows.clear();
                  _routeLabels.clear();
                });
              },
              onLongPress: (tapPosition, point) {
                if (!mounted) return;
                setState(() {
                  _selectedShop = null;
                  _customDestination = point;
                });
                _drawRouteToPoint(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.defaultTileLayer,
                userAgentPackageName: 'com.shopr radar.app',
                tileProvider: NetworkTileProvider(),
              ),
              if (_currentLocation != null)
                CircleLayer(circles: [
                  // Outer pulsing circle
                  CircleMarker(
                    point: _currentLocation!,
                    color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    borderStrokeWidth: 0,
                    radius: 40,
                  ),
                  // Inner circle
                  CircleMarker(
                    point: _currentLocation!,
                    color: const Color(0xFF2979FF).withValues(alpha: 0.2),
                    borderStrokeWidth: 0,
                    radius: 25,
                  ),
                ]),
              if (_currentLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Transform.rotate(
                        angle: _userHeading != null ? (_userHeading! - 90) * 3.141592653589793 / 180.0 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2979FF).withValues(alpha: 0.4), 
                                blurRadius: 12, 
                                offset: const Offset(0, 4),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15), 
                                blurRadius: 8, 
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isNavigating
                              ? const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ),
                ]),
              if (_markers.isNotEmpty)
                MarkerLayer(markers: _markers),
              if (_selectedShop != null)
                MarkerLayer(markers: [
                  Marker(
                    point: latlng.LatLng(_selectedShop!.latitude, _selectedShop!.longitude),
                    width: 220,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            _selectedShop!.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              if (_customDestination != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _customDestination!,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.flag, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              if (_routePolyline.length >= 2)
                PolylineLayer(
                  polylines: [
                    // Enhanced route styling based on mode
                    _buildRoutePolyline(),
                  ],
                ),
              if (_routeArrows.isNotEmpty)
                MarkerLayer(markers: _routeArrows),
              if (_routeLabels.isNotEmpty)
                MarkerLayer(markers: _routeLabels),
              // Attribution
              RichAttributionWidget(
                popupBackgroundColor: Colors.white,
                attributions: [
                  TextSourceAttribution(
                    MapConfig.attribution,
                    onTap: () {},
                  ),
                  ],
                ),
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
          if (_showSearchOverlay)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showSearchOverlay = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + (isTablet ? 72 : 60)),
                    padding: const EdgeInsets.all(12),
                    width: MediaQuery.of(context).size.width - (isTablet ? 80 : 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: _buildSearchContent(isTablet),
                  ),
                ),
              ),
            ),
          
          // Map Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + (isTablet ? 20 : 16),
            right: isTablet ? 20 : 16,
            child: MapControls(
              onSearchPressed: _showSearchDialog,
              onMyLocationPressed: _onMyLocationPressed,
              onFilterPressed: _showFilterSheet,
              onRecenterPressed: _onRecenterPressed,
              showRecenterButton: _currentLocation != null,
              isFollowingUser: _followUser,
            ),
          ),

          // Navigation Banner (shows turn-by-turn instructions)
          if (_isNavigating && _nextTurnInstruction != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + (isTablet ? 80 : 60),
              left: isTablet ? 88 : 80, // Add left margin to avoid overlapping with back button (48px button + 20px margin + buffer)
              right: isTablet ? 88 : 80, // Add right margin to avoid overlapping with map controls (48px button + 20px margin + buffer)
              child: _buildNavigationBanner(isTablet),
            ),
          
          // Directions Panel
          if (_showDirectionsPanel && _routePolyline.length >= 2)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: DirectionsPanel(
                destination: _selectedShop,
                distanceKm: _lastRouteKm,
                durationMinutes: _lastRouteMin,
                routeMode: _routeMode,
                onStartNavigation: _onStartNavigation,
                onEndNavigation: _onEndNavigation,
                onRouteModeChanged: _onRouteModeChanged,
                isNavigating: _isNavigating,
              ),
            ),
          
          // Arrival Success Animation
          if (_showArrivalAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _arrivalController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _arrivalScale.value,
                        child: Opacity(
                          opacity: _arrivalOpacity.value,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Success Icon with Animation
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF10B981),
                                    size: 50,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Success Message
                                Text(
                                  '🎉 You\'ve Arrived!',
                                  style: TextStyle(
                                    fontSize: isTablet ? 24 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                Text(
                                  _selectedShop?.name ?? 'Destination',
                                  style: TextStyle(
                                    fontSize: isTablet ? 18 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2979FF),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                
                                Text(
                                  'Navigation completed successfully',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Action Button
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showArrivalAnimation = false;
                                      _isNavigating = false;
                                      _showDirectionsPanel = false;
                                    });
                                    _arrivalController.reset();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Great!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
