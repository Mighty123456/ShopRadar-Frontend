import 'package:url_launcher/url_launcher.dart';

class MapsLauncherService {
  static Future<bool> openDirections({
    required double destLatitude,
    required double destLongitude,
    String? destinationName,
    double? originLatitude,
    double? originLongitude,
  }) async {
    final String destLabel = Uri.encodeComponent(destinationName ?? 'Destination');

    // Prefer Google Maps universal link with optional origin
    final String googleUrl = originLatitude != null && originLongitude != null
        ? 'https://www.google.com/maps/dir/?api=1&origin=$originLatitude,$originLongitude&destination=$destLatitude,$destLongitude&travelmode=driving'
        : 'https://www.google.com/maps/dir/?api=1&destination=$destLatitude,$destLongitude&travelmode=driving';

    final Uri googleUri = Uri.parse(googleUrl);
    if (await canLaunchUrl(googleUri)) {
      return launchUrl(googleUri, mode: LaunchMode.externalApplication);
    }

    // Fallback: Apple Maps scheme (iOS)
    final String appleUrl = 'http://maps.apple.com/?daddr=$destLatitude,$destLongitude&q=$destLabel';
    final Uri appleUri = Uri.parse(appleUrl);
    if (await canLaunchUrl(appleUri)) {
      return launchUrl(appleUri, mode: LaunchMode.externalApplication);
    }

    // Fallback: generic geo URI
    final Uri geoUri = Uri.parse('geo:$destLatitude,$destLongitude');
    if (await canLaunchUrl(geoUri)) {
      return launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}


