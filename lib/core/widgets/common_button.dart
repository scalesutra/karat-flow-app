import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum _ButtonType { primary, outlined, tonal, danger, text }

class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _type = _ButtonType.primary;

  const CommonButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _type = _ButtonType.primary;

  const CommonButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _type = _ButtonType.outlined;

  const CommonButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _type = _ButtonType.tonal;

  const CommonButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _type = _ButtonType.danger;

  const CommonButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  }) : _type = _ButtonType.text;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final _ButtonType _type;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? _resolveTextColor();
    final effectiveBgColor = backgroundColor ?? _resolveBgColor();

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: effectiveTextColor),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: effectiveTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        if (!isLoading && suffixIcon != null) ...[
          const SizedBox(width: 6),
          Icon(suffixIcon, size: 18, color: effectiveTextColor),
        ],
      ],
    );

    Widget button = switch (_type) {
      _ButtonType.primary || _ButtonType.danger => FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          disabledBackgroundColor: effectiveBgColor.withValues(alpha: 0.6),
          minimumSize: Size(isFullWidth ? double.infinity : 40, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: content,
      ),
      _ButtonType.outlined => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          side: BorderSide(
            color:
                borderColor ??
                (onPressed == null
                    ? AppColors.outline.withValues(alpha: 0.5)
                    : AppColors.outline),
          ),
          minimumSize: Size(isFullWidth ? double.infinity : 40, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: content,
      ),
      _ButtonType.tonal => FilledButton.tonal(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveTextColor,
          minimumSize: Size(isFullWidth ? double.infinity : 40, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: content,
      ),
      _ButtonType.text => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: effectiveTextColor,
          minimumSize: Size(isFullWidth ? double.infinity : 40, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: content,
      ),
    };

    if (isFullWidth) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.hasBoundedWidth) {
            return SizedBox(width: double.infinity, child: button);
          }
          return button;
        },
      );
    }
    return button;
  }

  Color _resolveTextColor() => switch (_type) {
    _ButtonType.primary => AppColors.pureWhite,
    _ButtonType.outlined => AppColors.ink,
    _ButtonType.tonal => AppColors.emerald,
    _ButtonType.danger => AppColors.pureWhite,
    _ButtonType.text => AppColors.ink,
  };

  Color _resolveBgColor() => switch (_type) {
    _ButtonType.primary => AppColors.emerald,
    _ButtonType.outlined => Colors.transparent,
    _ButtonType.tonal => AppColors.emeraldLight,
    _ButtonType.danger => AppColors.danger,
    _ButtonType.text => Colors.transparent,
  };
}
