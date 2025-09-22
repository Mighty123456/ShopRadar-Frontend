class MapConfig {
  // Default location (San Francisco)
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  
  // Zoom levels
  static const double defaultZoom = 14.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;
  
  // Tile layer configuration (OpenStreetMap - free)
  static const String defaultTileLayer = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  // Attribution
  static const String attribution = '© OpenStreetMap contributors';
}
