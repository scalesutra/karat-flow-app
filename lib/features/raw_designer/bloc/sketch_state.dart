import '../../../data/models/api_models.dart';

sealed class SketchState {
  const SketchState();
}

final class SketchInitial extends SketchState {
  const SketchInitial();
}

final class SketchLoading extends SketchState {
  const SketchLoading();
}

final class SketchLoaded extends SketchState {
  const SketchLoaded({required this.sketches, required this.status});
  final List<ApiSketch> sketches;
  final String status;
}

final class SketchActionSuccess extends SketchState {
  const SketchActionSuccess(this.message);
  final String message;
}

final class SketchError extends SketchState {
  const SketchError(this.message);
  final String message;
}
