import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_3d_viewer.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';
import '../../instructions/instruction_composer.dart';

/// Modular Admin CAD 3D Sign-off & Inspection Card
class CadApprovalTaskCard extends StatelessWidget {
  const CadApprovalTaskCard({
    super.key,
    required this.task,
    required this.store,
  });

  final CadDesignTask task;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final isApproved = task.specs.contains('(Approved)');

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.designCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isApproved
                      ? AppColors.emeraldLight
                      : AppColors.goldLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  isApproved ? 'APPROVED' : 'PENDING 3D SIGN-OFF',
                  style: TextStyle(
                    color: isApproved
                        ? AppColors.emeraldDark
                        : AppColors.goldDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.productTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Client: ${task.clientName} · Order: ${task.orderId}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.specs,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (task.hasStlFile)
                _indicator(
                  Icons.view_in_ar,
                  '3D Mesh Uploaded',
                  AppColors.emerald,
                  AppColors.emeraldLight,
                ),
              if (task.hasSketchImage)
                _indicator(
                  Icons.brush,
                  'Client Sketch Attached',
                  AppColors.goldDark,
                  AppColors.goldLight,
                ),
              _indicator(
                Icons.person_outline,
                'Assigned: ${task.assignedTo}',
                AppColors.ink,
                AppColors.canvas,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (task.hasStlFile) ...[
                Expanded(
                  child: CommonButton.outlined(
                    height: 36,
                    icon: Icons.view_in_ar,
                    label: '3D Preview',
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => Common3DViewer(
                          designCode: task.designCode,
                          productTitle: task.productTitle,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!isApproved) ...[
                Expanded(
                  child: CommonButton.primary(
                    height: 36,
                    backgroundColor: AppColors.emerald,
                    icon: Icons.check_circle_outline,
                    label: 'Approve',
                    onPressed: () {
                      store.approveCadTask(task.id);
                      CommonSnackbar.success(
                        context,
                        title: 'Design Approved',
                        message:
                            'Approved 3D Model & CAD for ${task.productTitle}.',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              CommonButton.outlined(
                isFullWidth: false,
                height: 36,
                icon: Icons.chat_bubble_outline,
                label: 'Directive',
                onPressed: () {
                  showInstructionComposer(context, store: store);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _indicator(IconData icon, String label, Color color, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
