import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../domain/models.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/instructions/directives_notification_button.dart';
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
    bool isAdminUser = false;
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        isAdminUser = AppRole.fromRoleString(authState.role) == AppRole.admin;
      } else {
        isAdminUser = currentRole == AppRole.admin;
      }
    } catch (_) {
      isAdminUser = currentRole == AppRole.admin;
    }

    final canSwitchRole = onRoleChanged != null && isAdminUser;

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
                  title ?? 'RK JEWELLERS',
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
        // Notification bell with unread directives badge for all dashboards
        DirectivesNotificationButton(currentRole: currentRole),
        // Strict Role Display Badge (Only Admin can switch roles)
        if (currentRole != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: canSwitchRole
                  ? () => _showAdminRoleSwitchModal(
                      context,
                      currentRole!,
                      onRoleChanged!,
                    )
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                    if (canSwitchRole) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ],
                  ],
                ),
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

  void _showAdminRoleSwitchModal(
    BuildContext context,
    AppRole activeRole,
    ValueChanged<AppRole> onRoleChanged,
  ) {
    const allowedRoles = [
      AppRole.admin,
      AppRole.frontOffice,
      AppRole.processManager,
      AppRole.cadDesigner,
      AppRole.rawDesigner,
      AppRole.stockist,
      AppRole.workshopArtisan,
      AppRole.worker,
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.emeraldDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin View Switcher',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Switch and inspect any department dashboard or worker bench',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: allowedRoles.map((r) {
                      final isSel = r == activeRole;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.emerald.withValues(alpha: 0.1)
                              : AppColors.paper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? AppColors.emerald
                                : AppColors.outlineLight,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            _roleIcon(r),
                            color: isSel
                                ? AppColors.emeraldDark
                                : AppColors.ink,
                          ),
                          title: Text(
                            r.label,
                            style: TextStyle(
                              fontWeight: isSel
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSel
                                  ? AppColors.emeraldDark
                                  : AppColors.ink,
                            ),
                          ),
                          subtitle: Text(
                            _roleSubtitle(r),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          trailing: isSel
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.emerald,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            onRoleChanged(r);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _roleSubtitle(AppRole role) => switch (role) {
    AppRole.admin => 'Master Control & Analytics Portal',
    AppRole.processManager => 'Workshop Stage & Lot Management',
    AppRole.cadDesigner => '3D Design & CAD Render Submissions',
    AppRole.rawDesigner => '2D Hand Sketches & Order Concept Uploads',
    AppRole.stockist => 'Gold, Diamonds & Vault Inventory Management',
    AppRole.workshopArtisan => 'Bench Assembly & Production Tasks',
    _ => '',
  };

  static IconData _roleIcon(AppRole role) => switch (role) {
    AppRole.admin => Icons.admin_panel_settings_outlined,
    AppRole.frontOffice => Icons.storefront_outlined,
    AppRole.processManager => Icons.precision_manufacturing_outlined,
    AppRole.cadDesigner => Icons.view_in_ar_outlined,
    AppRole.rawDesigner => Icons.draw_outlined,
    AppRole.workshopArtisan => Icons.handyman_outlined,
    AppRole.worker => Icons.handyman_outlined,
    AppRole.stockist => Icons.security_outlined,
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
        'RK',
        style: TextStyle(
          color: Color(0xFFFFD18A),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
