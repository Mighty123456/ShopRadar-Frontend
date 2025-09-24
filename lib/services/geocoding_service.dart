import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingResult {
  final LatLng center;
  final String displayName;
  GeocodingResult({required this.center, required this.displayName});
}

class GeocodingService {
  static const String _base = 'https://nominatim.openstreetmap.org';

  /// Forward geocode a free-text query using Nominatim (no key required).
  /// Returns the first result or null.
  static Future<GeocodingResult?> forwardSearch(String query) async {
    if (query.trim().isEmpty) return null;
    final uri = Uri.parse('$_base/search?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      // Be a good citizen: send a meaningful UA per Nominatim policy
      'User-Agent': 'ShopRadar/1.0 (test geocoding)'
    }).timeout(const Duration(seconds: 12));

    if (resp.statusCode != 200) return null;
    final List data = jsonDecode(resp.body);
    if (data.isEmpty) return null;
    final item = data.first as Map<String, dynamic>;
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    final name = (item['display_name'] as String?) ?? query;
    return GeocodingResult(center: LatLng(lat, lon), displayName: name);
  }
}


