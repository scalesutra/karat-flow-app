import '../../../domain/models.dart';

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
    this.selectedFilter,
  });

  final List<CadDesignTask> tasks;
  final List<CadDesignTask> filteredTasks;
  final CadTaskStatus? selectedFilter;
}

/// CAD operation successful (e.g. Uploaded STL / Approved / Status updated)
final class CadOperationSuccess extends CadState {
  const CadOperationSuccess(this.message);

  final String message;
}

/// CAD error occurred
final class CadError extends CadState {
  const CadError(this.message);

  final String message;
}
