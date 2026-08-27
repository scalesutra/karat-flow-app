import 'package:flutter/foundation.dart';

@immutable
sealed class InventoryEvent {
  const InventoryEvent();
}

final class FetchInventoryEvent extends InventoryEvent {
  const FetchInventoryEvent({this.category, this.search});
  final String? category;
  final String? search;
}

final class AddInventoryItemEvent extends InventoryEvent {
  const AddInventoryItemEvent({
    required this.name,
    required this.category,
    required this.purity,
    required this.totalStock,
    this.reservedWip = 0.0,
    required this.freeBalance,
    required this.unit,
    required this.location,
  });

  final String name;
  final String category;
  final String purity;
  final double totalStock;
  final double reservedWip;
  final double freeBalance;
  final String unit;
  final String location;
}
