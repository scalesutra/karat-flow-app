import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/features/status/status_detail_page.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../instructions/instruction_composer.dart';
import '../workshop/bloc/workshop_bloc.dart';
import 'widgets/cad_approval_task_card.dart';
import 'widgets/instruction_task_card.dart';
import '../admin/bloc/admin_bloc.dart';
import '../directives/bloc/directives_bloc.dart';

class AdminTasksPage extends StatefulWidget {
  const AdminTasksPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<AdminTasksPage> createState() => _AdminTasksPageState();
}

class _AdminTasksPageState extends State<AdminTasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return CommonRefreshIndicator(
      onRefresh: () async {
        context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: AnimatedBuilder(
        animation: store,
        builder: (context, _) => _InstructionList(
          title: '${AppStrings.navTasks.trClean} & Approvals',
          subtitle: 'Track workshop instructions and make governed decisions.',
          instructions: store.instructions,
          mode: TaskDisplayMode.admin,
          store: store,
        ),
      ),
    );
  }
}

class ProcessManagerTasksPage extends StatelessWidget {
  const ProcessManagerTasksPage({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkshopBloc, WorkshopState>(
      builder: (context, state) {
        if (state is WorkshopLoading) {
          return const Center(
            child: CommonProgressIndicator.workshop(
              label: 'Syncing Process Manager Directives...',
            ),
          );
        }
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) => _InstructionList(
            title: 'My Tasks & Directives',
            subtitle:
                'Admin instructions stay visible until acknowledged and resolved.',
            instructions: store.instructions,
            mode: TaskDisplayMode.manager,
            store: store,
          ),
        );
      },
    );
  }
}

