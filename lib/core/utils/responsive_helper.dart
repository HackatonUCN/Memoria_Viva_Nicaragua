import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 || !kIsWeb;

  static bool isTablet(BuildContext context) =>
      kIsWeb &&
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      kIsWeb && MediaQuery.of(context).size.width >= 1200;

  static double getContentWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width;
    if (isTablet(context)) return 600;
    return 800; // desktop
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isMobile(context)) return const EdgeInsets.all(24);
    return EdgeInsets.symmetric(
      horizontal: (width - getContentWidth(context)) / 2,
      vertical: 32,
    );
  }

  static double getLoginCardWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width;
    if (isTablet(context)) return 500;
    return 550;
  }
}
