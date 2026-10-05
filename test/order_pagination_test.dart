import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/core/network/api_client.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';

class PagedOrdersClient extends ApiClient {
  PagedOrdersClient(this.rows, {this.failPage, this.repeatPage = false});

  final List<Map<String, dynamic>> rows;
  final int? failPage;
  final bool repeatPage;
  final queries = <Map<String, dynamic>>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final query = Map<String, dynamic>.from(queryParameters!);
    queries.add(query);
    final page = query['page'] as int;
    if (page == failPage) throw StateError('Page failed');
    // Simulate a server that caps pages at 50 despite a larger request.
    final start = repeatPage ? 0 : (page - 1) * 50;
    final body = {'data': rows.skip(start).take(50).toList()};
    return Response<T>(
      data: body as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}

List<Map<String, dynamic>> orders(int count) => List.generate(
  count,
  (i) => {
    'id': 'order-$i',
    'orderNumber': 'ORD-$i',
    'status': 'IN_PRODUCTION',
    'parts': [
      {
        'id': 'part-$i',
        'quantity': 1,
        'assignments': [
          {'id': 'assignment-$i'},
        ],
      },
    ],
  },
);

void main() {
  test('loads beyond 50 and 100 even when the server caps page size', () async {
    final client = PagedOrdersClient(orders(123));
    final result = await KaratFlowApiRepository(
      apiClient: client,
    ).listAllOrders(status: 'IN_PRODUCTION');
    expect(result.length, 123);
    expect(result.last.id, 'order-122');
    expect(client.queries.map((q) => q['page']), [1, 2, 3, 4]);
    expect(client.queries.every((q) => q['status'] == 'IN_PRODUCTION'), isTrue);
  });

  test('restores assigned parts from orders beyond the first 100', () async {
    final client = PagedOrdersClient(orders(123));
    final parts = await KaratFlowApiRepository(
      apiClient: client,
    ).listOrderPartsRaw();
    expect(parts.length, 123);
    expect(parts.last['_orderId'], 'order-122');
    expect(parts.last['_orderNumber'], 'ORD-122');
    expect(parts.last['assignments'], [
      {'id': 'assignment-122'},
    ]);
  });

  test(
    'does not return a silently truncated list when a later page fails',
    () async {
      final client = PagedOrdersClient(orders(123), failPage: 2);
      await expectLater(
        KaratFlowApiRepository(apiClient: client).listAllOrders(),
        throwsStateError,
      );
    },
  );

  test(
    'fails instead of looping forever when the server repeats a page',
    () async {
      final client = PagedOrdersClient(orders(50), repeatPage: true);
      await expectLater(
        KaratFlowApiRepository(apiClient: client).listAllOrders(),
        throwsFormatException,
      );
      expect(client.queries.length, 2);
    },
  );

  test('empty order collection terminates after one request', () async {
    final client = PagedOrdersClient([]);
    expect(
      await KaratFlowApiRepository(apiClient: client).listAllOrders(),
      isEmpty,
    );
    expect(client.queries.length, 1);
  });
}
