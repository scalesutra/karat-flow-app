import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../front_office/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import 'departments/department_logs_dialog.dart';
import 'ledger/craftsman_monthly_ledger_page.dart';
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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<OrdersBloc>().add(
      const FetchOrdersEvent(search: '', statusFilter: ''),
    );
  }

  void _searchOrders(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    void fetch() => context.read<OrdersBloc>().add(
      FetchOrdersEvent(search: value, statusFilter: ''),
    );
    if (value.trim().isEmpty) {
      fetch();
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 300), fetch);
    }
  }

  final _peopleSearchController = TextEditingController();
  String _peopleSearchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _peopleSearchController.dispose();
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
          final hasUnfinished =
              o.designs.isNotEmpty &&
              o.designs.any((d) {
                final stg = d.currentStage.toLowerCase();
                return !stg.contains('pack') &&
                    !stg.contains('dispatch') &&
                    !stg.contains('ready') &&
                    !stg.contains('complete');
              });
          if (hasUnfinished) return false;

          final allFinished =
              o.designs.isNotEmpty &&
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
                      o.currentWorkshopStage.toLowerCase().contains(
                        'dispatch',
                      ) ||
                      o.currentWorkshopStage.toLowerCase().contains('pack')));
        }).length;

        final inProgressCount = widget.store.orders.where((o) {
          final hasUnfinished =
              o.designs.isNotEmpty &&
              o.designs.any((d) {
                final stg = d.currentStage.toLowerCase();
                return !stg.contains('pack') &&
                    !stg.contains('dispatch') &&
                    !stg.contains('ready') &&
                    !stg.contains('complete');
              });
          if (hasUnfinished) return true;

          final allFinished =
              o.designs.isNotEmpty &&
              o.designs.every((d) {
                final stg = d.currentStage.toLowerCase();
                return stg.contains('pack') ||
                    stg.contains('dispatch') ||
                    stg.contains('ready') ||
                    stg.contains('complete');
              });

          final isFinished =
              o.status == OrderStatus.ready ||
              o.status == OrderStatus.dispatched ||
              o.status == OrderStatus.delivered ||
              allFinished ||
              (o.designs.isEmpty &&
                  (o.currentWorkshopStage.toLowerCase().contains('complete') ||
                      o.currentWorkshopStage.toLowerCase().contains(
                        'dispatch',
                      ) ||
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CommonText.headlineLarge(
                            AppStrings.productManager.trClean,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CommonButton.primary(
                              isFullWidth: false,
                              height: 32.h,
                              icon: Icons.precision_manufacturing_rounded,
                              label: 'Dept Logs',
                              backgroundColor: AppColors.goldDark,
                              onPressed: () =>
                                  DepartmentLogsDialog.show(context),
                            ),
                            SizedBox(width: 6.w),
                            CommonButton.primary(
                              isFullWidth: false,
                              height: 32.h,
                              icon: Icons.menu_book_rounded,
                              label: 'Ledger',
                              backgroundColor: AppColors.emerald,
                              onPressed: () => Navigator.of(context).push(
                                CraftsmanMonthlyLedgerPage.route(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),

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
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$pendingCount',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5.sp,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
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
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$inProgressCount',
                                    style: TextStyle(
                                      color: AppColors.goldDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5.sp,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'In Progress',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
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
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$completeCount',
                                    style: TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5.sp,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Complete',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9.sp,
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
                      SizedBox(height: 8.h),
                      CommonSearchBar(
                        controller: _searchController,
                        hintText: 'Order #, customer, phone or design #...',
                        onChanged: _searchOrders,
                      ),
                    ],

                    if (_activePivot == StatusPivot.people) ...[
                      SizedBox(height: 8.h),
                      CommonSearchBar(
                        controller: _peopleSearchController,
                        hintText: 'Search people by name, craft or stage...',
                        onChanged: (value) =>
                            setState(() => _peopleSearchQuery = value),
                        onClear: () => setState(() => _peopleSearchQuery = ''),
                      ),
                    ],

                    SizedBox(height: 8.h),

                    // 3 Segmented Top Tabs: [ orders ] [ people ] [ stages ]
                    Container(
                      height: 36.h,
                      padding: EdgeInsets.all(3.r),
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
                  StatusPivot.people => ArtisansPeopleTab(
                    store: widget.store,
                    searchQuery: _peopleSearchQuery,
                  ),
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
