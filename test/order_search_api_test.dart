import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/core/network/api_client.dart';
import 'package:jewellery_ops_mobile/core/network/api_endpoints.dart';
import 'package:jewellery_ops_mobile/core/network/token_storage_service.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import 'package:jewellery_ops_mobile/features/front_office/bloc/orders_bloc.dart';

class SearchClient extends ApiClient {
  final requests = <Map<String, dynamic>>[];
  final responses = <Completer<Response<dynamic>>>[];
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    expect(path, ApiEndpoints.orders);
    requests.add(queryParameters!);
    final response = Completer<Response<dynamic>>();
    responses.add(response);
    return await response.future as Response<T>;
  }

  void complete(
    int index, {
    String id = 'live-order',
    int page = 1,
    int totalPages = 1,
  }) {
    responses[index].complete(
      Response(
        requestOptions: RequestOptions(path: ApiEndpoints.orders),
        data: {
          'success': true,
          'data': [
            {'id': id, 'orderNumber': id, 'parts': []},
          ],
          'pagination': {
            'page': page,
            'limit': 50,
            'total': totalPages,
            'totalPages': totalPages,
          },
        },
      ),
    );
  }
}

class AdminTokenStorage extends TokenStorageService {
  @override
  Future<String?> getUserRole() async => 'ADMIN';
}

Future<void> pumpRequests(SearchClient client, int count) async {
  for (var i = 0; i < 100 && client.requests.length < count; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(client.requests.length, count);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sends all documented filters and uses pagination metadata', () async {
    final client = SearchClient();
    final future = KaratFlowApiRepository(apiClient: client).listOrdersPage(
      search: '  9876543210  ',
      status: 'IN_PRODUCTION',
      stage: 'Casting',
      stageId: 'stage-id',
      isBlocked: false,
      customerId: 'customer-id',
      page: 2,
      limit: 20,
    );
    expect(client.requests.single, {
      'search': '9876543210',
      'status': 'IN_PRODUCTION',
      'stage': 'Casting',
      'stageId': 'stage-id',
      'isBlocked': false,
      'customerId': 'customer-id',
      'page': 2,
      'limit': 20,
    });
    client.complete(0, page: 2, totalPages: 2);
    expect((await future).hasMore, isFalse);
  });
  test('malformed response is an error, never an empty fallback', () {
    expect(() => ApiOrdersPage.fromJson({'data': 'invalid_not_a_list'}), throwsFormatException);
    expect(() => ApiOrdersPage.fromJson({'success': false}), throwsFormatException);
  });
  test('tracking identifier is safely encoded', () {
    expect(
      ApiEndpoints.orderTrack(' ORD/2026 #1 '),
      '/orders/track/ORD%2F2026%20%231',
    );
  });
  test(
    'latest query wins, pagination retains search, and failure shows error',
    () async {
      final client = SearchClient();
      final bloc = OrdersBloc(
        store: DemoStore.instance,
        apiRepository: KaratFlowApiRepository(apiClient: client),
        tokenStorage: AdminTokenStorage(),
      );
      addTearDown(bloc.close);
      bloc.add(const FetchOrdersEvent(search: 'old'));
      await pumpRequests(client, 1);
      bloc.add(
        const FetchOrdersEvent(search: 'NK-842', statusFilter: 'IN_PRODUCTION'),
      );
      await pumpRequests(client, 2);
      final loaded = bloc.stream.firstWhere((s) => s is OrdersLoaded);
      client.complete(1, id: 'new', totalPages: 2);
      await loaded;
      client.complete(0, id: 'old');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((bloc.state as OrdersLoaded).orders.single.apiId, 'new');
      bloc.add(const FetchOrdersEvent(loadMore: true));
      await pumpRequests(client, 3);
      expect(client.requests[2]['search'], 'NK-842');
      expect(client.requests[2]['status'], 'IN_PRODUCTION');
      expect(client.requests[2]['page'], 2);
      final next = bloc.stream.firstWhere(
        (s) => s is OrdersLoaded && s.page == 2,
      );
      client.complete(2, id: 'next', page: 2, totalPages: 2);
      expect((await next as OrdersLoaded).hasMore, isFalse);
      bloc.add(const FetchOrdersEvent(search: ''));
      await pumpRequests(client, 4);
      expect(client.requests[3].containsKey('search'), isFalse);
      expect(client.requests[3]['page'], 1);
      final failed = bloc.stream.firstWhere((s) => s is OrdersError);
      client.responses[3].completeError(StateError('403 Forbidden'));
      expect(await failed, isA<OrdersError>());
    },
  );
}
