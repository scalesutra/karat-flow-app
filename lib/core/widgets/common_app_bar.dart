import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/models.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'common_logout_dialog.dart';
import 'common_text.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.currentRole,
    this.onRoleChanged,
    this.showBrand = true,
    this.showBackButton = false,
    this.actions,
    this.leading,
    this.bottom,
  });

  final String? title;
  final String? subtitle;
  final AppRole? currentRole;
  final ValueChanged<AppRole>? onRoleChanged;
  final bool showBrand;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    AppDimensions.appBarHeight + (bottom?.preferredSize.height ?? 0.0),
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: AppDimensions.appBarHeight,
      titleSpacing: showBackButton ? 0 : AppDimensions.space20,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Get.back(),
                )
              : null),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBrand) ...[const _BrandMark(), const SizedBox(width: 10)],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonText.labelLarge(
                  title ?? 'KARATFLOW',
                  letterSpacing: title == null ? 1.5 : 0.2,
                  fontSize: title == null ? 13 : 15,
                ),
                if (subtitle != null)
                  CommonText.bodySmall(subtitle!, color: AppColors.muted),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        // Strict Role Display Badge (Non-switchable in Production)
        if (currentRole != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _roleIcon(currentRole!),
                    size: 14,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentRole!.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            tooltip: 'Sign Out of KaratFlow',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            onPressed: () => CommonLogoutDialog.show(context),
          ),
        ),
      ],
      bottom: bottom,
    );
  }

  static IconData _roleIcon(AppRole role) => switch (role) {
    AppRole.admin => Icons.admin_panel_settings_outlined,
    AppRole.frontOffice => Icons.storefront_outlined,
    AppRole.processManager => Icons.precision_manufacturing_outlined,
    AppRole.cadDesigner => Icons.view_in_ar_outlined,
    AppRole.rawDesigner => Icons.draw_outlined,
    AppRole.workshopArtisan => Icons.handyman_outlined,
  };
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'K',
        style: TextStyle(
          color: Color(0xFFFFD18A),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
