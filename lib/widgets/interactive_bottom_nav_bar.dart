import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive animated bottom navigation bar with smooth transitions,
/// haptic feedback, and modern UI design
class InteractiveBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;

  const InteractiveBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<InteractiveBottomNavBar> createState() => _InteractiveBottomNavBarState();
}

class _InteractiveBottomNavBarState extends State<InteractiveBottomNavBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _iconAnimations;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;
  
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    
    // Initialize controllers for each item
    _controllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    // Scale animations for tap feedback
    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Icon bounce animations
    _iconAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );
    }).toList();

    // Indicator slide animation
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOutCubic,
    );

    _indicatorController.forward();
  }

  @override
  void didUpdateWidget(InteractiveBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animateToNewIndex(widget.currentIndex);
    }
  }

  void _animateToNewIndex(int newIndex) {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Animate the previous item out (scale down)
    if (_previousIndex < _controllers.length) {
      _controllers[_previousIndex].forward().then((_) {
        if (mounted) {
          _controllers[_previousIndex].reverse();
        }
      });
    }
    
    // Animate the new item in (bounce effect)
    if (newIndex < _controllers.length) {
      _controllers[newIndex].reset();
      _controllers[newIndex].forward().then((_) {
        if (mounted) {
          _controllers[newIndex].reverse();
        }
      });
    }

    // Animate indicator slide
    _indicatorController.reset();
    _indicatorController.forward();
    
    _previousIndex = newIndex;
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              widget.items.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isSelected = widget.currentIndex == index;
    final controller = _controllers[index];

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index != widget.currentIndex) {
            widget.onTap(index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected
                    ? 1.0 - (_scaleAnimations[index].value * 0.15)
                    : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated icon container
                    Flexible(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.all(isSelected ? 8 : 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2979FF).withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Icon with animation
                          AnimatedBuilder(
                            animation: controller,
                            builder: (context, child) {
                              final iconScale = isSelected
                                  ? 1.0 + (_iconAnimations[index].value - 1.0) * 0.15
                                  : 1.0;
                              return Transform.scale(
                                scale: iconScale,
                                child: Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: isSelected ? 24 : 22,
                                  color: isSelected
                                      ? const Color(0xFF2979FF)
                                      : Colors.grey[600],
                                ),
                              );
                            },
                          ),
                          // Pulse effect for selected item
                          if (isSelected)
                            AnimatedBuilder(
                              animation: _indicatorController,
                              builder: (context, child) {
                                return Container(
                                  width: 40 * _indicatorAnimation.value,
                                  height: 40 * _indicatorAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2979FF)
                                        .withValues(alpha: 0.1 * (1 - _indicatorAnimation.value)),
                                  ),
                                );
                            },
                          ),
                        ],
                      ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Label with animation
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        style: GoogleFonts.inter(
                          fontSize: isSelected ? 11 : 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2979FF)
                              : Colors.grey[600],
                          letterSpacing: isSelected ? 0.2 : 0,
                        ),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Model for navigation bar items
class NavBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

