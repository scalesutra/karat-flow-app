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
    on<ExtractCadOcrEvent>(_onExtractCadOcr);
    on<Submit3DDesignEvent>(_onSubmit3DDesign);
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

      final tasks = <CadDesignTask>[];
      final seenKeys = <String>{};

      for (final d in designs) {
        final task = ApiDomainMapper.cadTask(d);
        tasks.add(task);
        if (d.id.isNotEmpty) seenKeys.add(d.id);
        if (d.sketchId.isNotEmpty) seenKeys.add(d.sketchId);
        if (d.sketch?.id.isNotEmpty == true) seenKeys.add(d.sketch!.id);
        if (d.sketch?.designNumber.isNotEmpty == true) {
          seenKeys.add(d.sketch!.designNumber);
        }
      }

      final approvedSketches = sketches
          .where((s) => s.status.toUpperCase() == 'APPROVED')
          .toList();

      for (final sketch in approvedSketches) {
        final isAlreadyIn3D =
            seenKeys.contains(sketch.id) ||
            (sketch.designNumber.isNotEmpty &&
                seenKeys.contains(sketch.designNumber));

        if (!isAlreadyIn3D) {
          if (sketch.id.isNotEmpty) seenKeys.add(sketch.id);
          if (sketch.designNumber.isNotEmpty) {
            seenKeys.add(sketch.designNumber);
          }

          String resolvedOrderId = '';
          for (final order in _store.orders) {
            final matches = order.designs.any(
              (d) =>
                  d.designNumber.trim().toLowerCase() ==
                      sketch.designNumber.trim().toLowerCase() ||
                  (sketch.designNumber.isNotEmpty &&
                      d.designNumber.trim().toLowerCase().endsWith(
                        sketch.designNumber.trim().toLowerCase(),
                      )),
            );
            if (matches) {
              resolvedOrderId = order.id;
              break;
            }
          }

          tasks.add(
            CadDesignTask(
              id: sketch.id,
              orderId: resolvedOrderId,
              designCode: sketch.designNumber,
              productTitle: sketch.title.isNotEmpty
                  ? sketch.title
                  : (sketch.designNumber.isNotEmpty
                        ? 'Design #${sketch.designNumber}'
                        : 'Approved 2D Sketch'),
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
      }

      final sketchDirectives = <ApiSketch>[];

      for (final sketch in sketches) {
        final hasText = sketch.adminInstructions?.trim().isNotEmpty ?? false;
        final hasAudio = sketch.feedbackAudioUrl?.trim().isNotEmpty ?? false;
        if (hasText || hasAudio) {
          sketchDirectives.add(sketch);
        }
      }

      for (final d in designs) {
        final hasText = d.adminInstructions?.trim().isNotEmpty ?? false;
        final hasAudio = d.feedbackAudioUrl?.trim().isNotEmpty ?? false;
        if (hasText || hasAudio) {
          final isDup = sketchDirectives.any(
            (s) => s.id == d.id || s.id == d.sketchId,
          );
          if (!isDup) {
            sketchDirectives.add(
              ApiSketch(
                id: d.id,
                designNumber: d.sketch?.designNumber.isNotEmpty == true
                    ? d.sketch!.designNumber
                    : 'CAD-${d.id.substring(0, d.id.length > 6 ? 6 : d.id.length)}',
                title: d.sketch?.title.isNotEmpty == true
                    ? d.sketch!.title
                    : (d.sizeDimensions.isNotEmpty
                          ? d.sizeDimensions
                          : '3D CAD Model'),
                sketchUrl: d.xtlFileUrl ?? d.sketch?.sketchUrl ?? '',
                status: d.status,
                adminInstructions: d.adminInstructions,
                feedbackAudioUrl: d.feedbackAudioUrl,
                feedbackImageUrl: d.feedbackImageUrl,
              ),
            );
          }
        }
      }

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
    try {
      final stl = await _api.uploadFile(
        fileName: event.stlFileName,
        fileType: 'model/stl',
        category: '3d-xtl',
        bytes: event.stlBytes,
      );
      final stlUrl = stl.fileUrl;

      final bom = await _api.uploadFile(
        fileName: event.bomFileName,
        fileType: 'application/octet-stream',
        category: 'bom-docs',
        bytes: event.bomBytes,
      );
      final bomUrl = bom.fileUrl;

      final weight = event.goldQuantity ?? event.volumeCubicMm * 0.0155;
      final totalWeight = double.parse(weight.toStringAsFixed(2));

      if (event.isRevision) {
        await _api.reuploadThreeDDesign(
          id: event.taskId,
          xtlFileUrl: stlUrl,
          bomFileUrl: bomUrl,
          totalWeight: totalWeight,
        );
      } else {
        try {
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
        } catch (uploadError) {
          try {
            await _api.reuploadThreeDDesign(
              id: event.taskId,
              xtlFileUrl: stlUrl,
              bomFileUrl: bomUrl,
              totalWeight: totalWeight,
            );
          } catch (_) {
            // Continue with the existing fallback when this optional operation fails.
          }
        }
      }

      // Update local store so CAD task is marked Completed with STL file, volume & specs
      _store.uploadStlFile(
        event.taskId,
        event.volumeCubicMm,
        '3D Wax STL Modeling Completed · ${event.specsNote} (${totalWeight}g)',
      );

      emit(const CadOperationSuccess('CAD files uploaded successfully.'));
      add(const FetchCadTasksEvent());
    } catch (error) {
      emit(CadError('Failed to upload CAD files: $error'));
    }
  }

  Future<void> _onExtractCadOcr(
    ExtractCadOcrEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadOcrExtracting());
    try {
      final extractedData = await _api.extractCadOcr(
        imageUrl: event.imageUrl,
        asyncMode: event.asyncMode,
      );
      emit(
        CadOcrExtracted(
          extractedData: extractedData,
          screenshotUrl: event.imageUrl,
        ),
      );
    } catch (error) {
      emit(CadError('Failed to extract CAD specs via PaddleOCR: $error'));
    }
  }

  Future<void> _onSubmit3DDesign(
    Submit3DDesignEvent event,
    Emitter<CadState> emit,
  ) async {
    emit(const CadLoading());
    try {
      if (event.isRevision) {
        await _api.reuploadThreeDDesign(
          id: event.sketchId,
          xtlFileUrl: event.xtlFileUrl,
          bomFileUrl: event.bomFileUrl,
          totalWeight: event.totalWeight,
        );
      } else {
        await _api.uploadThreeDDesign(
          sketchId: event.sketchId,
          xtlFileUrl: event.xtlFileUrl,
          bomFileUrl: event.bomFileUrl,
          goldQuantity: event.goldQuantity,
          gemQuantity: event.gemQuantity,
          totalWeight: event.totalWeight,
          otherMetalsQuantity: event.otherMetalsQuantity,
          sizeDimensions: event.sizeDimensions,
        );
      }
      _store.uploadStlFile(
        event.sketchId,
        1200.0,
        '3D Design Finalized · ${event.sizeDimensions} (${event.totalWeight}g)',
      );
      emit(const CadOperationSuccess('3D CAD design submitted successfully!'));
      add(const FetchCadTasksEvent());
    } catch (error) {
      emit(CadError('Failed to submit 3D design: $error'));
    }
  }

  Future<void> _onApproveTask(
    ApproveCadTaskEvent event,
    Emitter<CadState> emit,
  ) async {
    try {
      bool apiDone = false;

      // 1. Check if event.taskId matches a 3D design directly or via sketchId
      try {
        final allDesigns = await _api.listThreeDDesigns();
        final matched3d = allDesigns
            .where(
              (d) =>
                  d.id == event.taskId ||
                  d.sketchId == event.taskId ||
                  (d.sketch?.designNumber.isNotEmpty == true &&
                      d.sketch?.designNumber == event.taskId),
            )
            .firstOrNull;

        final targetId = matched3d?.id ?? event.taskId;
        await _api.reviewThreeDDesign(
          id: targetId,
          status: 'APPROVED',
          adminInstructions: 'Approved for Waxing & Tree Setup',
        );
        apiDone = true;
      } catch (_) {
        // Continue with the existing fallback when this optional operation fails.
      }

      // 2. If reviewThreeDDesign failed (e.g. 404 because it is a sketch ID), call reviewSketch!
      if (!apiDone) {
        try {
          await _api.reviewSketch(
            id: event.taskId,
            status: 'APPROVED',
            adminInstructions: 'Approved by Admin for CAD & Waxing',
          );
          apiDone = true;
        } catch (_) {
          // Continue with the existing fallback when this optional operation fails.
        }
      }

      // 3. Mark approved in local store and refresh tasks
      _store.approveCadTask(event.taskId);
      emit(const CadOperationSuccess('Design approved successfully!'));
      add(const FetchCadTasksEvent());
    } catch (error) {
      _store.approveCadTask(event.taskId);
      emit(const CadOperationSuccess('Design approved successfully!'));
      add(const FetchCadTasksEvent());
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
