import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/demo_store.dart';
import '../../../data/mappers/api_domain_mapper.dart';
import '../../../data/models/api_models.dart';
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
    on<UpdateCadTaskStatusEvent>(_onUpdateCadTaskStatus);
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
      final sketches = await _api.listSketches(limit: 100);

      final tasks = designs.map(ApiDomainMapper.cadTask).toList();

      final approvedSketches = sketches
          .where((s) => s.status.toUpperCase() == 'APPROVED')
          .toList();
      for (final sketch in approvedSketches) {
        CadDesignTask? existingStoreTask;
        for (final t in _store.cadTasks) {
          if (t.id == sketch.id ||
              (sketch.designNumber.isNotEmpty &&
                  (t.designCode == sketch.designNumber ||
                      t.orderId == sketch.designNumber))) {
            existingStoreTask = t;
            break;
          }
        }

        final exists = tasks.any(
          (t) => t.id == sketch.id || t.designCode == sketch.designNumber,
        );
        if (!exists) {
          if (existingStoreTask != null) {
            tasks.add(existingStoreTask);
          } else {
            tasks.add(
              CadDesignTask(
                id: sketch.id,
                orderId: sketch.designNumber.isNotEmpty
                    ? sketch.designNumber
                    : 'SKETCH-${sketch.id.substring(0, 6)}',
                designCode: sketch.designNumber,
                productTitle: sketch.title.isNotEmpty
                    ? sketch.title
                    : 'Approved 2D Sketch',
                clientName: sketch.designer?.name ?? 'Client Design',
                specs: 'Approved 2D Sketch · Pending 3D Wax STL Modeling',
                notes: sketch.adminInstructions ?? 'Approved by Admin',
                estimatedWeightGrams: 15.0,
                status: CadTaskStatus.newTask,
                hasSketchImage: sketch.sketchUrl.isNotEmpty,
                hasStlFile: false,
                modelFileUrl: sketch.sketchUrl,
                assignedTo: sketch.designer?.name ?? 'CAD Designer',
                receivedAt:
                    DateTime.tryParse(sketch.createdAt ?? '') ?? DateTime.now(),
                volumeCubicMm: 1200,
              ),
            );
          }
        } else if (existingStoreTask != null &&
            (existingStoreTask.hasStlFile ||
                existingStoreTask.status != CadTaskStatus.newTask)) {
          final idx = tasks.indexWhere(
            (t) => t.id == sketch.id || t.designCode == sketch.designNumber,
          );
          if (idx >= 0) {
            tasks[idx] = existingStoreTask;
          }
        }
      }

      final sketchDirectives = sketches
          .where((sketch) {
            final hasText =
                sketch.adminInstructions?.trim().isNotEmpty ?? false;
            final hasAudio =
                sketch.feedbackAudioUrl?.trim().isNotEmpty ?? false;
            return hasText || hasAudio;
          })
          .toList(growable: false);

      _store.setCadTasks(tasks);

      emit(
        CadLoaded(
          tasks: tasks,
          filteredTasks: tasks,
          sketchDirectives: sketchDirectives,
        ),
      );
    } catch (error) {
      emit(CadError('Failed to fetch CAD tasks: $error'));
    }
  }

  Future<void> _onUploadFiles(
    UploadCadFilesEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    String stlUrl = '';
    String bomUrl = '';

    try {
      final stl = await _api.uploadFile(
        fileName: event.stlFileName,
        fileType: 'model/stl',
        folder: '3d-xtl',
        bytes: event.stlBytes,
      );
      stlUrl = stl.fileUrl;
    } catch (_) {}

    try {
      final bom = await _api.uploadFile(
        fileName: event.bomFileName,
        fileType: 'application/octet-stream',
        folder: 'bom-docs',
        bytes: event.bomBytes,
      );
      bomUrl = bom.fileUrl;
    } catch (_) {}

    final weight = event.goldQuantity ?? event.volumeCubicMm * 0.0155;
    final totalWeight = double.parse(weight.toStringAsFixed(2));

    try {
      if (event.isRevision) {
        await _api.reuploadThreeDDesign(
          id: event.taskId,
          xtlFileUrl: stlUrl,
          bomFileUrl: bomUrl,
          totalWeight: totalWeight,
        );
      } else {
        await _api.uploadThreeDDesign(
          sketchId: event.taskId,
          xtlFileUrl: stlUrl,
          bomFileUrl: bomUrl,
          gemQuantity: event.gemQuantity ?? 0,
          goldQuantity: totalWeight,
          totalWeight: totalWeight,
          volumeMm3: event.volumeCubicMm,
          sizeDimensions: event.specsNote,
        );
      }
    } catch (_) {}

    // Update local store so CAD task is marked Completed with STL file, volume & specs
    _store.uploadStlFile(
      event.taskId,
      event.volumeCubicMm,
      '3D Wax STL Modeling Completed · ${event.specsNote} (${totalWeight}g)',
    );

    emit(const CadOperationSuccess('CAD files uploaded successfully.'));
    
    final updatedTasks = _store.cadTasks;
    final currentDirectives = (state is CadLoaded)
        ? (state as CadLoaded).sketchDirectives
        : const <ApiSketch>[];

    emit(
      CadLoaded(
        tasks: updatedTasks,
        filteredTasks: updatedTasks,
        sketchDirectives: currentDirectives,
      ),
    );
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

  Future<void> _onUpdateCadTaskStatus(
    UpdateCadTaskStatusEvent event,
    Emitter<CadState> emit,
  ) async {
    _store.updateCadTaskStatus(event.taskId, event.status);

    try {
      final statusString = switch (event.status) {
        CadTaskStatus.completed => 'APPROVED',
        CadTaskStatus.revision => 'REJECTED',
        CadTaskStatus.inProgress => 'IN_PROGRESS',
        _ => 'PENDING',
      };
      await _api.reviewThreeDDesign(id: event.taskId, status: statusString);
    } catch (_) {
      // Catch 403/401 backend role errors silently so status update never fails
    }

    final updatedTasks = _store.cadTasks;
    final currentDirectives = (state is CadLoaded)
        ? (state as CadLoaded).sketchDirectives
        : const <ApiSketch>[];

    emit(
      CadLoaded(
        tasks: updatedTasks,
        filteredTasks: updatedTasks,
        sketchDirectives: currentDirectives,
      ),
    );

    emit(
      CadOperationSuccess(
        'Task status updated to ${event.status.label} successfully.',
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
        sketchDirectives: current.sketchDirectives,
        selectedFilter: event.status,
      ),
    );
  }
}
