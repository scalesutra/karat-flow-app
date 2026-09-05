import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../domain/models.dart';

/// Front Office Customer Order Card
class FrontOfficeOrderCard extends StatelessWidget {
  const FrontOfficeOrderCard({
    super.key,
    required this.index,
    required this.order,
    required this.onTap,
  });

  final int index;
  final CustomerOrder order;
  final VoidCallback onTap;

  static Color getStatusColor(OrderStatus status) => switch (status) {
    OrderStatus.pending => AppColors.danger,
    OrderStatus.inWorkshop => AppColors.goldDark,
    OrderStatus.ready => AppColors.emerald,
    OrderStatus.dispatched => const Color(0xFF2C3E50),
    OrderStatus.delivered => AppColors.emeraldDark,
    OrderStatus.cancelled => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor = order.isBlocked
        ? AppColors.danger
        : getStatusColor(order.status);

    return CommonCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$index. ${order.id} · ${order.clientFirmName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  order.isBlocked
                      ? 'ON HOLD'
                      : order.status == OrderStatus.inWorkshop
                      ? 'in progress'
                      : order.status == OrderStatus.ready
                      ? 'complete'
                      : order.status == OrderStatus.pending
                      ? 'delay'
                      : order.status.label.toLowerCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (order.isBlocked) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pause_circle_filled_rounded,
                    color: AppColors.danger,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ON CRITICAL HOLD: ${order.blockedReason ?? "Stage blocked by workshop"}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Stage: ${order.currentWorkshopStage.isNotEmpty ? order.currentWorkshopStage : 'Unassigned'}',
            style: TextStyle(
              color: order.currentWorkshopStage.isNotEmpty &&
                      order.currentWorkshopStage.toLowerCase() != 'unassigned'
                  ? AppColors.emeraldDark
                  : AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.promiseDate.isEmpty ? '' : 'Due: ${order.promiseDate} · '}${order.itemsCount} pcs${order.totalGrossGrams > 0 ? ' · ${order.totalGrossGrams}g' : ''}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (order.designs.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...order.designs.take(3).map((d) {
                  final name = d.displayName;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${d.quantity} pcs',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('·', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (order.designs.length > 3)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${order.designs.length - 3} more',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
              ],
            ),
          ] else if (order.itemsSummary.isNotEmpty) ...[
            Text(
              order.itemsSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
