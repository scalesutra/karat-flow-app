import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import 'widgets/artisans_people_tab.dart';
import 'widgets/live_orders_tab.dart';
import 'widgets/stages_pipeline_tab.dart';

class ProductManagerPage extends StatefulWidget {
  const ProductManagerPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<ProductManagerPage> createState() => _ProductManagerPageState();
}

class _ProductManagerPageState extends State<ProductManagerPage> {
  StatusPivot _activePivot = StatusPivot.orders;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final pendingCount = widget.store.orders
            .where((o) => o.status == OrderStatus.pending)
            .length;
        final completeCount = widget.store.orders.where((o) {
          final hasUnfinished = o.designs.isNotEmpty &&
              o.designs.any((d) {
                final stg = d.currentStage.toLowerCase();
                return !stg.contains('pack') &&
                    !stg.contains('dispatch') &&
                    !stg.contains('ready') &&
                    !stg.contains('complete');
              });
          if (hasUnfinished) return false;

          final allFinished = o.designs.isNotEmpty &&
              o.designs.every((d) {
                final stg = d.currentStage.toLowerCase();
                return stg.contains('pack') ||
                    stg.contains('dispatch') ||
                    stg.contains('ready') ||
                    stg.contains('complete');
              });

          return o.status == OrderStatus.ready ||
              o.status == OrderStatus.dispatched ||
              o.status == OrderStatus.delivered ||
              allFinished ||
              (o.designs.isEmpty &&
                  (o.currentWorkshopStage.toLowerCase().contains('complete') ||
                      o.currentWorkshopStage
                          .toLowerCase()
                          .contains('dispatch') ||
                      o.currentWorkshopStage.toLowerCase().contains('pack')));
        }).length;

        final inProgressCount = widget.store.orders.where((o) {
          final hasUnfinished = o.designs.isNotEmpty &&
              o.designs.any((d) {
                final stg = d.currentStage.toLowerCase();
                return !stg.contains('pack') &&
                    !stg.contains('dispatch') &&
                    !stg.contains('ready') &&
                    !stg.contains('complete');
              });
          if (hasUnfinished) return true;

          final allFinished = o.designs.isNotEmpty &&
              o.designs.every((d) {
                final stg = d.currentStage.toLowerCase();
                return stg.contains('pack') ||
                    stg.contains('dispatch') ||
                    stg.contains('ready') ||
                    stg.contains('complete');
              });

          final isFinished = o.status == OrderStatus.ready ||
              o.status == OrderStatus.dispatched ||
              o.status == OrderStatus.delivered ||
              allFinished ||
              (o.designs.isEmpty &&
                  (o.currentWorkshopStage.toLowerCase().contains('complete') ||
                      o.currentWorkshopStage
                          .toLowerCase()
                          .contains('dispatch') ||
                      o.currentWorkshopStage.toLowerCase().contains('pack')));
          return !isFinished && o.status == OrderStatus.inWorkshop;
        }).length;

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText.headlineLarge(AppStrings.productManager.trClean),
                    const SizedBox(height: 8),

                    // Top Task Summary Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              CommonSnackbar.info(
                                context,
                                title: 'Pending Tasks',
                                message:
                                    'Showing $pendingCount pending lot allocations from Front Office.',
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              CommonSnackbar.info(
                                context,
                                title: 'In Progress',
                                message:
                                    '$inProgressCount orders currently active in crafting stages.',
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$inProgressCount',
                                    style: const TextStyle(
                                      color: AppColors.goldDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'In Progress',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              CommonSnackbar.info(
                                context,
                                title: 'Completed',
                                message:
                                    '$completeCount finished orders ready for dispatch & invoicing.',
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completeCount',
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Complete',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_activePivot == StatusPivot.orders) ...[
                      const SizedBox(height: 10),
                      CommonSearchBar(
                        controller: _searchController,
                        hintText: 'Search by Order #, client or item...',
                        onChanged: (val) => setState(() => _searchQuery = val),
                        onClear: () => setState(() => _searchQuery = ''),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 3 Segmented Top Tabs: [ orders ] [ people ] [ stages ]
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: StatusPivot.values.map((pivot) {
                          final isSelected = _activePivot == pivot;
                          return Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _activePivot = pivot),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.emerald
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  pivot.label.toLowerCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.pureWhite
                                        : AppColors.ink,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: switch (_activePivot) {
                  StatusPivot.orders => LiveOrdersTab(
                    store: widget.store,
                    searchQuery: _searchQuery,
                  ),
                  StatusPivot.people => ArtisansPeopleTab(store: widget.store),
                  StatusPivot.stages => StagesPipelineTab(store: widget.store),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
