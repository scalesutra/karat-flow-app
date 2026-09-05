import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';

class CadDesignLibraryPage extends StatefulWidget {
  const CadDesignLibraryPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<CadDesignLibraryPage> createState() => _CadDesignLibraryPageState();
}

class _CadDesignLibraryPageState extends State<CadDesignLibraryPage> {
  String _activeFilter = 'All';

  static const _filters = ['All', 'Completed', 'With STL', 'Pending'];

  List<CadDesignTask> get _filteredTasks {
    final tasks = widget.store.cadTasks;
    return switch (_activeFilter) {
      'Completed' =>
        tasks.where((t) => t.status == CadTaskStatus.completed).toList(),
      'With STL' => tasks.where((t) => t.hasStlFile).toList(),
      'Pending' =>
        tasks
            .where(
              (t) =>
                  t.status == CadTaskStatus.newTask ||
                  t.status == CadTaskStatus.inProgress,
            )
            .toList(),
      _ => tasks.toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final filtered = _filteredTasks;

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText.headlineLarge(
                      AppStrings.cadDesignLibrary.trClean,
                    ),
                    const SizedBox(height: 2),
                    CommonText.bodySmall(
                      '${widget.store.cadTasks.length} designs across ${widget.store.cadTasks.map((t) => t.orderId).toSet().length} orders',
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 12),

                    // ── Filter chips ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((f) {
                          final isActive = _activeFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _activeFilter = f),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.emeraldLight
                                      : AppColors.paper,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull,
                                  ),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.emerald
                                        : AppColors.outline,
                                  ),
                                ),
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppColors.emeraldDark
                                        : AppColors.ink,
                                    fontWeight: isActive
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Design cards ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: CommonText.bodySmall(
                          'No designs found.',
                          color: AppColors.muted,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          return _DesignLibraryCard(
                            task: task,
                            store: widget.store,
                            onChanged: () => setState(() {}),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesignLibraryCard extends StatelessWidget {
  const _DesignLibraryCard({
    required this.task,
    required this.store,
    required this.onChanged,
  });

  final CadDesignTask task;
  final DemoStore store;
  final VoidCallback onChanged;

  IconData get _categoryIcon {
    if (task.designCode.startsWith('NK')) return Icons.auto_awesome_outlined;
    if (task.designCode.startsWith('ER')) return Icons.grain_outlined;
    if (task.designCode.startsWith('RG')) return Icons.diamond_outlined;
    if (task.designCode.startsWith('BG')) return Icons.circle_outlined;
    if (task.designCode.startsWith('CH')) return Icons.link_outlined;
    return Icons.category_outlined;
  }

  Color get _statusColor => switch (task.status) {
    CadTaskStatus.newTask => AppColors.gold,
    CadTaskStatus.inProgress => const Color(0xFF1565C0),
    CadTaskStatus.completed => AppColors.success,
    CadTaskStatus.revision => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: task.hasStlFile
                  ? AppColors.emeraldLight
                  : AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: task.hasStlFile
                    ? AppColors.emerald.withValues(alpha: 0.3)
                    : AppColors.outline,
              ),
            ),
            child: Icon(
              task.hasStlFile ? Icons.view_in_ar : _categoryIcon,
              color: task.hasStlFile ? AppColors.emerald : AppColors.muted,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // ── Details ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.productTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      child: Text(
                        task.status.label,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  task.specs.trim().isNotEmpty
                      ? '${task.designCode} · ${task.specs}'
                      : task.designCode,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.estimatedWeightGrams > 0 || task.hasStlFile) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.estimatedWeightGrams > 0) ...[
                        Text(
                          '${task.estimatedWeightGrams} g',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (task.hasStlFile)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'STL ready',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                store.markCadTaskStlUploaded(task.id);
                                onChanged();
                                CommonSnackbar.success(
                                  context,
                                  title: 'STL Uploaded',
                                  message:
                                      '${task.designCode.toLowerCase()}_v1.stl attached.',
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      size: 11,
                                      color: AppColors.muted,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Upload STL',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
