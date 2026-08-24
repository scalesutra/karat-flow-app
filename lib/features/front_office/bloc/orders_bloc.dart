import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/demo_store.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'orders_event.dart';
import 'orders_state.dart';

export 'orders_event.dart';
export 'orders_state.dart';

/// Orders BLoC with Strict Live Backend Order APIs (/orders) & Debug Logs
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({required DemoStore store, KaratFlowApiRepository? apiRepository})
    : _store = store,
      _api = apiRepository ?? KaratFlowApiRepository(),
      super(const OrdersInitial()) {
    on<FetchOrdersEvent>(_onFetchOrders);
    on<CreateOrderEvent>(_onCreateOrder);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<FilterOrdersEvent>(_onFilterOrders);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;

  Future<void> _onFetchOrders(
    FetchOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    debugPrint(
      '📦 [OrdersBloc] Fetching orders from GET /orders?status=${event.statusFilter ?? 'IN_PRODUCTION'}...',
    );
    try {
      final apiOrders = await _api.listOrders(status: event.statusFilter ?? '');

      debugPrint(
        '✅ [OrdersBloc] Received ${apiOrders.length} orders from live API.',
      );

      final mappedOrders = apiOrders.map((ao) {
        final firstPart = ao.parts.isNotEmpty ? ao.parts.first : null;
        return CustomerOrder(
          id: ao.orderNumber,
          clientFirmName: ao.customerName.isNotEmpty
              ? ao.customerName
              : 'Client Order',
          clientCity: 'Jaipur',
          itemsCount: ao.parts.fold(0, (sum, part) => sum + part.quantity),
          totalGrossGrams: firstPart?.grossWeight ?? 0.0,
          estimatedTotalAmount: 0,
          status: ao.status == 'CHECKED_OUT'
              ? OrderStatus.ready
              : OrderStatus.inWorkshop,
          promiseDate: 'Due Date',
          createdAt: DateTime.now(),
          itemsSummary: ao.parts
              .map((p) => '${p.quantity}x ${p.designNumber}')
              .join(', '),
          currentWorkshopStage: firstPart?.currentStage ?? '',
          responsibleManager: '',
        );
      }).toList();

      emit(OrdersLoaded(orders: mappedOrders, filteredOrders: mappedOrders));
    } catch (e) {
      debugPrint('❌ [OrdersBloc] Failed to fetch orders: $e');
      emit(
        OrdersError('Failed to fetch orders from live API: ${e.toString()}'),
      );
    }
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    debugPrint(
      '📝 [OrdersBloc] Creating multi-design order on POST /orders for ${event.order.clientFirmName}...',
    );
    try {
      final designName = event.order.itemsSummary.isNotEmpty
          ? event.order.itemsSummary
          : 'Custom Design';
      await _api.createMultiDesignOrder(
        customerId: event.order.clientFirmName.isNotEmpty
            ? event.order.clientFirmName
            : 'client-general',
        dueDate: event.order.promiseDate,
        specialInstructions: event.order.itemsSummary,
        parts: [
          {
            'designNumber': designName,
            'quantity': event.order.itemsCount > 0 ? event.order.itemsCount : 1,
            'grossWeight': event.order.totalGrossGrams,
            'notes': event.order.itemsSummary,
          },
        ],
      );

      debugPrint('🎉 [OrdersBloc] Order placed successfully on live backend!');
      emit(
        OrderOperationSuccess(
          'Order ${event.order.id} placed successfully on server.',
        ),
      );
      add(const FetchOrdersEvent());
    } catch (e) {
      debugPrint('❌ [OrdersBloc] Failed to create order: $e');
      emit(OrdersError('Failed to create order on live API: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      _store.updateOrderStatus(event.orderId, event.status);
      emit(
        OrderOperationSuccess(
          'Order ${event.orderId} updated to ${event.status.label}.',
        ),
      );
      add(const FetchOrdersEvent());
    } catch (e) {
      emit(OrdersError('Failed to update status: ${e.toString()}'));
    }
  }

  void _onFilterOrders(FilterOrdersEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final current = state as OrdersLoaded;
      final filtered = current.orders.where((order) {
        final matchesStatus = switch (event.statusFilter) {
          'In Workshop' => order.status == OrderStatus.inWorkshop,
          'Ready' => order.status == OrderStatus.ready,
          'Delivered' => order.status == OrderStatus.delivered,
          _ => true,
        };

        final matchesSearch =
            event.query.isEmpty ||
            order.id.toLowerCase().contains(event.query.toLowerCase()) ||
            order.clientFirmName.toLowerCase().contains(
              event.query.toLowerCase(),
            ) ||
            order.itemsSummary.toLowerCase().contains(
              event.query.toLowerCase(),
            );

        return matchesStatus && matchesSearch;
      }).toList();

      emit(
        OrdersLoaded(
          orders: current.orders,
          filteredOrders: filtered,
          selectedFilter: event.statusFilter,
          searchQuery: event.query,
        ),
      );
    }
  }
}
