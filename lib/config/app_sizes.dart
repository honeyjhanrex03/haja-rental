import 'package:flutter/material.dart';

class AppSizes {
  // Padding & Margins
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  // Border Radius
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 32;
  static const double radiusXl = 49;
  
  // Icon sizes
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  
  // Button heights
  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 58;
  
  // Input heights
  static const double inputHeightSm = 40;
  static const double inputHeightMd = 48;
  static const double inputHeightLg = 58;
}

class AppBreakpoints {
  // Responsive breakpoints
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1200;
  
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < tablet;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}
