import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../auth/widgets/authenticated_profile_card.dart';
import 'widgets/sketch_directives_section.dart';

class CadMorePage extends StatefulWidget {
  const CadMorePage({super.key, required this.store});

  final DemoStore store;

  @override
  State<CadMorePage> createState() => _CadMorePageState();
}

class _CadMorePageState extends State<CadMorePage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final completedToday = widget.store.cadCompletedCount;
        final totalTasks = widget.store.cadTasks.length;
        final inProgress = widget.store.cadInProgressCount;

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              const CommonText.headlineLarge('CAD Studio'),
              const SizedBox(height: 1),
              CommonText.bodySmall(
                'Profile, directives & performance',
                color: AppColors.muted,
              ),
              const SizedBox(height: 14),

              // 1. PROFILE CARD
              const AuthenticatedProfileCard(),
              const SizedBox(height: 14),

              // 2. ADMIN DIRECTIVES & GUIDELINES
              const SketchDirectivesSection(),
              const SizedBox(height: 14),

              // 3. TODAY'S PERFORMANCE STATS
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.insights,
                          color: AppColors.emerald,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Today\'s Performance',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Total',
                            value: '$totalTasks',
                            icon: Icons.folder_outlined,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'In Progress',
                            value: '$inProgress',
                            icon: Icons.auto_fix_high,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatTile(
                            label: 'Completed',
                            value: '$completedToday',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const CommonText.titleMedium('Preferences & Settings'),
              const SizedBox(height: 8),

              // 4. LANGUAGE PICKER
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
                            'Language / भाषा / ભાષા',
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
