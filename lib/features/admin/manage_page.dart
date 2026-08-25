import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../auth/widgets/authenticated_profile_card.dart';
import 'widgets/add_artisan_sheet.dart';
import 'widgets/admin_manage_item.dart';
import 'widgets/admin_review_cad_sheet.dart';
import 'widgets/admin_review_sketches_sheet.dart';
import 'widgets/send_directive_dialog.dart';
import 'bloc/admin_bloc.dart';

class AdminManagePage extends StatelessWidget {
  const AdminManagePage({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    return CommonRefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: SafeArea(
        top: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          children: [
          CommonText.headlineLarge(AppStrings.manageWorkshop.trClean),
          const SizedBox(height: 1),
          CommonText.bodySmall(
            'Employees, client limits, jewellery taxonomy and stage rules',
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),

          const AuthenticatedProfileCard(),
          const SizedBox(height: 14),

          AdminManageSection(
            title: '1. Human Resources & Crafts',
            items: [
              ManageItemData(
                icon: Icons.badge_outlined,
                title: 'Employees & Goldsmiths',
                subtitle:
                    '${store.team.length} active workshop artisans registered',
                badge: '${store.team.length} Active',
                onTap: () => _showEmployeesModal(context),
              ),
              ManageItemData(
                icon: Icons.engineering_outlined,
                title: 'Craft & Skill Capabilities',
                subtitle:
                    'Stone Setting, Filing, Casting, Polish & QC matrices',
                badge: '6 Crafts',
                onTap: () => _showSkillsModal(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          AdminManageSection(
            title: '2. Client Accounts & Credit Governance',
            items: [
              ManageItemData(
                icon: Icons.storefront_outlined,
                title: 'Client Accounts & Credit Limits',
                subtitle:
                    '${store.clients.length} wholesale jewellery clients (API sync)',
                badge: '${store.clients.length} Firms',
                onTap: () => _showClientsModal(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          AdminManageSection(
            title: '3. Manufacturing Routing & Stages',
            items: [
              ManageItemData(
                icon: Icons.alt_route,
                title: 'Production Routes & Standard Sequences',
                subtitle: '${store.stages.length} live production stages',
                badge: '${store.stages.length} Stages',
                onTap: () => _showRoutesModal(context),
              ),
              ManageItemData(
                icon: Icons.category_outlined,
                title: 'Jewellery Categories & Hallmarking Rules',
                subtitle: 'Necklaces, Earrings, Rings, Bangles (916/750/999)',
                badge: 'BIS 2026',
                onTap: () => _showCategoriesModal(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          AdminManageSection(
            title: '4. Design Review & Creative Governance',
            items: [
              ManageItemData(
                icon: Icons.brush_outlined,
                title: 'Review Client Sketch Designs',
                subtitle: 'Approve or log design corrections for 2D sketches',
                badge: 'Pending',
                onTap: () => AdminReviewSketchesSheet.show(
                  context,
                  store: store,
                  onSendDirective: (ctxRef) =>
                      _showSendDirectiveDialog(context, ctxRef),
                ),
              ),
              ManageItemData(
                icon: Icons.view_in_ar_outlined,
                title: 'Review CAD 3D Models',
                subtitle:
                    'Inspect solitaire meshes and approve casting weights',
                badge: '3D Preview',
                onTap: () => AdminReviewCadSheet.show(
                  context,
                  store: store,
                  onSendDirective: (ctxRef) =>
                      _showSendDirectiveDialog(context, ctxRef),
                ),
              ),
              ManageItemData(
                icon: Icons.send_and_archive_outlined,
                title: 'Send Creative Directives',
                subtitle: 'Issue structural rules to designers & gold artisans',
                badge: '${store.adminDirectives.length} Active',
                onTap: () => _showDirectivesModal(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          AdminManageSection(
            title: '5. Account & Session',
            items: [
              ManageItemData(
                icon: Icons.logout_rounded,
                title: 'Sign Out / Switch User',
                subtitle: 'End active session and return to login screen',
                badge: 'Auth',
                onTap: () => CommonLogoutDialog.show(context),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  // ==========================================
  // 1. EMPLOYEES & GOLDSMITHS MODAL
  // ==========================================
  void _showEmployeesModal(BuildContext context) {
    _openSheet(
      context: context,
      title: 'Employees & Goldsmiths',
      subtitle: 'Registered workshop artisans, skill matrix and wage slabs',
      actionLabel: 'Add Artisan',
      onAction: () {
        AddArtisanSheet.show(context, store);
      },
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: store.team.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) {
          final member = store.team[index];
          final (statusColor, statusBg) = switch (member.status) {
            EmployeeStatus.working => (
              AppColors.emerald,
              AppColors.emeraldLight,
            ),
            EmployeeStatus.available => (
              AppColors.warning,
              AppColors.warningLight,
            ),
            EmployeeStatus.onLeave => (AppColors.muted, AppColors.outlineLight),
            EmployeeStatus.blocked => (AppColors.danger, AppColors.dangerLight),
          };

          return CommonCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.emeraldLight,
                  child: Text(
                    member.name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.status.label,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${member.craft} · Shift: ${member.shift} · ${member.currentAssignment}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${member.todayEfficiencyPercent}% Eff.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${member.activeLotsCount} Active Lots',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 2. CRAFT & SKILL CAPABILITIES MODAL
  // ==========================================
  void _showSkillsModal(BuildContext context) {
    final crafts = [
      {
        'name': 'CAD & 3D Wax Camming',
        'artisans': '2 Specialists',
        'loss': '0.00%',
        'accuracy': '99.8%',
      },
      {
        'name': 'Flask Burnout & Tree Casting',
        'artisans': '3 Master Casters',
        'loss': '< 0.20%',
        'accuracy': '99.1%',
      },
      {
        'name': 'Filing, Jointing & Laser Assembly',
        'artisans': '4 Goldsmiths',
        'loss': '< 0.15%',
        'accuracy': '98.5%',
      },
      {
        'name': 'Micro-Prong & Pave Stone Setting',
        'artisans': '3 Master Setters',
        'loss': '< 0.05%',
        'accuracy': '99.5%',
      },
      {
        'name': 'High-Lustre Polishing & Rhodium',
        'artisans': '3 Polishers',
        'loss': '< 0.10%',
        'accuracy': '99.0%',
      },
      {
        'name': 'Assay QC & XRF Hallmarking',
        'artisans': '2 QC Officers',
        'loss': '0.00%',
        'accuracy': '100.0%',
      },
    ];

    _openSheet(
      context: context,
      title: 'Craft & Skill Matrices',
      subtitle:
          'Workshop technical capabilities and allowed scrap loss thresholds',
      actionLabel: 'Add Craft Category',
      onAction: () => CommonSnackbar.info(
        context,
        title: 'Crafts',
        message: 'Configure craft matrix thresholds.',
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: crafts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final c = crafts[i];
          return CommonCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c['accuracy']!,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _metricMini(Icons.people_outline, c['artisans']!),
                    const SizedBox(width: 16),
                    _metricMini(
                      Icons.shield_outlined,
                      'Max Allowed Loss: ${c['loss']}',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 3. CLIENT ACCOUNTS & CREDIT LIMITS MODAL
  // ==========================================
  void _showClientsModal(BuildContext context) {
    _openSheet(
      context: context,
      title: 'Wholesale Client Ledgers',
      subtitle: 'Client credit allocations, active orders and ledger caps',
      actionLabel: 'Register Client',
      onAction: () => CommonSnackbar.info(
        context,
        title: 'Clients',
        message: 'Opening client registration modal...',
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: store.clients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final client = store.clients[i];
          final limitRupees = client.creditLimitLakhs * 100000;
          final percent =
              (client.outstandingBalance / (limitRupees > 0 ? limitRupees : 1))
                  .clamp(0.0, 1.0);

          return CommonCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      client.firmName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      client.city,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Contact: ${client.contactPerson} · ${client.phone}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Outstanding: ₹${(client.outstandingBalance / 100000).toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                    Text(
                      'Limit: ₹${client.creditLimitLakhs.toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: AppColors.outlineLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 0.8 ? AppColors.danger : AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 5. PRODUCTION ROUTES & SEQUENCES MODAL
  // ==========================================
  void _showRoutesModal(BuildContext context) {
    final stages = store.stages
        .map(
          (stage) => {
            'step': '${stage.stageNumber}',
            'name': stage.name,
            'sla': 'Live API',
            'loss': '—',
          },
        )
        .toList();

    _openSheet(
      context: context,
      title: 'Standard Production Routing',
      subtitle: '${stages.length} backend-configured production stages',
      actionLabel: 'Edit Routing',
      onAction: () => CommonSnackbar.info(
        context,
        title: 'Route',
        message: 'Production pipeline SLA rules verified.',
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: stages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final s = stages[i];
          return CommonCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.ink,
                  child: Text(
                    s['step']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard SLA: ${s['sla']} · Allowed Scrap: ${s['loss']}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 6. CATEGORIES & HALLMARKING RULES MODAL
  // ==========================================
  void _showCategoriesModal(BuildContext context) {
    final rules = [
      {
        'karat': '24KT (999 Purity)',
        'app': 'Pure Gold Bullion Bars & Primary Coins',
        'huid': 'Mandatory Assay',
      },
      {
        'karat': '22KT (916 Purity)',
        'app': 'Traditional Wholesale Necklaces, Bangles & Temple Jewellery',
        'huid': 'BIS 2026 Laser HUID',
      },
      {
        'karat': '18KT (750 Purity)',
        'app': 'Diamond Studded Rings, Solitaires & Modern Fine Jewelry',
        'huid': 'BIS 2026 + IGI/GIA',
      },
      {
        'karat': '14KT (585 Purity)',
        'app': 'Lightweight Export Pendants & High-Durability Chains',
        'huid': 'BIS 2026 Export Standard',
      },
    ];

    _openSheet(
      context: context,
      title: 'Jewellery Categories & Hallmarking',
      subtitle: 'BIS 2026 HUID Laser-marking and Karatage purity guidelines',
      actionLabel: 'Configure BIS Slabs',
      onAction: () => CommonSnackbar.info(
        context,
        title: 'Hallmarking',
        message: 'BIS 2026 compliance active.',
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: rules.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final r = rules[i];
          return CommonCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r['karat']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sage,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        r['huid']!,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r['app']!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SHARED MODAL SHEET HELPER
  // ==========================================
  void _openSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (c, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: child),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAction();
                  },
                  label: actionLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricMini(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.muted),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ==========================================
  // 4. DESIGN REVIEW & GOVERNANCE MODALS
  // ==========================================

  void _showDirectivesModal(BuildContext context) {
    _openSheet(
      context: context,
      title: 'Active Governance Directives',
      subtitle:
          'Direct instructions issued to design team & workshop gold artisans',
      actionLabel: 'New Directive',
      onAction: () {
        _showSendDirectiveDialog(context, 'Global Directive');
      },
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: store.adminDirectives.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) {
          final directive = store.adminDirectives[index];

          return CommonCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'To: ${directive['recipient']}',
                        style: const TextStyle(
                          color: AppColors.emeraldDark,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      directive['date']!,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  directive['content']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSendDirectiveDialog(BuildContext context, String contextTag) {
    SendDirectiveDialog.show(context, contextTag);
  }
}
