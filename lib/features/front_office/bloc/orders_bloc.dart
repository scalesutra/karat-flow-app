import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/network/token_storage_service.dart';
import 'package:jewellery_ops_mobile/core/services/app_local_cache_service.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import '../../../core/network/token_storage_service.dart';
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
  final TokenStorageService _tokenStorage = TokenStorageService();

  Future<void> _onFetchOrders(
    FetchOrdersEvent event,
    Emitter<OrdersState> emit,
  ) async {
    final tokenRole = (await _tokenStorage.getUserRole())?.toUpperCase() ?? '';
    final isWorkerRole =
        _store.activeRole == AppRole.worker ||
        _store.activeRole == AppRole.workshopArtisan ||
        tokenRole == 'CRAFTSMAN' ||
        tokenRole == 'WORKER' ||
        tokenRole == 'ARTISAN';

    if (isWorkerRole) {
      emit(OrdersLoaded(orders: _store.orders, filteredOrders: _store.orders));
      return;
    }

    emit(const OrdersLoading());
    try {
      final apiOrders = await _api.listOrders(status: event.statusFilter ?? '');

      final mappedOrders = apiOrders.map(ApiDomainMapper.order).toList();

      _store.setOrders(mappedOrders);
      emit(OrdersLoaded(orders: mappedOrders, filteredOrders: mappedOrders));
    } catch (e) {
      if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        emit(
          OrdersLoaded(orders: _store.orders, filteredOrders: _store.orders),
        );
        return;
      }
      emit(
        OrdersError('Failed to fetch orders from live API: ${e.toString()}'),
      );
    }
  }

  Future<void> _onFetchFrontOfficeData(
    FetchFrontOfficeDataEvent event,
    Emitter<OrdersState> emit,
  ) async {
    // ── 0. Stale-While-Revalidate: Instant Local Cache Load ─────────
    try {
      final cachedThreeD = await AppLocalCacheService.instance
          .getCachedThreeDDesigns();
      final cachedSketches = await AppLocalCacheService.instance
          .getCachedSketches();
      final cachedCustomers = await AppLocalCacheService.instance
          .getCachedCustomers();
      final cachedOrders = await AppLocalCacheService.instance
          .getCachedOrders();

      if (cachedThreeD.isNotEmpty ||
          cachedSketches.isNotEmpty ||
          cachedCustomers.isNotEmpty ||
          cachedOrders.isNotEmpty) {
        if (cachedCustomers.isNotEmpty) {
          _store.setClients(
            cachedCustomers.map(ApiDomainMapper.customer).toList(),
          );
        }
        if (cachedThreeD.isNotEmpty || cachedSketches.isNotEmpty) {
          final cachedCatalogue = _buildCatalogue(cachedThreeD, cachedSketches);
          _store.setDesigns(cachedCatalogue);
        }
        if (cachedOrders.isNotEmpty) {
          final mapped = cachedOrders.map(ApiDomainMapper.order).toList();
          _store.setOrders(mapped);
          emit(OrdersLoaded(orders: mapped, filteredOrders: mapped));
        } else if (_store.designs.isNotEmpty) {
          emit(
            OrdersLoaded(orders: _store.orders, filteredOrders: _store.orders),
          );
        }
      } else {
        emit(const OrdersLoading());
      }
    } catch (_) {
      emit(const OrdersLoading());
    }

    // ── 1. Live Fetch from KaratFlow Server ───────────────────────────
    try {
      final orders = await _api.listOrders(status: '', limit: 200);
      final customers = await _api.listCustomers(limit: 200);
      final sketches = await _api.listAllSketches(status: '');
      final threeD = await _api.listAllThreeDDesigns(status: '');

      final catalogueDesigns = _buildCatalogue(threeD, sketches);

      _store
        ..setClients(customers.map(ApiDomainMapper.customer).toList())
        ..setDesigns(catalogueDesigns);

      final mappedOrders = orders.map(ApiDomainMapper.order).toList();
      _store.setOrders(mappedOrders);

      emit(OrdersLoaded(orders: mappedOrders, filteredOrders: mappedOrders));

      // ── 2. Persist to Local Storage Cache for Fast Subsequent Loads ─
      AppLocalCacheService.instance.saveThreeDDesigns(threeD);
      AppLocalCacheService.instance.saveSketches(sketches);
      AppLocalCacheService.instance.saveCustomers(customers);
      AppLocalCacheService.instance.saveOrders(orders);
    } catch (error) {
      if (_store.designs.isNotEmpty || _store.orders.isNotEmpty) {
        emit(
          OrdersLoaded(orders: _store.orders, filteredOrders: _store.orders),
        );
      } else {
        emit(OrdersError('Failed to load live front-office data: $error'));
      }
    }
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
