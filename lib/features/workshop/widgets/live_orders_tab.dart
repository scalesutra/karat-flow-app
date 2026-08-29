import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/constants/app_dimensions.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_empty_state.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_progress_indicator.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import 'package:jewellery_ops_mobile/routes/app_routes.dart';
import '../../front_office/bloc/orders_bloc.dart';
import '../bloc/workshop_bloc.dart';

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
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return BlocBuilder<WorkshopBloc, WorkshopState>(
          builder: (context, state) {
            if (state is WorkshopLoading) {
              return const Center(
                child: CommonProgressIndicator.workshop(
                  label: 'Syncing Process Manager Active Orders...',
                ),
              );
            }

            final rawOrders = store.orders
                .where((o) => o.status != OrderStatus.delivered)
                .toList();

            final filteredOrders = rawOrders.where((o) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              return o.id.toLowerCase().contains(q) ||
                  o.clientFirmName.toLowerCase().contains(q) ||
                  o.itemsSummary.toLowerCase().contains(q) ||
                  o.responsibleManager.toLowerCase().contains(q);
            }).toList();

            final liveOrders = filteredOrders.map((o) {
              final matchingLots = store.lots.where((l) {
                final matchesOrder =
                    l.orderId == o.id ||
                    (o.apiId.isNotEmpty && l.orderId == o.apiId);
                final matchesPart = o.designs.any(
                  (design) => design.partId.isNotEmpty && design.partId == l.id,
                );
                return matchesOrder || matchesPart;
              }).toList();
              final blockedLot = matchingLots
                  .where((l) => l.blockerReason != null)
                  .firstOrNull;
              final isBlocked = o.isBlocked || blockedLot != null;
              final blockedReason =
                  o.blockedReason ?? blockedLot?.blockerReason;

              final designRows = o.designs
                  .map((design) {
                    final matchedLot =
                        matchingLots
                            .where(
                              (lot) =>
                                  design.partId.isNotEmpty &&
                                  lot.id == design.partId,
                            )
                            .firstOrNull ??
                        matchingLots
                            .where(
                              (lot) =>
                                  design.designNumber.isNotEmpty &&
                                  lot.designCode == design.designNumber,
                            )
                            .firstOrNull;
                    final stage =
                        matchedLot?.stage.label ??
                        (design.currentStage.isNotEmpty
                            ? design.currentStage
                            : design.status);
                    return {
                      'partId': design.partId,
                      'designNumber': design.designNumber,
                      'quantity': design.quantity,
                      'stage': stage,
                      'artisan': matchedLot?.assignedEmployee ?? '',
                      'isBlocked':
                          design.isBlocked || matchedLot?.blockerReason != null,
                      'blockReason':
                          design.blockReason ?? matchedLot?.blockerReason,
                    };
                  })
                  .toList(growable: false);

              final allDesignsFinished = designRows.isNotEmpty &&
                  designRows.every((r) {
                    final stg = (r['stage'] as String).toLowerCase();
                    return stg.contains('pack') ||
                        stg.contains('dispatch') ||
                        stg.contains('ready') ||
                        stg.contains('complete');
                  });

              final hasUnfinishedDesigns = designRows.isNotEmpty &&
                  designRows.any((r) {
                    final stg = (r['stage'] as String).toLowerCase();
                    return !stg.contains('pack') &&
                        !stg.contains('dispatch') &&
                        !stg.contains('ready') &&
                        !stg.contains('complete');
                  });

              final isComplete = !hasUnfinishedDesigns &&
                  (o.status == OrderStatus.ready ||
                      o.status == OrderStatus.dispatched ||
                      o.status == OrderStatus.delivered ||
                      allDesignsFinished ||
                      (designRows.isEmpty &&
                          (o.currentWorkshopStage
                                  .toLowerCase()
                                  .contains('complete') ||
                              o.currentWorkshopStage
                                  .toLowerCase()
                                  .contains('dispatch') ||
                              o.currentWorkshopStage
                                  .toLowerCase()
                                  .contains('pack'))));
              final isInProgress =
                  !isComplete && o.status == OrderStatus.inWorkshop;
              final activeStages = designRows
                  .map((row) => row['stage'] as String)
                  .where((stage) => stage.isNotEmpty)
                  .toSet();
              final showDesignStages =
                  activeStages.length > 1 ||
                  designRows.any((row) => row['isBlocked'] == true);

              final orderDetails = <String>['${o.itemsCount} Pcs'];
              if (o.totalGrossGrams > 0) {
                orderDetails.add('${o.totalGrossGrams}g');
              }
              if (o.promiseDate.trim().isNotEmpty) {
                orderDetails.add('Due ${o.promiseDate}');
              }

              final orderCadTasks = store.cadTasks
                  .where(
                    (task) =>
                        task.orderId == o.id ||
                        (o.apiId.isNotEmpty && task.orderId == o.apiId) ||
                        o.designs.any(
                          (design) =>
                              design.designNumber.isNotEmpty &&
                              task.designCode == design.designNumber,
                        ),
                  )
                  .toList();
              final totalCad = orderCadTasks.length;
              final completedCad = orderCadTasks
                  .where((t) => t.status == CadTaskStatus.completed)
                  .length;
              final hasStl = orderCadTasks.any((t) => t.hasStlFile);

              return {
                'id': o.id,
                'apiId': o.apiId,
                'title': o.designs.isEmpty
                    ? 'No design parts'
                    : '${o.designs.length} design${o.designs.length == 1 ? '' : 's'}',
                'client': '${o.clientFirmName} · ${o.clientCity}',
                'stage': isBlocked
                    ? 'ON CRITICAL HOLD'
                    : (isComplete
                          ? 'Complete'
                          : activeStages.length > 1
                          ? '${activeStages.length} Active Stages'
                          : activeStages.firstOrNull ??
                                (isInProgress
                                    ? o.currentWorkshopStage
                                    : 'Pending Start')),
                'details': orderDetails.join(' · '),
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
                'designs': designRows,
                'showDesignStages': showDesignStages,
                'artisan': o.responsibleManager,
                'totalCad': totalCad,
                'completedCad': completedCad,
                'hasStl': hasStl,
                'isBlocked': isBlocked,
                'blockedReason': blockedReason,
                'blockReason': blockedReason,
                'partId': blockedLot?.id ?? matchingLots.firstOrNull?.id,
                'orderPartId': blockedLot?.id ?? matchingLots.firstOrNull?.id,
              };
            }).toList();

            if (liveOrders.isEmpty) {
              return const CommonEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No active orders from Front Office',
                description:
                    'New orders placed in Front Office will appear here.',
              );
            }

            return CommonRefreshIndicator(
              theme: IndicatorTheme.workshop,
              onRefresh: () async {
                context.read<OrdersBloc>().add(const FetchOrdersEvent());
                context.read<WorkshopBloc>().add(
                  const FetchWorkshopLotsEvent(),
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                itemCount: liveOrders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = liveOrders[index];
                  final isBlocked = order['isBlocked'] as bool? ?? false;
                  final designRows =
                      order['designs'] as List<Map<String, Object?>>;
                  final statusColor = isBlocked
                      ? AppColors.danger
                      : (order['statusColor'] as Color);

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
                          color: isBlocked
                              ? AppColors.danger
                              : statusColor.withValues(alpha: 0.8),
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
                                  '${ApiDomainMapper.formatOrderNumber(order['id'] as String? ?? '')} - ${order['title']}',
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull,
                                  ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.danger.withValues(
                                    alpha: 0.3,
                                  ),
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
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      final orderId =
                                          order['id'] as String? ?? '';
                                      final apiId =
                                          order['apiId'] as String? ?? '';
                                      final designRows =
                                          order['designs']
                                              as List<Map<String, Object?>>;
                                      final partIds = designRows
                                          .map(
                                            (row) =>
                                                row['partId'] as String? ?? '',
                                          )
                                          .where((id) => id.isNotEmpty)
                                          .toSet();

                                      final matchingBlockedLots = store.lots
                                          .where((l) {
                                            if (l.blockerReason == null) {
                                              return false;
                                            }
                                            return l.orderId == orderId ||
                                                (apiId.isNotEmpty &&
                                                    l.orderId == apiId) ||
                                                partIds.contains(l.id);
                                          })
                                          .toList();

                                      final partId =
                                          order['partId'] as String? ??
                                          order['orderPartId'] as String?;

                                      if (matchingBlockedLots.isNotEmpty) {
                                        for (final bLot
                                            in matchingBlockedLots) {
                                          context.read<WorkshopBloc>().add(
                                            UnblockLotPartEvent(
                                              partId: bLot.id,
                                              notes: 'Unhold from Order card',
                                            ),
                                          );
                                        }
                                        CommonSnackbar.success(
                                          context,
                                          title: 'Hold Released',
                                          message:
                                              'Production resumed for ${order["title"] ?? "order"}.',
                                        );
                                      } else if (partId != null &&
                                          partId.isNotEmpty) {
                                        context.read<WorkshopBloc>().add(
                                          UnblockLotPartEvent(
                                            partId: partId,
                                            notes: 'Unhold from Order card',
                                          ),
                                        );
                                        CommonSnackbar.success(
                                          context,
                                          title: 'Hold Released',
                                          message:
                                              'Production resumed for ${order["title"] ?? "order"}.',
                                        );
                                      } else {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.stageOverview,
                                          arguments: {
                                            ...order,
                                            'allowStageChange': true,
                                          },
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            color: AppColors.pureWhite,
                                            size: 13,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Resume',
                                            style: TextStyle(
                                              color: AppColors.pureWhite,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            order['client'] as String,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: designRows.isEmpty
                                ? const Text(
                                    'No design parts returned by the API.',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (
                                        var designIndex = 0;
                                        designIndex < designRows.length;
                                        designIndex++
                                      ) ...[
                                        _OrderDesignStageRow(
                                          design: designRows[designIndex],
                                          showStage:
                                              order['showDesignStages'] as bool,
                                        ),
                                        if (designIndex < designRows.length - 1)
                                          const Divider(height: 14),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
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
                                      const Icon(
                                        Icons.layers_outlined,
                                        size: 14,
                                        color: AppColors.muted,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          order['stage'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: isBlocked
                                                ? AppColors.danger
                                                : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order['details'] as String,
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
          },
        );
      },
    );
  }
}

class _OrderDesignStageRow extends StatelessWidget {
  const _OrderDesignStageRow({required this.design, required this.showStage});

  final Map<String, Object?> design;
  final bool showStage;

  @override
  Widget build(BuildContext context) {
    final designNumber = design['designNumber'] as String? ?? '';
    final quantity = design['quantity'] as int? ?? 0;
    final stage = design['stage'] as String? ?? '';
    final artisan = design['artisan'] as String? ?? '';
    final isBlocked = design['isBlocked'] as bool? ?? false;
    final normalizedStage = stage.toLowerCase();
    final stageColor = isBlocked
        ? AppColors.danger
        : normalizedStage.contains('complete') ||
              normalizedStage.contains('dispatch')
        ? AppColors.emerald
        : normalizedStage.contains('pending') || stage.isEmpty
        ? AppColors.muted
        : AppColors.goldDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.diamond_outlined,
              size: 15,
              color: AppColors.emerald,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                designNumber.isEmpty
                    ? 'Design number not returned'
                    : designNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                '$quantity pcs',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (showStage || (artisan.isNotEmpty && artisan != 'Unassigned')) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (showStage)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(
                      color: stageColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    isBlocked
                        ? 'On Hold'
                        : stage.isEmpty
                        ? 'Stage not returned'
                        : stage,
                    style: TextStyle(
                      color: stageColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (artisan.isNotEmpty && artisan != 'Unassigned')
                Text(
                  'Assigned: $artisan',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
