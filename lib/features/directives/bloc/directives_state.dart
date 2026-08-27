import 'package:flutter/foundation.dart';
import '../../../data/models/api_models.dart';

@immutable
sealed class DirectivesState {
  const DirectivesState();
}

final class DirectivesInitial extends DirectivesState {
  const DirectivesInitial();
}

final class DirectivesLoading extends DirectivesState {
  const DirectivesLoading();
}

final class DirectivesLoaded extends DirectivesState {
  const DirectivesLoaded({required this.directives});
  final List<ApiDirective> directives;
}

final class DirectivesOperationSuccess extends DirectivesState {
  const DirectivesOperationSuccess(this.message);
  final String message;
}

final class DirectivesError extends DirectivesState {
  const DirectivesError(this.message);
  final String message;
}
