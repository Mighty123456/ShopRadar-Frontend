import 'package:flutter/material.dart';
import 'loading_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;
  final double? width;
  final bool isPrimary;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.height,
    this.width,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    const primaryBlue = Color(0xFF2979FF);
    const primaryBlueHover = Color(0xFF1565C0);
    const secondaryGray = Color(0xFF6B7280);
    const lightGrayBg = Color(0xFFF5F5F5);
    const lightGrayBgHover = Color(0xFFE5E5E5);
    
    final defaultBgColor = isPrimary 
        ? primaryBlue
        : lightGrayBg;
    
    final defaultTextColor = isPrimary 
        ? Colors.white 
        : secondaryGray;
    
    final disabledBgColor = Colors.grey[300];
    final disabledTextColor = Colors.grey[600];
    
    return SizedBox(
      height: height ?? (isSmallScreen ? 48 : 52),
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (onPressed == null || isLoading) {
                return disabledBgColor;
              }
              return backgroundColor ?? defaultBgColor;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (onPressed == null || isLoading) {
                return disabledTextColor;
              }
              return textColor ?? defaultTextColor;
            },
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevation: WidgetStateProperty.resolveWith<double?>(
            (Set<WidgetState> states) {
              if (onPressed == null || isLoading) {
                return 0;
              }
              return 2;
            },
          ),
          shadowColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (onPressed == null || isLoading) {
                return Colors.transparent;
              }
              return Colors.black.withValues(alpha: 0.1);
            },
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 12 : 14,
            ),
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered) && onPressed != null && !isLoading) {
                return isPrimary ? primaryBlueHover.withValues(alpha: 0.1) : lightGrayBgHover.withValues(alpha: 0.1);
              }
              return null;
            },
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: LoadingWidget(
                  size: 20,
                  color: textColor ?? (isPrimary ? Colors.white : secondaryGray),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
} 