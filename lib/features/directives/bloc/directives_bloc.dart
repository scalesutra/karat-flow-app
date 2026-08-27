import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/karatflow_api_repository.dart';
import 'directives_event.dart';
import 'directives_state.dart';

export 'directives_event.dart';
export 'directives_state.dart';

class DirectivesBloc extends Bloc<DirectivesEvent, DirectivesState> {
  DirectivesBloc({KaratFlowApiRepository? repository})
    : _repository = repository ?? KaratFlowApiRepository(),
      super(const DirectivesInitial()) {
    on<FetchDirectivesEvent>(_onFetchDirectives);
    on<DispatchDirectiveEvent>(_onDispatchDirective);
    on<AcknowledgeDirectiveEvent>(_onAcknowledgeDirective);
  }

  final KaratFlowApiRepository _repository;

  Future<void> _onFetchDirectives(
    FetchDirectivesEvent event,
    Emitter<DirectivesState> emit,
  ) async {
    emit(const DirectivesLoading());
    try {
      final list = await _repository.listDirectives(
        status: event.status,
        search: event.search,
      );
      emit(DirectivesLoaded(directives: list));
    } catch (error) {
      emit(DirectivesError('Failed to fetch floor directives: $error'));
    }
  }

  Future<void> _onDispatchDirective(
    DispatchDirectiveEvent event,
    Emitter<DirectivesState> emit,
  ) async {
    try {
      await _repository.dispatchDirective(
        title: event.title,
        targetType: event.targetType,
        instruction: event.instruction,
        audioUrl: event.audioUrl,
        imageUrl: event.imageUrl,
      );
      emit(
        const DirectivesOperationSuccess('Directive dispatched successfully.'),
      );
      add(const FetchDirectivesEvent());
    } catch (error) {
      emit(DirectivesError('Failed to dispatch directive: $error'));
    }
  }

  Future<void> _onAcknowledgeDirective(
    AcknowledgeDirectiveEvent event,
    Emitter<DirectivesState> emit,
  ) async {
    try {
      await _repository.acknowledgeDirective(event.id);
      emit(const DirectivesOperationSuccess('Directive acknowledged.'));
      add(const FetchDirectivesEvent());
    } catch (error) {
      emit(DirectivesError('Failed to acknowledge directive: $error'));
    }
  }
}
