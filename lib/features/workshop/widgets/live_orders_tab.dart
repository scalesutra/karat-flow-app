import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_empty_state.dart';
import '../../../../core/widgets/common_progress_indicator.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';
import '../../../../routes/app_routes.dart';

/// Workshop Process Manager - Live Orders Tab
class LiveOrdersTab extends StatelessWidget {
  const LiveOrdersTab({
    super.key,
    required this.store,
    required this.searchQuery,
  });

  final DemoStore store;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final rawOrders = store.orders.where((o) => o.status != OrderStatus.delivered).toList();

    final filteredOrders = rawOrders.where((o) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return o.id.toLowerCase().contains(q) ||
          o.clientFirmName.toLowerCase().contains(q) ||
          o.itemsSummary.toLowerCase().contains(q) ||
          o.responsibleManager.toLowerCase().contains(q);
    }).toList();

    final liveOrders = filteredOrders.map((o) {
      final isBlocked = o.isBlocked;
      final isComplete = o.status == OrderStatus.ready || o.status == OrderStatus.dispatched;
      final isInProgress = o.status == OrderStatus.inWorkshop;

      final orderCadTasks = store.cadTasks
          .where((t) => t.productTitle.toLowerCase().contains(o.id.toLowerCase()))
          .toList();
      final totalCad = orderCadTasks.length;
      final completedCad = orderCadTasks.where((t) => t.status == CadTaskStatus.completed).length;
      final hasStl = orderCadTasks.any((t) => t.hasStlFile);

      return {
        'id': o.id,
        'title': o.itemsSummary,
        'client': '${o.clientFirmName} · ${o.clientCity}',
        'stage': isBlocked
            ? 'ON CRITICAL HOLD'
            : (isComplete ? 'Complete' : (isInProgress ? o.currentWorkshopStage : 'Pending Start')),
        'purity': '${o.totalGrossGrams}g · Due ${o.promiseDate}',
        'status': isBlocked
            ? 'on hold'
            : isComplete
                ? 'complete'
                : isInProgress
                    ? 'in progress'
                    : 'pending',
        'statusColor': isBlocked
            ? AppColors.danger
            : isComplete
                ? AppColors.emerald
                : isInProgress
                    ? AppColors.goldDark
                    : const Color(0xFFFFD18A),
        'pieces': o.itemsCount,
        'artisan': o.responsibleManager,
        'totalCad': totalCad,
        'completedCad': completedCad,
        'hasStl': hasStl,
        'isBlocked': isBlocked,
        'blockedReason': o.blockedReason,
      };
    }).toList();

    if (liveOrders.isEmpty) {
      return const CommonEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No active orders from Front Office',
        description: 'New orders placed in Front Office will appear here.',
      );
    }

    return CommonRefreshIndicator(
      theme: IndicatorTheme.workshop,
      onRefresh: () async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        itemCount: liveOrders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = liveOrders[index];
          final isBlocked = order['isBlocked'] as bool? ?? false;
          final statusColor = isBlocked ? AppColors.danger : (order['statusColor'] as Color);

          return InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.stageOverview,
                arguments: {...order, 'allowStageChange': true},
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isBlocked ? AppColors.danger : statusColor.withValues(alpha: 0.8),
                  width: isBlocked ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isBlocked
                        ? AppColors.danger.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${order['id']} - ${order['title']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order['status'] as String,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isBlocked) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
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
                              'ON CRITICAL HOLD: ${order['blockedReason'] ?? "Stage blocked"}',
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
                  const SizedBox(height: 6),
                  Text(
                    order['client'] as String,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.layers_outlined, size: 14, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  order['stage'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: isBlocked ? AppColors.danger : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${order['pieces']} Pcs · ${order['purity']}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'View Stage Overview',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: AppColors.emerald,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
