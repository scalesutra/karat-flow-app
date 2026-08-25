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

  @override
  void initState() {
    super.initState();
    context.read<ArtisanBloc>().add(const FetchArtisanTasksEvent());
  }

  void _filter(String value) {
    setState(() => _status = value);
    context.read<ArtisanBloc>().add(FetchArtisanTasksEvent(status: value));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtisanBloc, ArtisanState>(
      builder: (context, state) {
        final tasks = state is ArtisanLoaded
            ? state.tasks
            : const <ApiWorkerTask>[];
        final loading = state is ArtisanLoading || state is ArtisanInitial;
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
                          'Start assigned work, complete finished tasks and report production issues.',
                      icon: Icons.handyman_outlined,
                    ),
                    const SizedBox(height: 20),
                    ResponsiveMetricGrid(
                      metrics: [
                        DashboardMetric(
                          value: '${tasks.length}',
                          label: 'Visible tasks',
                          icon: Icons.assignment_outlined,
                          color: AppColors.emerald,
                        ),
                        DashboardMetric(
                          value: '${_count(tasks, 'ASSIGNED')}',
                          label: 'Ready to start',
                          icon: Icons.play_circle_outline,
                          color: AppColors.info,
                        ),
                        DashboardMetric(
                          value: '${_count(tasks, 'IN_PROGRESS')}',
                          label: 'In progress',
                          icon: Icons.precision_manufacturing_outlined,
                          color: AppColors.warning,
                        ),
                        DashboardMetric(
                          value: '${_count(tasks, 'COMPLETED')}',
                          label: 'Completed',
                          icon: Icons.task_alt_outlined,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                      labelBuilder: (value) =>
                          value.isEmpty ? 'All' : _label(value),
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
                    else if (tasks.isEmpty)
                      const CommonEmptyState(
                        icon: Icons.task_alt_outlined,
                        title: 'No assigned tasks',
                        description:
                            'The live worker-task API returned no work for this filter.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 850 ? 2 : 1;
                          final cardWidth =
                              (constraints.maxWidth - (12 * (columns - 1))) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: tasks
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
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text('Report Task Issue'),
        content: CommonTextField(
          controller: controller,
          label: 'Issue reason *',
          hintText: 'Describe the production issue clearly',
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                CommonSnackbar.error(
                  context,
                  title: 'Reason required',
                  message: 'Enter the task issue before submitting.',
                );
                return;
              }
              context.read<ArtisanBloc>().add(
                ReportArtisanFailureEvent(taskId: task.id, reason: reason),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Submit Issue'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  static String _label(String status) => switch (status.toUpperCase()) {
    'ASSIGNED' => 'Assigned',
    'IN_PROGRESS' => 'In Progress',
    'COMPLETED' => 'Completed',
    'FAILED' => 'Issue Reported',
    _ => status,
  };
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
    final color = switch (status) {
      'COMPLETED' => AppColors.success,
      'FAILED' => AppColors.danger,
      'IN_PROGRESS' => AppColors.warning,
      _ => AppColors.info,
    };
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.diamond_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.designNumber,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      task.orderId.isEmpty
                          ? 'Order number unavailable'
                          : task.orderId,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _ArtisanDashboardPageState._label(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
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
              if (task.stageName.isNotEmpty)
                _TaskFact(
                  icon: Icons.account_tree_outlined,
                  label: task.stageName,
                ),
            ],
          ),
          if (task.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.instructions,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
                  child: CommonButton.danger(
                    height: 42,
                    label: 'Report Issue',
                    onPressed: onFailure,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonButton.primary(
                    height: 42,
                    label: 'Complete',
                    icon: Icons.check_rounded,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.goldDark),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
