import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_badge.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../core/widgets/common_text.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';

enum TaskDisplayMode { admin, manager }

/// Modular Instruction & Directive Task Card
class InstructionTaskCard extends StatelessWidget {
  const InstructionTaskCard({
    super.key,
    required this.instruction,
    required this.mode,
    required this.store,
  });

  final Instruction instruction;
  final TaskDisplayMode mode;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final isResolved = instruction.status == InstructionStatus.resolved;

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UrgencyBadge(urgency: instruction.urgency),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  instruction.targetLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status: instruction.status),
            ],
          ),
          const SizedBox(height: 12),
          CommonText.bodyLarge(instruction.message),
          if (instruction.hasPhoto || instruction.hasVoice) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (instruction.hasVoice)
                  InkWell(
                    onTap: () {
                      CommonSnackbar.info(
                        context,
                        title: 'Playing Audio Note',
                        message:
                            'Playing: "${instruction.message}" (0:18 recorded by ${instruction.createdBy}).',
                      );
                    },
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 15, color: AppColors.emerald),
                          SizedBox(width: 5),
                          Text(
                            'Voice Note · 0:18 (Tap to play)',
                            style: TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (instruction.hasPhoto)
                  InkWell(
                    onTap: () => _showPhotoPreview(context, instruction),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image,
                            size: 15,
                            color: AppColors.goldDark,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Attached Photo · View (1)',
                            style: TextStyle(
                              color: AppColors.goldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mode == TaskDisplayMode.admin
                      ? 'Assigned to ${instruction.assignedTo}'
                      : 'From ${instruction.createdBy} · ${instruction.urgency.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              Text(
                '${instruction.createdAt.hour}:${instruction.createdAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),

          // Action Buttons for Process Manager
          if (mode == TaskDisplayMode.manager && !isResolved) ...[
            const SizedBox(height: 14),
            if (instruction.status == InstructionStatus.sent)
              CommonButton.primary(
                height: 42,
                onPressed: () => _showUnsupportedAction(context),
                label: 'Acknowledge Instruction',
              )
            else
              Row(
                children: [
                  Expanded(
                    child: CommonButton.outlined(
                      height: 42,
                      onPressed:
                          instruction.status == InstructionStatus.inProgress
                          ? null
                          : () => _showUnsupportedAction(context),
                      label: 'Start Work',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CommonButton.primary(
                      height: 42,
                      onPressed: () => _showUnsupportedAction(context),
                      label: 'Resolve Task',
                    ),
                  ),
                ],
              ),
          ],

          // Action Buttons for Admin Mode
          if (mode == TaskDisplayMode.admin && !isResolved) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CommonButton.outlined(
                    height: 40,
                    label: 'Mark Resolved',
                    icon: Icons.check,
                    onPressed: () => _showUnsupportedAction(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showUnsupportedAction(BuildContext context) {
    CommonSnackbar.error(
      context,
      title: 'Instructions API unavailable',
      message:
          'The API documentation does not provide an instruction status endpoint.',
    );
  }

  void _showPhotoPreview(BuildContext context, Instruction instruction) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inspection Photo · ${instruction.targetLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 54, color: Colors.white54),
                      SizedBox(height: 8),
                      Text(
                        'High-Res Bench Inspection Photo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Surface porosity check · Magnification 20x',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  height: 36,
                  label: 'Acknowledge Image',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
