import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Interactive radar-style loading animation
/// 
/// Features:
/// - Rotating radar sweeps
/// - Pulsing concentric circles
/// - Scanning particles
/// - Grid lines
/// - Customizable message
class RadarLoader extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool useAppColors; // Use app's color scheme by default

  const RadarLoader({
    super.key,
    this.message,
    this.size,
    this.primaryColor,
    this.secondaryColor,
    this.useAppColors = true,
  });

  @override
  State<RadarLoader> createState() => _RadarLoaderState();
}

class _RadarLoaderState extends State<RadarLoader>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarRotation;
  late Animation<double> _radarOpacity;
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Radar animation controller
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _radarRotation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.linear),
    );
    _radarOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 0.3), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeInOut),
    );
    
    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final size = widget.size ?? (isTablet ? 200.0 : 180.0);
    
    // Use app's consistent color scheme (blue gradient theme)
    final primaryColor = widget.primaryColor ?? (widget.useAppColors 
        ? const Color(0xFF2979FF) 
        : const Color(0xFF2979FF));
    final secondaryColor = widget.secondaryColor ?? (widget.useAppColors 
        ? const Color(0xFF1E40AF) // Darker blue to match gradient
        : const Color(0xFF10B981));
    final radius = size / 2;
    
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_radarController, _particleController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // White animated ripple effects (outermost)
              ...List.generate(3, (index) {
                final delay = index * 0.35;
                final rippleValue = ((_radarOpacity.value + delay) % 1.0);
                final rippleSize = size * (0.95 + (rippleValue * 0.25)); // Grows outward
                final rippleOpacity = (1.0 - rippleValue * 1.2).clamp(0.0, 0.8); // Fades out
                return Positioned(
                  left: (size - rippleSize) / 2,
                  top: (size - rippleSize) / 2,
                  child: Container(
                    width: rippleSize,
                    height: rippleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: rippleOpacity * 0.9),
                        width: 2.5,
                      ),
                    ),
                  ),
                );
              }),
              // Outer pulsing circles - refined design
              ...List.generate(3, (index) {
                final circleSize = size - (index * (isTablet ? 40.0 : 35.0));
                final delay = index * 0.2;
                final adjustedOpacity = ((_radarOpacity.value - delay) % 1.0).abs().clamp(0.0, 1.0);
                return Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: adjustedOpacity * 0.4),
                      width: index == 0 ? 2.0 : 1.5,
                    ),
                  ),
                );
              }),
              
              // Grid lines for radar effect - cleaner design
              ...List.generate(8, (index) {
                final angle = (index * 45.0) * math.pi / 180.0;
                final lineLength = radius * 0.75;
                final opacity = (0.25 + (_radarOpacity.value * 0.25)).clamp(0.1, 0.5);
                return Transform.rotate(
                  angle: angle,
                  child: Container(
                    width: 0.8,
                    height: lineLength,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withValues(alpha: 0.0),
                          primaryColor.withValues(alpha: opacity * 0.5),
                          primaryColor.withValues(alpha: opacity),
                          primaryColor.withValues(alpha: opacity * 0.5),
                          primaryColor.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                );
              }),
              
              // Scanning particles - refined positioning
              ...List.generate(8, (index) {
                final particleAngle = (index * 45.0 + _particleAnimation.value * 360.0) * math.pi / 180.0;
                final particleRadius = radius * (0.4 + (_radarOpacity.value * 0.3));
                final particleX = math.cos(particleAngle) * particleRadius;
                final particleY = math.sin(particleAngle) * particleRadius;
                final particleOpacity = (math.sin(_particleAnimation.value * 2 * math.pi + index * 0.5) * 0.4 + 0.6).clamp(0.3, 1.0);
                
                return Positioned(
                  left: radius + particleX - 4,
                  top: radius + particleY - 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: particleOpacity),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: particleOpacity * 0.6),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              
              // Primary rotating radar sweep
              Transform.rotate(
                angle: _radarRotation.value * math.pi / 180.0,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: RadarSweepPainter(
                      sweepAngle: 60.0,
                      color: primaryColor,
                      opacity: _radarOpacity.value,
                    ),
                  ),
                ),
              ),
              
              // Secondary counter-rotating sweep
              Transform.rotate(
                angle: (-_radarRotation.value * 0.6) * math.pi / 180.0,
                child: SizedBox(
                  width: size * 0.75,
                  height: size * 0.75,
                  child: CustomPaint(
                    painter: RadarSweepPainter(
                      sweepAngle: 45.0,
                      color: secondaryColor,
                      opacity: _radarOpacity.value * 0.5,
                    ),
                  ),
                ),
              ),
              
              // Center circle with refined pulsing effect
              Transform.scale(
                scale: 0.92 + (_radarOpacity.value * 0.08),
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: _radarOpacity.value * 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: _radarOpacity.value * 0.5),
                        blurRadius: 18,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: primaryColor.withValues(alpha: _radarOpacity.value * 0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _particleController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _particleAnimation.value * 2 * math.pi,
                          child: Container(
                            width: size * 0.18,
                            height: size * 0.18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [primaryColor, secondaryColor],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: size * 0.08,
                                height: size * 0.08,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Loading text (optional - only if message provided)
              if (widget.message != null)
                Positioned(
                  bottom: size * 0.12,
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      final textOpacity = (math.sin(_particleAnimation.value * 2 * math.pi) * 0.15 + 0.85).clamp(0.75, 1.0);
                      return Opacity(
                        opacity: textOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.message!,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: isTablet ? 15 : 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter for the radar sweep
class RadarSweepPainter extends CustomPainter {
  final double sweepAngle;
  final Color color;
  final double opacity;

  RadarSweepPainter({
    required this.sweepAngle,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.0),
          color.withValues(alpha: opacity * 0.6),
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.6),
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.3, 0.4, 0.45, 0.5, 0.55, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepRadians = sweepAngle * math.pi / 180.0;
    
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + radius * math.cos(-sweepRadians / 2),
        center.dy + radius * math.sin(-sweepRadians / 2),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -sweepRadians / 2,
        sweepRadians,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RadarSweepPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity;
  }
}

