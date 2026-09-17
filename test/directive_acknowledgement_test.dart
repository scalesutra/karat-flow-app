import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/core/network/api_client.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import 'package:jewellery_ops_mobile/features/directives/bloc/directives_bloc.dart';
import 'package:jewellery_ops_mobile/features/instructions/directives_notification_button.dart';

const directive = ApiDirective(
  id: 'directive-1',
  directiveCode: 'DIR-1',
  title: 'Process review',
  targetType: 'PROCESS_MANAGER',
  instruction: 'Review production',
);

class FakeDirectiveApi extends ApiClient {
  Object? reply;
  bool fail = false;
  int calls = 0;
  String? lastPath;
  Completer<void>? gate;

  @override
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    calls++;
    lastPath = path;
    await gate?.future;
    if (fail) throw StateError('Permission denied');
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: reply == null ? 204 : 200,
      data: reply as T?,
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async => Response<T>(
    requestOptions: RequestOptions(path: path),
    statusCode: 200,
    data:
        {
              'data': [
                {...directive.toJson(), 'id': directive.id, 'status': 'ACTIVE'},
              ],
            }
            as T,
  );
}

void main() {
  for (final reply in <Object?>[
    null,
    {'success': true, 'message': 'Acknowledged'},
    {
      'data': {'id': 'directive-1', 'status': 'ACKNOWLEDGED'},
    },
  ]) {
    test(
      'acknowledges with response $reply and preserves directive details',
      () async {
        final api = FakeDirectiveApi()..reply = reply;
        final store = DemoStore.empty()..setApiDirectives([directive]);
        final bloc = DirectivesBloc(
          store: store,
          repository: KaratFlowApiRepository(apiClient: api),
        );
        final completed = bloc.stream.firstWhere(
          (s) => s is DirectivesOperationSuccess,
        );
        bloc.add(const AcknowledgeDirectiveEvent('directive-1'));
        await completed;
        expect(store.directivesForRole(AppRole.processManager), isEmpty);
        expect(store.adminDirectives.single['content'], 'Review production');
        expect(
          store.instructions.single.status,
          InstructionStatus.acknowledged,
        );
        await bloc.close();
        store.dispose();
      },
    );
  }

  test('application-level rejection keeps the directive pending', () async {
    final api = FakeDirectiveApi()
      ..reply = {'success': false, 'message': 'Denied'};
    final store = DemoStore.empty()..setApiDirectives([directive]);
    final bloc = DirectivesBloc(
      store: store,
      repository: KaratFlowApiRepository(apiClient: api),
    );
    final failed = bloc.stream.firstWhere((s) => s is DirectivesError);
    bloc.add(const AcknowledgeDirectiveEvent('directive-1'));
    await failed;
    expect(store.directivesForRole(AppRole.processManager), hasLength(1));
    await bloc.close();
    store.dispose();
  });

  testWidgets(
    'process manager can retry a failed notification and acknowledge once',
    (tester) async {
      final api = FakeDirectiveApi()..fail = true;
      final store = DemoStore.empty()..setApiDirectives([directive]);
      final bloc = DirectivesBloc(
        store: store,
        repository: KaratFlowApiRepository(apiClient: api),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  DirectivesNotificationButton(
                    currentRole: AppRole.processManager,
                    store: store,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Acknowledged'));
      await tester.pumpAndSettle();
      expect(api.calls, 1);
      expect(api.lastPath, '/directives/directive-1/acknowledge');
      expect(bloc.state, isA<DirectivesError>());
      expect(
        (bloc.state as DirectivesError).message,
        contains('Permission denied'),
      );
      expect(find.textContaining('Permission denied'), findsOneWidget);
      expect(store.directivesForRole(AppRole.processManager), hasLength(1));

      api.fail = false;
      api.gate = Completer<void>();
      await tester.tap(find.text('Mark as Acknowledged'));
      await tester.pump();
      expect(find.text('Acknowledging…'), findsOneWidget);
      await tester.tap(find.text('Acknowledging…'));
      await tester.pump();
      expect(api.calls, 2);
      api.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('No Pending Directives'), findsOneWidget);
      expect(store.directivesForRole(AppRole.processManager), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await bloc.close();
      store.dispose();
    },
  );
}
