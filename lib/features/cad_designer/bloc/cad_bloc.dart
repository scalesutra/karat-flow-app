import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/demo_store.dart';
import '../../../data/mappers/api_domain_mapper.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'cad_event.dart';
import 'cad_state.dart';

export 'cad_event.dart';
export 'cad_state.dart';

class CadBloc extends Bloc<CadEvent, CadState> {
  CadBloc({required DemoStore store, KaratFlowApiRepository? apiRepository})
    : _store = store,
      _api = apiRepository ?? KaratFlowApiRepository(),
      super(const CadInitial()) {
    on<FetchCadTasksEvent>(_onFetchTasks);
    on<UploadCadFilesEvent>(_onUploadFiles);
    on<ApproveCadTaskEvent>(_onApproveTask);
    on<DownloadCadFileEvent>(_onDownloadFile);
    on<FilterCadTasksEvent>(_onFilterTasks);
    on<UpdateCadTaskStatusEvent>(_onUnsupportedLocalStatus);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;

  Future<void> _onFetchTasks(
    FetchCadTasksEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    try {
      final designs = await _api.listThreeDDesigns();
      final tasks = designs.map(ApiDomainMapper.cadTask).toList();
      _store.setCadTasks(tasks);
      emit(CadLoaded(tasks: tasks, filteredTasks: tasks));
    } catch (error) {
      emit(CadError('Failed to fetch CAD tasks: $error'));
    }
  }

  Future<void> _onUploadFiles(
    UploadCadFilesEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    try {
      final stl = await _api.uploadFile(
        fileName: event.stlFileName,
        fileType: 'model/stl',
        folder: '3d-xtl',
        bytes: event.stlBytes,
      );
      final bom = await _api.uploadFile(
        fileName: event.bomFileName,
        fileType: 'application/octet-stream',
        folder: 'bom-docs',
        bytes: event.bomBytes,
      );
      final weight = event.goldQuantity ?? event.volumeCubicMm * 0.0155;
      final totalWeight = double.parse(weight.toStringAsFixed(2));
      if (event.isRevision) {
        await _api.reuploadThreeDDesign(
          id: event.taskId,
          xtlFileUrl: stl.fileUrl,
          bomFileUrl: bom.fileUrl,
          totalWeight: totalWeight,
        );
      } else {
        await _api.uploadThreeDDesign(
          sketchId: event.taskId,
          xtlFileUrl: stl.fileUrl,
          bomFileUrl: bom.fileUrl,
          gemQuantity: event.gemQuantity ?? 0,
          goldQuantity: totalWeight,
          totalWeight: totalWeight,
          volumeMm3: event.volumeCubicMm,
          sizeDimensions: event.specsNote,
        );
      }
      emit(const CadOperationSuccess('CAD files uploaded successfully.'));
      add(const FetchCadTasksEvent());
    } catch (error) {
      emit(CadError('Failed to upload CAD files: $error'));
    }
  }

  Future<void> _onApproveTask(
    ApproveCadTaskEvent event,
    Emitter<CadState> emit,
  ) async {
    try {
      await _api.reviewThreeDDesign(
        id: event.taskId,
        status: 'APPROVED',
        adminInstructions: 'Approved for Waxing & Tree Setup',
      );
      emit(const CadOperationSuccess('CAD design approved successfully.'));
      add(const FetchCadTasksEvent());
    } catch (error) {
      emit(CadError('Failed to approve CAD design: $error'));
    }
  }

  Future<void> _onDownloadFile(
    DownloadCadFileEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    try {
      final signed = await _api.getPresignedDownloadUrl(event.fileKey);
      emit(CadDownloadReady(signed.downloadUrl));
    } catch (error) {
      emit(CadError('Failed to create download link: $error'));
    }
  }

  void _onUnsupportedLocalStatus(
    UpdateCadTaskStatusEvent event,
    Emitter<CadState> emit,
  ) {
    emit(
      const CadError(
        'The backend does not expose a generic CAD status endpoint.',
      ),
    );
  }

  void _onFilterTasks(FilterCadTasksEvent event, Emitter<CadState> emit) {
    final current = state;
    if (current is! CadLoaded) return;
    final filtered = event.status == null
        ? current.tasks
        : current.tasks.where((task) => task.status == event.status).toList();
    emit(
      CadLoaded(
        tasks: current.tasks,
        filteredTasks: filtered,
        selectedFilter: event.status,
      ),
    );
  }
}
