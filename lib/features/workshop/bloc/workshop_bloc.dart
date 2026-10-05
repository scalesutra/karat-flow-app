import 'package:flutter/foundation.dart';
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
    on<BlockLotPartEvent>(_onBlockPart);
    on<UnblockLotPartEvent>(_onUnblockPart);
    on<StartWorkerTaskEvent>(_onStartWorkerTask);
    on<CompleteWorkerTaskEvent>(_onCompleteWorkerTask);
    on<ReportWorkerFailureEvent>(_onReportWorkerFailure);
    on<FilterWorkshopLotsEvent>(_onFilterLots);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;
  final TokenStorageService _tokenStorage;
  int _loadedOrderPages = 1;

  Future<void> _onFetchLots(
    FetchWorkshopLotsEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(const WorkshopLoading());
    try {
      final roleStr = await _tokenStorage.getUserRole();
      final appRole = AppRole.fromRoleString(roleStr);
      debugPrint(
        '🔍 [WORKSHOP BLOC] Fetching dynamic stages, team & lots for role: $roleStr ($appRole)...',
      );
      final stages = await _api.listStages();
      debugPrint('📋 [WORKSHOP BLOC] Loaded ${stages.length} stages from API');
      // Stage IDs in the production response need this lookup during mapping.
      _store.setStages(stages);
      try {
        final workerTasks = await _api.listWorkerTasks();
        _store.setWorkerTasks(workerTasks);
      } catch (_) {}
      final isWorker = appRole == AppRole.workshopArtisan;
      final isFrontier = appRole == AppRole.frontOffice;
      final canManageAssignments =
          appRole == AppRole.admin || appRole == AppRole.processManager;
      final team = canManageAssignments
          ? (await _api.listEmployees()).map(ApiDomainMapper.employee).toList()
          : <TeamMember>[];
      debugPrint(
        '👥 [WORKSHOP BLOC] Loaded ${team.length} team members / artisans',
      );
      // Pending production may contain only an employee ID. Hydrate employees
      // first so assignments survive a fresh app launch without local fallback.
      _store.setTeam(team);
      List<WorkshopLot> lots = [];
      if (isWorker) {
        lots = (await _api.listWorkerTasks())
            .map(ApiDomainMapper.workerTask)
            .toList();
        debugPrint('👷 [WORKSHOP BLOC] Loaded ${lots.length} artisan tasks');
      } else {
        // Fetch raw order parts — they include assignments even after assignment.
        // /production/pending only returns UNASSIGNED parts, so assigned parts vanish from it.
        if (event.orderPage != null) _loadedOrderPages = event.orderPage!;
        final allOrderParts = <Map<String, dynamic>>[];
        // Refresh only pages the user has requested, never the entire archive.
        for (var page = event.orderPage ?? 1; page <= _loadedOrderPages; page++) {
          allOrderParts.addAll(await _api.listOrderPartsRaw(page: page, limit: 50));
        }

        // Front Office has a read-only stage view. Its order data comes from
        // /orders and it must not query the manager-only pending queue.
        final pendingLots = isFrontier
            ? <WorkshopLot>[]
            : (await _api.listPendingProductionFloor())
                  .map(
                    (item) => ApiDomainMapper.pendingPart(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList();

        // Build a map starting with pending (unassigned) lots
        final lotMap = <String, WorkshopLot>{
          if ((event.orderPage ?? 1) > 1)
            for (final lot in _store.lots) lot.id: lot,
        };
        for (final lot in pendingLots) {
          if (lot.id.isNotEmpty) lotMap[lot.id] = lot;
        }

        // Merge in all order parts (both unassigned in queue and assigned to artisans)
        for (final partMap in allOrderParts) {
          final partId = partMap['id'] as String? ?? '';
          if (partId.isEmpty) continue;
          final batchLots = ApiDomainMapper.pendingPartBatches(partMap);
          // Replace the pending parent with its batches; retaining both doubles
          // the available quantity after a partial assignment.
          lotMap.remove(partId);

          for (final batchLot in batchLots) {
            lotMap[batchLot.id] = batchLot;
          }
        }
        lots = lotMap.values.toList();
        debugPrint(
          '🏭 [WORKSHOP BLOC] Loaded ${lots.length} total production floor lots (${pendingLots.length} pending unassigned)',
        );
      }
      // Mapped lots already contain their hold state. Replaying hold actions
      // for every lot rescans the entire store and notifies once per lot.
      _store.setLots(lots);

      emit(
        WorkshopLoaded(
          lots: lots,
          filteredLots: lots,
          team: team,
          apiStages: stages,
        ),
      );
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to load live workshop data: $error');
      emit(WorkshopError('Failed to load live workshop data: $error'));
    }
  }

  Future<void> _onAdvanceLotStage(
    AdvanceLotStageEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint(
        '🚀 [WORKSHOP BLOC] Advancing Lot: ${event.lotId} Stage (qty: ${event.quantity})',
      );
      final data = await _api.transitionPartNextStage(
        partId: event.lotId,
        quantity: event.quantity,
        notes: 'Stage advanced from KaratFlow mobile app',
      );
      final rawStage = data?['currentStage'];
      final currentStage = rawStage is Map
          ? rawStage['name'] as String?
          : rawStage as String?;
      final isComplete =
          (data?['isComplete'] as bool? ?? false) ||
          currentStage == 'ALL_STAGES_COMPLETED';
      final returnedStageId = rawStage is Map
          ? rawStage['id'] as String?
          : null;
      final assignmentStageId = returnedStageId?.isNotEmpty == true
          ? returnedStageId
          : event.nextStageId;
      if (!isComplete &&
          event.nextArtisanId != null &&
          assignmentStageId != null) {
        try {
          await _api.assignPartToArtisan(
            partIds: [
              data?['partId'] as String? ??
                  data?['id'] as String? ??
                  event.lotId,
            ],
            stageId: assignmentStageId,
            assignedEmployeeId: event.nextArtisanId!,
            splitQuantity: event.quantity,
          );
        } catch (error) {
          emit(
            WorkshopError(
              'Stage moved, but worker assignment failed: $error. Refresh and assign the remaining lot.',
            ),
          );
          add(const FetchWorkshopLotsEvent());
          return;
        }
      }
      debugPrint(
        '✅ [WORKSHOP BLOC] Transition response: currentStage=$currentStage, isComplete=$isComplete',
      );
      // A parent part can contain several worker batches. Updating by parent
      // UUID here can move an unrelated batch; hydrate persisted batches below.
      emit(const WorkshopStageUpdated('Part advanced successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to advance part: $error');
      emit(WorkshopError('Failed to advance part: $error'));
    }
  }

  Future<void> _onAllocateArtisan(
    AllocateLotArtisanEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    final cleanLotId = KaratFlowApiRepository.extractCleanUuid(event.lotId);
    final cleanStageId = KaratFlowApiRepository.extractCleanUuid(
      event.stageId ?? '',
    );
    final cleanArtisanId = KaratFlowApiRepository.extractCleanUuid(
      event.artisanId ?? '',
    );

    if (!KaratFlowApiRepository.isValidUuid(cleanLotId)) {
      debugPrint('❌ [WORKSHOP BLOC] Invalid OrderPart UUID: "${event.lotId}"');
      emit(
        WorkshopError(
          'Invalid OrderPart UUID: "${event.lotId}". Database UUID required.',
        ),
      );
      return;
    }
    if (!KaratFlowApiRepository.isValidUuid(cleanStageId)) {
      debugPrint('❌ [WORKSHOP BLOC] Invalid Stage UUID: "${event.stageId}"');
      emit(WorkshopError('Invalid ProductionStage UUID: "${event.stageId}".'));
      return;
    }
    if (!KaratFlowApiRepository.isValidUuid(cleanArtisanId)) {
      debugPrint(
        '❌ [WORKSHOP BLOC] Invalid Artisan UUID: "${event.artisanId}"',
      );
      emit(
        WorkshopError(
          'Invalid Artisan UUID for "${event.artisanName}". Database UUID required.',
        ),
      );
      return;
    }

    try {
      debugPrint(
        '🚀 [WORKSHOP BLOC] Allocating Part: $cleanLotId -> Artisan: ${event.artisanName} ($cleanArtisanId), Stage: $cleanStageId, Split: ${event.splitQuantity}',
      );
      String assignInstructions =
          (event.instructions != null && event.instructions!.trim().isNotEmpty)
          ? event.instructions!.trim()
          : 'Assigned to ${event.artisanName}';
      if (event.splitQuantity != null && event.splitQuantity! > 0) {
        if (!assignInstructions.contains('[splitQty:')) {
          assignInstructions =
              '[splitQty: ${event.splitQuantity}] $assignInstructions';
        }
      }
      await _api.assignPartToArtisan(
        partIds: [cleanLotId],
        stageId: cleanStageId,
        assignedEmployeeId: cleanArtisanId,
        instructions: assignInstructions,
        splitQuantity: event.splitQuantity,
      );
      final targetStage = _stageForId(event.stageId!);
      if (event.splitQuantity != null && event.splitQuantity! > 0) {
        _store.allocateLotWithSplit(
          lotId: event.lotId,
          targetStage: targetStage,
          assignedEmployee: event.artisanName,
          splitPieces: event.splitQuantity!,
        );
      } else {
        _store.updateLotStage(
          event.lotId,
          targetStage,
          assignedEmployee: event.artisanName,
        );
      }
      debugPrint('✅ [WORKSHOP BLOC] Lot ${event.lotId} assigned successfully');
      emit(const WorkshopStageUpdated('Part assigned successfully.'));
      // Rebuild all workshop views from persisted backend state. The pending
      // endpoint drops assigned parts, while the orders endpoint retains them.
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to assign part: $error');
      emit(WorkshopError('Failed to assign part: $error'));
    }
  }

  Future<void> _onRollbackStage(
    RollbackLotStageEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint(
        '🔙 [WORKSHOP BLOC] Rolling back Lot: ${event.lotId} -> Stage: ${event.targetStageId}, Reason: ${event.reason}, Qty: ${event.quantity}',
      );
      await _api.rollbackPartStage(
        partId: event.lotId,
        targetStageId: event.targetStageId,
        reason: event.reason,
        quantity: event.quantity,
      );
      if (event.quantity == null) {
        _store.updateLotStage(event.lotId, _stageForId(event.targetStageId));
      }
      debugPrint(
        '✅ [WORKSHOP BLOC] Lot ${event.lotId} rolled back successfully',
      );
      emit(const WorkshopStageUpdated('Part rolled back successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to rollback part: $error');
      emit(WorkshopError('Failed to rollback part: $error'));
    }
  }

  Future<void> _onBlockPart(
    BlockLotPartEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint(
        '🛑 [WORKSHOP BLOC] Placing Lot Part on Hold: ${event.partId} - Reason: ${event.reason}',
      );
      await _api.blockOrderPart(partId: event.partId, reason: event.reason);
      _store.toggleLotHold(event.partId, isBlocked: true, reason: event.reason);
      debugPrint('✅ [WORKSHOP BLOC] Lot Part ${event.partId} blocked / held');
      emit(const WorkshopStageUpdated('Part blocked / placed on hold.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to block order part: $error');
      emit(WorkshopError('Failed to block order part: $error'));
    }
  }

  Future<void> _onUnblockPart(
    UnblockLotPartEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint(
        '🟢 [WORKSHOP BLOC] Releasing Lot Part from Hold: ${event.partId} - Notes: ${event.notes}',
      );
      await _api.unblockOrderPart(partId: event.partId, notes: event.notes);
      _store.toggleLotHold(event.partId, isBlocked: false);
      debugPrint(
        '✅ [WORKSHOP BLOC] Lot Part ${event.partId} unblocked / resumed',
      );
      emit(const WorkshopStageUpdated('Part unblocked / hold released.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to unblock order part: $error');
      emit(WorkshopError('Failed to unblock order part: $error'));
    }
  }

  Future<void> _onStartWorkerTask(
    StartWorkerTaskEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint('▶️ [WORKSHOP BLOC] Starting Worker Task: ${event.taskId}');
      await _api.startWorkerTask(event.taskId);
      emit(const WorkshopStageUpdated('Task started successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to start task: $error');
      emit(WorkshopError('Failed to start task: $error'));
    }
  }

  Future<void> _onCompleteWorkerTask(
    CompleteWorkerTaskEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint('🏁 [WORKSHOP BLOC] Completing Worker Task: ${event.taskId}');
      await _api.completeWorkerTask(event.taskId);
      emit(const WorkshopStageUpdated('Task completed successfully.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to complete task: $error');
      emit(WorkshopError('Failed to complete task: $error'));
    }
  }

  Future<void> _onReportWorkerFailure(
    ReportWorkerFailureEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    try {
      debugPrint(
        '⚠️ [WORKSHOP BLOC] Reporting Failure on Worker Task: ${event.taskId} - Reason: ${event.reason}',
      );
      await _api.reportWorkerTaskFailure(event.taskId, event.reason);
      emit(const WorkshopStageUpdated('Task failure reported.'));
      add(const FetchWorkshopLotsEvent());
    } catch (error) {
      debugPrint('❌ [WORKSHOP BLOC] Failed to report task failure: $error');
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
    if (index < 0) {
      throw StateError('Production stage $stageId is not loaded from the API.');
    }
    final apiStage = _store.stages[index];
    return ApiDomainMapper.stage(apiStage.name);
  }
}
