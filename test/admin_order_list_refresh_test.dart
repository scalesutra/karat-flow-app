import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/features/status/admin_status_page.dart';
import 'package:jewellery_ops_mobile/features/admin/bloc/admin_bloc.dart';
import 'package:jewellery_ops_mobile/features/front_office/bloc/orders_bloc.dart';
import 'package:jewellery_ops_mobile/features/workshop/bloc/workshop_bloc.dart';
import 'package:jewellery_ops_mobile/features/cad_designer/bloc/cad_bloc.dart';
import 'package:jewellery_ops_mobile/features/materials/bloc/materials_bloc.dart';
import 'package:jewellery_ops_mobile/features/inventory/bloc/inventory_bloc.dart';
import 'package:jewellery_ops_mobile/features/directives/bloc/directives_bloc.dart';

class _RecordingBloc<E, S> extends Fake implements Bloc<E, S> {
  _RecordingBloc(this.state);

  @override
  final S state;
  final events = <E>[];
  final controller = StreamController<S>.broadcast();

  @override
  Stream<S> get stream => controller.stream;

  @override
  void add(E event) => events.add(event);
}

class _AdminBloc extends _RecordingBloc<AdminEvent, AdminState>
    implements AdminBloc {
  _AdminBloc() : super(const AdminInitial());
}

class _OrdersBloc extends _RecordingBloc<OrdersEvent, OrdersState>
    implements OrdersBloc {
  _OrdersBloc() : super(const OrdersInitial());
}

class _WorkshopBloc extends _RecordingBloc<WorkshopEvent, WorkshopState>
    implements WorkshopBloc {
  _WorkshopBloc() : super(const WorkshopInitial());
}

class _CadBloc extends _RecordingBloc<CadEvent, CadState> implements CadBloc {
  _CadBloc() : super(const CadInitial());
}

class _MaterialsBloc extends _RecordingBloc<MaterialsEvent, MaterialsState>
    implements MaterialsBloc {
  _MaterialsBloc() : super(const MaterialsInitial());
}

class _InventoryBloc extends _RecordingBloc<InventoryEvent, InventoryState>
    implements InventoryBloc {
  _InventoryBloc() : super(const InventoryInitial());
}

class _DirectivesBloc extends _RecordingBloc<DirectivesEvent, DirectivesState>
    implements DirectivesBloc {
  _DirectivesBloc() : super(const DirectivesInitial());
}

void main() {
  testWidgets('admin orders remain visible while refresh completes', (
    tester,
  ) async {
    final admin = _AdminBloc();
    final orders = _OrdersBloc();
    final workshop = _WorkshopBloc();
    final cad = _CadBloc();
    final materials = _MaterialsBloc();
    final inventory = _InventoryBloc();
    final directives = _DirectivesBloc();
    final store = DemoStore.empty();
    final initialOrders = List.generate(
      12,
      (index) => ApiDomainMapper.order(
        ApiOrder.fromJson({
          'id': 'order-$index',
          'orderNumber': 'ORD-$index',
          'status': 'IN_PRODUCTION',
          'parts': <dynamic>[],
        }),
      ),
    );
    addTearDown(() async {
      await Future.wait([
        admin.controller.close(),
        orders.controller.close(),
        workshop.controller.close(),
        cad.controller.close(),
        materials.controller.close(),
        inventory.controller.close(),
        directives.controller.close(),
      ]);
      store.dispose();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AdminBloc>.value(value: admin),
          BlocProvider<OrdersBloc>.value(value: orders),
          BlocProvider<WorkshopBloc>.value(value: workshop),
          BlocProvider<CadBloc>.value(value: cad),
          BlocProvider<MaterialsBloc>.value(value: materials),
          BlocProvider<InventoryBloc>.value(value: inventory),
          BlocProvider<DirectivesBloc>.value(value: directives),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, child) => MaterialApp(
            home: Scaffold(body: AdminStatusPage(store: store)),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(admin.events.whereType<FetchAdminDashboardEvent>(), hasLength(1));
    expect(
      (admin.events.single as FetchAdminDashboardEvent).overviewOnly,
      isTrue,
    );
    expect(orders.events, isEmpty);
    expect(materials.events, isEmpty);
    expect(inventory.events, isEmpty);
    expect(find.text('Loading orders...'), findsOneWidget);
    admin.controller.add(const AdminError('Offline'));
    await tester.pump();
    expect(find.text('Could not load orders'), findsOneWidget);
    store.setOrders(initialOrders);
    admin.controller.add(
      const AdminLoaded(team: [], clients: [], designs: [], directives: []),
    );
    await tester.pump();
    expect(find.text('Loading orders...'), findsNothing);

    final scrollable = find.byType(CustomScrollView);
    await tester.fling(scrollable, const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    expect(admin.events, hasLength(1));
    expect(store.orders, hasLength(12));

    // An intentional refresh must retain the list until the response arrives.
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    var finished = false;
    final pending = refresh.onRefresh().then((_) => finished = true);
    admin.controller.add(const AdminLoading());
    await tester.pump(const Duration(seconds: 1));

    expect(finished, isFalse);
    expect(scrollable, findsOneWidget);
    expect(store.orders, hasLength(12));
    expect(orders.events, isEmpty);
    expect(admin.events, hasLength(2));

    admin.controller.add(
      const AdminLoaded(team: [], clients: [], designs: [], directives: []),
    );
    await tester.pump();
    await pending;
    expect(finished, isTrue);
    expect(scrollable, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
