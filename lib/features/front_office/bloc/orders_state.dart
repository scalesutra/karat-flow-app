import '../../../domain/models.dart';
import '../../../data/models/api_models.dart';

/// Base Orders State (Minimal, readable and clear)
sealed class OrdersState {
  const OrdersState();
}

/// Initial orders state
final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

/// Loading orders or executing order action
final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

/// Orders successfully loaded
final class OrdersLoaded extends OrdersState {
  const OrdersLoaded({
    required this.orders,
    required this.filteredOrders,
    this.selectedFilter = 'All',
    this.searchQuery = '',
  });

  final List<CustomerOrder> orders;
  final List<CustomerOrder> filteredOrders;
  final String selectedFilter;
  final String searchQuery;
}

/// Orders operation successful (e.g. Order created / Status updated)
final class OrderOperationSuccess extends OrdersState {
  const OrderOperationSuccess(this.message);

  final String message;
}

final class OrderTrackingLoaded extends OrdersState {
  const OrderTrackingLoaded(this.tracking);

  final ApiOrderTracking tracking;
}

/// Orders error occurred
final class OrdersError extends OrdersState {
  const OrdersError(this.message);

  final String message;
}
