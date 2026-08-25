import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/karatflow_api_repository.dart';
import 'artisan_event.dart';
import 'artisan_state.dart';

export 'artisan_event.dart';
export 'artisan_state.dart';

class ArtisanBloc extends Bloc<ArtisanEvent, ArtisanState> {
  ArtisanBloc({KaratFlowApiRepository? apiRepository})
    : _api = apiRepository ?? KaratFlowApiRepository(),
      super(const ArtisanInitial()) {
    on<FetchArtisanTasksEvent>(_onFetch);
    on<StartArtisanTaskEvent>(_onStart);
    on<CompleteArtisanTaskEvent>(_onComplete);
    on<ReportArtisanFailureEvent>(_onFailure);
  }

  final KaratFlowApiRepository _api;

  Future<void> _onFetch(
    FetchArtisanTasksEvent event,
    Emitter<ArtisanState> emit,
  ) async {
    emit(const ArtisanLoading());
    try {
      final all = await _api.listWorkerTasks();
      final tasks = event.status.isEmpty
          ? all
          : all
                .where(
                  (task) =>
                      task.status.toUpperCase() == event.status.toUpperCase(),
                )
                .toList();
      emit(ArtisanLoaded(tasks: tasks, status: event.status));
    } catch (error) {
      emit(ArtisanError('Failed to load assigned tasks: $error'));
    }
  }

  Future<void> _onStart(
    StartArtisanTaskEvent event,
    Emitter<ArtisanState> emit,
  ) async {
    try {
      await _api.startWorkerTask(event.taskId);
      emit(const ArtisanActionSuccess('Task started successfully.'));
      add(const FetchArtisanTasksEvent());
    } catch (error) {
      emit(ArtisanError('Failed to start task: $error'));
    }
  }

  Future<void> _onComplete(
    CompleteArtisanTaskEvent event,
    Emitter<ArtisanState> emit,
  ) async {
    try {
      await _api.completeWorkerTask(event.taskId);
      emit(const ArtisanActionSuccess('Task completed successfully.'));
      add(const FetchArtisanTasksEvent());
    } catch (error) {
      emit(ArtisanError('Failed to complete task: $error'));
    }
  }

  Future<void> _onFailure(
    ReportArtisanFailureEvent event,
    Emitter<ArtisanState> emit,
  ) async {
    try {
      await _api.reportWorkerTaskFailure(event.taskId, event.reason);
      emit(const ArtisanActionSuccess('Task issue reported successfully.'));
      add(const FetchArtisanTasksEvent());
    } catch (error) {
      emit(ArtisanError('Failed to report task issue: $error'));
    }
  }
}
