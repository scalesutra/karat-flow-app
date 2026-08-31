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

/// Step 2: Extract technical specs via PaddleOCR
final class ExtractCadOcrEvent extends CadEvent {
  const ExtractCadOcrEvent({
    required this.imageUrl,
    this.asyncMode = false,
  });

  final String imageUrl;
  final bool asyncMode;
}

/// Step 3: Final 3D Design Submission
final class Submit3DDesignEvent extends CadEvent {
  const Submit3DDesignEvent({
    required this.sketchId,
    required this.xtlFileUrl,
    required this.bomFileUrl,
    required this.goldQuantity,
    required this.gemQuantity,
    required this.totalWeight,
    this.otherMetalsQuantity = 0.0,
    required this.sizeDimensions,
    this.isRevision = false,
  });

  final String sketchId;
  final String xtlFileUrl;
  final String bomFileUrl;
  final double goldQuantity;
  final int gemQuantity;
  final double totalWeight;
  final double otherMetalsQuantity;
  final String sizeDimensions;
  final bool isRevision;
}

