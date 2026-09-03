import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/services/live_data_bloc_coordinator.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../instructions/instruction_composer.dart';
import 'status_detail_page.dart';

class AdminStatusPage extends StatefulWidget {
  const AdminStatusPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<AdminStatusPage> createState() => _AdminStatusPageState();
}

class _AdminStatusPageState extends State<AdminStatusPage> {
  StatusPivot _pivot = StatusPivot.orders;
  bool _exceptionsOnly = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.store.workItemsFor(_pivot);
    final items = all.where((item) {
      if (_exceptionsOnly && item.tone == HealthTone.healthy) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.id.toLowerCase().contains(q) ||
            item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q) ||
            item.status.toLowerCase().contains(q) ||
            item.owner.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SafeArea(
      top: false,
      child: CommonRefreshIndicator(
        onRefresh: () async {
          LiveDataBlocCoordinator.refreshForRole(context, AppRole.admin);
          await Future<void>.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              sliver: SliverList.list(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonText.headlineLarge(
                              AppStrings.adminDashboard.trClean,
                            ),
                            const SizedBox(height: 1),
                            CommonText.bodySmall(
                              'Live floor tracking · All workshop routes',
                              color: AppColors.muted,
                            ),
                          ],
                        ),
                      ),
                      CommonButton.primary(
                        isFullWidth: false,
                        height: 36,
                        icon: Icons.add_comment_outlined,
                        label: AppStrings.directives.trClean,
                        onPressed: () {
                          showInstructionComposer(context, store: widget.store);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _HealthStrip(store: widget.store),
                  const SizedBox(height: 10),

                  // GLOWING CUSTOM SEGMENTED PIVOT BAR
                  _SegmentedPivotBar(
                    selectedPivot: _pivot,
                    onSelected: (p) => setState(() => _pivot = p),
                  ),

                  const SizedBox(height: 10),

                  // LIVE SEARCH BAR
                  CommonSearchBar(
                    controller: _searchController,
                    hintText: 'Search status by order, person, or stage...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onClear: () => setState(() => _searchQuery = ''),
                  ),

                  const SizedBox(height: 10),

                  // GLOWING FILTER TOGGLES
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _GlowFilterChip(
                          label: 'All Items',
                          count: all.length,
                          isSelected: !_exceptionsOnly,
                          activeColor: AppColors.emerald,
                          onTap: () => setState(() => _exceptionsOnly = false),
                        ),
                        const SizedBox(width: 8),
                        _GlowFilterChip(
                          label: 'Needs Attention',
                          count: all
                              .where((i) => i.tone != HealthTone.healthy)
                              .length,
                          isSelected: _exceptionsOnly,
                          activeColor: AppColors.warning,
                          onTap: () => setState(() => _exceptionsOnly = true),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${items.length} shown',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _HealthyEmptyState(pivot: _pivot),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _StatusCard(
                    item: items[index],
                    onOpen: () => _openDetail(items[index]),
                    onInstruction: () => _composeInstruction(items[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(WorkItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatusDetailPage(item: item, store: widget.store),
      ),
    );
  }

  Future<void> _composeInstruction(WorkItem item) async {
    await showInstructionComposer(context, store: widget.store, target: item);
  }
}

class _SegmentedPivotBar extends StatelessWidget {
  const _SegmentedPivotBar({
    required this.selectedPivot,
    required this.onSelected,
  });

  final StatusPivot selectedPivot;
  final ValueChanged<StatusPivot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: StatusPivot.values.map((pivot) {
          final isSelected = selectedPivot == pivot;
          final (icon, label) = switch (pivot) {
            StatusPivot.orders => (Icons.inventory_2_outlined, 'Orders'),
            StatusPivot.people => (Icons.group_outlined, 'People'),
            StatusPivot.stages => (Icons.account_tree_outlined, 'Stages'),
          };

          return Expanded(
            child: InkWell(
              onTap: () => onSelected(pivot),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.emerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GlowFilterChip extends StatelessWidget {
  const _GlowFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : AppColors.paper,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.outline,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 13, color: activeColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : AppColors.ink,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : AppColors.outlineLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthStrip extends StatelessWidget {
  const _HealthStrip({required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final completedCount = store.orders.where((order) {
      return order.status == OrderStatus.ready ||
          order.status == OrderStatus.delivered ||
          order.currentWorkshopStage.toLowerCase().contains('complete') ||
          (order.designs.isNotEmpty &&
              order.designs.every(
                (d) =>
                    d.currentStage.toLowerCase().contains('complete') ||
                    d.currentStage.toLowerCase().contains('dispatch'),
              ));
    }).length;

    return CommonCard(
      backgroundColor: AppColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: _HealthMetric(
              value: '${store.heldLotsCount}',
              label: 'On Hold',
              accent: const Color(0xFFFFA88D),
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _HealthMetric(
              value:
                  '${store.orders.where((order) => order.status == OrderStatus.pending).length}',
              label: 'Pending',
              accent: const Color(0xFFFFD18A),
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _HealthMetric(
              value: '${store.cadTasks.length}',
              label: 'CAD Tasks',
              accent: const Color(0xFFA9DDD0),
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _HealthMetric(
              value: '$completedCount',
              label: 'Completed',
              accent: const Color(0xFF34D399),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: TextStyle(
          color: accent,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: Colors.white24,
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.item,
    required this.onOpen,
    required this.onInstruction,
  });

  final WorkItem item;
  final VoidCallback onOpen;
  final VoidCallback onInstruction;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = statusTone(item.tone);
    final isCritical = item.tone == HealthTone.critical;
    final isWarning = item.tone == HealthTone.warning;
    final displayId = switch (item.pivot) {
      StatusPivot.orders => ApiDomainMapper.formatOrderNumber(item.id),
      StatusPivot.people =>
        'EMP-${item.id.length > 6 ? item.id.substring(0, 6).toUpperCase() : item.id}',
      StatusPivot.stages =>
        item.id.length > 12 ? item.id.substring(0, 10) : item.id,
    };

    return CommonCard(
      borderColor: isCritical
          ? AppColors.danger.withValues(alpha: 0.5)
          : (isWarning
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.outline),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.pivot == StatusPivot.orders) ...[
                          Container(
                            constraints: const BoxConstraints(maxWidth: 110),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              displayId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TonePill(label: isCritical ? 'ON HOLD' : label, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isCritical ? AppColors.danger : AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    [
                      item.quantity,
                      item.owner,
                    ].where((value) => value.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CommonButton.outlined(
                  height: 38,
                  onPressed: onInstruction,
                  icon: Icons.chat_bubble_outline,
                  label: 'Send Directive',
                ),
              ),
              const SizedBox(width: 10),
              CommonButton.tonal(
                isFullWidth: false,
                height: 38,
                onPressed: onOpen,
                icon: Icons.arrow_forward,
                label: 'Details',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TonePill extends StatelessWidget {
  const _TonePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _HealthyEmptyState extends StatelessWidget {
  const _HealthyEmptyState({required this.pivot});

  final StatusPivot pivot;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, color) = switch (pivot) {
      StatusPivot.orders => (
        Icons.inventory_2_outlined,
        'No Orders in View',
        'All client orders in this status category are healthy and on schedule.',
        AppColors.emerald,
      ),
      StatusPivot.people => (
        Icons.group_outlined,
        'No Artisan Workloads',
        'All artisans and gold masters are actively working on schedule.',
        AppColors.emerald,
      ),
      StatusPivot.stages => (
        Icons.account_tree_outlined,
        'No Stage Blockers',
        'All manufacturing stages and routing sequences are moving smoothly.',
        AppColors.emerald,
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedEmptyStateWidget(
          icon: icon,
          title: title,
          subtitle: subtitle,
          accentColor: color,
        ),
      ),
    );
  }
}
