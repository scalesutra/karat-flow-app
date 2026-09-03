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

/// Register a new employee (Keycloak sync & DB creation)
final class AddArtisanEvent extends AdminEvent {
  const AddArtisanEvent(
    this.member, {
    required this.email,
    required this.phone,
    required this.stageId,
    this.role = 'CRAFTSMAN',
    this.password,
    this.skills,
    this.specialty,
  });

  final TeamMember member;
  final String email;
  final String phone;
  final String stageId;
  final String role;
  final String? password;
  final List<String>? skills;
  final String? specialty;
}

final class CreateEmployeeEvent extends AdminEvent {
  const CreateEmployeeEvent({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.password,
    this.skills,
    this.specialty,
  });

  final String name;
  final String email;
  final String phone;
  final String role;
  final String? password;
  final List<String>? skills;
  final String? specialty;
}

/// Send creative or operational governance directive
final class SendDirectiveEvent extends AdminEvent {
  const SendDirectiveEvent({
    required this.recipient,
    required this.directive,
    this.audioFileName,
    this.audioBytes,
    this.imageFileName,
    this.imageBytes,
  });

  final String recipient;
  final String directive;
  final String? audioFileName;
  final Uint8List? audioBytes;
  final String? imageFileName;
  final Uint8List? imageBytes;
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
    this.imageFileName,
    this.imageBytes,
  });

  final String sketchId;
  final String instructions;
  final String? audioFileName;
  final Uint8List? audioBytes;
  final String? imageFileName;
  final Uint8List? imageBytes;
}

final class UpdateEmployeeEvent extends AdminEvent {
  const UpdateEmployeeEvent({
    required this.employeeId,
    this.name,
    this.phone,
    this.role,
    this.specialty,
    this.skills,
    this.isActive,
  });

  final String employeeId;
  final String? name;
  final String? phone;
  final String? role;
  final String? specialty;
  final List<String>? skills;
  final bool? isActive;
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

/// Update 3D CAD product stock and catalog record via PATCH /three-d-designs/{designId}/product
final class UpdateProductStockEvent extends AdminEvent {
  const UpdateProductStockEvent({
    required this.designId,
    this.stock,
    this.stockStatus,
    this.price,
    this.title,
    this.category,
    this.goldQuantity,
    this.totalWeight,
    this.description,
    this.imageUrl,
  });

  final String designId;
  final int? stock;
  final String? stockStatus;
  final double? price;
  final String? title;
  final String? category;
  final double? goldQuantity;
  final double? totalWeight;
  final String? description;
  final String? imageUrl;
}
