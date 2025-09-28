import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
 
import '../models/shop.dart';
import '../widgets/map_controls.dart';
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
  bool _isLoading = true;
  Timer? _routeUpdateTimer;
  // Removed overlay usage; keeping UI minimal
  // ignore: unused_field
  bool _showSearchOverlay = false;
  
  latlng.LatLng? _currentLocation;
  Shop? _selectedShop;
  double _minRating = 0.0;
  bool _openNowOnly = false;
  latlng.LatLng? _customDestination;
  StreamSubscription<Position>? _positionSub;
  bool _followUser = true;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  
  // Google-specific fields removed for WebView implementation
  
  

  // Map configuration
  static final latlng.LatLng _defaultCenter = latlng.LatLng(MapConfig.defaultLatitude, MapConfig.defaultLongitude);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulse = Tween<double>(begin: 0.9, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    _initializeMap();
    if (widget.searchQuery != null) {
      // no-op: search overlay removed
    }
    if (widget.category != null) {
      // no-op: category UI removed
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _routeUpdateTimer?.cancel();
    _pulseController.dispose();
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
        // If a specific destination was provided, draw route immediately
        if (widget.routeToShop != null && _currentLocation != null) {
          _selectedShop = widget.routeToShop!;
          _drawRouteTo(widget.routeToShop!);
        }
        // If asked to draw routes for all, draw to up to 5 closest by distance
        if (widget.drawRoutesForAll && _currentLocation != null) {
          final List<Shop> sorted = List<Shop>.from(_shops);
          sorted.sort((a, b) => _haversineMeters(_toLL(a), _currentLocation!).compareTo(_haversineMeters(_toLL(b), _currentLocation!)));
          final List<Shop> subset = sorted.take(5).toList();
          // Draw a combined polyline by concatenating individual routes start->shop
          _routePolyline.clear();
          for (final shop in subset) {
            await RoutingService.getRoute(start: _currentLocation!, end: _toLL(shop)).then((route) {
              if (route != null && route.points.length >= 2) {
                _routePolyline.addAll(route.points);
              } else {
                _routePolyline..add(_currentLocation!)..add(_toLL(shop));
              }
            }).catchError((_) {
              _routePolyline..add(_currentLocation!)..add(_toLL(shop));
            });
          }
          if (mounted) {
            setState(() {});
            _fitRouteToView();
          }
        }
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
    for (final shop in source) {
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
          width: 56,
          height: 64,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(shop),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 8,
            child: Container(
                    width: 44,
                    height: 44,
              decoration: BoxDecoration(
                      color: pinColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.store, color: Colors.white, size: 20),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  

  // For category-based styling we style in builder above; no BitmapDescriptor in flutter_map

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
      _mapController.move(location, 16.0);
      if (_selectedShop != null) {
        _drawRouteTo(_selectedShop!);
      }
    }
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
    RoutingService.getRoute(start: start, end: end).then((route) {
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
    RoutingService.getRoute(start: start, end: end).then((route) {
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
    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Increased from 5 to reduce updates
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen((Position pos) {
      final latlng.LatLng newLoc = latlng.LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      
      double distance = 0.0;
      // Only update if location changed significantly (more than 10 meters)
      if (_currentLocation != null) {
        distance = _haversineMeters(_currentLocation!, newLoc);
        if (distance < 10) return; // Skip update if movement is less than 10 meters
      }
      
      setState(() {
        _currentLocation = newLoc;
      });
      if (_followUser) {
        try {
          _mapController.move(newLoc, MapConfig.defaultZoom);
        } catch (_) {}
      }
      // Only redraw routes if user is following location and moved significantly
      if (_followUser && _selectedShop != null && distance >= 10) {
        _drawRouteTo(_selectedShop!);
      } else if (_followUser && _customDestination != null && distance >= 10) {
        _drawRouteToPoint(_customDestination!);
      }
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
    final bounds = LatLngBounds(_routePolyline.first, _routePolyline.first);
    for (final p in _routePolyline.skip(1)) {
      bounds.extend(p);
    }
    try {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 160),
      ));
    } catch (_) {}
  }

  void _buildRouteArrows() {
    _routeArrows.clear();
    _routeLabels.clear();
    if (_routePolyline.length < 3) return;
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

  latlng.LatLng _toLL(Shop s) => latlng.LatLng(s.latitude, s.longitude);

  void _showSearchDialog() {
    setState(() {
      _showSearchOverlay = true;
    });
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
                    width: 30,
                    height: 30,
                    child: ScaleTransition(
                      scale: _pulse,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
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
                    // soft outer glow
                    Polyline(points: _routePolyline, color: const Color(0x6693C5FD), strokeWidth: 16),
                    // inner white core for contrast
                    Polyline(points: _routePolyline, color: Colors.white.withValues(alpha: 0.85), strokeWidth: 10),
                    // main light UI blue line
                    Polyline(points: _routePolyline, color: const Color(0xFF60A5FA), strokeWidth: 7),
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
          // Search Overlay - simple inline search dialog
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
          
          
          // Map Controls - only show my location button
          if (true)
            Positioned(
              top: MediaQuery.of(context).padding.top + (isTablet ? 20 : 16),
              right: isTablet ? 20 : 16,
              child: MapControls(
                onSearchPressed: _showSearchDialog,
                onMyLocationPressed: _onMyLocationPressed,
                onFilterPressed: _showFilterSheet,
              ),
            )
          ,

          // Directions button removed per request; use long-press to set destination and draw route.

          // Route info pill
          if (_routePolyline.length >= 2)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions, color: Color(0xFF2979FF), size: 18),
                          const SizedBox(width: 8),
                          Text('${_formatDistanceKm(_lastRouteKm)} • ${_lastRouteMin > 0 ? '~$_lastRouteMin min' : 'ETA n/a'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.center_focus_strong),
                            tooltip: 'Recenter route',
                            onPressed: _fitRouteToView,
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear route',
                            onPressed: () {
                              setState(() {
                                _routePolyline.clear();
                                _routeArrows.clear();
                                _customDestination = null;
                                _selectedShop = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Removed shop details - no shop interactions in map view
          

          // Removed recommendation banner - recommendations moved to stores screen
          
          
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
