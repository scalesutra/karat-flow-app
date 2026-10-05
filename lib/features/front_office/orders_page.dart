import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        final filteredOrders = state is OrdersLoaded
            ? state.orders
            : <CustomerOrder>[];
        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                            const SizedBox(height: 2),
                            CommonText.bodySmall(
                              '${filteredOrders.length} ${filteredOrders.length == 1 ? 'order' : 'orders'} listed',
                            ),
                          ],
                        ),
                        CommonButton.primary(
                          label: '+ New Order',
                          isFullWidth: false,
                          onPressed: () => _openNewOrderModal(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CommonSearchBar(
                      controller: _searchController,
                      hintText: 'Order #, customer, phone or design #...',
                      onChanged: (val) {
                        _searchQuery = val;
                        _searchDebounce?.cancel();
                        if (val.trim().isEmpty) {
                          _fetchLiveOrders();
                          return;
                        }
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          _fetchLiveOrders,
                        );
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
                child: state is OrdersError
                    ? CommonEmptyState(
                        icon: Icons.error_outline,
                        title: 'Could not load orders',
                        description: state.message,
                        actionLabel: 'Retry',
                        onAction: _fetchLiveOrders,
                      )
                    : state is! OrdersLoaded
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
                        description:
                            'No customer orders match the selected filters.',
                        actionLabel: 'Reset Filters',
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
                        onRefresh: _fetchLiveOrders,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          itemCount:
                              filteredOrders.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == filteredOrders.length) {
                              return Column(
                                children: [
                                  if (state.pageError != null)
                                    Text(state.pageError!),
                                  TextButton(
                                    onPressed: state.isLoadingMore
                                        ? null
                                        : () => context.read<OrdersBloc>().add(
                                            const FetchOrdersEvent(
                                              loadMore: true,
                                            ),
                                          ),
                                    child: Text(
                                      state.isLoadingMore
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
