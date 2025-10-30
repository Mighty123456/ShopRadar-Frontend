import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onSearchPressed;
  final VoidCallback onMyLocationPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback? onRecenterPressed;
  final bool showRecenterButton;
  final bool isFollowingUser;

  const MapControls({
    super.key,
    required this.onSearchPressed,
    required this.onMyLocationPressed,
    required this.onFilterPressed,
    this.onRecenterPressed,
    this.showRecenterButton = false,
    this.isFollowingUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search button
        _buildControlButton(
          icon: Icons.search,
          onPressed: onSearchPressed,
          tooltip: 'Search shops',
        ),
        
        const SizedBox(height: 8),
        
        // My location button
        _buildControlButton(
          icon: Icons.my_location,
          onPressed: onMyLocationPressed,
          tooltip: 'My location',
        ),
        
        const SizedBox(height: 8),
        
        // Recenter button (only show when not following user)
        if (showRecenterButton && !isFollowingUser)
          _buildControlButton(
            icon: Icons.center_focus_strong,
            onPressed: onRecenterPressed ?? () {},
            tooltip: 'Recenter on my location',
            backgroundColor: const Color(0xFF2979FF),
            iconColor: Colors.white,
          ),
        
        if (showRecenterButton && !isFollowingUser)
          const SizedBox(height: 8),
        
        // Filter button
        _buildControlButton(
          icon: Icons.filter_list,
          onPressed: onFilterPressed,
          tooltip: 'Filter options',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF2979FF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
