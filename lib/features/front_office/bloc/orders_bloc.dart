import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/network/token_storage_service.dart';
import 'package:jewellery_ops_mobile/core/services/app_local_cache_service.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import '../../../data/demo_store.dart';
import '../../../data/mappers/api_domain_mapper.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'orders_event.dart';
import 'orders_state.dart';

export 'orders_event.dart';
export 'orders_state.dart';

/// Orders BLoC with Strict Live Backend Order APIs (/orders)
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({
    required DemoStore store,
    KaratFlowApiRepository? apiRepository,
    TokenStorageService? tokenStorage,
  }) : _store = store,
       _api = apiRepository ?? KaratFlowApiRepository(),
       _tokenStorage = tokenStorage ?? TokenStorageService(),
       super(const OrdersInitial()) {
    on<FetchOrdersEvent>(_onFetchOrders);
    on<FetchFrontOfficeDataEvent>(_onFetchFrontOfficeData);
    on<FetchDesignsCatalogEvent>(_onFetchDesignsCatalog);
    on<FetchCustomersEvent>(_onFetchCustomers);
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
  final TokenStorageService _tokenStorage;
  int _ordersRequest = 0;
  String _orderStatus = '';
  String _orderSearch = '';

  Future<void> _onFetchOrders(
    FetchOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final previous = state is OrdersLoaded ? state as OrdersLoaded : null;
    if (event.loadMore &&
        (previous == null || !previous.hasMore || previous.isLoadingMore)) {
      return;
    }
    final request = ++_ordersRequest;
    if (!event.loadMore) {
      _orderStatus = event.statusFilter ?? _orderStatus;
      _orderSearch = event.search?.trim() ?? _orderSearch;
    }
    final status = _orderStatus;
    final search = _orderSearch;
    final page = event.loadMore ? previous!.page + 1 : 1;
    OrdersLoaded loaded(
      List<CustomerOrder> orders, {
      required int page,
      required bool hasMore,
      bool loadingMore = false,
      String? error,
    }) => OrdersLoaded(
      orders: orders,
      filteredOrders: orders,
      page: page,
      hasMore: hasMore,
      isLoadingMore: loadingMore,
      pageError: error,
      searchQuery: search,
      selectedFilter: status.isEmpty ? 'All' : status,
    );
    if (event.loadMore) {
      emit(
        loaded(
          previous!.orders,
          page: previous.page,
          hasMore: true,
          loadingMore: true,
        ),
      );
    } else if (previous != null) {
      // Keep existing orders visible on background search / filter refresh
      // Do not clear the UI with OrdersLoading()
      emit(
        loaded(
          previous.orders,
          page: 1,
          hasMore: previous.hasMore,
        ),
      );
    } else {
      emit(const OrdersLoading());
    }
    try {
      final role = (await _tokenStorage.getUserRole())?.toUpperCase() ?? '';
      if (request != _ordersRequest || emit.isDone) return;
      if (_store.activeRole == AppRole.worker ||
          _store.activeRole == AppRole.workshopArtisan ||
          {'CRAFTSMAN', 'WORKER', 'ARTISAN'}.contains(role)) {
        throw StateError(
          'Order search is available to admins, front office and managers only.',
        );
      }
      final result = await _api.listOrdersPage(
        status: status,
        search: search,
        page: page,
        limit: 50,
      );
      if (request != _ordersRequest || emit.isDone) return;
      if (result.page != page) {
        throw const FormatException('Unexpected order page returned.');
      }
      final newOrders = result.orders.map(ApiDomainMapper.order).toList();
      final merged = <String, CustomerOrder>{
        if (event.loadMore && previous != null)
          for (final order in previous.orders)
            order.apiId.isNotEmpty ? order.apiId : order.id: order,
        for (final order in newOrders)
          order.apiId.isNotEmpty ? order.apiId : order.id: order,
      }.values.toList();
      if (search.isEmpty && status.isEmpty) {
        _store.setOrders(merged);
      } else {
        _store.upsertOrders(newOrders);
      }
      emit(loaded(merged, page: result.page, hasMore: result.hasMore));
    } catch (error) {
      if (request != _ordersRequest || emit.isDone) return;
      if (event.loadMore) {
        emit(
          loaded(
            previous!.orders,
            page: previous.page,
            hasMore: true,
            error: 'Could not load the next page: $error',
          ),
        );
      } else {
        emit(OrdersError('Failed to fetch orders from live API: $error'));
      }
    }
  }

  Future<void> _onFetchFrontOfficeData(
    FetchFrontOfficeDataEvent event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());

    // ── 1. Live Fetch from KaratFlow Server ───────────────────────────
    try {
      final customers = await _api.listCustomers(limit: 200);
      final sketches = await _api.listAllSketches(status: '');

      // ── Customer Catalog (Public endpoint: /three-d-designs/catalog) ───
      List<ApiThreeDDesign> threeD = await _api.listAllCatalog();
      if (threeD.isEmpty) {
        threeD = await _api.listAllThreeDDesigns(status: '');
      }

      final catalogueDesigns = _buildCatalogue(threeD, sketches);

      _store
        ..setClients(customers.map(ApiDomainMapper.customer).toList())
        ..setDesigns(catalogueDesigns);

      add(const FetchOrdersEvent());

      // ── 2. Persist to Local Storage Cache for Fast Subsequent Loads ─
      AppLocalCacheService.instance.saveThreeDDesigns(threeD);
      AppLocalCacheService.instance.saveSketches(sketches);
      AppLocalCacheService.instance.saveCustomers(customers);
    } catch (error) {
      emit(OrdersError('Failed to load live front-office data: $error'));
    }
  }

  Future<void> _onFetchDesignsCatalog(
    FetchDesignsCatalogEvent event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final sketches = await _api.listAllSketches(status: '');
      List<ApiThreeDDesign> threeD = await _api.listAllCatalog();
      if (threeD.isEmpty) {
        threeD = await _api.listAllThreeDDesigns(status: '');
      }
      final catalogueDesigns = _buildCatalogue(threeD, sketches);
      _store.setDesigns(catalogueDesigns);
      AppLocalCacheService.instance.saveThreeDDesigns(threeD);
      AppLocalCacheService.instance.saveSketches(sketches);
    } catch (_) {}
  }

  Future<void> _onFetchCustomers(
    FetchCustomersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      final customers = await _api.listCustomers(limit: 200);
      _store.setClients(customers.map(ApiDomainMapper.customer).toList());
      AppLocalCacheService.instance.saveCustomers(customers);
    } catch (_) {}
  }

  List<JewelleryDesign> _buildCatalogue(
    List<ApiThreeDDesign> threeD,
    List<ApiSketch> sketches,
  ) {
    final seenDesignKeys = <String>{};
    final catalogueDesigns = <JewelleryDesign>[];

    // 1. Add finished 3D CAD designs (exclude REJECTED)
    for (final t in threeD) {
      final isExcluded = t.status.toUpperCase() == 'REJECTED';
      if (!isExcluded) {
        ApiSketch? linkedSketch = t.sketch;
        final currentSketchUrl =
            linkedSketch?.sketchUrl.trim().toLowerCase() ?? '';
        if (linkedSketch == null ||
            currentSketchUrl.isEmpty ||
            currentSketchUrl.startsWith('blob:')) {
          linkedSketch =
              sketches.where((s) {
                final matchById =
                    t.sketchId.isNotEmpty &&
                    s.id.toLowerCase().trim() ==
                        t.sketchId.toLowerCase().trim();
                final matchByNum =
                    (t.sketch?.designNumber.isNotEmpty == true &&
                        s.designNumber.toLowerCase().trim() ==
                            t.sketch!.designNumber.toLowerCase().trim()) ||
                    (t.sketchId.isNotEmpty &&
                        s.designNumber.toLowerCase().trim() ==
                            t.sketchId.toLowerCase().trim());
                final matchByTitle =
                    (t.sketch?.title.isNotEmpty == true &&
                    s.title.toLowerCase().trim() ==
                        t.sketch!.title.toLowerCase().trim());
                final isMatch = matchById || matchByNum || matchByTitle;
                final sUrl = s.sketchUrl.trim().toLowerCase();
                return isMatch && sUrl.isNotEmpty && !sUrl.startsWith('blob:');
              }).firstOrNull ??
              linkedSketch;
        }

        final effectiveThreeD =
            (linkedSketch != null &&
                (t.sketch == null ||
                    t.sketch!.sketchUrl.isEmpty ||
                    t.sketch!.sketchUrl.toLowerCase().startsWith('blob:')))
            ? ApiThreeDDesign(
                id: t.id,
                sketchId: t.sketchId,
                totalWeight: t.totalWeight,
                status: t.status,
                version: t.version,
                xtlFileUrl: t.xtlFileUrl,
                bomFileUrl: t.bomFileUrl,
                gemQuantity: t.gemQuantity,
                goldQuantity: t.goldQuantity,
                otherMetalsQuantity: t.otherMetalsQuantity,
                volumeMm3: t.volumeMm3,
                sizeDimensions: t.sizeDimensions,
                makingCode: t.makingCode,
                gemWeightTw: t.gemWeightTw,
                gemBreakdown: t.gemBreakdown,
                adminInstructions: t.adminInstructions,
                feedbackAudioUrl: t.feedbackAudioUrl,
                feedbackImageUrl: t.feedbackImageUrl,
                sketch: linkedSketch,
                designer: t.designer,
                category: t.category,
                stock: t.stock,
                stockStatus: t.stockStatus,
                price: t.price,
                calculatedPrice: t.calculatedPrice,
                priceBreakdown: t.priceBreakdown,
                description: t.description,
                imageUrl: t.imageUrl,
                renderImageUrl: t.renderImageUrl,
                cleanDesignUrl: t.cleanDesignUrl,
              )
            : t;

        catalogueDesigns.add(ApiDomainMapper.threeDDesign(effectiveThreeD));
        if (t.sketchId.isNotEmpty) seenDesignKeys.add(t.sketchId);
        if (t.sketch?.id.isNotEmpty == true) {
          seenDesignKeys.add(t.sketch!.id);
        }
        if (linkedSketch?.id.isNotEmpty == true) {
          seenDesignKeys.add(linkedSketch!.id);
        }
        if (t.sketch?.designNumber.isNotEmpty == true) {
          seenDesignKeys.add(t.sketch!.designNumber.toLowerCase().trim());
        }
        if (linkedSketch?.designNumber.isNotEmpty == true) {
          seenDesignKeys.add(linkedSketch!.designNumber.toLowerCase().trim());
        }
        if (t.id.isNotEmpty) seenDesignKeys.add(t.id);
      }
    }

    // 2. Add all 2D Sketches that do NOT already have a 3D CAD design (exclude REJECTED)
    for (final s in sketches) {
      final isExcluded = s.status.toUpperCase() == 'REJECTED';
      final isDuplicate =
          seenDesignKeys.contains(s.id) ||
          seenDesignKeys.contains(s.designNumber.toLowerCase().trim());
      if (!isExcluded && !isDuplicate) {
        catalogueDesigns.add(ApiDomainMapper.sketch(s));
        if (s.id.isNotEmpty) seenDesignKeys.add(s.id);
        if (s.designNumber.isNotEmpty) {
          seenDesignKeys.add(s.designNumber.toLowerCase().trim());
        }
      }
    }

    return catalogueDesigns;
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
      add(const FetchOrdersEvent());
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
      add(const FetchOrdersEvent());
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
      add(const FetchOrdersEvent());
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
      add(const FetchOrdersEvent());
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
      add(const FetchCustomersEvent());
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
    add(
      FetchOrdersEvent(
        search: event.query,
        statusFilter: event.statusFilter == 'All' ? '' : event.statusFilter,
      ),
    );
  }
}
