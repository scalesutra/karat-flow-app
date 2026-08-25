sealed class ArtisanEvent {
  const ArtisanEvent();
}

final class FetchArtisanTasksEvent extends ArtisanEvent {
  const FetchArtisanTasksEvent({this.status = ''});
  final String status;
}

final class StartArtisanTaskEvent extends ArtisanEvent {
  const StartArtisanTaskEvent(this.taskId);
  final String taskId;
}

final class CompleteArtisanTaskEvent extends ArtisanEvent {
  const CompleteArtisanTaskEvent(this.taskId);
  final String taskId;
}

final class ReportArtisanFailureEvent extends ArtisanEvent {
  const ReportArtisanFailureEvent({required this.taskId, required this.reason});
  final String taskId;
  final String reason;
}
