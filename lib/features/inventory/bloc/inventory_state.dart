import 'package:flutter/foundation.dart';
import '../../../data/models/api_models.dart';

@immutable
sealed class InventoryState {
  const InventoryState();
}

final class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

final class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

final class InventoryLoaded extends InventoryState {
  const InventoryLoaded({required this.response});
  final ApiInventoryResponse response;
}

final class InventoryDetailLoaded extends InventoryState {
  const InventoryDetailLoaded({required this.item});
  final ApiInventoryItem item;
}

final class InventoryOperationSuccess extends InventoryState {
  const InventoryOperationSuccess(this.message);
  final String message;
}

final class InventoryError extends InventoryState {
  const InventoryError(this.message);
  final String message;
}

final class PendingIssuancesQueueLoaded extends InventoryState {
  const PendingIssuancesQueueLoaded({required this.queue});
  final List<ApiPendingIssuance> queue;
}
