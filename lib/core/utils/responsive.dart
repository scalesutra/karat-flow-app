import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive extends StatelessWidget {
  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppDimensions.mobileBreakpoint &&
        width < AppDimensions.desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.desktopBreakpoint;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppDimensions.mobileBreakpoint) return DeviceType.mobile;
    if (width < AppDimensions.desktopBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  static double widthPercent(BuildContext context, double percent) =>
      MediaQuery.sizeOf(context).width * (percent / 100);

  static double heightPercent(BuildContext context, double percent) =>
      MediaQuery.sizeOf(context).height * (percent / 100);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppDimensions.desktopBreakpoint && desktop != null) {
      return desktop!;
    }
    if (width >= AppDimensions.mobileBreakpoint && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}
