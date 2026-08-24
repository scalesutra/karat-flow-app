import '../../../domain/models.dart';

/// Base Admin Event
sealed class AdminEvent {
  const AdminEvent();
}

/// Fetch admin executive overview, stock stats & registered employees
final class FetchAdminDashboardEvent extends AdminEvent {
  const FetchAdminDashboardEvent();
}

/// Fetch stock vault inventory
final class FetchStockInventoryEvent extends AdminEvent {
  const FetchStockInventoryEvent();
}

/// Register a new workshop artisan / goldsmith
final class AddArtisanEvent extends AdminEvent {
  const AddArtisanEvent(
    this.member, {
    required this.phone,
    required this.stageId,
  });

  final TeamMember member;
  final String phone;
  final String stageId;
}

/// Send creative or operational governance directive
final class SendDirectiveEvent extends AdminEvent {
  const SendDirectiveEvent({required this.recipient, required this.directive});

  final String recipient;
  final String directive;
}

/// Approve 2D sketch design
final class ApproveSketchDesignEvent extends AdminEvent {
  const ApproveSketchDesignEvent(this.designCode);

  final String designCode;
}
