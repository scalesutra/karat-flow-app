import '../../../domain/models.dart';

/// Base Workshop Event
sealed class WorkshopEvent {
  const WorkshopEvent();
}

/// Fetch fresh workshop manufacturing lots & stages
final class FetchWorkshopLotsEvent extends WorkshopEvent {
  const FetchWorkshopLotsEvent();
}

/// Advance lot pouch to next jewellery stage
final class AdvanceLotStageEvent extends WorkshopEvent {
  const AdvanceLotStageEvent(this.lotId);

  final String lotId;
}

/// Allocate lot to a specific artisan / goldsmith
final class AllocateLotArtisanEvent extends WorkshopEvent {
  const AllocateLotArtisanEvent({
    required this.lotId,
    required this.artisanName,
    this.artisanId,
    this.stageId,
  });

  final String lotId;
  final String artisanName;
  final String? artisanId;
  final String? stageId;
}

/// Filter lots by stage or search query
final class FilterWorkshopLotsEvent extends WorkshopEvent {
  const FilterWorkshopLotsEvent({
    required this.query,
    this.stage,
  });

  final String query;
  final WorkshopStage? stage;
}
