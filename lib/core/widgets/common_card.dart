import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor = AppColors.paper,
    this.borderColor = AppColors.outline,
    this.borderRadius,
    this.onTap,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(10.r);
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h);
    final effectiveMargin = margin ?? EdgeInsets.zero;

    Widget cardContent = Padding(padding: effectivePadding, child: child);

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: cardContent,
      );
    }

    return Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: Border.all(color: borderColor),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04 * elevation),
                  blurRadius: 8 * elevation,
                  offset: Offset(0, 2 * elevation),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: cardContent,
      ),
    );
  }
}
