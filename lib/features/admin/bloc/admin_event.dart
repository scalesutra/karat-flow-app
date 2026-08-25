import 'dart:typed_data';

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
    required this.email,
    required this.phone,
    required this.stageId,
  });

  final TeamMember member;
  final String email;
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
  const ApproveSketchDesignEvent(this.sketchId);

  final String sketchId;
}

final class ReviewSketchDirectiveEvent extends AdminEvent {
  const ReviewSketchDirectiveEvent({
    required this.sketchId,
    required this.instructions,
    this.audioFileName,
    this.audioBytes,
  });

  final String sketchId;
  final String instructions;
  final String? audioFileName;
  final Uint8List? audioBytes;
}

final class UpdateEmployeeEvent extends AdminEvent {
  const UpdateEmployeeEvent({
    required this.employeeId,
    required this.role,
    required this.isActive,
  });

  final String employeeId;
  final String role;
  final bool isActive;
}

final class RegisterCustomerEvent extends AdminEvent {
  const RegisterCustomerEvent({
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

final class UpdateCustomerEvent extends AdminEvent {
  const UpdateCustomerEvent({
    required this.customerId,
    required this.creditLimitLakhs,
    this.notes = '',
  });

  final String customerId;
  final double creditLimitLakhs;
  final String notes;
}

final class CreateStageEvent extends AdminEvent {
  const CreateStageEvent({
    required this.name,
    required this.stageNumber,
    this.description = '',
  });

  final String name;
  final int stageNumber;
  final String description;
}

final class UpdateStageEvent extends AdminEvent {
  const UpdateStageEvent({
    required this.stageId,
    required this.name,
    required this.isActive,
  });

  final String stageId;
  final String name;
  final bool isActive;
}

final class DeleteStageEvent extends AdminEvent {
  const DeleteStageEvent(this.stageId);

  final String stageId;
}

final class UploadSketchEvent extends AdminEvent {
  const UploadSketchEvent({
    required this.designNumber,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String designNumber;
  final String title;
  final String fileName;
  final Uint8List bytes;
}

final class ReuploadSketchEvent extends AdminEvent {
  const ReuploadSketchEvent({
    required this.sketchId,
    required this.title,
    required this.fileName,
    required this.bytes,
  });

  final String sketchId;
  final String title;
  final String fileName;
  final Uint8List bytes;
}

final class CheckSystemHealthEvent extends AdminEvent {
  const CheckSystemHealthEvent();
}
