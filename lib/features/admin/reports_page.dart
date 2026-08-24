import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../../routes/app_routes.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  int _selectedTab = 0; // 0: All, 1: Delayed, 2: Pending, 3: Dispatched

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final allOrders = widget.store.orders;

        // 1. Pending orders
        final pendingOrders = allOrders
            .where((o) => o.status == OrderStatus.pending)
            .toList();

        // 2. In Workshop / Daily Production orders
        final productionOrders = allOrders
            .where((o) => o.status == OrderStatus.inWorkshop)
            .toList();

        // 3. Dispatched orders today
        final dispatchedOrders = allOrders
            .where(
              (o) =>
                  o.status == OrderStatus.dispatched ||
                  o.status == OrderStatus.delivered,
            )
            .toList();

        // 4. Delayed / Attention orders (Urgent/Delayed or Promise Date passed)
        final delayedOrders = allOrders.where((o) {
          final summary = o.itemsSummary.toLowerCase();
          final isDelayedOrUrgent =
              summary.contains('urgent') ||
              summary.contains('delayed') ||
              o.status == OrderStatus.pending;
          return isDelayedOrUrgent && o.status != OrderStatus.delivered;
        }).toList();

        // Total daily production weight
        final double productionGrams = productionOrders.fold(
          0.0,
          (sum, o) => sum + o.totalGrossGrams,
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
        } else {
          displayedOrders = allOrders;
        }

        return SafeArea(
          top: false,
          child: CommonRefreshIndicator(
            onRefresh: () async {
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
                        subtitle: '${productionOrders.length} lots on floor',
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
                        title: 'Dispatched Today',
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
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Order List for selected category
                if (displayedOrders.isEmpty)
                  CommonEmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No orders in this section',
                    description:
                        'All orders in this filter category are clear.',
                    actionLabel: 'View All Orders',
                    onAction: () => setState(() => _selectedTab = 0),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedOrders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return _OrderReportRow(
                        order: order,
                        onTap: () {
                          final orderMap = {
                            'id': order.id,
                            'title': order.itemsSummary,
                            'client':
                                '${order.clientFirmName} · ${order.clientCity}',
                            'stage': order.currentWorkshopStage,
                            'status': order.status.label,
                            'statusColor': _statusColor(order.status),
                            'purity':
                                '${order.totalGrossGrams}g · Due ${order.promiseDate}',
                            'pieces': order.itemsCount,
                            'artisan': order.responsibleManager,
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
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppColors.outline,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
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
  const _OrderReportRow({required this.order, required this.onTap});

  final CustomerOrder order;
  final VoidCallback onTap;

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

    return CommonCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.clientFirmName} · ${order.clientCity}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            order.itemsSummary,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemsCount} pcs · ${order.totalGrossGrams}g Gold',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Due: ${order.promiseDate}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
