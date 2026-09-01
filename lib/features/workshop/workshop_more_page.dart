import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../auth/widgets/authenticated_profile_card.dart';
import '../instructions/role_directives_section.dart';

class WorkshopMorePage extends StatefulWidget {
  const WorkshopMorePage({super.key, required this.store});

  final DemoStore store;

  @override
  State<WorkshopMorePage> createState() => _WorkshopMorePageState();
}

class _WorkshopMorePageState extends State<WorkshopMorePage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              const CommonText.headlineLarge('Workshop & Directives'),
              const SizedBox(height: 1),
              CommonText.bodySmall(
                'Manager directives, active SOPs and settings',
                color: AppColors.muted,
              ),
              const SizedBox(height: 10),

              const AuthenticatedProfileCard(),
              const SizedBox(height: 14),

              RoleDirectivesSection(
                store: widget.store,
                role: AppRole.processManager,
              ),
              const SizedBox(height: 14),

              const CommonText.titleMedium('Preferences & Settings'),
              const SizedBox(height: 8),

              CommonCard(
                onTap: () => CommonLanguagePicker.show(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: AppColors.emerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Language / भाषा (i18n)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Switch between English, हिंदी and ગુજરાતી',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
