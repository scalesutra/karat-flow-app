import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/api_models.dart';
import 'bloc/artisan_bloc.dart';

class ArtisanDashboardPage extends StatefulWidget {
  const ArtisanDashboardPage({super.key});

  @override
  State<ArtisanDashboardPage> createState() => _ArtisanDashboardPageState();
}

class _ArtisanDashboardPageState extends State<ArtisanDashboardPage> {
  String _status = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ArtisanBloc>().add(const FetchArtisanTasksEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String value) {
    setState(() => _status = value);
    context.read<ArtisanBloc>().add(FetchArtisanTasksEvent(status: value));
  }

  List<ApiWorkerTask> _applySearch(List<ApiWorkerTask> tasks) {
    if (_searchQuery.trim().isEmpty) return tasks;
    final query = _searchQuery.toLowerCase().trim();
    return tasks.where((t) {
      final matchesDesign = t.designNumber.toLowerCase().contains(query);
      final matchesOrder = t.orderId.toLowerCase().contains(query);
      final matchesStage = t.stageName.toLowerCase().contains(query);
      return matchesDesign || matchesOrder || matchesStage;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtisanBloc, ArtisanState>(
      builder: (context, state) {
        final allTasks = state is ArtisanLoaded
            ? state.tasks
            : const <ApiWorkerTask>[];
        final filteredTasks = _applySearch(allTasks);
        final loading = state is ArtisanLoading || state is ArtisanInitial;

        final assignedCount = _count(allTasks, 'ASSIGNED');
        final inProgressCount = _count(allTasks, 'IN_PROGRESS');
        final completedCount = _count(allTasks, 'COMPLETED');
        final failedCount = _count(allTasks, 'FAILED');

        return RefreshIndicator(
          color: AppColors.emerald,
          onRefresh: () async => context.read<ArtisanBloc>().add(
            FetchArtisanTasksEvent(status: _status),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RoleDashboardHeader(
                      eyebrow: 'My Workshop Bench',
                      title: 'Artisan Dashboard',
                      description:
                          'Start assigned bench tasks, track live progress, and report production issues.',
                      icon: Icons.handyman_outlined,
                    ),
                    const SizedBox(height: 20),
                    ResponsiveMetricGrid(
                      metrics: [
                        DashboardMetric(
                          value: '${allTasks.length}',
                          label: 'Total Tasks',
                          icon: Icons.assignment_outlined,
                          color: AppColors.emerald,
                        ),
                        DashboardMetric(
                          value: '$assignedCount',
                          label: 'Ready to Start',
                          icon: Icons.play_circle_outline,
                          color: AppColors.info,
                        ),
                        DashboardMetric(
                          value: '$inProgressCount',
                          label: 'In Progress',
                          icon: Icons.precision_manufacturing_outlined,
                          color: AppColors.warning,
                        ),
                        DashboardMetric(
                          value: '$completedCount',
                          label: 'Completed',
                          icon: Icons.task_alt_outlined,
                          color: AppColors.success,
                        ),
                        if (failedCount > 0)
                          DashboardMetric(
                            value: '$failedCount',
                            label: 'Issues Reported',
                            icon: Icons.report_problem_outlined,
                            color: AppColors.danger,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search & Filter Controls Bar
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            controller: _searchController,
                            hintText: 'Search by design code, order ID or stage...',
                            prefixIcon: Icons.search_rounded,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CommonFilterChips<String>(
                      padding: EdgeInsets.zero,
                      options: const [
                        '',
                        'ASSIGNED',
                        'IN_PROGRESS',
                        'COMPLETED',
                        'FAILED',
                      ],
                      selected: _status,
                      onSelected: _filter,
                      labelBuilder: (value) => switch (value.toUpperCase()) {
                        'ASSIGNED' => 'Assigned ($assignedCount)',
                        'IN_PROGRESS' => 'In Progress ($inProgressCount)',
                        'COMPLETED' => 'Completed ($completedCount)',
                        'FAILED' => 'Issues ($failedCount)',
                        _ => 'All (${allTasks.length})',
                      },
                    ),
                    const SizedBox(height: 16),

                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CommonProgressIndicator.workshop(
                          label: 'Loading your assigned bench work...',
                        ),
                      )
                    else if (state is ArtisanError)
                      CommonEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Tasks unavailable',
                        description: state.message,
                        actionLabel: 'Retry',
                        onAction: () => _filter(_status),
                      )
                    else if (filteredTasks.isEmpty)
                      CommonEmptyState(
                        icon: Icons.task_alt_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'No matching tasks found'
                            : 'No tasks in this category',
                        description: _searchQuery.isNotEmpty
                            ? 'Try searching with a different design code or order number.'
                            : 'There are currently no tasks matching this status filter.',
                        actionLabel: _searchQuery.isNotEmpty ? 'Clear Search' : null,
                        onAction: _searchQuery.isNotEmpty
                            ? () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              }
                            : null,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 850 ? 2 : 1;
                          final cardWidth =
                              (constraints.maxWidth - (16 * (columns - 1))) /
                                  columns;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: filteredTasks
                                .map(
                                  (task) => SizedBox(
                                    width: cardWidth,
                                    child: _ArtisanTaskCard(
                                      task: task,
                                      onStart: () => context
                                          .read<ArtisanBloc>()
                                          .add(StartArtisanTaskEvent(task.id)),
                                      onComplete: () =>
                                          context.read<ArtisanBloc>().add(
                                            CompleteArtisanTaskEvent(task.id),
                                          ),
                                      onFailure: () =>
                                          _showFailureDialog(context, task),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static int _count(List<ApiWorkerTask> values, String status) =>
      values.where((value) => value.status.toUpperCase() == status).length;

  void _showFailureDialog(BuildContext context, ApiWorkerTask task) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ReportIssueDialog(
        task: task,
        onSubmit: (reason) {
          context.read<ArtisanBloc>().add(
            ReportArtisanFailureEvent(taskId: task.id, reason: reason),
          );
        },
      ),
    );
  }

  static String statusLabel(String status) => switch (status.toUpperCase()) {
    'ASSIGNED' => 'Assigned',
    'IN_PROGRESS' => 'In Progress',
    'COMPLETED' => 'Completed',
    'FAILED' => 'Issue Reported',
    _ => status,
  };
}

class _ReportIssueDialog extends StatefulWidget {
  const _ReportIssueDialog({
    required this.task,
    required this.onSubmit,
  });

  final ApiWorkerTask task;
  final ValueChanged<String> onSubmit;

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  late final TextEditingController _reasonController;

  static const List<String> _quickPresets = [
    'Defective Raw Material',
    'Gem/Stone Setting Failure',
    'Dimensions Off Spec',
    'Machine/Tool Breakdown',
    'Casting Porosity Defect',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    final current = _reasonController.text.trim();
    if (current.isEmpty) {
      _reasonController.text = preset;
    } else {
      _reasonController.text = '$current. $preset';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Production Issue',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Design #${widget.task.designNumber} · ${widget.task.stageName.isEmpty ? 'Bench Work' : widget.task.stageName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              const Text(
                'QUICK ISSUE REASONS:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickPresets.map((preset) {
                  return ActionChip(
                    label: Text(
                      preset,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    avatar: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    backgroundColor: AppColors.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.outline),
                    ),
                    onPressed: () => _applyPreset(preset),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              CommonTextField(
                controller: _reasonController,
                label: 'Detailed Issue Description *',
                hintText: 'Describe what went wrong on the bench (e.g. Gold cracked during bending)',
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
        ),
        CommonButton.danger(
          isFullWidth: false,
          height: 40,
          label: 'Submit Issue Report',
          icon: Icons.send_rounded,
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (reason.isEmpty) {
              CommonSnackbar.error(
                context,
                title: 'Issue Details Missing',
                message: 'Please enter the production issue reason before submitting.',
              );
              return;
            }
            widget.onSubmit(reason);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _ArtisanTaskCard extends StatelessWidget {
  const _ArtisanTaskCard({
    required this.task,
    required this.onStart,
    required this.onComplete,
    required this.onFailure,
  });

  final ApiWorkerTask task;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onFailure;

  @override
  Widget build(BuildContext context) {
    final status = task.status.toUpperCase();
    final (color, icon) = switch (status) {
      'COMPLETED' => (AppColors.success, Icons.check_circle_rounded),
      'FAILED' => (AppColors.danger, Icons.warning_amber_rounded),
      'IN_PROGRESS' => (AppColors.warning, Icons.precision_manufacturing_outlined),
      _ => (AppColors.info, Icons.play_circle_outline),
    };

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            task.designNumber,
                            style: const TextStyle(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (task.stageName.isNotEmpty) ...[
                          const SizedBox(width: 8),
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
                              task.stageName,
                              style: const TextStyle(
                                color: AppColors.emeraldDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.orderId.isEmpty ? 'Order #N/A' : 'Order #${task.orderId}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _ArtisanDashboardPageState.statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Specs Fact Badges
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _TaskFact(
                icon: Icons.layers_outlined,
                label: '${task.quantity} pieces',
              ),
              _TaskFact(
                icon: Icons.scale_outlined,
                label: '${task.grossWeight.toStringAsFixed(2)} g',
              ),
              if (task.assignedEmployeeName.isNotEmpty)
                _TaskFact(
                  icon: Icons.person_outline_rounded,
                  label: task.assignedEmployeeName,
                ),
            ],
          ),

          // Instructions Box
          if (task.instructions.trim().isNotEmpty && status != 'FAILED') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: AppColors.goldDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.instructions,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Reported Production Issue Banner Container
          if (status == 'FAILED') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PRODUCTION ISSUE REPORTED',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.instructions.isNotEmpty
                        ? task.instructions
                        : 'Bench issue reported to workshop manager.',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          if (status == 'ASSIGNED') ...[
            const SizedBox(height: 14),
            CommonButton.primary(
              height: 42,
              label: 'Start Work',
              icon: Icons.play_arrow_rounded,
              onPressed: onStart,
            ),
          ] else if (status == 'IN_PROGRESS') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CommonButton.outlined(
                    height: 42,
                    label: 'Report Issue',
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: AppColors.dangerLight,
                    textColor: AppColors.danger,
                    borderColor: AppColors.danger.withValues(alpha: 0.5),
                    onPressed: onFailure,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonButton.primary(
                    height: 42,
                    label: 'Complete Work',
                    icon: Icons.check_circle_rounded,
                    onPressed: onComplete,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskFact extends StatelessWidget {
  const _TaskFact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.goldDark),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
