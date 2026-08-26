import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../auth/widgets/authenticated_profile_card.dart';
import '../instructions/role_directives_section.dart';

class RoleProfilePage extends StatelessWidget {
  const RoleProfilePage({
    super.key,
    required this.title,
    required this.description,
    required this.store,
    required this.role,
  });

  final String title;
  final String description;
  final DemoStore store;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoleDashboardHeader(
                  eyebrow: 'Account',
                  title: title,
                  description: description,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                const AuthenticatedProfileCard(),
                const SizedBox(height: 14),
                RoleDirectivesSection(store: store, role: role),
                const SizedBox(height: 14),
                CommonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Secure Session',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your access and role are loaded from the authenticated API profile.',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      CommonButton.danger(
                        label: 'Sign Out',
                        icon: Icons.logout_rounded,
                        onPressed: () => CommonLogoutDialog.show(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
