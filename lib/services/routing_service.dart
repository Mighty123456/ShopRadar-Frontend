import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // Use free OSRM public server (no API key). Note: best-effort service with rate limits.
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Fetch route using OSRM with GeoJSON geometry.
  static Future<({List<LatLng> points, double distanceMeters, double durationSeconds})?>
      getRoute({required LatLng start, required LatLng end}) async {
    final String coords = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
    final Uri uri = Uri.parse('$_baseUrl/$coords?overview=full&geometries=geojson');

    final http.Response resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'User-Agent': 'ShopRadar/1.0 (routing)'
    }).timeout(const Duration(seconds: 20));

    if (resp.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> data = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> routes = (data['routes'] as List<dynamic>?) ?? const [];
    if (routes.isEmpty) {
      return null;
    }

    final Map<String, dynamic> route = routes.first as Map<String, dynamic>;
    final double distance = (route['distance'] as num?)?.toDouble() ?? 0.0; // meters
    final double duration = (route['duration'] as num?)?.toDouble() ?? 0.0; // seconds

    final Map<String, dynamic>? geometry = route['geometry'] as Map<String, dynamic>?;
    final List<dynamic> coordinates = (geometry?['coordinates'] as List<dynamic>?) ?? const [];
    final List<LatLng> points = <LatLng>[];
    for (final dynamic c in coordinates) {
      if (c is List && c.length >= 2) {
        final double lon = (c[0] as num).toDouble();
        final double lat = (c[1] as num).toDouble();
        points.add(LatLng(lat, lon));
      }
    }

    return (points: points, distanceMeters: distance, durationSeconds: duration);
  }
}


