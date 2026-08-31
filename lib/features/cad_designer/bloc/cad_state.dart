import '../../../domain/models.dart';
import '../../../data/models/api_models.dart';

/// Base CAD State (Minimal & clear)
sealed class CadState {
  const CadState();
}

/// Initial CAD state
final class CadInitial extends CadState {
  const CadInitial();
}

/// Loading CAD tasks or uploading files
final class CadLoading extends CadState {
  const CadLoading();
}

/// CAD tasks successfully loaded
final class CadLoaded extends CadState {
  const CadLoaded({
    required this.tasks,
    required this.filteredTasks,
    this.sketchDirectives = const [],
    this.selectedFilter,
  });

  final List<CadDesignTask> tasks;
  final List<CadDesignTask> filteredTasks;
  final List<ApiSketch> sketchDirectives;
  final CadTaskStatus? selectedFilter;
}

/// CAD operation successful (e.g. Uploaded STL / Approved / Status updated)
final class CadOperationSuccess extends CadState {
  const CadOperationSuccess(this.message);

  final String message;
}

final class CadDownloadReady extends CadState {
  const CadDownloadReady(this.url);

  final String url;
}

/// CAD error occurred
final class CadError extends CadState {
  const CadError(this.message);

  final String message;
}

/// PaddleOCR Spec extraction in progress
final class CadOcrExtracting extends CadState {
  const CadOcrExtracting();
}

/// PaddleOCR Spec extraction completed
final class CadOcrExtracted extends CadState {
  const CadOcrExtracted({
    required this.extractedData,
    required this.screenshotUrl,
  });

  final CadOcrExtractedData extractedData;
  final String screenshotUrl;
}

