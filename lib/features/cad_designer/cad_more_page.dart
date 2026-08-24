import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';

class CadMorePage extends StatefulWidget {
  const CadMorePage({super.key, required this.store});

  final DemoStore store;

  @override
  State<CadMorePage> createState() => _CadMorePageState();
}

class _CadMorePageState extends State<CadMorePage> {
  bool _matrixGoldConnected = true;
  bool _rhinoGoldConnected = false;
  bool _printerConnected = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final completedToday = widget.store.cadCompletedCount;
        final totalTasks = widget.store.cadTasks.length;
        final inProgress = widget.store.cadInProgressCount;
        final cadDirectives = widget.store.cadDirectives();

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              const CommonText.headlineLarge('CAD Studio'),
              const SizedBox(height: 1),
              CommonText.bodySmall(
                'Profile, software sync & settings',
                color: AppColors.muted,
              ),
              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════
              // 1. PROFILE CARD
              // ═══════════════════════════════════════════════════
              CommonCard(
                backgroundColor: AppColors.ink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'VK',
                              style: TextStyle(
                                color: AppColors.pureWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vikram Kumar',
                                style: TextStyle(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Senior CAD Designer · Morning Shift',
                                style: TextStyle(
                                  color: Color(0xFFFFD18A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppColors.successLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Color(0xFFFFD18A),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '8:00 AM - 5:00 PM · Floor 2, Station C-04',
                          style: TextStyle(
                            color: Color(0xFFFFD18A),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════
              // 2. ADMIN DIRECTIVES & GUIDELINES
              // ═══════════════════════════════════════════════════
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.campaign_outlined,
                                color: AppColors.goldDark,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Admin Directives',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cadDirectives.isNotEmpty
                                ? AppColors.goldLight
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                            border: Border.all(
                              color: cadDirectives.isNotEmpty
                                  ? AppColors.gold.withValues(alpha: 0.4)
                                  : AppColors.outline,
                            ),
                          ),
                          child: Text(
                            '${cadDirectives.length} Active',
                            style: TextStyle(
                              color: cadDirectives.isNotEmpty
                                  ? AppColors.goldDark
                                  : AppColors.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (cadDirectives.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: AppColors.emerald,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No pending directives. All guidelines followed.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...cadDirectives.map((directive) {
                        final isAck = directive['status'] == 'Acknowledged';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAck
                                ? AppColors.canvas
                                : AppColors.goldLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAck
                                  ? AppColors.outline
                                  : AppColors.gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.ink,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      directive['id'] ?? 'DIR',
                                      style: const TextStyle(
                                        color: AppColors.pureWhite,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    directive['date'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                directive['content'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isAck
                                      ? AppColors.muted
                                      : AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isAck)
                                    InkWell(
                                      onTap: () {
                                        widget.store.acknowledgeDirective(
                                          directive['id']!,
                                        );
                                        CommonSnackbar.success(
                                          context,
                                          title: 'Directive Acknowledged',
                                          message: 'Marked ${directive['id']} as read.',
                                          duration: const Duration(seconds: 2),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emerald,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.done_all,
                                              color: AppColors.pureWhite,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Acknowledge',
                                              style: TextStyle(
                                                color: AppColors.pureWhite,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.emerald,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Acknowledged',
                                          style: TextStyle(
                                            color: AppColors.emeraldDark,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════
              // 2. TODAY'S STATS
              // ═══════════════════════════════════════════════════
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

              // ═══════════════════════════════════════════════════
              // 3. CAD SOFTWARE SYNC
              // ═══════════════════════════════════════════════════
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.sync_alt,
                          color: AppColors.emerald,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CAD Software Sync',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SyncToggleRow(
                      title: 'MatrixGold CAD',
                      subtitle: 'Auto-import STL from MatrixGold',
                      icon: Icons.view_in_ar,
                      isConnected: _matrixGoldConnected,
                      onToggle: (v) =>
                          setState(() => _matrixGoldConnected = v),
                    ),
                    const Divider(height: 20),
                    _SyncToggleRow(
                      title: 'RhinoGold / Rhino 3D',
                      subtitle: 'Sync .3dm files to KaratFlow',
                      icon: Icons.hub_outlined,
                      isConnected: _rhinoGoldConnected,
                      onToggle: (v) =>
                          setState(() => _rhinoGoldConnected = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════
              // 4. PRINTER
              // ═══════════════════════════════════════════════════
              CommonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.print_outlined,
                          color: AppColors.emerald,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Label Printer',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SyncToggleRow(
                      title: 'Zebra ZD421',
                      subtitle: '38×25mm CAD pouch labels',
                      icon: Icons.print,
                      isConnected: _printerConnected,
                      onToggle: (v) =>
                          setState(() => _printerConnected = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════
              // 5. QUICK ACTIONS
              // ═══════════════════════════════════════════════════
              CommonButton.outlined(
                height: 44,
                icon: Icons.print_outlined,
                label: '+ Print Barcode Tag',
                onPressed: () {
                  CommonSnackbar.info(
                    context,
                    title: 'Zebra Label Printed',
                    message: 'Sent 38×25mm CAD pouch label to Zebra ZD421.',
                  );
                },
              ),
              const SizedBox(height: 10),
              CommonButton.outlined(
                height: 44,
                icon: Icons.help_outline,
                label: 'Help & Support',
                onPressed: () {
                  CommonSnackbar.info(
                    context,
                    title: 'Support',
                    message: 'Contact IT: ext. 204 · support@karatflow.in',
                  );
                },
              ),
              const SizedBox(height: 10),
              CommonButton.outlined(
                height: 44,
                icon: Icons.translate_rounded,
                label: 'Language / भाषा / ભાષા',
                onPressed: () => CommonLanguagePicker.show(context),
              ),
              const SizedBox(height: 10),
              CommonButton.outlined(
                height: 44,
                icon: Icons.logout_rounded,
                label: 'Sign Out / Switch User',
                onPressed: () => CommonLogoutDialog.show(context),
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

class _SyncToggleRow extends StatelessWidget {
  const _SyncToggleRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isConnected,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isConnected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isConnected
                ? AppColors.emeraldLight
                : AppColors.canvas,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isConnected ? AppColors.emerald : AppColors.muted,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: isConnected,
          onChanged: (v) {
            onToggle(v);
            CommonSnackbar.info(
              context,
              title: v ? '$title Connected' : '$title Disconnected',
              message: v
                  ? 'Sync enabled for $title.'
                  : 'Sync paused for $title.',
            );
          },
          activeTrackColor: AppColors.emerald,
        ),
      ],
    );
  }
}