class ProcessManagerHome extends StatelessWidget {
  const ProcessManagerHome({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkshopBloc, WorkshopState>(
      builder: (context, state) {
        if (state is WorkshopLoading) {
          return const Center(
            child: CommonProgressIndicator.workshop(
              label: 'Syncing Workshop Overview & Tasks...',
            ),
          );
        }
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final active = store.instructions
                .where((item) => item.status != InstructionStatus.resolved)
                .toList();

            final workingArtisans = store.team
                .where((m) => m.status == EmployeeStatus.working)
                .length;
            final blockedArtisans = store.team
                .where((m) => m.status == EmployeeStatus.blocked)
                .length;
            final qcCount = store.lots
                .where((lot) => lot.stage == WorkshopStage.qualityCheck)
                .length;
            final blockedLots = store.lots
                .where((lot) => lot.blockerReason?.isNotEmpty ?? false)
                .toList();

            return SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                children: [
                  // 1. GREETING & SHIFT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CommonText.headlineLarge('Workshop Tasks'),
                            const SizedBox(height: 1),
                            Text(
                              '${store.team.length} API workers · ${store.lots.length} active tasks',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldLight,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Floor Live',
                              style: TextStyle(
                                color: AppColors.emeraldDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. SCAN POUCH BARCODE BUTTON
                  CommonButton.primary(
                    height: 44,
                    onPressed: () => _openScanDialog(context),
                    icon: Icons.qr_code_scanner,
                    label: 'Scan Lot Barcode / Pouch QR',
                  ),

                  const SizedBox(height: 14),

                  // 3. 4-METRIC COMMAND GRID
                  Row(
                    children: [
                      Expanded(
                        child: CommonMetricTile(
                          value: '${active.length}',
                          label: 'Directives',
                          sublabel: 'Action needed',
                          color: active.isNotEmpty
                              ? AppColors.goldDark
                              : AppColors.emerald,
                          icon: Icons.assignment_late_outlined,
                          onTap: () {
                            CommonSnackbar.info(
                              context,
                              title: 'Directives Filtered',
                              message:
                                  'Showing ${active.length} pending directives below.',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CommonMetricTile(
                          value: '$qcCount',
                          label: 'Awaiting QC',
                          sublabel: 'Stage 6 check',
                          color: AppColors.emerald,
                          icon: Icons.fact_check_outlined,
                          onTap: () => _showQcLotsModal(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CommonMetricTile(
                          value: '$workingArtisans',
                          label: 'On Bench',
                          sublabel: 'Active crafts',
                          color: AppColors.emeraldDark,
                          icon: Icons.precision_manufacturing,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CommonMetricTile(
                          value: '$blockedArtisans',
                          label: 'Holds',
                          sublabel: 'Material hold',
                          color: blockedArtisans > 0
                              ? AppColors.danger
                              : AppColors.muted,
                          icon: Icons.warning_amber_rounded,
                          onTap: () => _showHoldsModal(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 4. FLOOR STAGE PULSE STRIP
                  const CommonText.titleMedium(
                    'Workshop Stage Pulse (Live WIP Lots)',
                  ),
                  const SizedBox(height: 8),
                  _buildStagePulseStrip(context),

                  const SizedBox(height: 18),

                  // 5. DIRECTIVES REQUIRING ACTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CommonText.titleMedium(
                        'Needs Action Now (Directives)',
                      ),
                      if (active.length > 2)
                        Text(
                          '${active.length} Total',
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    const CommonCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No pending Admin directives. All instructions cleared.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    for (final instruction in active.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InstructionTaskCard(
                          instruction: instruction,
                          mode: TaskDisplayMode.manager,
                          store: store,
                        ),
                      ),

                  const SizedBox(height: 14),

                  // 6. WORKSHOP EXCEPTIONS & HOLDS
                  const CommonText.titleMedium(
                    'Active Workshop Blockers & Holds',
                  ),
                  const SizedBox(height: 8),
                  if (blockedLots.isEmpty)
                    const CommonCard(
                      child: Text(
                        'No blocked worker tasks returned by the API.',
                      ),
                    )
                  else
                    CommonCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () {
                        final item = store
                            .workItemsFor(StatusPivot.orders)
                            .firstOrNull;
                        if (item != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  StatusDetailPage(item: item, store: store),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFE7DF),
                            radius: 18,
                            child: Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${blockedLots.first.stage.label} · ${blockedLots.first.orderId}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'CRITICAL HOLD',
                                      style: TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${blockedLots.first.pieces} pieces · ${blockedLots.first.blockerReason}',
                                  style: const TextStyle(
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

                  const SizedBox(height: 18),

                  // 7. ARTISAN BENCH PULSE
                  const CommonText.titleMedium('Active Artisan Bench Workload'),
                  const SizedBox(height: 8),
                  _buildArtisanBenchPulse(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStagePulseStrip(BuildContext context) {
    final stages = store.stages.map((stage) {
      final stageIndex = (stage.stageNumber - 1)
          .clamp(0, WorkshopStage.values.length - 1)
          .toInt();
      final count = store.lots
          .where((lot) => lot.stage == WorkshopStage.values[stageIndex])
          .length;
      return {
        'name': stage.name,
        'count': '$count',
        'color': count > 0 ? AppColors.emerald : AppColors.muted,
      };
    }).toList();

    return CommonCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pipeline Flow: ${store.lots.length} Active Batches',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${stages.length} Live Stages',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < stages.length; i++) ...[
                Expanded(
                  child: InkWell(
                    onTap: () {
                      CommonSnackbar.info(
                        context,
                        title: 'Stage Filtered',
                        message:
                            'Showing ${stages[i]['count']} lots in ${stages[i]['name']} stage.',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (stages[i]['color'] as Color).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (stages[i]['color'] as Color).withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            stages[i]['count'] as String,
                            style: TextStyle(
                              color: stages[i]['color'] as Color,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stages[i]['name'] as String,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < stages.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: AppColors.outline,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanBenchPulse(BuildContext context) {
    final activeArtisans = store.team.take(3).toList();

    return Column(
      children: [
        for (final a in activeArtisans)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CommonCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.emeraldLight,
                    child: Text(
                      a.name.substring(0, 1),
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${a.craft} · ${a.currentAssignment}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${a.todayEfficiencyPercent}% Eff.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${a.activeLotsCount} lots',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openScanDialog(BuildContext context) {
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
              'Scan Job Barcode / Pouch QR',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'Position the camera over the physical lot pouch barcode',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 54,
                      color: Colors.white60,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Camera Active · Scanning...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CommonButton.primary(
              height: 38,
              label: 'Close Scanner',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showQcLotsModal(BuildContext context) {
    final qcBatches = store.lots
        .where((lot) => lot.stage == WorkshopStage.qualityCheck)
        .toList();

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
              'Stage 6: Batches Awaiting QC',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text(
              'Completed workshop pieces ready for final certification',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            for (final q in qcBatches)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CommonCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${q.orderId} · ${q.productTitle}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${q.pieces} pcs · ${q.issueWeightGrams}g · ${q.assignedEmployee}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CommonButton.primary(
                        isFullWidth: false,
                        height: 32,
                        label: 'Approve QC',
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<WorkshopBloc>().add(
                            AdvanceLotStageEvent(q.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHoldsModal(BuildContext context) {
    final blockedLots = store.lots
        .where((lot) => lot.blockerReason?.isNotEmpty ?? false)
        .toList();
    final lot = blockedLots.firstOrNull;
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
              'Active Workshop Material Holds',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Batches currently paused due to material or QC hold',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 14),
            CommonCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot == null
                        ? 'No active holds'
                        : '${lot.orderId} · ${lot.stage.label}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lot == null
                        ? 'No blocked worker tasks returned by the API.'
                        : '${lot.pieces} pieces · ${lot.assignedEmployee}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7DF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lot == null
                          ? 'No hold reason.'
                          : 'Reason: ${lot.blockerReason}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CommonButton.primary(
                    label: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionList extends StatefulWidget {
  const _InstructionList({
    required this.title,
    required this.subtitle,
    required this.instructions,
    required this.mode,
    required this.store,
  });

  final String title;
  final String subtitle;
  final List<Instruction> instructions;
  final TaskDisplayMode mode;
  final DemoStore store;

  @override
  State<_InstructionList> createState() => _InstructionListState();
}

class _InstructionListState extends State<_InstructionList> {
  int _adminActiveTab = 0; // 0: Directives, 1: CAD & 3D Approvals
  String _selectedFilter = 'Actionable';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = const [
    'Actionable',
    'All',
    'Urgent',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.mode == TaskDisplayMode.admin) {
      _selectedFilter = 'All';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (builderContext, _) {
        final filtered = widget.instructions.where((ins) {
          if (_selectedFilter == 'Actionable') {
            if (ins.status == InstructionStatus.resolved) return false;
          } else if (_selectedFilter == 'Urgent') {
            if (ins.urgency != InstructionUrgency.urgent) return false;
          } else if (_selectedFilter == 'Resolved') {
            if (ins.status != InstructionStatus.resolved) return false;
          }

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return ins.id.toLowerCase().contains(q) ||
                ins.targetLabel.toLowerCase().contains(q) ||
                ins.message.toLowerCase().contains(q) ||
                ins.assignedTo.toLowerCase().contains(q) ||
                ins.createdBy.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        final cadFiltered = widget.store.cadTasks.where((task) {
          if (!task.hasStlFile) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return task.designCode.toLowerCase().contains(q) ||
                task.productTitle.toLowerCase().contains(q) ||
                task.clientName.toLowerCase().contains(q) ||
                task.specs.toLowerCase().contains(q);
          }
          return true;
        }).toList();

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText.headlineLarge(widget.title),
                              const SizedBox(height: 1),
                              CommonText.bodySmall(
                                widget.subtitle,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                        if (widget.mode == TaskDisplayMode.admin) ...[
                          const SizedBox(width: 12),
                          CommonButton.primary(
                            isFullWidth: false,
                            height: 36,
                            icon: Icons.add_comment_outlined,
                            label: 'New Directive',
                            onPressed: () =>
                                _openNewInstructionForAdmin(context),
                          ),
                        ],
                      ],
                    ),
                    if (widget.mode == TaskDisplayMode.admin) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _adminActiveTab = 0),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSmall,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _adminActiveTab == 0
                                        ? AppColors.paper
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSmall,
                                    ),
                                    boxShadow: _adminActiveTab == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Directives & Tasks (${widget.instructions.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _adminActiveTab == 0
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _adminActiveTab == 0
                                            ? AppColors.emeraldDark
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _adminActiveTab = 1),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSmall,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _adminActiveTab == 1
                                        ? AppColors.paper
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSmall,
                                    ),
                                    boxShadow: _adminActiveTab == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'CAD 3D Approvals (${cadFiltered.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _adminActiveTab == 1
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: _adminActiveTab == 1
                                            ? AppColors.emeraldDark
                                            : AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    CommonSearchBar(
                      controller: _searchController,
                      hintText: _adminActiveTab == 0
                          ? 'Search directives or notes...'
                          : 'Search CAD tasks (e.g. SOL-401, client)...',
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                  ],
                ),
              ),
              if (_adminActiveTab == 0) ...[
                CommonFilterChips<String>(
                  options: _filters,
                  selected: _selectedFilter,
                  onSelected: (val) => setState(() => _selectedFilter = val),
                  labelBuilder: (val) => val,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filtered.isEmpty
                      ? CommonEmptyState(
                          icon: Icons.task_alt,
                          title: 'No tasks found',
                          description:
                              'No instructions match the selected filters.',
                          actionLabel: 'Show All Tasks',
                          onAction: () {
                            setState(() {
                              _selectedFilter = 'All';
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : CommonRefreshIndicator(
                          onRefresh: () async {
                            context.read<DirectivesBloc>().add(
                              const FetchDirectivesEvent(),
                            );
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                InstructionTaskCard(
                                  instruction: filtered[index],
                                  mode: widget.mode,
                                  store: widget.store,
                                ),
                          ),
                        ),
                ),
              ] else ...[
                Expanded(
                  child: cadFiltered.isEmpty
                      ? const CommonEmptyState(
                          icon: Icons.view_in_ar,
                          title: 'No CAD models pending',
                          description:
                              'All 3D CAD models and sketches have been signed off.',
                        )
                      : CommonRefreshIndicator(
                          theme: IndicatorTheme.cad,
                          onRefresh: () async {
                            await Future<void>.delayed(
                              const Duration(milliseconds: 600),
                            );
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                            itemCount: cadFiltered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                CadApprovalTaskCard(
                                  task: cadFiltered[index],
                                  store: widget.store,
                                ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openNewInstructionForAdmin(BuildContext context) {
    final workItems = widget.store.workItemsFor(StatusPivot.orders);
    showInstructionComposer(
      context,
      store: widget.store,
      target: workItems.isNotEmpty ? workItems.first : null,
    );
  }
}
