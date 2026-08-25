import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import 'widgets/cad_metric_chip.dart';
import 'widgets/cad_task_card.dart';
import 'bloc/cad_bloc.dart';

class CadDashboardPage extends StatefulWidget {
  const CadDashboardPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<CadDashboardPage> createState() => _CadDashboardPageState();
}

class _CadDashboardPageState extends State<CadDashboardPage> {
  CadTaskStatus? _activeFilter;

  List<CadDesignTask> get _filteredTasks {
    if (_activeFilter == null) return widget.store.cadTasks;
    return widget.store.cadTasksByStatus(_activeFilter!);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final allCount = widget.store.cadTasks.length;
        final newCount = widget.store.cadNewCount;
        final inProgressCount = widget.store.cadInProgressCount;
        final completedCount = widget.store.cadCompletedCount;

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText.headlineLarge(AppStrings.cadDashboard.trClean),
                    const SizedBox(height: 8),

                    // Metric cards
                    Row(
                      children: [
                        CadMetricChip(
                          count: allCount,
                          label: AppStrings.viewAll.trClean,
                          isActive: _activeFilter == null,
                          activeColor: AppColors.emerald,
                          activeBg: AppColors.emeraldLight,
                          onTap: () => setState(() => _activeFilter = null),
                        ),
                        const SizedBox(width: 8),
                        CadMetricChip(
                          count: newCount,
                          label: 'New',
                          isActive: _activeFilter == CadTaskStatus.newTask,
                          activeColor: AppColors.goldDark,
                          activeBg: AppColors.goldLight,
                          onTap: () => setState(
                            () => _activeFilter = CadTaskStatus.newTask,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CadMetricChip(
                          count: inProgressCount,
                          label: 'WIP',
                          isActive: _activeFilter == CadTaskStatus.inProgress,
                          activeColor: AppColors.info,
                          activeBg: AppColors.infoLight,
                          onTap: () => setState(
                            () => _activeFilter = CadTaskStatus.inProgress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CadMetricChip(
                          count: completedCount,
                          label: 'Done',
                          isActive: _activeFilter == CadTaskStatus.completed,
                          activeColor: AppColors.success,
                          activeBg: AppColors.successLight,
                          onTap: () => setState(
                            () => _activeFilter = CadTaskStatus.completed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Task list
              Expanded(
                child: _filteredTasks.isEmpty
                    ? Center(
                        child: CommonText.bodySmall(
                          'No tasks in this category.',
                          color: AppColors.muted,
                        ),
                      )
                    : CommonRefreshIndicator(
                        theme: IndicatorTheme.cad,
                        onRefresh: () async => context.read<CadBloc>().add(
                          const FetchCadTasksEvent(),
                        ),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                          itemCount: _filteredTasks.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return CadTaskCard(
                              task: task,
                              store: widget.store,
                              onStatusChanged: () => setState(() {}),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
