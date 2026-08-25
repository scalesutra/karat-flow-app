import 'dart:typed_data';

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
  const UpdateCadTaskStatusEvent({required this.taskId, required this.status});

  final String taskId;
  final CadTaskStatus status;
}

/// Upload 3D STL & Matrix block files with calculated metal weight
final class UploadCadFilesEvent extends CadEvent {
  const UploadCadFilesEvent({
    required this.taskId,
    required this.volumeCubicMm,
    required this.specsNote,
    required this.stlFileName,
    required this.stlBytes,
    required this.bomFileName,
    required this.bomBytes,
    this.isRevision = false,
    this.gemQuantity,
    this.goldQuantity,
  });

  final String taskId;
  final double volumeCubicMm;
  final String specsNote;
  final String stlFileName;
  final Uint8List stlBytes;
  final String bomFileName;
  final Uint8List bomBytes;
  final bool isRevision;
  final int? gemQuantity;
  final double? goldQuantity;
}

final class DownloadCadFileEvent extends CadEvent {
  const DownloadCadFileEvent(this.fileKey);

  final String fileKey;
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
