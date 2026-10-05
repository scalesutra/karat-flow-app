import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import 'bloc/orders_bloc.dart';
import 'widgets/front_office_order_card.dart';
import 'widgets/new_order_sheet.dart';
import 'widgets/order_detail_sheet.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _searchController = TextEditingController();
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  Timer? _searchDebounce;

  final List<String> _statusFilters = const [
    'All',
    'DRAFT',
    'CHECKED_OUT',
    'IN_PRODUCTION',
    'COMPLETED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
  }

  Future<void> _fetchLiveOrders() async {
    _searchDebounce?.cancel();
    context.read<OrdersBloc>().add(
      FetchOrdersEvent(
        search: _searchQuery,
        statusFilter: _selectedStatusFilter == 'All'
            ? ''
            : _selectedStatusFilter,
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openNewOrderModal(BuildContext context) {
    NewOrderSheet.show(context, widget.store);
  }

  void _openOrderDetailModal(BuildContext context, CustomerOrder order) {
    OrderDetailSheet.show(context, order);
  }

  List<CustomerOrder> _filterOrders(List<CustomerOrder> source) {
    final query = _searchQuery.trim().toLowerCase();
    final status = _selectedStatusFilter;

    return source.where((order) {
      if (status != 'All' && status.isNotEmpty) {
        final matchesStatus = switch (status) {
          'DRAFT' => order.status == OrderStatus.pending,
          'CHECKED_OUT' => order.status == OrderStatus.inWorkshop,
          'IN_PRODUCTION' => order.status == OrderStatus.inWorkshop,
          'COMPLETED' => order.status == OrderStatus.ready,
          'CANCELLED' => order.status == OrderStatus.cancelled,
          _ => true,
        };
        if (!matchesStatus) return false;
      }

      if (query.isNotEmpty) {
        final idMatch = order.id.toLowerCase().contains(query) ||
            order.apiId.toLowerCase().contains(query);
        final clientMatch =
            order.clientFirmName.toLowerCase().contains(query) ||
            order.clientCity.toLowerCase().contains(query);
        final summaryMatch = order.itemsSummary.toLowerCase().contains(query);
        final stageMatch =
            order.currentWorkshopStage.toLowerCase().contains(query);
        final designMatch = order.designs.any((d) =>
            d.designNumber.toLowerCase().contains(query) ||
            d.displayName.toLowerCase().contains(query));

        if (!idMatch &&
            !clientMatch &&
            !summaryMatch &&
            !stageMatch &&
            !designMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        final loadedState = state is OrdersLoaded ? state : null;
        final hasMore = loadedState?.hasMore ?? false;
        final isLoadingMore = loadedState?.isLoadingMore ?? false;
        final pageError = loadedState?.pageError;

        final allOrdersMap = <String, CustomerOrder>{
          for (final o in widget.store.orders)
            (o.apiId.isNotEmpty ? o.apiId : o.id): o,
          if (loadedState != null)
            for (final o in loadedState.orders)
              (o.apiId.isNotEmpty ? o.apiId : o.id): o,
        };
        final allOrders = allOrdersMap.values.toList();
        final filteredOrders = _filterOrders(allOrders);

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonText.headlineLarge(
                              AppStrings.navOrders.trClean,
                            ),
                            SizedBox(height: 1.h),
                            CommonText.bodySmall(
                              '${filteredOrders.length} ${filteredOrders.length == 1 ? 'order' : 'orders'} listed',
                            ),
                          ],
                        ),
                        CommonButton.primary(
                          isFullWidth: false,
                          height: 32.h,
                          icon: Icons.add_shopping_cart_rounded,
                          label: 'New Order',
                          onPressed: () => _openNewOrderModal(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    CommonSearchBar(
                      controller: _searchController,
                      hintText: 'Order #, customer, phone or design #...',
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            if (mounted) _fetchLiveOrders();
                          },
                        );
                      },
                      onClear: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _fetchLiveOrders();
                      },
                    ),
                  ],
                ),
              ),
              CommonFilterChips<String>(
                options: _statusFilters,
                selected: _selectedStatusFilter,
                onSelected: (val) {
                  setState(() => _selectedStatusFilter = val);
                  _fetchLiveOrders();
                },
                labelBuilder: (val) => switch (val) {
                  'DRAFT' => 'Draft',
                  'CHECKED_OUT' => 'Checked Out',
                  'IN_PRODUCTION' => 'In Production',
                  'COMPLETED' => 'Completed',
                  'CANCELLED' => 'Cancelled',
                  _ => 'All',
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: state is OrdersError && allOrders.isEmpty
                    ? CommonEmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load orders',
                        description: state.message,
                        actionLabel: 'Retry',
                        onAction: _fetchLiveOrders,
                      )
                    : (state is! OrdersLoaded && allOrders.isEmpty)
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CommonProgressIndicator(
                            theme: IndicatorTheme.frontOffice,
                            size: 54,
                            label: 'Loading live customer orders...',
                          ),
                        ),
                      )
                    : filteredOrders.isEmpty
                    ? CommonEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No orders found',
                        description: _searchQuery.isNotEmpty
                            ? 'No customer orders match "$_searchQuery".'
                            : 'No customer orders match the selected filters.',
                        actionLabel: _searchQuery.isNotEmpty
                            ? 'Clear Search'
                            : 'Reset Filters',
                        onAction: () {
                          setState(() {
                            _selectedStatusFilter = 'All';
                            _searchController.clear();
                            _searchQuery = '';
                          });
                          _fetchLiveOrders();
                        },
                      )
                    : CommonRefreshIndicator(
                        theme: IndicatorTheme.frontOffice,
                        showIndicator: false,
                        onRefresh: _fetchLiveOrders,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 20.h),
                          itemCount:
                              filteredOrders.length + (hasMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              SizedBox(height: 6.h),
                          itemBuilder: (context, index) {
                            if (index == filteredOrders.length) {
                              return Column(
                                children: [
                                  if (pageError != null)
                                    Text(pageError),
                                  TextButton(
                                    onPressed: isLoadingMore
                                        ? null
                                        : () => context.read<OrdersBloc>().add(
                                            const FetchOrdersEvent(
                                              loadMore: true,
                                            ),
                                          ),
                                    child: Text(
                                      isLoadingMore
                                          ? 'Loading...'
                                          : 'Load more orders',
                                    ),
                                  ),
                                ],
                              );
                            }
                            final order = filteredOrders[index];
                            return FrontOfficeOrderCard(
                              index: index + 1,
                              order: order,
                              onTap: () =>
                                  _openOrderDetailModal(context, order),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
