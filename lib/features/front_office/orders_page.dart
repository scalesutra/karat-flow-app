import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/repositories/karatflow_api_repository.dart';
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

  final List<String> _statusFilters = const [
    'All',
    'In Workshop',
    'Ready',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
  }

  Future<void> _fetchLiveOrders() async {
    context.read<OrdersBloc>().add(const FetchOrdersEvent());
  }

  @override
  void dispose() {
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
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final allOrders = widget.store.orders;

        final filteredOrders = allOrders.where((order) {
          final matchesStatus = switch (_selectedStatusFilter) {
            'In Workshop' => order.status == OrderStatus.inWorkshop,
            'Ready' => order.status == OrderStatus.ready,
            'Delivered' => order.status == OrderStatus.delivered,
            _ => true,
          };

          final matchesSearch =
              _searchQuery.isEmpty ||
              order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.clientFirmName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              order.itemsSummary.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          return matchesStatus && matchesSearch;
        }).toList();

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
                      hintText: 'Search by Order # or client firm...',
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                  ],
                ),
              ),
              CommonFilterChips<String>(
                options: _statusFilters,
                selected: _selectedStatusFilter,
                onSelected: (val) =>
                    setState(() => _selectedStatusFilter = val),
                labelBuilder: (val) => val,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: context.watch<OrdersBloc>().state is OrdersLoading
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
                        },
                      )
                    : CommonRefreshIndicator(
                        theme: IndicatorTheme.frontOffice,
                        onRefresh: _fetchLiveOrders,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
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
