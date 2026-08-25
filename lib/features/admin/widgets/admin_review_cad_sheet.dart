import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_3d_viewer.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_progress_indicator.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';
import '../../cad_designer/bloc/cad_bloc.dart';

/// Modal bottom sheet for Admin Review of 3D CAD Models
class AdminReviewCadSheet extends StatelessWidget {
  const AdminReviewCadSheet({
    super.key,
    required this.store,
    required this.onSendDirective,
  });

  final DemoStore store;
  final void Function(String contextRef) onSendDirective;

  void _approveTask(BuildContext context, CadDesignTask task) {
    context.read<CadBloc>().add(ApproveCadTaskEvent(task.id));
  }

  static void show(
    BuildContext context, {
    required DemoStore store,
    required void Function(String contextRef) onSendDirective,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: AdminReviewCadSheet(
          store: store,
          onSendDirective: onSendDirective,
        ),
      ),
    );
  }

  void _openDirectCadBriefModal(BuildContext context) {
    CommonSnackbar.error(
      context,
      title: 'CAD Brief API Unavailable',
      message: 'The backend does not expose a direct CAD brief endpoint.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pendingTasks = store.cadTasks;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review 3D CAD Models',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Inspect solitaire ring models and approve for printing',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: BlocBuilder<CadBloc, CadState>(
                  builder: (context, cadState) {
                    if (cadState is CadLoading) {
                      return const Center(
                        child: CommonProgressIndicator.admin(
                          label: 'Syncing Admin 3D CAD Models...',
                        ),
                      );
                    }
                    return CommonRefreshIndicator(
                      theme: IndicatorTheme.cad,
                      onRefresh: () async => context.read<CadBloc>().add(
                        const FetchCadTasksEvent(),
                      ),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: pendingTasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final task = pendingTasks[index];
                          final isApproved =
                              task.status == CadTaskStatus.completed ||
                              task.specs.contains('(Approved)');

                          return CommonCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        color: isApproved
                                            ? AppColors.emeraldLight
                                            : AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isApproved)
                                            const Icon(
                                              Icons.check_circle,
                                              size: 11,
                                              color: AppColors.emeraldDark,
                                            )
                                          else
                                            const Icon(
                                              Icons.view_in_ar,
                                              size: 11,
                                              color: AppColors.goldDark,
                                            ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isApproved
                                                ? 'APPROVED'
                                                : 'PENDING 3D SIGN-OFF',
                                            style: TextStyle(
                                              color: isApproved
                                                  ? AppColors.emeraldDark
                                                  : AppColors.goldDark,
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
                                  'Code: ${task.designCode} Â· Client: ${task.clientName} Â· ${task.specs}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CommonButton.outlined(
                                        height: 34,
                                        icon: Icons.view_in_ar,
                                        label: 'View 3D',
                                        onPressed: () {
                                          showModalBottomSheet<void>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (viewCtx) =>
                                                Common3DViewer(
                                                  designCode: task.designCode,
                                                  productTitle:
                                                      task.productTitle,
                                                  modelUrl: task.modelFileUrl,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isApproved) ...[
                                      Expanded(
                                        child: CommonButton.primary(
                                          height: 34,
                                          backgroundColor: AppColors.emerald,
                                          icon: Icons.check_circle_outline,
                                          label: 'Approve 3D',
                                          onPressed: () =>
                                              _approveTask(context, task),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: CommonButton.outlined(
                                        height: 34,
                                        icon: Icons.edit_note,
                                        label: 'Directive',
                                        onPressed: () {
                                          Navigator.pop(context);
                                          onSendDirective(
                                            'CAD Modification: ${task.designCode}',
                                          );
                                        },
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
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  onPressed: () => _openDirectCadBriefModal(context),
                  label: '+ Direct CAD Brief / New Task',
                  icon: Icons.add_box_outlined,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet to create a direct CAD Design Task
