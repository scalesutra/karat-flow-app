import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_empty_state_widget.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_card.dart';
import '../../../core/widgets/common_snackbar.dart';
import '../../../core/widgets/common_text.dart';
import '../../../data/demo_store.dart';
import '../../../data/models/api_models.dart';
import '../bloc/admin_bloc.dart';
import 'add_stage_sheet.dart';

class AdminProductionStagesSheet extends StatefulWidget {
  const AdminProductionStagesSheet({super.key, required this.store});

  final DemoStore store;

  static Future<void> show(BuildContext context, {required DemoStore store}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AdminProductionStagesSheet(store: store),
    );
  }

  @override
  State<AdminProductionStagesSheet> createState() =>
      _AdminProductionStagesSheetState();
}

class _AdminProductionStagesSheetState
    extends State<AdminProductionStagesSheet> {
  DemoStore get store => widget.store;

  void _openAddStage(BuildContext context) {
    AddStageSheet.show(
      context,
      store: store,
      defaultSequence: store.stages.length + 1,
    );
  }

  Future<bool> _confirmDeleteStage(BuildContext context, ApiStage stage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Stage',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: 'Are you sure you want to delete stage ',
                children: [
                  TextSpan(
                    text: '"${stage.name}" (Step ${stage.stageNumber})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?\n\n'),
                  const TextSpan(
                    text:
                        'Remaining stages will automatically re-sequence in order (1, 2, 3...). '
                        'If this stage is currently used by active traveler orders or artisan tasks, deletion will be blocked by the server for safety.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Delete Stage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _dispatchDelete(ApiStage stage) {
    context.read<AdminBloc>().add(DeleteStageEvent(stage.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          CommonSnackbar.success(context, message: state.message);
        } else if (state is AdminError) {
          CommonSnackbar.error(
            context,
            title: 'Stage Action Failed',
            message: state.message,
          );
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final stages = store.stages.toList()
              ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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

                  // Header with Close & Add action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonText.headlineSmall(
                              'Standard Production Routing',
                            ),
                            const SizedBox(height: 2),
                            CommonText.bodySmall(
                              '${stages.length} live stages · Swipe to delete or add new',
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Swipe instruction banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swipe_left_rounded,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Swipe any stage left to delete, or tap the trash icon.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _openAddStage(context),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: AppColors.ink,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Add Stage',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stages List
                  Expanded(
                    child: stages.isEmpty
                        ? const AnimatedEmptyStateWidget(
                            icon: Icons.alt_route_rounded,
                            title: 'No Production Stages',
                            subtitle:
                                'No manufacturing stages configured yet. Tap "+ Add New Stage" below to create the first stage.',
                            accentColor: AppColors.gold,
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: stages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (itemCtx, i) {
                              final s = stages[i];
                              return Dismissible(
                                key: ValueKey('stage_${s.id}_${s.stageNumber}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete_forever_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Stage',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (direction) =>
                                    _confirmDeleteStage(context, s),
                                onDismissed: (direction) => _dispatchDelete(s),
                                child: CommonCard(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Step avatar
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundColor: AppColors.ink,
                                        child: Text(
                                          '${s.stageNumber}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Stage details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    s.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 13,
                                                      color: AppColors.ink,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (s.isActive
                                                            ? AppColors.emerald
                                                            : AppColors.muted)
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    s.isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: s.isActive
                                                          ? AppColors.emerald
                                                          : AppColors.muted,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (s.description != null &&
                                                s.description!.trim().isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                s.description!.trim(),
                                                style: const TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 11,
                                                  height: 1.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Direct Delete Button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: AppColors.muted,
                                        ),
                                        tooltip: 'Delete Stage',
                                        onPressed: () async {
                                          final ok = await _confirmDeleteStage(
                                            context,
                                            s,
                                          );
                                          if (ok) {
                                            _dispatchDelete(s);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Action Button
                  SizedBox(
                    width: double.infinity,
                    child: CommonButton.primary(
                      icon: Icons.add_rounded,
                      label: 'Add Production Stage',
                      onPressed: () => _openAddStage(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
