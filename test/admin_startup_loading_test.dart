import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/core/network/api_client.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import 'package:jewellery_ops_mobile/features/admin/bloc/admin_bloc.dart';

class _StartupClient extends ApiClient {
  _StartupClient({this.fail = false});
  final bool fail;
  final paths = <String>[];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    paths.add(path);
    if (fail) throw StateError('Offline');
    if (path != '/orders') throw StateError('Unexpected startup API: $path');
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data:
          {
                'data': [
                  {
                    'id': 'order-1',
                    'orderNumber': 'ORD-1',
                    'status': 'IN_PRODUCTION',
                    'parts': <dynamic>[],
                  },
                ],
              }
              as T,
    );
  }
}

void main() {
  for (final fail in [false, true]) {
    test(
      'admin overview loads orders independently (failure: $fail)',
      () async {
        final client = _StartupClient(fail: fail);
        final store = DemoStore.empty();
        final bloc = AdminBloc(
          store: store,
          apiRepository: KaratFlowApiRepository(apiClient: client),
        );
        final states = <AdminState>[];
        final subscription = bloc.stream.listen(states.add);
        final completed = bloc.stream.firstWhere(
          (state) => state is AdminLoaded || state is AdminError,
        );
        bloc.add(const FetchAdminDashboardEvent(overviewOnly: true));
        final result = await completed;
        expect(states.first, isA<AdminLoading>());
        expect(client.paths, ['/orders']);
        expect(result, fail ? isA<AdminError>() : isA<AdminLoaded>());
        expect(store.orders.length, fail ? 0 : 1);
        await subscription.cancel();
        await bloc.close();
        store.dispose();
      },
    );
  }
}
