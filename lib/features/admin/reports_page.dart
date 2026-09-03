import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/live_data_bloc_coordinator.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../../routes/app_routes.dart';
import '../instructions/instruction_composer.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  int _selectedTab =
      0; // 0: All, 1: Delayed, 2: Pending, 3: Dispatched, 4: Hold

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LiveDataBlocCoordinator.refreshForRole(context, AppRole.admin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final allOrders = widget.store.orders;
        final orderItems = widget.store.workItemsFor(StatusPivot.orders);

        // 1. Pending orders
        final pendingOrders = allOrders
            .where((o) => o.status == OrderStatus.pending)
            .toList();

        // 2. Active production lots from the production API
        final productionLots = widget.store.lots;

        // 3. Dispatched / delivered orders (API has no dispatch timestamp)
        final dispatchedOrders = allOrders
            .where(
              (o) =>
                  o.status == OrderStatus.dispatched ||
                  o.status == OrderStatus.delivered,
            )
            .toList();

        // 4. Delayed orders with an actual passed due date
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final delayedOrders = allOrders.where((o) {
          final dueDate = _parseApiDate(o.promiseDate);
          return dueDate != null &&
              dueDate.isBefore(todayDate) &&
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled;
        }).toList();

        final heldOrderIds = orderItems
            .where((item) => item.tone == HealthTone.critical)
            .map((item) => item.id)
            .toSet();
        final heldOrders = allOrders
            .where((order) => heldOrderIds.contains(order.id))
            .toList();

        // Total daily production weight
        final double productionGrams = productionLots.fold(
          0.0,
          (sum, lot) => sum + lot.targetWeightGrams,
        );

        final double dispatchedGrams = dispatchedOrders.fold(
          0.0,
          (sum, o) => sum + o.totalGrossGrams,
        );

        List<CustomerOrder> displayedOrders;
        if (_selectedTab == 1) {
          displayedOrders = delayedOrders;
        } else if (_selectedTab == 2) {
          displayedOrders = pendingOrders;
        } else if (_selectedTab == 3) {
          displayedOrders = dispatchedOrders;
        } else if (_selectedTab == 4) {
          displayedOrders = heldOrders;
        } else {
          displayedOrders = allOrders;
        }

        return SafeArea(
          top: false,
          child: CommonRefreshIndicator(
            onRefresh: () async {
              LiveDataBlocCoordinator.refreshForRole(context, AppRole.admin);
              await Future<void>.delayed(const Duration(milliseconds: 600));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText.headlineLarge('Daily Production & Orders'),
                    const SizedBox(height: 2),
                    CommonText.bodySmall(
                      'Real-time output, order pipeline and dispatch tracker',
                      color: AppColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 4 CORE REPORT METRICS ────────────────────────────────
                Row(
                  children: [
                    // 1. Daily Production
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Daily Production',
                        value: '${productionGrams.toStringAsFixed(1)} g',
                        subtitle: '${productionLots.length} lots on floor',
                        icon: Icons.precision_manufacturing_rounded,
                        color: AppColors.emerald,
                        bgColor: AppColors.emeraldLight,
                        onTap: () => setState(() => _selectedTab = 0),
                        isSelected: _selectedTab == 0,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 2. Pending Orders
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Pending Orders',
                        value: '${pendingOrders.length}',
                        subtitle: 'Awaiting floor start',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        bgColor: AppColors.warningLight,
                        onTap: () => setState(() => _selectedTab = 2),
                        isSelected: _selectedTab == 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 3. Delayed Orders
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Delayed Orders',
                        value: '${delayedOrders.length}',
                        subtitle: 'Needs attention',
                        icon: Icons.error_outline_rounded,
                        color: AppColors.danger,
                        bgColor: AppColors.dangerLight,
                        onTap: () => setState(() => _selectedTab = 1),
                        isSelected: _selectedTab == 1,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 4. Total Dispatched Orders Today
                    Expanded(
                      child: _ReportMetricCard(
                        title: 'Dispatched / Delivered',
                        value: '${dispatchedOrders.length}',
                        subtitle:
                            '${dispatchedGrams.toStringAsFixed(1)} g sent',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.ink,
                        bgColor: AppColors.sage,
                        onTap: () => setState(() => _selectedTab = 3),
                        isSelected: _selectedTab == 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ReportMetricCard(
                  title: 'Orders On Hold',
                  value: '${heldOrders.length}',
                  subtitle: '${widget.store.heldLotsCount} held parts',
                  icon: Icons.pause_circle_outline,
                  color: AppColors.danger,
                  bgColor: AppColors.dangerLight,
                  onTap: () => setState(() => _selectedTab = 4),
                  isSelected: _selectedTab == 4,
                ),

                const SizedBox(height: 20),

                // Filter Segment Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTabChip(
                        label: 'All (${allOrders.length})',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterTabChip(
                        label: 'Delayed (${delayedOrders.length})',
                        isSelected: _selectedTab == 1,
                        badgeColor: AppColors.danger,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterTabChip(
                        label: 'Pending (${pendingOrders.length})',
                        isSelected: _selectedTab == 2,
                        badgeColor: AppColors.warning,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                      const SizedBox(width: 8),
                      _FilterTabChip(
                        label: 'Dispatched (${dispatchedOrders.length})',
                        isSelected: _selectedTab == 3,
                        badgeColor: AppColors.emerald,
                        onTap: () => setState(() => _selectedTab = 3),
                      ),
                      const SizedBox(width: 8),
                      _FilterTabChip(
                        label: 'On Hold (${heldOrders.length})',
                        isSelected: _selectedTab == 4,
                        badgeColor: AppColors.danger,
                        onTap: () => setState(() => _selectedTab = 4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (displayedOrders.isEmpty) ...[
                  const SizedBox(height: 20),
                  AnimatedEmptyStateWidget(
                    icon: switch (_selectedTab) {
                      1 => Icons.error_outline_rounded,
                      2 => Icons.hourglass_top_rounded,
                      3 => Icons.local_shipping_rounded,
                      4 => Icons.pause_circle_outline,
                      _ => Icons.assignment_turned_in_outlined,
                    },
                    title: switch (_selectedTab) {
                      1 => 'No Delayed Orders',
                      2 => 'No Pending Orders',
                      3 => 'No Dispatched Orders',
                      4 => 'No Orders On Hold',
                      _ => 'No Orders Found',
                    },
                    subtitle: switch (_selectedTab) {
                      1 =>
                        'Great news! Zero orders are behind schedule right now.',
                      2 =>
                        'All customer orders have been assigned & started on floor.',
                      3 =>
                        'No dispatched or delivered orders recorded in history.',
                      4 => 'No production orders currently on hold or blocked.',
                      _ => 'No customer orders match your selected filter.',
                    },
                    accentColor: switch (_selectedTab) {
                      1 => AppColors.danger,
                      2 => AppColors.warning,
                      3 => AppColors.emerald,
                      4 => AppColors.danger,
                      _ => AppColors.emerald,
                    },
                    actionLabel: _selectedTab != 0 ? 'Show All Orders' : null,
                    onAction: _selectedTab != 0
                        ? () => setState(() => _selectedTab = 0)
                        : null,
                  ),
                ] else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      final workItem = orderItems
                          .where((item) => item.id == order.id)
                          .firstOrNull;
                      return _OrderReportRow(
                        order: order,
                        holdStatus: workItem?.tone == HealthTone.critical
                            ? workItem?.status
                            : null,
                        onDirective:
                            workItem == null ||
                                workItem.tone != HealthTone.critical
                            ? null
                            : () => showInstructionComposer(
                                context,
                                store: widget.store,
                                target: workItem,
                              ),
                        onTap: () {
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
                              order.currentWorkshopStage.toLowerCase().contains(
                                'complete',
                              ) ||
                              (designRows.isNotEmpty &&
                                  designRows.every((d) {
                                    final stg = (d['stage'] as String? ?? '')
                                        .toLowerCase();
                                    return stg.contains('complete') ||
                                        stg.contains('dispatch');
                                  }));
                          final orderMap = {
                            'id': order.id,
                            'apiId': order.apiId,
                            'orderNumber': order.id,
                            'title': order.itemsSummary,
                            'client':
                                '${order.clientFirmName} · ${order.clientCity}',
                            'stage': isOrderCompleted
                                ? 'Completed'
                                : order.currentWorkshopStage,
                            'status': isOrderCompleted
                                ? 'Completed'
                                : order.status.label,
                            'statusColor': _statusColor(order.status),
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
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
    OrderStatus.pending => AppColors.warning,
    OrderStatus.inWorkshop => AppColors.info,
    OrderStatus.ready => AppColors.emerald,
    OrderStatus.dispatched => AppColors.ink,
    OrderStatus.delivered => AppColors.emeraldDark,
    OrderStatus.cancelled => AppColors.danger,
  };

  DateTime? _parseApiDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final parts = value.split(RegExp(r'[-/]'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [AppColors.paper, color.withOpacity(0.08)]
                : [AppColors.paper, AppColors.canvas],
          ),
          border: Border.all(
            color: isSelected ? color : AppColors.outlineLight,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.22)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 12 : 6,
              spreadRadius: isSelected ? 1 : 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabChip extends StatelessWidget {
  const _FilterTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.pureWhite : AppColors.ink,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderReportRow extends StatelessWidget {
  const _OrderReportRow({
    required this.order,
    required this.onTap,
    this.holdStatus,
    this.onDirective,
  });

  final CustomerOrder order;
  final VoidCallback onTap;
  final String? holdStatus;
  final VoidCallback? onDirective;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.inWorkshop => AppColors.info,
      OrderStatus.ready => AppColors.emerald,
      OrderStatus.dispatched => AppColors.ink,
      OrderStatus.delivered => AppColors.emeraldDark,
      OrderStatus.cancelled => AppColors.danger,
    };

    final statusBg = switch (order.status) {
      OrderStatus.pending => AppColors.warningLight,
      OrderStatus.inWorkshop => AppColors.infoLight,
      OrderStatus.ready => AppColors.emeraldLight,
      OrderStatus.dispatched => AppColors.sage,
      OrderStatus.delivered => AppColors.emeraldLight,
      OrderStatus.cancelled => AppColors.dangerLight,
    };

    final isOnHold = holdStatus?.isNotEmpty == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnHold
              ? AppColors.danger.withOpacity(0.5)
              : AppColors.outlineLight,
          width: isOnHold ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnHold
                ? AppColors.danger.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id.length > 10
                          ? 'ORD-${order.id.substring(0, 6).toUpperCase()}'
                          : order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isOnHold ? AppColors.dangerLight : statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOnHold ? 'ON HOLD' : order.status.label,
                        style: TextStyle(
                          color: isOnHold ? AppColors.danger : statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.clientFirmName} · ${order.clientCity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  order.itemsSummary,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isOnHold) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      holdStatus!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.itemsCount} pcs · ${order.totalGrossGrams}g Gold',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Due: ${order.promiseDate}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDirective != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onDirective,
                      icon: const Icon(Icons.add_comment_outlined, size: 14),
                      label: const Text(
                        'Send Directive',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
