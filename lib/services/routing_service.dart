import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/map_keys.dart';

class RoutingService {
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions/driving-car';

  /// Fetch a route polyline and distance/duration using OpenRouteService.
  /// start: (lon, lat), end: (lon, lat) as per ORS API
  static Future<({List<LatLng> points, double distanceMeters, double durationSeconds})?>
      getRoute({required LatLng start, required LatLng end}) async {
    final uri = Uri.parse('$_baseUrl?api_key=${Uri.encodeComponent(MapKeys.orsApiKey)}&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'User-Agent': 'ShopRadar/1.0 (routing)'
    }).timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      return null;
    }
    final Map<String, dynamic> data = jsonDecode(resp.body);
    if (data['features'] is! List || (data['features'] as List).isEmpty) {
      return null;
    }
    final feature = (data['features'] as List).first as Map<String, dynamic>;
    final props = (feature['properties'] as Map<String, dynamic>)['summary'] as Map<String, dynamic>?;
    final geom = feature['geometry'] as Map<String, dynamic>?;
    final coords = (geom?['coordinates'] as List<dynamic>?) ?? [];
    final points = <LatLng>[];
    for (final c in coords) {
      if (c is List && c.length >= 2) {
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        points.add(LatLng(lat, lon));
      }
    }
    final distance = (props?['distance'] as num?)?.toDouble() ?? 0.0; // meters
    final duration = (props?['duration'] as num?)?.toDouble() ?? 0.0; // seconds
    return (points: points, distanceMeters: distance, durationSeconds: duration);
  }
}


