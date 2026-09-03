import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/services/live_data_bloc_coordinator.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/models/api_models.dart';
import '../workshop_artisan/bloc/artisan_bloc.dart';

class WorkerDashboardPage extends StatefulWidget {
  const WorkerDashboardPage({super.key, this.store});

  final DemoStore? store;

  @override
  State<WorkerDashboardPage> createState() => _WorkerDashboardPageState();
}

class _WorkerDashboardPageState extends State<WorkerDashboardPage> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ArtisanBloc>().add(const FetchArtisanTasksEvent());
    DemoStore.instance.addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DemoStore.instance.removeListener(_onStoreChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<ApiWorkerTask> _filterTasks(List<ApiWorkerTask> tasks) {
    var result = tasks;
    if (_selectedFilter != 'ALL') {
      result = result.where((t) {
        if (_selectedFilter == 'ASSIGNED') return t.status == 'ASSIGNED';
        if (_selectedFilter == 'IN_PROGRESS') return t.status == 'IN_PROGRESS';
        if (_selectedFilter == 'COMPLETED') return t.status == 'COMPLETED';
        return true;
      }).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((t) {
        return t.designNumber.toLowerCase().contains(q) ||
            t.orderId.toLowerCase().contains(q) ||
            t.stageName.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ArtisanBloc, ArtisanState>(
      listener: (context, state) {
        if (state is ArtisanError) {
          final msg = state.message
              .replaceAll('Exception: ', '')
              .replaceAll('Failed to start task: ', '');
          if (msg.contains('Stockist') || msg.contains('issued')) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Stockist Issue Required',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  msg,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            CommonSnackbar.error(context, message: msg);
          }
        } else if (state is ArtisanActionSuccess) {
          CommonSnackbar.success(context, message: state.message);
          try {
            LiveDataBlocCoordinator.refreshForRole(
              context,
              AppRole.processManager,
            );
          } catch (_) {}
        }
      },
      builder: (context, state) {
        final allTasks = state is ArtisanLoaded
            ? state.tasks
            : const <ApiWorkerTask>[];
        final filtered = _filterTasks(allTasks);

        final inProgressCount = allTasks
            .where((t) => t.status == 'IN_PROGRESS')
            .length;
        final assignedCount = allTasks
            .where((t) => t.status == 'ASSIGNED')
            .length;
        final completedCount = allTasks
            .where((t) => t.status == 'COMPLETED')
            .length;

        return CommonRefreshIndicator(
          theme: IndicatorTheme.workshop,
          onRefresh: () async => context.read<ArtisanBloc>().add(
            FetchArtisanTasksEvent(status: _selectedFilter),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              // ── HERO BENCH STATUS BAR ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.precision_manufacturing_rounded,
                              color: AppColors.gold,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Goldsmith Bench Workspace',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
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
                            color: AppColors.emerald.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.emerald.withOpacity(0.4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: AppColors.emerald,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'ACTIVE BENCH',
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _benchStat(
                            'Active Jobs',
                            '$inProgressCount',
                            Icons.play_circle_fill,
                            AppColors.warning,
                          ),
                        ),
                        Expanded(
                          child: _benchStat(
                            'Queued',
                            '$assignedCount',
                            Icons.hourglass_empty_rounded,
                            AppColors.info,
                          ),
                        ),
                        Expanded(
                          child: _benchStat(
                            'Done Today',
                            '$completedCount',
                            Icons.check_circle_rounded,
                            AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── SEARCH & QUICK FILTER BAR ──────────────────────────────────
              CommonSearchBar(
                controller: _searchController,
                hintText: 'Search bench task by design code, order #...',
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () => setState(() => _searchQuery = ''),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All (${allTasks.length})',
                      isSelected: _selectedFilter == 'ALL',
                      onTap: () => setState(() => _selectedFilter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Assigned ($assignedCount)',
                      isSelected: _selectedFilter == 'ASSIGNED',
                      onTap: () => setState(() => _selectedFilter = 'ASSIGNED'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'In Progress ($inProgressCount)',
                      isSelected: _selectedFilter == 'IN_PROGRESS',
                      onTap: () =>
                          setState(() => _selectedFilter = 'IN_PROGRESS'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Completed ($completedCount)',
                      isSelected: _selectedFilter == 'COMPLETED',
                      onTap: () =>
                          setState(() => _selectedFilter = 'COMPLETED'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── TASK CARDS OR ANIMATED EMPTY STATE ────────────────────────
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 40),
                  child: AnimatedEmptyStateWidget(
                    icon: Icons.handyman_outlined,
                    title: 'No Bench Tasks Pending',
                    subtitle:
                        'All assigned goldsmith & artisan tasks are complete and cleared.',
                    accentColor: AppColors.emerald,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final task = filtered[i];
                    return _WorkerTaskCard(task: task);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _benchStat(String title, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

void _showReportFailureDialog(BuildContext context, String taskId) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.report_problem_outlined, color: AppColors.danger),
          SizedBox(width: 8),
          Text(
            'Report Rework / Defect',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Describe the reason for failure or rework required:',
            style: TextStyle(fontSize: 12, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Broken prong, casting porosity...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(ctx);
            context.read<ArtisanBloc>().add(
              ReportArtisanFailureEvent(taskId: taskId, reason: reason),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Report Defect'),
        ),
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.outlineLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _WorkerTaskCard extends StatelessWidget {
  const _WorkerTaskCard({required this.task});

  final ApiWorkerTask task;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      'IN_PROGRESS' => AppColors.warning,
      'COMPLETED' => AppColors.emerald,
      'FAILED' => AppColors.danger,
      _ => AppColors.info,
    };

    final statusBg = switch (task.status) {
      'IN_PROGRESS' => AppColors.warningLight,
      'COMPLETED' => AppColors.emeraldLight,
      'FAILED' => AppColors.dangerLight,
      _ => AppColors.infoLight,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DESIGN-${task.designNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        !task.effectiveIsStockIssued &&
                            task.status == 'ASSIGNED'
                        ? AppColors.warningLight
                        : statusBg,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        !task.effectiveIsStockIssued &&
                            task.status == 'ASSIGNED'
                        ? Border.all(color: AppColors.warning.withOpacity(0.4))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!task.effectiveIsStockIssued &&
                          task.status == 'ASSIGNED') ...[
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 11,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        !task.effectiveIsStockIssued &&
                                task.status == 'ASSIGNED'
                            ? 'WAITING FOR STOCKIST'
                            : task.status.replaceAll('_', ' '),
                        style: TextStyle(
                          color:
                              !task.effectiveIsStockIssued &&
                                  task.status == 'ASSIGNED'
                              ? AppColors.warning
                              : statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Stage: ${task.stageName}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Order: ${task.orderId.isNotEmpty ? task.orderId : "N/A"} · Qty: ${task.quantity} pcs (${task.grossWeight.toStringAsFixed(1)}g)',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            if (task.instructions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 13,
                          color: AppColors.ink,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Manager Instructions:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.instructions,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: task.effectiveIsStockIssued
                    ? AppColors.emerald.withOpacity(0.06)
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.effectiveIsStockIssued
                      ? AppColors.emerald.withOpacity(0.2)
                      : AppColors.warning.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    task.effectiveIsStockIssued
                        ? Icons.verified_outlined
                        : Icons.warning_amber_rounded,
                    size: 14,
                    color: task.effectiveIsStockIssued
                        ? AppColors.emeraldDark
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task.effectiveIsStockIssued
                          ? (task.orderPart.gemQuantity > 0
                                ? 'Allocated Specs: ${task.orderPart.gemQuantity} Gems · ${task.orderPart.goldQuantity.toStringAsFixed(1)}g Gold (Issued by Vault Stockist)'
                                : 'Allocated Specs: Raw Casting Metal & Setting Package (Issued by Vault Stockist)')
                          : 'Materials NOT YET Issued by Vault Stockist (Stock Allocation Pending)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: task.effectiveIsStockIssued
                            ? AppColors.emeraldDark
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (task.status == 'FAILED' || task.status == 'HOLD') ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.report_problem_outlined,
                              color: AppColors.danger,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'FAILURE REPORT & REASON',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        if (task.assignedEmployeeName.isNotEmpty)
                          Text(
                            'BY: ${task.assignedEmployeeName.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.failureReason != null &&
                              task.failureReason!.trim().isNotEmpty
                          ? task.failureReason!.trim()
                          : 'Block/Failure reason recorded.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.work_history_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Assignment #${task.id.length > 6 ? task.id.substring(0, 6) : task.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Builder(
                    builder: (context) {
                      final isStockIssued =
                          DemoStore.instance.isStockIssuedForTask(task);
                      if (task.status == 'ASSIGNED') {
                        return ElevatedButton.icon(
                          onPressed: () {
                            if (!isStockIssued) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(
                                        Icons.lock_clock_outlined,
                                        color: AppColors.warning,
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Stockist Issue Required',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    'Vault Stockist has NOT yet issued raw materials (casting gold/diamonds) for this order part. Please collect issued stock from Vault Custodian first before starting bench work.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.ink,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            context.read<ArtisanBloc>().add(
                              StartArtisanTaskEvent(task.id),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStockIssued
                                ? AppColors.emerald
                                : AppColors.muted,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(
                            isStockIssued
                                ? Icons.play_arrow_rounded
                                : Icons.lock_outline_rounded,
                            size: 14,
                          ),
                          label: Text(
                            isStockIssued ? 'Start Task' : 'Stock Pending',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else if (task.status == 'IN_PROGRESS') {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  _showReportFailureDialog(context, task.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Report Defect',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<ArtisanBloc>().add(
                                  CompleteArtisanTaskEvent(task.id),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(Icons.check, size: 13),
                              label: const Text(
                                'Mark Complete',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      if (task.status == 'FAILED' ||
                          task.status == 'HOLD' ||
                          task.status == 'BLOCKED') {
                        return ElevatedButton.icon(
                          onPressed: () {
                            context.read<ArtisanBloc>().add(
                              StartArtisanTaskEvent(task.id),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 14),
                          label: const Text(
                            'Resume / Unhold Task',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
