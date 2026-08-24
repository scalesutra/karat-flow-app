import '../../../domain/models.dart';

/// Base CAD Event
sealed class CadEvent {
  const CadEvent();
}

/// Fetch fresh 3D CAD design tasks from backend
final class FetchCadTasksEvent extends CadEvent {
  const FetchCadTasksEvent();
}

/// Update CAD workflow task status
final class UpdateCadTaskStatusEvent extends CadEvent {
  const UpdateCadTaskStatusEvent({
    required this.taskId,
    required this.status,
  });

  final String taskId;
  final CadTaskStatus status;
}

/// Upload 3D STL & Matrix block files with calculated metal weight
final class UploadCadFilesEvent extends CadEvent {
  const UploadCadFilesEvent({
    required this.taskId,
    required this.volumeCubicMm,
    required this.specsNote,
    this.stlFileUrl,
    this.bomFileUrl,
    this.gemQuantity,
    this.goldQuantity,
  });

  final String taskId;
  final double volumeCubicMm;
  final String specsNote;
  final String? stlFileUrl;
  final String? bomFileUrl;
  final int? gemQuantity;
  final double? goldQuantity;
}

/// Approve 3D CAD model for casting
final class ApproveCadTaskEvent extends CadEvent {
  const ApproveCadTaskEvent(this.taskId);

  final String taskId;
}

/// Filter CAD tasks by status
final class FilterCadTasksEvent extends CadEvent {
  const FilterCadTasksEvent(this.status);

  final CadTaskStatus? status;
}
