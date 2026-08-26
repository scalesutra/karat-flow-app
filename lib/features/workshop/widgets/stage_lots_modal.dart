import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/constants/app_dimensions.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import '../bloc/workshop_bloc.dart';

/// Modal bottom sheet displaying active lots in a specific workshop stage
class StageLotsModal extends StatelessWidget {
  const StageLotsModal({super.key, required this.stage, required this.store});

  final Map<String, dynamic> stage;
  final DemoStore store;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> stage,
    required DemoStore store,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StageLotsModal(stage: stage, store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lots = (stage['lots'] as List<WorkshopLot>?) ?? [];

    return Padding(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage['name'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '${lots.length} lots',
                  style: const TextStyle(
                    color: AppColors.emeraldDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Active Pouches on Bench:',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (lots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No lots currently in this stage.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            )
          else
            for (final lot in lots)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                              lot.id.length > 10
                                  ? 'LOT-${lot.id.substring(0, 6).toUpperCase()}'
                                  : lot.id,
                              style: const TextStyle(
                                color: AppColors.emeraldDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lot.productTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${lot.issueWeightGrams} g',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order: ${lot.orderId} · Worker: ${lot.assignedEmployee}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (store.activeRole == AppRole.processManager) ...[
                            InkWell(
                              onTap: () {
                                _showRollbackDialog(context, lot, store);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.undo,
                                      size: 12,
                                      color: AppColors.warning,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '↺ Revert Stage',
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          InkWell(
                            onTap: () {
                              context.read<WorkshopBloc>().add(
                                AdvanceLotStageEvent(lot.id),
                              );
                              Navigator.pop(context);
                              CommonSnackbar.success(
                                context,
                                title: 'Stage Advanced',
                                message:
                                    '${lot.id} (${lot.productTitle}) moved to next stage.',
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emerald,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Next Stage ➡️',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
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
                ),
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CommonButton.primary(
              height: 40,
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  static void _showRollbackDialog(
    BuildContext context,
    WorkshopLot lot,
    DemoStore store,
  ) {
    final stages = store.stages;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Move Lot ${lot.id} Back to Any Stage',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${lot.productTitle} · Currently at ${lot.stage.label}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: stages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final stage = stages[index];
                    final isCurrent =
                        stage.name.toLowerCase() ==
                        lot.stage.label.toLowerCase();
                    return InkWell(
                      onTap: isCurrent
                          ? null
                          : () {
                              context.read<WorkshopBloc>().add(
                                RollbackLotStageEvent(
                                  lotId: lot.id,
                                  targetStageId: stage.id,
                                  reason:
                                      'Process Manager manual stage revert from app',
                                ),
                              );
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              CommonSnackbar.success(
                                context,
                                title: 'Stage Reverted',
                                message:
                                    'Lot ${lot.id} moved back to ${stage.name}',
                              );
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.canvas
                              : AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.outline
                                : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stage ${stage.stageNumber}: ${stage.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isCurrent
                                    ? AppColors.muted
                                    : AppColors.ink,
                              ),
                            ),
                            if (isCurrent)
                              const Text(
                                '(Current)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              )
                            else
                              const Icon(
                                Icons.undo,
                                size: 16,
                                color: AppColors.warning,
                              ),
                          ],
                        ),
                      ),
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
