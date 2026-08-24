import '../../../domain/models.dart';

/// Base Orders Event
sealed class OrdersEvent {
  const OrdersEvent();
}

/// Fetch fresh orders from backend (Zero Cache Policy)
final class FetchOrdersEvent extends OrdersEvent {
  const FetchOrdersEvent({this.statusFilter});

  final String? statusFilter;
}

/// Create and submit a new jewellery wholesale/custom order
final class CreateOrderEvent extends OrdersEvent {
  const CreateOrderEvent(this.order);

  final CustomerOrder order;
}

/// Update order workflow status
final class UpdateOrderStatusEvent extends OrdersEvent {
  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.status,
  });

  final String orderId;
  final OrderStatus status;
}

/// Filter orders by search query or status
final class FilterOrdersEvent extends OrdersEvent {
  const FilterOrdersEvent({
    required this.query,
    this.statusFilter = 'All',
  });

  final String query;
  final String statusFilter;
}
