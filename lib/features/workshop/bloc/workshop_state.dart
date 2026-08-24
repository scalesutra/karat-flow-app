import '../../../data/models/api_models.dart';
import '../../../domain/models.dart';

/// Base Workshop State (Minimal & clean)
sealed class WorkshopState {
  const WorkshopState();
}

/// Initial workshop state
final class WorkshopInitial extends WorkshopState {
  const WorkshopInitial();
}

/// Loading workshop lots / stages
final class WorkshopLoading extends WorkshopState {
  const WorkshopLoading();
}

/// Workshop lots & artisan workload successfully loaded
final class WorkshopLoaded extends WorkshopState {
  const WorkshopLoaded({
    required this.lots,
    required this.filteredLots,
    required this.team,
    this.apiStages = const [],
    this.selectedStage,
    this.searchQuery = '',
  });

  final List<WorkshopLot> lots;
  final List<WorkshopLot> filteredLots;
  final List<TeamMember> team;
  final List<ApiStage> apiStages;
  final WorkshopStage? selectedStage;
  final String searchQuery;
}

/// Lot advanced or updated successfully
final class WorkshopStageUpdated extends WorkshopState {
  const WorkshopStageUpdated(this.message);

  final String message;
}

/// Workshop error occurred
final class WorkshopError extends WorkshopState {
  const WorkshopError(this.message);

  final String message;
}
