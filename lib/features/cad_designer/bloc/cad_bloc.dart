import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/demo_store.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'cad_event.dart';
import 'cad_state.dart';

export 'cad_event.dart';
export 'cad_state.dart';

/// CAD BLoC with Strict Live 3D Modeling & CAD APIs (/three-d-designs, /storage) & Debug Logs
class CadBloc extends Bloc<CadEvent, CadState> {
  CadBloc({
    required DemoStore store,
    KaratFlowApiRepository? apiRepository,
  })  : _store = store,
        _api = apiRepository ?? KaratFlowApiRepository(),
        super(const CadInitial()) {
    on<FetchCadTasksEvent>(_onFetchTasks);
    on<UpdateCadTaskStatusEvent>(_onUpdateStatus);
    on<UploadCadFilesEvent>(_onUploadFiles);
    on<ApproveCadTaskEvent>(_onApproveTask);
    on<FilterCadTasksEvent>(_onFilterTasks);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;

  Future<void> _onFetchTasks(
    FetchCadTasksEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    debugPrint('💎 [CadBloc] Fetching 3D CAD designs from GET /three-d-designs?status=PENDING...');
    try {
      final apiDesigns = await _api.listThreeDDesigns(status: 'PENDING');
      debugPrint('✅ [CadBloc] Received ${apiDesigns.length} CAD designs from server.');

      final mappedTasks = apiDesigns.map((td) {
        return CadDesignTask(
          id: td.id,
          orderId: td.sketchId,
          designCode: 'CAD-${td.id}',
          productTitle: '3D CAM Model (${td.sketchId})',
          clientName: 'Live Client',
          specs: 'Weight: ${td.totalWeight}g · Vol: ${td.volumeMm3}mm³',
          notes: 'Direct 3D model from live backend',
          estimatedWeightGrams: td.totalWeight,
          status: td.status == 'APPROVED'
              ? CadTaskStatus.completed
              : CadTaskStatus.newTask,
          hasVoiceNote: false,
          hasSketchImage: true,
          hasStlFile: td.xtlFileUrl != null && td.xtlFileUrl!.isNotEmpty,
          assignedTo: '3D CAD Designer',
          receivedAt: DateTime.now(),
        );
      }).toList();

      emit(CadLoaded(
        tasks: mappedTasks,
        filteredTasks: mappedTasks,
      ));
    } catch (e) {
      debugPrint('❌ [CadBloc] Failed to fetch CAD tasks: $e');
      emit(CadError('Failed to fetch CAD tasks from live API: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateCadTaskStatusEvent event,
    Emitter<CadState> emit,
  ) async {
    try {
      _store.updateCadTaskStatus(event.taskId, event.status);
      emit(CadOperationSuccess('CAD task status updated to ${event.status.label}.'));
      add(const FetchCadTasksEvent());
    } catch (e) {
      emit(CadError('Failed to update CAD status: ${e.toString()}'));
    }
  }

  Future<void> _onUploadFiles(
    UploadCadFilesEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    debugPrint('📤 [CadBloc] Uploading 3D STL & Matrix block to POST /three-d-designs/upload...');
    try {
      final computedGoldWeight = event.goldQuantity ?? (event.volumeCubicMm * 0.0155);
      await _api.uploadThreeDDesign(
        sketchId: event.taskId,
        xtlFileUrl: event.stlFileUrl ?? '3d-models/${event.taskId}.stl',
        bomFileUrl: event.bomFileUrl ?? 'bom/${event.taskId}.3dm',
        gemQuantity: event.gemQuantity ?? 0,
        goldQuantity: double.parse(computedGoldWeight.toStringAsFixed(2)),
        totalWeight: double.parse(computedGoldWeight.toStringAsFixed(2)),
        volumeMm3: event.volumeCubicMm,
        sizeDimensions: 'Custom CAD Dimensions',
      );

      debugPrint('✅ [CadBloc] 3D STL uploaded successfully on live server.');
      emit(const CadOperationSuccess('3D STL and Matrix block uploaded successfully to live server.'));
      add(const FetchCadTasksEvent());
    } catch (e) {
      debugPrint('❌ [CadBloc] Failed to upload CAD files: $e');
      emit(CadError('Failed to upload CAD files to live server: ${e.toString()}'));
    }
  }

  Future<void> _onApproveTask(
    ApproveCadTaskEvent event,
    Emitter<CadState> emit,
  ) async {
    debugPrint('✍️ [CadBloc] Approving 3D design on PATCH /three-d-designs/${event.taskId}/review...');
    try {
      await _api.reviewThreeDDesign(
        id: event.taskId,
        status: 'APPROVED',
        adminInstructions: 'Approved for Waxing & Tree Setup',
      );

      debugPrint('✅ [CadBloc] 3D design approved on server.');
      emit(const CadOperationSuccess('3D Model approved on server for wax printing.'));
      add(const FetchCadTasksEvent());
    } catch (e) {
      debugPrint('❌ [CadBloc] Failed to approve CAD model: $e');
      emit(CadError('Failed to approve CAD model on live server: ${e.toString()}'));
    }
  }

  void _onFilterTasks(
    FilterCadTasksEvent event,
    Emitter<CadState> emit,
  ) {
    if (state is CadLoaded) {
      final current = state as CadLoaded;
      final filtered = event.status == null
          ? current.tasks
          : current.tasks.where((t) => t.status == event.status).toList();

      emit(CadLoaded(
        tasks: current.tasks,
        filteredTasks: filtered,
        selectedFilter: event.status,
      ));
    }
  }
}
