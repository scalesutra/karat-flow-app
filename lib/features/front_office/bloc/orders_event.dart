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

final class FetchFrontOfficeDataEvent extends OrdersEvent {
  const FetchFrontOfficeDataEvent();
}

final class CreateLiveOrderEvent extends OrdersEvent {
  const CreateLiveOrderEvent({
    required this.customerId,
    required this.dueDate,
    required this.parts,
    this.specialInstructions = '',
  });

  final String customerId;
  final String dueDate;
  final List<Map<String, dynamic>> parts;
  final String specialInstructions;
}

final class CreateAndCheckoutOrderEvent extends OrdersEvent {
  const CreateAndCheckoutOrderEvent({
    required this.customerId,
    required this.dueDate,
    required this.parts,
    this.specialInstructions = '',
    this.clearCart = false,
  });

  final String customerId;
  final String dueDate;
  final List<Map<String, dynamic>> parts;
  final String specialInstructions;
  final bool clearCart;
}

final class AddOrderPartsEvent extends OrdersEvent {
  const AddOrderPartsEvent({required this.orderId, required this.parts});

  final String orderId;
  final List<Map<String, dynamic>> parts;
}

final class CheckoutOrderEvent extends OrdersEvent {
  const CheckoutOrderEvent(this.orderId);

  final String orderId;
}

final class TrackOrderEvent extends OrdersEvent {
  const TrackOrderEvent(this.orderNumber);

  final String orderNumber;
}

final class RegisterFrontOfficeCustomerEvent extends OrdersEvent {
  const RegisterFrontOfficeCustomerEvent({
    required this.name,
    required this.city,
    required this.contactPerson,
    required this.phone,
    this.email = '',
    this.creditLimitLakhs = 0,
    this.notes = '',
  });

  final String name;
  final String city;
  final String contactPerson;
  final String phone;
  final String email;
  final double creditLimitLakhs;
  final String notes;
}

/// Create and submit a new jewellery wholesale/custom order
final class CreateOrderEvent extends OrdersEvent {
  const CreateOrderEvent(this.order);

  final CustomerOrder order;
}

/// Update order workflow status
final class UpdateOrderStatusEvent extends OrdersEvent {
  const UpdateOrderStatusEvent({required this.orderId, required this.status});

  final String orderId;
  final OrderStatus status;
}

/// Filter orders by search query or status
final class FilterOrdersEvent extends OrdersEvent {
  const FilterOrdersEvent({required this.query, this.statusFilter = 'All'});

  final String query;
  final String statusFilter;
}
