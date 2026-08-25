import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/demo_store.dart';
import '../../../data/mappers/api_domain_mapper.dart';
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
    on<FetchFrontOfficeDataEvent>(_onFetchFrontOfficeData);
    on<CreateOrderEvent>(_onCreateOrder);
    on<CreateLiveOrderEvent>(_onCreateLiveOrder);
    on<CreateAndCheckoutOrderEvent>(_onCreateAndCheckoutOrder);
    on<AddOrderPartsEvent>(_onAddOrderParts);
    on<CheckoutOrderEvent>(_onCheckoutOrder);
    on<TrackOrderEvent>(_onTrackOrder);
    on<RegisterFrontOfficeCustomerEvent>(_onRegisterCustomer);
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

      final mappedOrders = apiOrders.map(ApiDomainMapper.order).toList();

      _store.setOrders(mappedOrders);
      emit(OrdersLoaded(orders: mappedOrders, filteredOrders: mappedOrders));
    } catch (e) {
      debugPrint('❌ [OrdersBloc] Failed to fetch orders: $e');
      emit(
        OrdersError('Failed to fetch orders from live API: ${e.toString()}'),
      );
    }
  }

  Future<void> _onFetchFrontOfficeData(
    FetchFrontOfficeDataEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      final orders = await _api.listOrders(status: '', limit: 100);
      final customers = await _api.listCustomers(limit: 100);
      final sketches = await _api.listSketches(limit: 100);
      final threeD = await _api.listThreeDDesigns(limit: 100);
      final mappedOrders = orders.map(ApiDomainMapper.order).toList();
      _store
        ..setOrders(mappedOrders)
        ..setClients(customers.map(ApiDomainMapper.customer).toList())
        ..setDesigns([
          ...sketches.map(ApiDomainMapper.sketch),
          ...threeD.map(ApiDomainMapper.threeDDesign),
        ]);
      emit(OrdersLoaded(orders: mappedOrders, filteredOrders: mappedOrders));
    } catch (error) {
      emit(OrdersError('Failed to load live front-office data: $error'));
    }
  }

  Future<void> _onCreateLiveOrder(
    CreateLiveOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      await _api.createMultiDesignOrder(
        customerId: event.customerId,
        dueDate: event.dueDate,
        specialInstructions: event.specialInstructions,
        parts: event.parts,
      );
      emit(const OrderOperationSuccess('Order created successfully.'));
      add(const FetchFrontOfficeDataEvent());
    } catch (error) {
      emit(OrdersError('Failed to create order: $error'));
    }
  }

  Future<void> _onCreateAndCheckoutOrder(
    CreateAndCheckoutOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      final order = await _api.createMultiDesignOrder(
        customerId: event.customerId,
        dueDate: event.dueDate,
        specialInstructions: event.specialInstructions,
        parts: event.parts,
      );
      if (order.id.isEmpty) {
        throw const FormatException('Order API returned an empty ID.');
      }
      await _api.checkoutOrder(order.id);
      if (event.clearCart) _store.clearCart();
      emit(
        OrderOperationSuccess(
          'Order ${order.orderNumber} created and checked out.',
        ),
      );
      add(const FetchFrontOfficeDataEvent());
    } catch (error) {
      emit(OrdersError('Failed to create and checkout order: $error'));
    }
  }

  Future<void> _onAddOrderParts(
    AddOrderPartsEvent event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _api.addOrderParts(orderId: event.orderId, parts: event.parts);
      emit(const OrderOperationSuccess('Designs added to order.'));
      add(const FetchFrontOfficeDataEvent());
    } catch (error) {
      emit(OrdersError('Failed to add order designs: $error'));
    }
  }

  Future<void> _onCheckoutOrder(
    CheckoutOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _api.checkoutOrder(event.orderId);
      emit(const OrderOperationSuccess('Order checked out successfully.'));
      add(const FetchFrontOfficeDataEvent());
    } catch (error) {
      emit(OrdersError('Failed to checkout order: $error'));
    }
  }

  Future<void> _onTrackOrder(
    TrackOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      emit(OrderTrackingLoaded(await _api.trackOrder(event.orderNumber)));
    } catch (error) {
      emit(OrdersError('Failed to track order: $error'));
    }
  }

  Future<void> _onRegisterCustomer(
    RegisterFrontOfficeCustomerEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    try {
      await _api.registerCustomer(
        name: event.name,
        city: event.city,
        contactPerson: event.contactPerson,
        phone: event.phone,
        email: event.email,
        creditLimitLakhs: event.creditLimitLakhs,
        notes: event.notes,
      );
      emit(const OrderOperationSuccess('Customer registered successfully.'));
      add(const FetchFrontOfficeDataEvent());
    } catch (error) {
      emit(OrdersError('Failed to register customer: $error'));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrderEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      const OrdersError(
        'This legacy order action has no reliable customer ID or part data. '
        'Use the live order form instead.',
      ),
    );
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(
      const OrdersError(
        'The backend does not expose a generic order status endpoint.',
      ),
    );
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
