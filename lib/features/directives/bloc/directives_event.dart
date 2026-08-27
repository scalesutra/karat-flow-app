import 'package:flutter/foundation.dart';

@immutable
sealed class DirectivesEvent {
  const DirectivesEvent();
}

final class FetchDirectivesEvent extends DirectivesEvent {
  const FetchDirectivesEvent({this.status, this.search});
  final String? status;
  final String? search;
}

final class DispatchDirectiveEvent extends DirectivesEvent {
  const DispatchDirectiveEvent({
    required this.title,
    required this.targetType,
    required this.instruction,
    this.audioUrl,
    this.imageUrl,
  });

  final String title;
  final String targetType;
  final String instruction;
  final String? audioUrl;
  final String? imageUrl;
}

final class AcknowledgeDirectiveEvent extends DirectivesEvent {
  const AcknowledgeDirectiveEvent(this.id);
  final String id;
}
