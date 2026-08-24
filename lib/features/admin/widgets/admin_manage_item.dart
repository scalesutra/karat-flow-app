import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_text.dart';

class ManageItemData {
  const ManageItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
}

/// Section container for admin management cards
class AdminManageSection extends StatelessWidget {
  const AdminManageSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ManageItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText.titleMedium(title),
        const SizedBox(height: 8),
        CommonCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      items[i].icon,
                      color: AppColors.emerald,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    items[i].title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    items[i].subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (items[i].badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: Text(
                            items[i].badge!,
                            style: const TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.muted,
                        size: 18,
                      ),
                    ],
                  ),
                  onTap: items[i].onTap,
                ),
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: AppColors.outlineLight,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
