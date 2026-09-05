import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/constants/app_dimensions.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_card.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_text.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import 'package:jewellery_ops_mobile/routes/app_routes.dart';
import 'front_office_order_card.dart';

/// Front Office Customer Order Detail Bottom Sheet
class OrderDetailSheet extends StatelessWidget {
  const OrderDetailSheet({super.key, required this.order});

  final CustomerOrder order;

  static Future<void> show(BuildContext context, CustomerOrder order) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => OrderDetailSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = FrontOfficeOrderCard.getStatusColor(order.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              CommonText.headlineMedium(order.id),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CommonText.bodyMedium(
            '${order.clientFirmName} · ${order.clientCity}',
            color: AppColors.muted,
          ),
          const SizedBox(height: 16),
          CommonCard(
            backgroundColor: AppColors.ink,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('Pieces', '${order.itemsCount} pcs'),
                _statColumn('Due Date', order.promiseDate),
                _statColumn('Status', order.status.label),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const CommonText.titleMedium('Workshop Progress'),
          const SizedBox(height: 8),
          _stageStep(
            '•',
            order.currentWorkshopStage.isNotEmpty
                ? order.currentWorkshopStage
                : 'Unassigned',
            order.currentWorkshopStage.isNotEmpty &&
                order.currentWorkshopStage.toLowerCase() != 'unassigned',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CommonButton.outlined(
                  label: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonButton.primary(
                  label: 'View Stages',
                  onPressed: () {
                    Navigator.pop(context);
                    final designRows = order.designs
                        .map(
                          (design) => <String, Object?>{
                            'partId': design.partId,
                            'designNumber': design.designNumber,
                            'quantity': design.quantity,
                            'stage': design.currentStage.isNotEmpty
                                ? design.currentStage
                                : design.status,
                            'isBlocked': design.isBlocked,
                            'blockReason': design.blockReason,
                          },
                        )
                        .toList(growable: false);
                    final isOrderCompleted =
                        order.status == OrderStatus.ready ||
                        order.status == OrderStatus.delivered ||
                        order.currentWorkshopStage
                            .toLowerCase()
                            .contains('complete') ||
                        (designRows.isNotEmpty &&
                            designRows.every((d) {
                              final stg =
                                  (d['stage'] as String? ?? '').toLowerCase();
                              return stg.contains('complete') ||
                                  stg.contains('dispatch');
                            }));
                    final Map<String, dynamic> orderMap = {
                      'id': order.id,
                      'apiId': order.apiId,
                      'orderNumber': order.id,
                      'title': order.itemsSummary,
                      'client': '${order.clientFirmName} · ${order.clientCity}',
                      'stage': isOrderCompleted
                          ? 'Completed'
                          : order.currentWorkshopStage,
                      'status': isOrderCompleted
                          ? 'Completed'
                          : order.status.label,
                      'purity':
                          '${order.totalGrossGrams}g · Due ${order.promiseDate}',
                      'pieces': order.itemsCount,
                      'artisan': order.responsibleManager,
                      'designs': designRows,
                      'allowStageChange': false,
                    };
                    Navigator.pushNamed(
                      context,
                      Routes.stageOverview,
                      arguments: orderMap,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Color(0xFFFFD18A),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _stageStep(String num, String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isDone ? AppColors.emerald : AppColors.outline,
            child: isDone
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    num,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                color: isDone ? AppColors.ink : AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
