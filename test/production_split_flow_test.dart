import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';

import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import 'package:jewellery_ops_mobile/features/workshop/bloc/workshop_bloc.dart';

const partId = 'c4b8e21a-7b32-4d10-9e81-229ef5e01b34';
const stageId = 'a1f2b3c4-d5e6-4f8a-9b0c-1d2e3f4a5b6c';
const employeeId = 'f8e7d6c5-b4a3-410f-adcb-a98765432100';

class TransitionApi extends KaratFlowApiRepository {
  final transition = Completer<Map<String, dynamic>?>();
  final assigned = Completer<void>();
  List<String>? assignedParts;
  int? assignedQuantity;
  String? assignedStage;

  @override
  Future<Map<String, dynamic>?> transitionPartNextStage({
    required String partId,
    int? quantity,
    String notes = '',
  }) => transition.future;

  @override
  Future<void> assignPartToArtisan({
    required List<String> partIds,
    required String stageId,
    required String assignedEmployeeId,
    String instructions = '',
    int? splitQuantity,
  }) async {
    assignedParts = partIds;
    assignedStage = stageId;
    assignedQuantity = splitQuantity;
    assigned.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    DemoStore.instance.setLots([]);
    DemoStore.instance.setStages([]);
  });

  test('moving one piece keeps the other nine at their assignment stage', () {
    DemoStore.instance.setStages(const [
      ApiStage(id: 'buffing', name: 'Buffing', stageNumber: 1),
      ApiStage(id: 'setting', name: 'Hand setting', stageNumber: 2),
    ]);
    final lots = ApiDomainMapper.pendingPartBatches({
      'id': partId,
      'quantity': 10,
      'grossWeight': 195,
      'currentStage': {'id': 'setting', 'name': 'Hand setting'},
      'assignments': [
        {
          'id': 'nine',
          'stageId': 'buffing',
          'status': 'IN_PROGRESS',
          'splitQuantity': 9,
          'assignedEmployee': {'name': 'Narayan da'},
        },
        {
          'id': 'one',
          'stageId': 'buffing',
          'status': 'COMPLETED',
          'splitQuantity': 1,
          'assignedEmployee': {'name': 'Rupali'},
        },
      ],
    });
    expect(lots.length, 2);
    expect(lots.first.pieces, 9);
    expect(lots.first.apiStageId, 'buffing');
    expect(lots.first.apiStageName, 'Buffing');
    expect(lots.first.assignedEmployee, 'Narayan da');
    expect(lots.last.pieces, 1);
    expect(lots.last.apiStageId, 'setting');
    expect(lots.last.assignedEmployee, 'Unassigned');
  });

  test(
    'nested assignment stage IDs survive mapping and missing stages are not inferred',
    () {
      final lots = ApiDomainMapper.pendingPartBatches({
        'id': partId,
        'quantity': 2,
        'currentStage': {'id': 'setting', 'name': 'Hand setting'},
        'assignments': [
          {
            'id': 'a',
            'status': 'IN_PROGRESS',
            'splitQuantity': 1,
            'stage': {'id': 'buffing', 'name': 'Buffing'},
          },
          {'id': 'b', 'status': 'IN_PROGRESS', 'splitQuantity': 1},
        ],
      });
      expect(lots.first.apiStageId, 'buffing');
      expect(lots.first.apiStageName, 'Buffing');
      expect(lots.last.apiStageId, isEmpty);
      expect(lots.last.apiStageName, isEmpty);
    },
  );

  test('backend stage identity wins over overlapping enum names', () {
    const stages = [
      ApiStage(id: 'pre', name: 'Pre Polishing', stageNumber: 1),
      ApiStage(id: 'final', name: 'Final Polishing', stageNumber: 2),
    ];
    expect(
      ApiDomainMapper.productionStageIndex(
        stages,
        stageId: 'final',
        stageName: 'Pre Polishing',
      ),
      1,
    );
    expect(
      ApiDomainMapper.productionStageIndex(
        stages,
        stageName: 'Final Polishing',
      ),
      1,
    );
    expect(
      ApiDomainMapper.productionStageIndex(stages, stageId: 'missing'),
      -1,
    );
    expect(ApiDomainMapper.productionStageIndex(stages), -1);
  });

  test('completion sentinel never assigns another worker', () async {
    final api = TransitionApi();
    final bloc = WorkshopBloc(store: DemoStore.instance, apiRepository: api);
    final success = bloc.stream.firstWhere((s) => s is WorkshopStageUpdated);
    bloc.add(
      const AdvanceLotStageEvent(
        partId,
        quantity: 30,
        nextStageId: stageId,
        nextArtisanId: employeeId,
      ),
    );
    api.transition.complete({'currentStage': 'ALL_STAGES_COMPLETED'});
    await success.timeout(const Duration(seconds: 3));
    expect(api.assigned.isCompleted, isFalse);
    await bloc.close();
  });

  test(
    '100 pieces retain worker batches and remaining quantity after refresh',
    () {
      Map<String, dynamic> assignment(String id, String worker, int quantity) =>
          {
            'id': id,
            'status': 'ASSIGNED',
            'splitQuantity': quantity,
            'assignedEmployee': {'name': worker},
            'stage': {'id': stageId, 'name': 'Wax'},
          };
      final part = <String, dynamic>{
        'id': partId,
        'quantity': 100,
        'grossWeight': 200,
        'assignments': [
          assignment('a', 'Worker A', 30),
          assignment('b', 'Worker B', 20),
        ],
      };
      var lots = ApiDomainMapper.pendingPartBatches(part);
      expect(lots.map((l) => l.pieces), [30, 20, 50]);
      expect(lots.last.assignedEmployee, 'Unassigned');
      expect(
        lots.map((l) => KaratFlowApiRepository.extractCleanUuid(l.id)).toSet(),
        {partId},
      );
      (part['assignments'] as List).add(assignment('c', 'Worker C', 50));
      lots = ApiDomainMapper.pendingPartBatches(part);
      expect(lots.map((l) => l.pieces), [30, 20, 50]);
      expect(lots.any((l) => l.assignedEmployee == 'Unassigned'), isFalse);
    },
  );

  test('composite lot IDs resolve to the order part UUID', () {
    expect(KaratFlowApiRepository.extractCleanUuid('$partId-assign-0'), partId);
    expect(
      KaratFlowApiRepository.extractCleanUuid('$partId#$partId#unassigned'),
      partId,
    );
    expect(KaratFlowApiRepository.isValidUuid('RKR-123'), isFalse);
  });

  test(
    'assignment waits for successful transition and accepts object stage response',
    () async {
      final api = TransitionApi();
      final bloc = WorkshopBloc(store: DemoStore.instance, apiRepository: api);
      final success = bloc.stream.firstWhere((s) => s is WorkshopStageUpdated);
      bloc.add(
        const AdvanceLotStageEvent(
          partId,
          quantity: 30,
          nextStageId: stageId,
          nextArtisanId: employeeId,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.assigned.isCompleted, isFalse);
      api.transition.complete({
        'currentStage': {'id': 'backend-stage-id', 'name': 'Polishing'},
        'partId': partId,
      });
      await success.timeout(const Duration(seconds: 3));
      expect(api.assignedParts, [partId]);
      expect(api.assignedQuantity, 30);
      expect(api.assignedStage, 'backend-stage-id');
      await bloc.close();
    },
  );

  test('failed transition never assigns the next worker', () async {
    final api = TransitionApi();
    final bloc = WorkshopBloc(store: DemoStore.instance, apiRepository: api);
    final failure = bloc.stream.firstWhere((s) => s is WorkshopError);
    bloc.add(
      const AdvanceLotStageEvent(
        partId,
        quantity: 30,
        nextStageId: stageId,
        nextArtisanId: employeeId,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    api.transition.completeError(Exception('Stage not completed'));
    await failure.timeout(const Duration(seconds: 3));
    expect(api.assigned.isCompleted, isFalse);
    await bloc.close();
  });
}
