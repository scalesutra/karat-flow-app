import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'common_card.dart';
import 'common_text.dart';

class CommonMetricTile extends StatelessWidget {
  const CommonMetricTile({
    super.key,
    required this.value,
    required this.label,
    this.sublabel,
    this.color = AppColors.emerald,
    this.icon,
    this.onTap,
  });

  final String value;
  final String label;
  final String? sublabel;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText.headlineMedium(
                value,
                color: color,
                fontWeight: FontWeight.w800,
              ),
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
            ],
          ),
          const SizedBox(height: 4),
          CommonText.bodySmall(
            label,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            CommonText.bodySmall(
              sublabel!,
              color: AppColors.muted,
              fontSize: 11,
            ),
          ],
        ],
      ),
    );
  }
}
