import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/token_storage_service.dart';
import '../../../data/demo_store.dart';
import '../../../data/mappers/api_domain_mapper.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'workshop_event.dart';
import 'workshop_state.dart';

export 'workshop_event.dart';
export 'workshop_state.dart';

class WorkshopBloc extends Bloc<WorkshopEvent, WorkshopState> {
  WorkshopBloc({
    required DemoStore store,
    KaratFlowApiRepository? apiRepository,
    TokenStorageService? tokenStorage,
  }) : _store = store,
       _api = apiRepository ?? KaratFlowApiRepository(),
       _tokenStorage = tokenStorage ?? TokenStorageService(),
       super(const WorkshopInitial()) {
    on<FetchWorkshopLotsEvent>(_onFetchLots);
    on<AdvanceLotStageEvent>(_onAdvanceLotStage);
    on<AllocateLotArtisanEvent>(_onAllocateArtisan);
    on<RollbackLotStageEvent>(_onRollbackStage);
    on<StartWorkerTaskEvent>(_onStartWorkerTask);
    on<CompleteWorkerTaskEvent>(_onCompleteWorkerTask);
    on<ReportWorkerFailureEvent>(_onReportWorkerFailure);
    on<FilterWorkshopLotsEvent>(_onFilterLots);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;
  final TokenStorageService _tokenStorage;

  Future<void> _onFetchLots(
    FetchWorkshopLotsEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(const WorkshopLoading());
    try {
      final role = (await _tokenStorage.getUserRole() ?? '').toUpperCase();
      final stages = await _api.listStages();
      final isWorker = role == 'OTHER_EMPLOYEE';
      final lots = isWorker
          ? (await _api.listWorkerTasks())
                .map(ApiDomainMapper.workerTask)
                .toList()
          : (await _api.listPendingProductionFloor())
                .map(
                  (item) => ApiDomainMapper.pendingPart(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      final canManageAssignments =
          role == 'ADMIN' ||
          role == 'PRODUCTION_MANAGER' ||
          role == 'PROCESS_MANAGER';
      final team = canManageAssignments
          ? (await _api.listEmployees()).map(ApiDomainMapper.employee).toList()
          : <TeamMember>[];

      _store
        ..setLots(lots)
        ..setTeam(team)
        ..setStages(stages);
      emit(
        WorkshopLoaded(
          lots: lots,
          filteredLots: lots,
          team: team,
          apiStages: stages,
        ),
      );
    } catch (error) {
      emit(WorkshopError('Failed to load live workshop data: $error'));
    }
  }

  Future<void> _onAdvanceLotStage(
    AdvanceLotStageEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      await _api.transitionPartNextStage(
        partId: event.lotId,
        notes: 'Stage advanced from KaratFlow mobile app',
      );
      _store.advanceLotStage(event.lotId);
      emit(const WorkshopStageUpdated('Part advanced successfully.'));
    } catch (error) {
      emit(WorkshopError('Failed to advance part: $error'));
    }
  }

  Future<void> _onAllocateArtisan(
    AllocateLotArtisanEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    if (event.artisanId?.isEmpty ?? true) {
      emit(const WorkshopError('A valid artisan ID is required.'));
      return;
    }
    if (event.stageId?.isEmpty ?? true) {
      emit(const WorkshopError('A valid production stage ID is required.'));
      return;
    }
    try {
      await _api.assignPartToArtisan(
        partIds: [event.lotId],
        stageId: event.stageId!,
        assignedEmployeeId: event.artisanId!,
        instructions: 'Assigned to ${event.artisanName}',
      );
      final targetStage = _stageForId(event.stageId!);
      _store.updateLotStage(
        event.lotId,
        targetStage,
        assignedEmployee: event.artisanName,
      );
      emit(const WorkshopStageUpdated('Part assigned successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      emit(WorkshopError('Failed to assign part: $error'));
    }
  }

  Future<void> _onRollbackStage(
    RollbackLotStageEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      await _api.rollbackPartStage(
        partId: event.lotId,
        targetStageId: event.targetStageId,
        reason: event.reason,
      );
      _store.updateLotStage(event.lotId, _stageForId(event.targetStageId));
      emit(const WorkshopStageUpdated('Part rolled back successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      emit(WorkshopError('Failed to rollback part: $error'));
    }
  }

  Future<void> _onStartWorkerTask(
    StartWorkerTaskEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      await _api.startWorkerTask(event.taskId);
      emit(const WorkshopStageUpdated('Task started successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      emit(WorkshopError('Failed to start task: $error'));
    }
  }

  Future<void> _onCompleteWorkerTask(
    CompleteWorkerTaskEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      await _api.completeWorkerTask(event.taskId);
      emit(const WorkshopStageUpdated('Task completed successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      emit(WorkshopError('Failed to complete task: $error'));
    }
  }

  Future<void> _onReportWorkerFailure(
    ReportWorkerFailureEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      await _api.reportWorkerTaskFailure(event.taskId, event.reason);
      emit(const WorkshopStageUpdated('Task failure reported.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      emit(WorkshopError('Failed to report task failure: $error'));
    }
  }

  void _onFilterLots(
    FilterWorkshopLotsEvent event,
    Emitter<WorkshopState> emit,
  ) {
    final current = state;
    if (current is! WorkshopLoaded) return;
    final query = event.query.toLowerCase();
    final filtered = current.lots.where((lot) {
      final matchesStage = event.stage == null || lot.stage == event.stage;
      final matchesQuery =
          query.isEmpty ||
          lot.id.toLowerCase().contains(query) ||
          lot.productTitle.toLowerCase().contains(query) ||
          lot.assignedEmployee.toLowerCase().contains(query);
      return matchesStage && matchesQuery;
    }).toList();
    emit(
      WorkshopLoaded(
        lots: current.lots,
        filteredLots: filtered,
        team: current.team,
        apiStages: current.apiStages,
        selectedStage: event.stage,
        searchQuery: event.query,
      ),
    );
  }

  WorkshopStage _stageForId(String stageId) {
    final index = _store.stages.indexWhere((stage) => stage.id == stageId);
    if (index < 0) return WorkshopStage.inQueue;
    final apiStage = _store.stages[index];
    final byName = ApiDomainMapper.stage(apiStage.name);
    if (byName != WorkshopStage.inQueue ||
        apiStage.name.trim().toLowerCase().contains('queue')) {
      return byName;
    }
    final stageIndex = (apiStage.stageNumber - 1)
        .clamp(0, WorkshopStage.values.length - 1)
        .toInt();
    return WorkshopStage.values[stageIndex];
  }
}
