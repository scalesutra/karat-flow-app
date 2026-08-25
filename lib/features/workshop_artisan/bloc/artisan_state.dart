import '../../../data/models/api_models.dart';

sealed class ArtisanState {
  const ArtisanState();
}

final class ArtisanInitial extends ArtisanState {
  const ArtisanInitial();
}

final class ArtisanLoading extends ArtisanState {
  const ArtisanLoading();
}

final class ArtisanLoaded extends ArtisanState {
  const ArtisanLoaded({required this.tasks, required this.status});
  final List<ApiWorkerTask> tasks;
  final String status;
}

final class ArtisanActionSuccess extends ArtisanState {
  const ArtisanActionSuccess(this.message);
  final String message;
}

final class ArtisanError extends ArtisanState {
  const ArtisanError(this.message);
  final String message;
}
