import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

/// Minimalist blue curved line loader - App-wide standard loader
/// 
/// This is a simple, elegant loading indicator with a rotating curved line
/// that matches the app's design language. Use this throughout the app
/// for consistent loading experiences.
class MinimalLoader extends StatefulWidget {
  /// Size of the loader in logical pixels (default: 40.0)
  final double? size;
  
  /// Color of the loader (default: App primary blue #2979FF)
  final Color? color;
  
  /// Width of the curved line stroke (default: 3.0)
  final double strokeWidth;
  
  /// Optional message text below the loader
  final String? message;
  
  /// Whether to show the ShopRadar icon before the loader animation
  final bool showIcon;

  const MinimalLoader({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 3.0,
    this.message,
    this.showIcon = false,
  });

  @override
  State<MinimalLoader> createState() => _MinimalLoaderState();
}

class _MinimalLoaderState extends State<MinimalLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 40.0;
    final color = widget.color ?? const Color(0xFF2979FF);
    
    Widget loader = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showIcon)
            SvgPicture.asset(
              'assets/images/shopradar_icon.svg',
              width: size * 0.7,
              height: size * 0.7,
              fit: BoxFit.contain,
            ),
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * math.pi,
                child: CustomPaint(
                  painter: CurvedLinePainter(
                    color: color,
                    strokeWidth: widget.strokeWidth,
                  ),
                  size: Size(size, size),
                ),
              );
            },
          ),
        ],
      ),
    );

    if (widget.message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loader;
  }
}

/// Custom painter for the curved line loader
class CurvedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  CurvedLinePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    
    // Draw a curved arc (approximately 270-300 degrees)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      5 * math.pi / 3, // Draw 300 degrees (5/6 of circle)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CurvedLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Full-screen loading overlay with the minimalist loader
class MinimalLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const MinimalLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.white.withValues(alpha: 0.8),
            child: Center(
              child: MinimalLoader(
                size: 50,
                message: message,
              ),
            ),
          ),
      ],
    );
  }
}

/// Inline loader for use in lists, cards, or small spaces
class MinimalLoaderInline extends StatelessWidget {
  final double size;
  final Color? color;

  const MinimalLoaderInline({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MinimalLoader(
      size: size,
      color: color,
      strokeWidth: 2.5,
    );
  }
}

