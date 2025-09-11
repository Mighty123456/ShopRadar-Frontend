import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
  
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      return baseFontSize * 0.8;
    } else if (width < 600) {
      return baseFontSize * 0.9;
    } else if (width > 1200) {
      return baseFontSize * 1.1;
    }
    return baseFontSize;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) {
      return const EdgeInsets.all(12.0);
    } else if (width < 600) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }
  
  static Widget buildResponsiveRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children.map((child) {
        if (child is Text) {
          return Flexible(
            child: child,
          );
        }
        return child;
      }).toList(),
    );
  }
  
  static Widget buildResponsiveColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
  
  static Widget buildScrollableColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    EdgeInsetsGeometry? padding,
  }) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}
