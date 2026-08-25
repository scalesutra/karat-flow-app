import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'common_text.dart';

class HealthToneBadge extends StatelessWidget {
  const HealthToneBadge({super.key, required this.tone, this.showLabel = true});

  final HealthTone tone;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, label) = switch (tone) {
      HealthTone.healthy => (
        AppColors.success,
        AppColors.successLight,
        'Healthy',
      ),
      HealthTone.warning => (
        AppColors.warning,
        AppColors.warningLight,
        'Warning',
      ),
      HealthTone.critical => (
        AppColors.danger,
        AppColors.dangerLight,
        'Critical',
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 8 : 6,
        vertical: showLabel ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (showLabel) ...[
            const SizedBox(width: 5),
            CommonText.labelSmall(
              label,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ],
        ],
      ),
    );
  }
}

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.urgency});

  final InstructionUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (urgency) {
      InstructionUrgency.routine => (AppColors.muted, AppColors.outlineLight),
      InstructionUrgency.today => (AppColors.warning, AppColors.warningLight),
      InstructionUrgency.urgent => (AppColors.danger, AppColors.dangerLight),
      InstructionUrgency.upcoming => (
        AppColors.emerald,
        AppColors.emeraldLight,
      ),
      InstructionUrgency.delayed => (AppColors.danger, AppColors.dangerLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          CommonText.labelSmall(
            urgency.label,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final InstructionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      InstructionStatus.sent => (AppColors.muted, AppColors.outlineLight),
      InstructionStatus.acknowledged => (AppColors.gold, AppColors.goldLight),
      InstructionStatus.inProgress => (
        AppColors.warning,
        AppColors.warningLight,
      ),
      InstructionStatus.resolved => (AppColors.success, AppColors.successLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: CommonText.labelSmall(
        status.label,
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class CustomBadge extends StatelessWidget {
  const CustomBadge({
    super.key,
    required this.label,
    this.color = AppColors.emerald,
    this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          CommonText.labelSmall(
            label,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
