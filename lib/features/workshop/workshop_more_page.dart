import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/widgets/authenticated_profile_card.dart';
import '../instructions/role_directives_section.dart';

class WorkshopMorePage extends StatefulWidget {
  const WorkshopMorePage({super.key, required this.store});

  final DemoStore store;

  @override
  State<WorkshopMorePage> createState() => _WorkshopMorePageState();
}

class _WorkshopMorePageState extends State<WorkshopMorePage> {
  bool _printerConnected = false;
  bool _scaleConnected = false;
  bool _scannerConnected = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final workshopDirectives = widget.store.workshopDirectives();

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
            children: [
              const CommonText.headlineLarge('Workshop & Hardware'),
              const SizedBox(height: 1),
              CommonText.bodySmall(
                'Peripherals, shift controls and workshop settings',
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

              // 1. SHIFT CARD
              CommonCard(
                backgroundColor: AppColors.ink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Color(0xFFFFD18A),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Current Shift: Morning Floor',
                              style: TextStyle(
                                color: Color(0xFFFFD18A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
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
                            color: AppColors.emerald,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Shift Time: 08:00 AM – 05:00 PM',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.store.team.length} Active goldsmiths logged in · 14 Active Benches',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CommonButton.outlined(
                        height: 34,
                        label: 'End Shift / Handover Log',
                        icon: Icons.swap_horiz,
                        textColor: const Color(0xFFFFD18A),
                        onPressed: () => _showShiftHandoverModal(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════
              // 2. ADMIN DIRECTIVES & FLOOR GUIDELINES
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
                              'Floor Directives & SOPs',
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
                            color: workshopDirectives.isNotEmpty
                                ? AppColors.goldLight
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                            border: Border.all(
                              color: workshopDirectives.isNotEmpty
                                  ? AppColors.gold.withValues(alpha: 0.4)
                                  : AppColors.outline,
                            ),
                          ),
                          child: Text(
                            '${workshopDirectives.length} Active',
                            style: TextStyle(
                              color: workshopDirectives.isNotEmpty
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
                    if (workshopDirectives.isEmpty)
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
                              'No pending floor directives. All SOPs cleared.',
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
                      ...workshopDirectives.map((directive) {
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.ink,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldLight,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'To: ${directive['recipient']}',
                                          style: const TextStyle(
                                            color: AppColors.emeraldDark,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                          message:
                                              'Marked ${directive['id']} as acknowledged.',
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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

              const SizedBox(height: 18),

              // 3. CONNECTED WORKSHOP HARDWARE
              const CommonText.titleMedium('Workshop Hardware (BLE/USB)'),
              const SizedBox(height: 8),

              // 2A. ZEBRA PRINTER CARD
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _printerConnected
                                ? AppColors.emeraldLight
                                : AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.print,
                            color: _printerConnected
                                ? AppColors.emerald
                                : AppColors.danger,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Zebra ZD421 Printer',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'BLE 5.2',
                                      style: TextStyle(
                                        color: AppColors.emeraldDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _printerConnected
                                    ? 'Ready · 38x25mm Barcode Roll'
                                    : 'Live printer integration unavailable',
                                style: TextStyle(
                                  color: _printerConnected
                                      ? AppColors.emeraldDark
                                      : AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _printerConnected,
                          activeTrackColor: AppColors.emerald,
                          onChanged: null,
                        ),
                      ],
                    ),
                    if (_printerConnected) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CommonButton.outlined(
                              height: 34,
                              label: 'Label Preview',
                              icon: Icons.preview_outlined,
                              onPressed: () => _showLabelPreviewModal(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CommonButton.primary(
                              height: 34,
                              label: 'Test Print 1x',
                              icon: Icons.print,
                              onPressed: () {
                                CommonSnackbar.error(
                                  context,
                                  title: 'Printer unavailable',
                                  message:
                                      'No live printer bridge is configured.',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2B. METTLER TOLEDO PRECISION BALANCE CARD
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _scaleConnected
                                ? AppColors.emeraldLight
                                : AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.scale,
                            color: _scaleConnected
                                ? AppColors.emerald
                                : AppColors.danger,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Mettler Toledo Scale',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '±0.001g',
                                      style: TextStyle(
                                        color: AppColors.emeraldDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _scaleConnected
                                    ? 'Live scale connected'
                                    : 'Live scale integration unavailable',
                                style: TextStyle(
                                  color: _scaleConnected
                                      ? AppColors.emeraldDark
                                      : AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _scaleConnected,
                          activeTrackColor: AppColors.emerald,
                          onChanged: null,
                        ),
                      ],
                    ),
                    if (_scaleConnected) ...[
                      const SizedBox(height: 12),
                      // Digital Scale LCD Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFFFFD18A,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LIVE SCALE READOUT',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Status: Stable',
                                  style: TextStyle(
                                    color: Color(0xFFFFD18A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              '-- g',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Color(0xFFFFD18A),
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CommonButton.outlined(
                              height: 34,
                              label: 'Zero Tare (0.000g)',
                              icon: Icons.restart_alt,
                              onPressed: () {
                                CommonSnackbar.error(
                                  context,
                                  title: 'Scale unavailable',
                                  message:
                                      'No live scale bridge is configured.',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CommonButton.primary(
                              height: 34,
                              label: 'Read Live Scale',
                              icon: Icons.scale_outlined,
                              onPressed: () {
                                CommonSnackbar.error(
                                  context,
                                  title: 'Scale unavailable',
                                  message:
                                      'No live scale reading is available.',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2C. HONEYWELL 2D SCANNER CARD
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _scannerConnected
                                ? AppColors.emeraldLight
                                : AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: _scannerConnected
                                ? AppColors.emerald
                                : AppColors.danger,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text(
                                      'Honeywell 2D Scanner',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'USB HID',
                                      style: TextStyle(
                                        color: AppColors.emeraldDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _scannerConnected
                                    ? 'Live scanner connected'
                                    : 'Live scanner integration unavailable',
                                style: TextStyle(
                                  color: _scannerConnected
                                      ? AppColors.emeraldDark
                                      : AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _scannerConnected,
                          activeTrackColor: AppColors.emerald,
                          onChanged: null,
                        ),
                      ],
                    ),
                    if (_scannerConnected) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CommonButton.outlined(
                              height: 34,
                              label: 'Beep Sound Test',
                              icon: Icons.volume_up_outlined,
                              onPressed: () {
                                CommonSnackbar.error(
                                  context,
                                  title: 'Scanner unavailable',
                                  message:
                                      'No live scanner bridge is configured.',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CommonButton.primary(
                              height: 34,
                              label: 'Trigger Laser Aim',
                              icon: Icons.line_weight,
                              onPressed: () {
                                CommonSnackbar.error(
                                  context,
                                  title: 'Scanner unavailable',
                                  message:
                                      'No live scanner bridge is configured.',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. FLOOR RECONCILIATION & PROTOCOLS
              const CommonText.titleMedium('Floor Governance & Daily Forms'),
              const SizedBox(height: 8),
              _menuItem(
                icon: Icons.checklist_rtl,
                title: 'Daily Gold Reconciliation & Floor Sweep',
                subtitle: 'Evening floor sweep and metal loss entry',
                badge: '5:00 PM',
                onTap: () => _showReconciliationModal(context),
              ),
              const SizedBox(height: 8),
              _menuItem(
                icon: Icons.shield_outlined,
                title: 'Safety & Vault Lockdown Protocols',
                subtitle: 'Dual-custody locker lockdown checklist',
                badge: 'ISO-2026',
                onTap: () => _showVaultProtocolModal(context),
              ),
              const SizedBox(height: 8),
              _menuItem(
                icon: Icons.auto_awesome_rounded,
                title: 'Advanced AI Yield & Melt Analytics',
                subtitle:
                    'Predictive workshop intelligence & metal loss forecasting',
                badge: 'SOON',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComingSoonScreen(
                        title: 'Advanced AI & Melt Analytics',
                        subtitle:
                            'We are building next-generation AI yield estimation, melt loss tracking, and predictive workshop insights for KaratFlow.',
                        icon: Icons.insights_rounded,
                        featureTag: 'AI WORKSHOP LABS',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _menuItem(
                icon: Icons.translate_rounded,
                title: 'App Language / भाषा (i18n)',
                subtitle: 'Switch between English, हिंदी and ગુજરાતી',
                badge: 'LIVE',
                onTap: () => CommonLanguagePicker.show(context),
              ),
              const SizedBox(height: 8),
              _menuItem(
                icon: Icons.logout_rounded,
                title: 'Sign Out / Switch User',
                subtitle: 'End active session & return to login screen',
                badge: 'Auth',
                onTap: () => CommonLogoutDialog.show(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return CommonCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, color: AppColors.emerald, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.sage,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.emeraldDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
        ],
      ),
    );
  }

  // ==========================================
  // 1. ZEBRA LABEL PREVIEW MODAL
  // ==========================================
  void _showLabelPreviewModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Zebra 38x25mm Label Preview',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'High-durability thermal transfer jewellery pouch tag',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),

            // Realistic Label Tag
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outline, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 54,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KARATFLOW MFG',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'LOT-842 · JO-10482',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '22KT 916 · GW: 380.000g',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'PCS: 56 · ART: Vikram R.',
                          style: TextStyle(fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CommonButton.primary(
                label: 'Send Print Command to Zebra',
                icon: Icons.print,
                onPressed: () {
                  Navigator.pop(ctx);
                  CommonSnackbar.info(
                    context,
                    title: 'Label Printed',
                    message: 'Printed 1x batch tag on Zebra ZD421.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. SHIFT HANDOVER MODAL
  // ==========================================
  void _showShiftHandoverModal(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final supervisorName =
        authState is AuthAuthenticated && authState.userName.trim().isNotEmpty
        ? authState.userName.trim()
        : 'Profile unavailable';
    final noteCtrl = TextEditingController(
      text:
          'All 14 benches operational. 3 lots in stone setting require urgent handover.',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Shift Handover & Status Transfer',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'Transfer active WIP lot responsibility to Evening Shift Supervisor',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _metricMini(
                    'Morning Shift',
                    supervisorName,
                    Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metricMini(
                    'Incoming Shift',
                    'Not assigned',
                    Icons.nights_stay_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CommonTextField(
              controller: noteCtrl,
              label: 'Supervisor Handover Note',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CommonButton.primary(
                label: 'Sign & Complete Handover',
                onPressed: () {
                  Navigator.pop(ctx);
                  CommonSnackbar.info(
                    context,
                    title: 'Shift Handover Signed',
                    message:
                        'Shift handover logged and broadcasted to Evening Floor.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. DAILY GOLD RECONCILIATION MODAL
  // ==========================================
  void _showReconciliationModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Daily Gold Reconciliation & Sweep',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'End-of-day physical scale audit against vault issuance',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            _reconRow(
              'Morning Vault Issuance',
              '3,480.500 g 22K',
              AppColors.ink,
            ),
            _reconRow(
              'Returned WIP Bench Lots',
              '2,920.140 g 22K',
              AppColors.ink,
            ),
            _reconRow(
              'Filing Scraps & Sprue Metal',
              '512.200 g 22K',
              AppColors.ink,
            ),
            _reconRow(
              'Vacuum Sweep & Filter Dust',
              '39.850 g 22K',
              AppColors.emerald,
            ),
            const Divider(height: 16),
            _reconRow(
              'Net Manufacturing Loss',
              '- 8.310 g (0.23%)',
              AppColors.danger,
            ),
            _reconRow(
              'Allowed Loss Tolerance Limit',
              '12.000 g (0.35%)',
              AppColors.muted,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reconciliation within allowed ISO-9001 tolerance (0.23% vs 0.35% cap).',
                      style: TextStyle(
                        color: AppColors.emeraldDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CommonButton.primary(
                label: 'Submit Daily Audit to Vault',
                onPressed: () {
                  Navigator.pop(ctx);
                  CommonSnackbar.success(
                    context,
                    title: 'Audit Submitted',
                    message: 'Gold reconciliation recorded into Vault ledger.',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. VAULT PROTOCOL MODAL
  // ==========================================
  void _showVaultProtocolModal(BuildContext context) {
    final checks = [
      {'title': 'All 14 Artisan Bench Trays Vaulted', 'checked': true},
      {'title': 'Ultrasonic Cleaning & Filter Tank Drained', 'checked': true},
      {'title': 'Precision Scale Zero-Tare Re-checked', 'checked': true},
      {'title': 'CCTV Coverage & Motion Sensors Armed', 'checked': true},
      {
        'title': 'Dual-Key Physical Lock Secured (Arjun + Prakash)',
        'checked': false,
      },
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Locker & Vault Security Checklist',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 2),
              const Text(
                'Mandatory evening shutdown dual-custody verification',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              for (int i = 0; i < checks.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CheckboxListTile(
                    value: checks[i]['checked'] as bool,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      checks[i]['title'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    activeColor: AppColors.emerald,
                    onChanged: (val) {
                      setModalState(() {
                        checks[i]['checked'] = val ?? false;
                      });
                    },
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  label: 'Confirm Vault Lockdown',
                  onPressed: () {
                    Navigator.pop(ctx);
                    CommonSnackbar.success(
                      context,
                      title: 'Vault Lockdown Verified',
                      message: 'Dual-key evening vault security logged.',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricMini(String label, String val, IconData icon) {
    return CommonCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.emerald, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reconRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
