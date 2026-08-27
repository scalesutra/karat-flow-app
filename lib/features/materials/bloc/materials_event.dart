import 'package:flutter/foundation.dart';

@immutable
sealed class MaterialsEvent {
  const MaterialsEvent();
}

final class FetchMaterialsEvent extends MaterialsEvent {
  const FetchMaterialsEvent({this.category, this.search});
  final String? category;
  final String? search;
}

final class UpdateMaterialRateEvent extends MaterialsEvent {
  const UpdateMaterialRateEvent({
    required this.id,
    required this.presetPricePerUnit,
  });
  final String id;
  final double presetPricePerUnit;
}

final class CreateMaterialEvent extends MaterialsEvent {
  const CreateMaterialEvent({
    required this.code,
    required this.name,
    required this.category,
    required this.specification,
    required this.unit,
    required this.presetPricePerUnit,
    this.description = '',
  });
  final String code;
  final String name;
  final String category;
  final String specification;
  final String unit;
  final double presetPricePerUnit;
  final String description;
}
