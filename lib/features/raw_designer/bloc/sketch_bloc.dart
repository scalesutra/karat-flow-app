import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/karatflow_api_repository.dart';
import 'sketch_event.dart';
import 'sketch_state.dart';

export 'sketch_event.dart';
export 'sketch_state.dart';

class SketchBloc extends Bloc<SketchEvent, SketchState> {
  SketchBloc({KaratFlowApiRepository? apiRepository})
    : _api = apiRepository ?? KaratFlowApiRepository(),
      super(const SketchInitial()) {
    on<FetchSketchesEvent>(_onFetch);
    on<UploadRawSketchEvent>(_onUpload);
    on<ReuploadRawSketchEvent>(_onReupload);
  }

  final KaratFlowApiRepository _api;

  Future<void> _onFetch(
    FetchSketchesEvent event,
    Emitter<SketchState> emit,
  ) async {
    emit(const SketchLoading());
    try {
      final sketches = await _api.listSketches(
        status: event.status,
        limit: 100,
      );
      emit(SketchLoaded(sketches: sketches, status: event.status));
    } catch (error) {
      emit(SketchError('Failed to load sketches: $error'));
    }
  }

  Future<void> _onUpload(
    UploadRawSketchEvent event,
    Emitter<SketchState> emit,
  ) async {
    emit(const SketchLoading());
    try {
      final upload = await _api.uploadFile(
        fileName: event.fileName,
        fileType: _contentType(event.fileName),
        category: 'sketches',
        bytes: event.bytes,
      );
      await _api.uploadSketch(
        designNumber: event.designNumber,
        title: event.title,
        sketchUrl: upload.fileKey,
      );
      emit(const SketchActionSuccess('Sketch uploaded successfully.'));
      add(const FetchSketchesEvent());
    } catch (error) {
      emit(SketchError('Failed to upload sketch: $error'));
    }
  }

  Future<void> _onReupload(
    ReuploadRawSketchEvent event,
    Emitter<SketchState> emit,
  ) async {
    emit(const SketchLoading());
    try {
      final upload = await _api.uploadFile(
        fileName: event.fileName,
        fileType: _contentType(event.fileName),
        category: 'sketches',
        bytes: event.bytes,
      );
      await _api.reuploadSketch(
        id: event.sketchId,
        title: event.title,
        sketchUrl: upload.fileKey,
      );
      emit(const SketchActionSuccess('Sketch revision uploaded successfully.'));
      add(const FetchSketchesEvent());
    } catch (error) {
      emit(SketchError('Failed to upload sketch revision: $error'));
    }
  }

  static String _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
