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
                  eyebrow: 'Account & Permissions',
                  title: title,
                  description: description,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 20),
                const AuthenticatedProfileCard(),
                const SizedBox(height: 14),
                RoleDirectivesSection(store: store, role: role),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 1,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              color: AppColors.emeraldDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authenticated Session',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Role privileges active and synchronized',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        role.shortDescription,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
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
