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
    this.notes,
  });

  final String name;
  final String category;
  final String purity;
  final double totalStock;
  final double reservedWip;
  final double freeBalance;
  final String unit;
  final String location;
  final String? notes;
}

final class GetInventoryByIdEvent extends InventoryEvent {
  const GetInventoryByIdEvent({required this.id});
  final String id;
}

final class UpdateInventoryItemEvent extends InventoryEvent {
  const UpdateInventoryItemEvent({
    required this.id,
    this.totalStock,
    this.reservedWip,
    this.freeBalance,
    this.location,
    this.notes,
  });

  final String id;
  final double? totalStock;
  final double? reservedWip;
  final double? freeBalance;
  final String? location;
  final String? notes;
}

final class DeleteInventoryItemEvent extends InventoryEvent {
  const DeleteInventoryItemEvent({required this.id});
  final String id;
}

final class FetchPendingIssuancesQueueEvent extends InventoryEvent {
  const FetchPendingIssuancesQueueEvent();
}

final class IssueMaterialsToCraftsmanEvent extends InventoryEvent {
  const IssueMaterialsToCraftsmanEvent({
    required this.orderPartId,
    required this.items,
    this.notes = '',
  });

  final String orderPartId;
  final List<Map<String, dynamic>> items;
  final String notes;
}
