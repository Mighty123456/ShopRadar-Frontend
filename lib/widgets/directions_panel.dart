import 'package:flutter/material.dart';
import '../models/shop.dart';

class DirectionsPanel extends StatelessWidget {
  final Shop? destination;
  final double distanceKm;
  final int durationMinutes;
  final String routeMode;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onEndNavigation;
  final VoidCallback? onRouteModeChanged;
  final bool isNavigating;

  const DirectionsPanel({
    super.key,
    this.destination,
    required this.distanceKm,
    required this.durationMinutes,
    required this.routeMode,
    this.onStartNavigation,
    this.onEndNavigation,
    this.onRouteModeChanged,
    this.isNavigating = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      margin: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with destination info
          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF2979FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination?.name ?? 'Destination',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (destination?.address != null)
                        Text(
                          destination!.address,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (onEndNavigation != null)
                  IconButton(
                    onPressed: onEndNavigation,
                    icon: const Icon(Icons.close, color: Colors.grey),
                    tooltip: 'End navigation',
                  ),
              ],
            ),
          ),

          // Route info and controls
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 16 : 12,
            ),
            child: Column(
              children: [
                // Distance and duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: _formatDistance(distanceKm),
                      isTablet: isTablet,
                    ),
                    _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'Duration',
                      value: durationMinutes > 0 ? '~$durationMinutes min' : 'ETA n/a',
                      isTablet: isTablet,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Route mode selector
                if (onRouteModeChanged != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRouteModeButton(
                          'driving',
                          Icons.directions_car,
                          'Drive',
                          isTablet,
                        ),
                        _buildRouteModeButton(
                          'foot',
                          Icons.directions_walk,
                          'Walk',
                          isTablet,
                        ),
                        _buildRouteModeButton(
                          'cycling',
                          Icons.directions_bike,
                          'Bike',
                          isTablet,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Navigation button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isNavigating ? onEndNavigation : onStartNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isNavigating ? Colors.red : const Color(0xFF2979FF),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 18 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isNavigating ? 1 : 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isNavigating ? Icons.stop : Icons.navigation,
                          size: isTablet ? 22 : 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isNavigating ? 'End Navigation' : 'Start Navigation',
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isTablet,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: isTablet ? 20 : 16,
          color: const Color(0xFF2979FF),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteModeButton(
    String mode,
    IconData icon,
    String label,
    bool isTablet,
  ) {
    final isSelected = routeMode == mode;
    return GestureDetector(
      onTap: onRouteModeChanged,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? 20 : 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1.0) {
      final int meters = (km * 1000).round();
      return '$meters m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
