import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

abstract final class CommonSnackbar {
  /// Base method to show a customized, floating snackbar
  static void show(
    BuildContext? context, {
    required String message,
    String? title,
    IconData? icon,
    Color backgroundColor = AppColors.ink,
    Color textColor = AppColors.pureWhite,
    Color? iconColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final effectiveContext = (context != null && context.mounted)
        ? context
        : (Get.context ?? Get.overlayContext);

    if (effectiveContext == null) return;

    final messenger = ScaffoldMessenger.maybeOf(effectiveContext);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: backgroundColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        action: action,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? textColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Success SnackBar (Emerald theme with Check icon)
  static void success(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.emerald,
      textColor: AppColors.pureWhite,
      duration: duration,
    );
  }

  /// Error / Danger SnackBar (Red theme with Error icon)
  static void error(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.danger,
      textColor: AppColors.pureWhite,
      duration: duration,
    );
  }

  /// Info / Primary SnackBar (Dark Ink theme with Info icon)
  static void info(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.ink,
      textColor: AppColors.pureWhite,
      duration: duration,
    );
  }

  /// Warning / Gold SnackBar (Gold theme with Warning icon)
  static void warning(
    BuildContext? context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AppColors.warning,
      textColor: AppColors.pureWhite,
      duration: duration,
    );
  }
}
