import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    return BlocConsumer<OrdersBloc, OrdersState>(
      listenWhen: (previous, current) =>
          current is OrdersLoaded &&
          !current.isLoadingMore &&
          current.pageError == null &&
          current.page > 1 &&
          (previous is! OrdersLoaded || previous.page != current.page),
      listener: (context, state) {
        context.read<WorkshopBloc>().add(
          FetchWorkshopLotsEvent(orderPage: (state as OrdersLoaded).page),
        );
      },
      builder: (context, state) {
        if (state is OrdersError) {
          return CommonEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load orders',
            description: state.message,
            actionLabel: 'Retry',
            onAction: () => context.read<OrdersBloc>().add(
              FetchOrdersEvent(search: searchQuery, statusFilter: ''),
            ),
          );
        }
        if (state is! OrdersLoaded) {
          if (store.orders.isNotEmpty) {
            return Column(
              children: [
                Expanded(child: _buildOrders(context, store.orders)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Text(
                    '${store.orders.length} orders loaded',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(child: _buildOrders(context, state.orders)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.orders.length} orders loaded',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (state.pageError != null) Text(state.pageError!),
                  if (state.hasMore)
                    TextButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => context.read<OrdersBloc>().add(
                              const FetchOrdersEvent(loadMore: true),
                            ),
                      child: Text(
                        state.isLoadingMore
                            ? 'Loading…'
                            : state.pageError != null
                            ? 'Retry next page'
                            : 'Load next 50 orders',
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrders(BuildContext context, List<CustomerOrder> orders) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return BlocBuilder<WorkshopBloc, WorkshopState>(
          builder: (context, state) {
            if (state is WorkshopLoading && orders.isEmpty) {
              return const Center(
                child: CommonProgressIndicator.workshop(
                  label: 'Syncing Process Manager Active Orders...',
                ),
              );
            }

            final allOrdersMap = <String, CustomerOrder>{
              for (final o in store.orders)
                (o.apiId.isNotEmpty ? o.apiId : o.id): o,
              for (final o in orders)
                (o.apiId.isNotEmpty ? o.apiId : o.id): o,
            };
            final allOrders = allOrdersMap.values.toList();
            final q = searchQuery.trim().toLowerCase();
            final filteredOrders = q.isEmpty
                ? allOrders
                : allOrders.where((o) {
                    final idMatch = o.id.toLowerCase().contains(q) ||
                        o.apiId.toLowerCase().contains(q);
                    final clientMatch =
                        o.clientFirmName.toLowerCase().contains(q) ||
                        o.clientCity.toLowerCase().contains(q);
                    final summaryMatch =
                        o.itemsSummary.toLowerCase().contains(q);
                    final stageMatch =
                        o.currentWorkshopStage.toLowerCase().contains(q);
                    final designMatch = o.designs.any((d) =>
                        d.designNumber.toLowerCase().contains(q) ||
                        d.displayName.toLowerCase().contains(q));
                    return idMatch ||
                        clientMatch ||
                        summaryMatch ||
                        stageMatch ||
                        designMatch;
                  }).toList();

            // Build derived card data only for rows requested by the lazy list.
            Map<String, Object?> buildOrder(CustomerOrder o) {
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

              final stages = o.stagesSnapshot;
              final totalStages = stages.isNotEmpty ? stages.length : 1;
              final totalOrderQuantity = o.totalPieces > 0
                  ? o.totalPieces
                  : (o.itemsCount > 0
                        ? o.itemsCount
                        : o.designs.fold<int>(0, (sum, d) => sum + d.quantity));

              int readyPieces = 0;
              double progressNumerator = 0;

              final designRows = o.designs.map((design) {
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

                String stage = design.currentStage.isNotEmpty
                    ? design.currentStage
                    : (matchedLot?.stage.label ?? design.status);

                final artisan = design.assignedArtisanName.isNotEmpty
                    ? design.assignedArtisanName
                    : (matchedLot?.assignedEmployee ?? '');

                // Find stage index (1-indexed) in order.stagesSnapshot
                int stageIndex = 1;
                bool isFinalStage = false;
                if (stages.isNotEmpty) {
                  final sIdx = stages.indexWhere(
                    (s) =>
                        (design.currentStageId.isNotEmpty &&
                            s.id == design.currentStageId) ||
                        s.name.trim().toLowerCase() ==
                            stage.trim().toLowerCase(),
                  );
                  if (sIdx >= 0) {
                    stageIndex = sIdx + 1;
                    isFinalStage =
                        stages[sIdx].isFinal || sIdx == stages.length - 1;
                    stage = stages[sIdx].name;
                  } else if (stage.toLowerCase().contains('dispatch') ||
                      stage.toLowerCase().contains('complete')) {
                    stageIndex = totalStages;
                    isFinalStage = true;
                  }
                } else if (stage.toLowerCase().contains('dispatch') ||
                    stage.toLowerCase().contains('complete')) {
                  stageIndex = totalStages;
                  isFinalStage = true;
                }

                final isReadyForDispatch =
                    isFinalStage ||
                    design.isPriceLocked ||
                    stage.toLowerCase().contains('dispatch') ||
                    stage.toLowerCase().contains('complete');

                if (isReadyForDispatch) {
                  readyPieces += design.quantity;
                }

                progressNumerator += (design.quantity * stageIndex);

                return {
                  'partId': design.partId,
                  'designNumber': design.designNumber,
                  'quantity': design.quantity,
                  'stage': stage,
                  'artisan': artisan,
                  'isBlocked':
                      design.isBlocked || matchedLot?.blockerReason != null,
                  'blockReason':
                      design.blockReason ?? matchedLot?.blockerReason,
                  'isPriceLocked': design.isPriceLocked,
                  'priceLockedAt': design.priceLockedAt,
                  'isReadyForDispatch': isReadyForDispatch,
                };
              }).toList();

              final progressDenominator =
                  (totalOrderQuantity > 0 ? totalOrderQuantity : 1) *
                  totalStages;
              final progressPercent = progressDenominator > 0
                  ? ((progressNumerator / progressDenominator) * 100).clamp(
                      0.0,
                      100.0,
                    )
                  : 0.0;

              final isAllPiecesReady =
                  totalOrderQuantity > 0 && readyPieces >= totalOrderQuantity;
              final isComplete =
                  isAllPiecesReady ||
                  o.status == OrderStatus.ready ||
                  o.status == OrderStatus.dispatched ||
                  o.status == OrderStatus.delivered;

              final isPartialReady = !isComplete && readyPieces > 0;
              final isInProgress =
                  !isComplete &&
                  (o.status == OrderStatus.inWorkshop || readyPieces > 0);

              final activeStages = designRows
                  .map((row) => row['stage'] as String)
                  .where((stage) => stage.isNotEmpty)
                  .toSet();
              final showDesignStages =
                  activeStages.length > 1 ||
                  designRows.any((row) => row['isBlocked'] == true) ||
                  designRows.any((row) => row['isPriceLocked'] == true);

              final orderDetails = <String>['${o.itemsCount} Pcs'];
              if (o.totalGrossGrams > 0) {
                orderDetails.add('${o.totalGrossGrams.toStringAsFixed(2)}g');
              }
              final cleanPromise = o.promiseDate.trim();
              if (cleanPromise.isNotEmpty) {
                final dueText = cleanPromise.toLowerCase().startsWith('due')
                    ? cleanPromise
                    : 'Due $cleanPromise';
                orderDetails.add(dueText);
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

              final statusText = isBlocked
                  ? 'ON CRITICAL HOLD'
                  : isComplete
                  ? 'Complete'
                  : isPartialReady
                  ? 'In Production ($readyPieces/$totalOrderQuantity Ready)'
                  : isInProgress
                  ? (activeStages.length > 1
                        ? '${activeStages.length} Active Stages'
                        : activeStages.firstOrNull ?? o.currentWorkshopStage)
                  : 'Pending Start';

              return {
                'id': o.id,
                'apiId': o.apiId,
                'orderNumber': o.id,
                'title': o.designs.isEmpty
                    ? 'No design parts'
                    : '${o.designs.length} design${o.designs.length == 1 ? '' : 's'}',
                'client': o.clientCity.trim().isNotEmpty
                    ? '${o.clientFirmName} · ${o.clientCity.trim()}'
                    : o.clientFirmName,
                'stage': statusText,
                'details': orderDetails.join(' · '),
                'status': isBlocked
                    ? 'on hold'
                    : isComplete
                    ? 'complete'
                    : isPartialReady
                    ? 'in progress'
                    : isInProgress
                    ? 'in progress'
                    : 'pending',
                'statusColor': isBlocked
                    ? AppColors.danger
                    : isComplete
                    ? AppColors.emerald
                    : isPartialReady
                    ? AppColors.emerald
                    : isInProgress
                    ? AppColors.goldDark
                    : const Color(0xFFFFD18A),
                'pieces': o.itemsCount,
                'totalPieces': totalOrderQuantity,
                'readyPieces': readyPieces,
                'progressPercent': progressPercent,
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
            }

            if (filteredOrders.isEmpty) {
              return const CommonEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No matching orders',
                description:
                    'Try a different order number, customer, phone or design number.',
              );
            }

            return CommonRefreshIndicator(
              theme: IndicatorTheme.workshop,
              showIndicator: false,
              onRefresh: () async {
                context.read<OrdersBloc>().add(
                  FetchOrdersEvent(search: searchQuery, statusFilter: ''),
                );
                context.read<WorkshopBloc>().add(
                  const FetchWorkshopLotsEvent(orderPage: 1),
                );
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 20.h),
                itemCount: filteredOrders.length,
                separatorBuilder: (_, _) => SizedBox(height: 6.h),
                itemBuilder: (context, index) {
                  final order = buildOrder(filteredOrders[index]);
                  final isBlocked = order['isBlocked'] as bool? ?? false;
                  final designRows =
                      order['designs'] as List<Map<String, Object?>>;
                  final statusColor = isBlocked
                      ? AppColors.danger
                      : (order['statusColor'] as Color);
                  final progressPercent =
                      (order['progressPercent'] as num?)?.toDouble() ?? 0.0;

                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.stageOverview,
                        arguments: {...order, 'allowStageChange': true},
                      );
                    },
                    borderRadius: BorderRadius.circular(10.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isBlocked
                              ? AppColors.danger
                              : statusColor.withValues(alpha: 0.8),
                          width: isBlocked ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isBlocked
                                ? AppColors.danger.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 5,
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.sp,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
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
                                    fontSize: 9.5.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isBlocked) ...[
                            SizedBox(height: 5.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
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
                          SizedBox(height: 5.h),
                          Text(
                            order['client'] as String,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(height: 7.h),
                          // Dynamic Production Progress Bar
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Production Progress',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${progressPercent.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: progressPercent >= 100
                                            ? AppColors.emerald
                                            : AppColors.goldDark,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3.r),
                                  child: LinearProgressIndicator(
                                    value: (progressPercent / 100.0).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    minHeight: 4.h,
                                    backgroundColor: AppColors.outline
                                        .withValues(alpha: 0.35),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressPercent >= 100
                                          ? AppColors.emerald
                                          : AppColors.goldDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: designRows.isEmpty
                                ? Text(
                                    'No design parts returned by the API.',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10.5.sp,
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
                                          Divider(height: 10.h),
                                      ],
                                    ],
                                  ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.layers_outlined,
                                        size: 13.sp,
                                        color: AppColors.muted,
                                      ),
                                      SizedBox(width: 4.w),
                                      Flexible(
                                        child: Text(
                                          order['stage'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10.5.sp,
                                            color: isBlocked
                                                ? AppColors.danger
                                                : (order['statusColor']
                                                      as Color),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  order['details'] as String,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 10.5.sp,
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
    final isPriceLocked = design['isPriceLocked'] as bool? ?? false;
    final isReadyForDispatch = design['isReadyForDispatch'] as bool? ?? false;

    final normalizedStage = stage.toLowerCase();
    final stageColor = isBlocked
        ? AppColors.danger
        : isReadyForDispatch ||
              normalizedStage.contains('complete') ||
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
            Icon(
              Icons.diamond_outlined,
              size: 13.sp,
              color: AppColors.emerald,
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                designNumber.isEmpty
                    ? 'Design number not returned'
                    : designNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                '$quantity pcs',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 3.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Stage Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: stageColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                isBlocked
                    ? 'On Hold'
                    : stage.isEmpty
                    ? 'Stage not returned'
                    : stage,
                style: TextStyle(
                  color: stageColor,
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // Ready for Dispatch Badge
            if (isReadyForDispatch)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4.r,
                      height: 4.r,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Ready for Dispatch ($quantity Pcs)',
                      style: TextStyle(
                        color: AppColors.emerald,
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

            // Rates Locked Badge
            if (isPriceLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.goldDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.goldDark.withValues(alpha: 0.45),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 10,
                      color: AppColors.goldDark,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Rates Locked',
                      style: TextStyle(
                        color: AppColors.goldDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

            // Assigned Artisan Badge
            if (artisan.isNotEmpty && artisan != 'Unassigned')
              Text(
                'Artisan: $artisan',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
