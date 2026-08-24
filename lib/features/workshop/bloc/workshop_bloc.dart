import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'workshop_event.dart';
import 'workshop_state.dart';

export 'workshop_event.dart';
export 'workshop_state.dart';

/// Workshop BLoC with Strict Live Production Floor & Worker Task APIs (/production, /worker-tasks, /stages) & Debug Logs
class WorkshopBloc extends Bloc<WorkshopEvent, WorkshopState> {
  WorkshopBloc({KaratFlowApiRepository? apiRepository})
    : _api = apiRepository ?? KaratFlowApiRepository(),
      super(const WorkshopInitial()) {
    on<FetchWorkshopLotsEvent>(_onFetchLots);
    on<AdvanceLotStageEvent>(_onAdvanceLotStage);
    on<AllocateLotArtisanEvent>(_onAllocateArtisan);
    on<FilterWorkshopLotsEvent>(_onFilterLots);
  }

  final KaratFlowApiRepository _api;

  Future<void> _onFetchLots(
    FetchWorkshopLotsEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    emit(const WorkshopLoading());
    debugPrint(
      '🏭 [WorkshopBloc] Fetching tasks (GET /worker-tasks), employees (GET /employees) & stages (GET /stages)...',
    );
    try {
      final workerTasks = await _api.listWorkerTasks();
      final employees = await _api.listEmployees();
      final liveStages = await _api.listStages();

      debugPrint(
        '✅ [WorkshopBloc] Received ${workerTasks.length} worker tasks, ${employees.length} artisans & ${liveStages.length} dynamic stages from server.',
      );

      final mappedLots = workerTasks.map((wt) {
        final stageEnum = switch (wt.stageName.toLowerCase()) {
          'waxing' || 'cad & wax' => WorkshopStage.cadAndWax,
          'casting' => WorkshopStage.casting,
          'filing & assembly' || 'filing' => WorkshopStage.filingAndAssembly,
          'stone setting' || 'setting' => WorkshopStage.stoneSetting,
          'polishing' => WorkshopStage.polishing,
          _ => WorkshopStage.qualityCheck,
        };

        return WorkshopLot(
          id: wt.id,
          orderId: wt.orderId.isNotEmpty ? wt.orderId : wt.id,
          designCode: wt.designNumber,
          productTitle: wt.designNumber.isNotEmpty
              ? wt.designNumber
              : 'Lot #${wt.id}',
          stage: stageEnum,
          assignedEmployee: wt.assignedEmployeeName,
          assignedEmployeeRole: wt.status,
          pieces: wt.quantity,
          issueWeightGrams: wt.grossWeight,
          targetWeightGrams: wt.grossWeight,
          tone: wt.status == 'FAILED'
              ? HealthTone.critical
              : HealthTone.healthy,
          blockerReason: wt.status == 'FAILED' ? wt.instructions : null,
          lastUpdatedTime: wt.stageName,
        );
      }).toList();

      final mappedTeam = employees.map((emp) {
        return TeamMember(
          id: emp.id,
          name: emp.name,
          craft: emp.role,
          shift: emp.role,
          activeLotsCount: emp.workerAssignmentsCount,
          status: emp.isActive
              ? EmployeeStatus.available
              : EmployeeStatus.blocked,
          todayEfficiencyPercent: emp.isActive ? 100 : 0,
          currentAssignment: '${emp.workerAssignmentsCount} active tasks',
        );
      }).toList();

      emit(
        WorkshopLoaded(
          lots: mappedLots,
          filteredLots: mappedLots,
          team: mappedTeam,
          apiStages: liveStages,
        ),
      );
    } catch (e) {
      debugPrint('❌ [WorkshopBloc] Failed to fetch live workshop data: $e');
      emit(
        WorkshopError('Failed to fetch live workshop data: ${e.toString()}'),
      );
    }
  }

  Future<void> _onAdvanceLotStage(
    AdvanceLotStageEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    debugPrint(
      '⏭️ [WorkshopBloc] Advancing part ${event.lotId} stage on POST /production/parts/${event.lotId}/transition...',
    );
    try {
      await _api.transitionPartNextStage(
        partId: event.lotId,
        notes: 'Stage advanced from KaratFlow mobile app',
      );
      debugPrint('✅ [WorkshopBloc] Part advanced successfully on server.');
      emit(
        WorkshopStageUpdated(
          'Lot ${event.lotId} moved to next stage on server.',
        ),
      );
      add(const FetchWorkshopLotsEvent());
    } catch (e) {
      debugPrint('❌ [WorkshopBloc] Failed to advance stage: $e');
      emit(
        WorkshopError('Failed to advance stage on live API: ${e.toString()}'),
      );
    }
  }

  Future<void> _onAllocateArtisan(
    AllocateLotArtisanEvent event,
    Emitter<WorkshopState> emit,
  ) async {
    debugPrint(
      '👨‍🏭 [WorkshopBloc] Assigning part ${event.lotId} to artisan ${event.artisanName} on POST /production/assign...',
    );
    try {
      await _api.assignPartToArtisan(
        partIds: [event.lotId],
        stageId: (event.stageId != null && event.stageId!.isNotEmpty)
            ? event.stageId!
            : event.lotId,
        assignedEmployeeId:
            (event.artisanId != null && event.artisanId!.isNotEmpty)
            ? event.artisanId!
            : event.artisanName,
        instructions: 'Assigned to ${event.artisanName}',
      );
      debugPrint('✅ [WorkshopBloc] Part allocated successfully on server.');
      emit(
        WorkshopStageUpdated(
          'Lot ${event.lotId} assigned to ${event.artisanName} on server.',
        ),
      );
      add(const FetchWorkshopLotsEvent());
    } catch (e) {
      debugPrint('❌ [WorkshopBloc] Failed to allocate artisan: $e');
      emit(
        WorkshopError(
          'Failed to allocate artisan on live API: ${e.toString()}',
        ),
      );
    }
  }

  void _onFilterLots(
    FilterWorkshopLotsEvent event,
    Emitter<WorkshopState> emit,
  ) {
    if (state is WorkshopLoaded) {
      final current = state as WorkshopLoaded;
      final filtered = current.lots.where((lot) {
        final matchesStage = event.stage == null || lot.stage == event.stage;
        final matchesQuery =
            event.query.isEmpty ||
            lot.id.toLowerCase().contains(event.query.toLowerCase()) ||
            lot.productTitle.toLowerCase().contains(
              event.query.toLowerCase(),
            ) ||
            lot.assignedEmployee.toLowerCase().contains(
              event.query.toLowerCase(),
            );

        return matchesStage && matchesQuery;
      }).toList();

      emit(
        WorkshopLoaded(
          lots: current.lots,
          filteredLots: filtered,
          team: current.team,
          selectedStage: event.stage,
          searchQuery: event.query,
        ),
      );
    }
  }
}
