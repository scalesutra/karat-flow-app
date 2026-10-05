import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/core/network/api_client.dart';
import 'package:jewellery_ops_mobile/core/network/api_endpoints.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';

class IssueClient extends ApiClient {
  IssueClient(this.result, {this.fail = false});
  final Map<String, dynamic> result;
  final bool fail;
  String? requestedPath;
  Object? payload;
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    requestedPath = path;
    payload = data;
    if (fail) throw DioException(requestOptions: RequestOptions(path: path));
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: {'data': result} as T,
    );
  }
}

void main() {
  const items = [
    {'category': 'STONE', 'quantity': 790, 'unit': 'pc'},
  ];
  test(
    'only matching backend issuance confirms success and sends total stones',
    () async {
      final client = IssueClient({
        'id': 'issue',
        'orderPartId': 'part',
        'status': 'ISSUED',
      });
      final issued = await KaratFlowApiRepository(
        apiClient: client,
      ).issueMaterialsForOrderPart('part', items: items);
      expect(issued.status, 'ISSUED');
      expect(
        client.requestedPath,
        ApiEndpoints.issueOrderPartMaterials('part'),
      );
      expect((client.payload as Map)['items'], items);
    },
  );
  test(
    'missing status, pending status and wrong part cannot become issued',
    () async {
      for (final result in [
        {'id': 'issue', 'orderPartId': 'part'},
        {'id': 'issue', 'orderPartId': 'part', 'status': 'PENDING'},
        {'id': 'issue', 'orderPartId': 'other', 'status': 'ISSUED'},
      ]) {
        await expectLater(
          KaratFlowApiRepository(
            apiClient: IssueClient(result),
          ).issueMaterialsForOrderPart('part', items: items),
          throwsFormatException,
        );
      }
    },
  );
  test('API failure remains a failure', () async {
    await expectLater(
      KaratFlowApiRepository(
        apiClient: IssueClient({}, fail: true),
      ).issueMaterialsForOrderPart('part', items: items),
      throwsA(isA<DioException>()),
    );
  });
}
