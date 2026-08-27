import 'package:flutter/foundation.dart';
import '../../../data/models/api_models.dart';

@immutable
sealed class MaterialsState {
  const MaterialsState();
}

final class MaterialsInitial extends MaterialsState {
  const MaterialsInitial();
}

final class MaterialsLoading extends MaterialsState {
  const MaterialsLoading();
}

final class MaterialsLoaded extends MaterialsState {
  const MaterialsLoaded({required this.materials});
  final List<ApiMaterial> materials;
}

final class MaterialsOperationSuccess extends MaterialsState {
  const MaterialsOperationSuccess(this.message);
  final String message;
}

final class MaterialsError extends MaterialsState {
  const MaterialsError(this.message);
  final String message;
}
