import 'package:flutter/material.dart';

enum HealthTone { healthy, warning, critical }

enum AppRole {
  admin,
  frontOffice,
  processManager,
  cadDesigner,
  rawDesigner,
  workshopArtisan;

  String get label => switch (this) {
    AppRole.admin => 'Admin',
    AppRole.frontOffice => 'Front Office',
    AppRole.processManager => 'Process Manager',
    AppRole.cadDesigner => 'CAD Designer',
    AppRole.rawDesigner => 'Raw Designer',
    AppRole.workshopArtisan => 'Workshop Artisan',
  };

  String get shortDescription => switch (this) {
    AppRole.admin => 'Full operations control, stock, reports & setup',
    AppRole.frontOffice => 'Client orders, design catalog & cart management',
    AppRole.processManager => 'Workshop lot assignment, stage overview & team',
    AppRole.cadDesigner => '3D CAD modeling, STL uploads & design tasks',
    AppRole.rawDesigner => 'Pencil sketch creation, review and revisions',
    AppRole.workshopArtisan => 'Assigned bench work and task completion',
  };
}

enum StatusPivot {
  orders,
  people,
  stages;

  String get singularLabel => switch (this) {
    StatusPivot.orders => 'Order',
    StatusPivot.people => 'Artisan',
    StatusPivot.stages => 'Stage',
  };

  String get label => switch (this) {
    StatusPivot.orders => 'Orders',
    StatusPivot.people => 'People',
    StatusPivot.stages => 'Stages',
  };
}

enum InstructionUrgency {
  today,
  upcoming,
  delayed,
  urgent,
  routine;

  String get label => switch (this) {
    InstructionUrgency.today => 'Today',
    InstructionUrgency.upcoming => 'Upcoming',
    InstructionUrgency.delayed => 'Delayed',
    InstructionUrgency.urgent => 'Urgent',
    InstructionUrgency.routine => 'Routine',
  };
}

enum InstructionStatus {
  sent,
  acknowledged,
  inProgress,
  resolved;

  String get label => switch (this) {
    InstructionStatus.sent => 'Sent',
    InstructionStatus.acknowledged => 'Acknowledged',
    InstructionStatus.inProgress => 'In Progress',
    InstructionStatus.resolved => 'Resolved',
  };
}

enum JewelleryCategory {
  all,
  rings,
  necklaces,
  earrings,
  bangles,
  chains,
  bridalSets;

  String get label => switch (this) {
    JewelleryCategory.all => 'All',
    JewelleryCategory.rings => 'Rings',
    JewelleryCategory.necklaces => 'Necklaces',
    JewelleryCategory.earrings => 'Earrings',
    JewelleryCategory.bangles => 'Bangles',
    JewelleryCategory.chains => 'Chains',
    JewelleryCategory.bridalSets => 'Bridal Sets',
  };

  IconData get icon => switch (this) {
    JewelleryCategory.all => Icons.grid_view_outlined,
    JewelleryCategory.rings => Icons.diamond_outlined,
    JewelleryCategory.necklaces => Icons.auto_awesome_outlined,
    JewelleryCategory.earrings => Icons.grain_outlined,
    JewelleryCategory.bangles => Icons.circle_outlined,
    JewelleryCategory.chains => Icons.link_outlined,
    JewelleryCategory.bridalSets => Icons.stars_outlined,
  };
}

enum OrderStatus {
  pending,
  inWorkshop,
  ready,
  dispatched,
  delivered,
  cancelled;

  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.inWorkshop => 'In Workshop',
    OrderStatus.ready => 'Ready',
    OrderStatus.dispatched => 'Dispatched',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };
}

enum WorkshopStage {
  inQueue,
  cadAndWax,
  casting,
  filingAndAssembly,
  stoneSetting,
  polishing,
  qualityCheck,
  readyForDispatch;

  String get label => switch (this) {
    WorkshopStage.inQueue => 'In Queue',
    WorkshopStage.cadAndWax => 'CAD & Wax',
    WorkshopStage.casting => 'Casting',
    WorkshopStage.filingAndAssembly => 'Filing & Assembly',
    WorkshopStage.stoneSetting => 'Stone Setting',
    WorkshopStage.polishing => 'Polishing',
    WorkshopStage.qualityCheck => 'Quality Check',
    WorkshopStage.readyForDispatch => 'Ready for Dispatch',
  };
}

enum EmployeeStatus { available, working, onLeave, blocked }

extension EmployeeStatusExt on EmployeeStatus {
  String get label => switch (this) {
    EmployeeStatus.available => 'Available',
    EmployeeStatus.working => 'Working',
    EmployeeStatus.onLeave => 'On Leave',
    EmployeeStatus.blocked => 'Blocked',
  };

  HealthTone get tone => switch (this) {
    EmployeeStatus.available => HealthTone.healthy,
    EmployeeStatus.working => HealthTone.healthy,
    EmployeeStatus.onLeave => HealthTone.warning,
    EmployeeStatus.blocked => HealthTone.critical,
  };
}

enum StockCategory {
  rawGold,
  cutDiamonds,
  findings,
  finishedGoods;

  String get label => switch (this) {
    StockCategory.rawGold => 'Raw Gold',
    StockCategory.cutDiamonds => 'Diamonds & Gems',
    StockCategory.findings => 'Findings & Components',
    StockCategory.finishedGoods => 'Finished Goods',
  };
}

class TimelineEntry {
  const TimelineEntry({
    required this.title,
    required this.detail,
    required this.time,
  });

  final String title;
  final String detail;
  final String time;
}

class WorkItem {
  const WorkItem({
    required this.id,
    required this.pivot,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.quantity,
    required this.owner,
    required this.tone,
    required this.metrics,
    required this.timeline,
  });

  final String id;
  final StatusPivot pivot;
  final String title;
  final String subtitle;
  final String status;
  final String quantity;
  final String owner;
  final HealthTone tone;
  final Map<String, String> metrics;
  final List<TimelineEntry> timeline;
}

class Instruction {
  const Instruction({
    required this.id,
    required this.targetId,
    required this.targetLabel,
    required this.message,
    required this.createdBy,
    required this.assignedTo,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.hasPhoto = false,
    this.hasVoice = false,
  });

  final String id;
  final String targetId;
  final String targetLabel;
  final String message;
  final String createdBy;
  final String assignedTo;
  final InstructionUrgency urgency;
  final InstructionStatus status;
  final DateTime createdAt;
  final bool hasPhoto;
  final bool hasVoice;

  Instruction copyWith({InstructionStatus? status}) {
    return Instruction(
      id: id,
      targetId: targetId,
      targetLabel: targetLabel,
      message: message,
      createdBy: createdBy,
      assignedTo: assignedTo,
      urgency: urgency,
      status: status ?? this.status,
      createdAt: createdAt,
      hasPhoto: hasPhoto,
      hasVoice: hasVoice,
    );
  }
}

class JewelleryDesign {
  const JewelleryDesign({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.purity,
    double? grossWeightGrams,
    double? defaultGrossWeightGrams,
    this.netGoldWeightGrams = 0.0,
    this.diamondCarats = 0.0,
    this.makingChargesPerGram = 0,
    this.accentColor = const Color(0xFFB9812E),
    double? estimatedPrice,
    this.imageUrl = '',
    required this.description,
    this.isPopular = false,
  }) : grossWeightGrams = grossWeightGrams ?? defaultGrossWeightGrams ?? 0.0,
       defaultGrossWeightGrams =
           defaultGrossWeightGrams ?? grossWeightGrams ?? 0.0,
       _estimatedPrice = estimatedPrice;

  final String id;
  final String name;
  final String code;
  final JewelleryCategory category;
  final String purity;
  final double grossWeightGrams;
  final double defaultGrossWeightGrams;
  final double netGoldWeightGrams;
  final double diamondCarats;
  final int makingChargesPerGram;
  final Color accentColor;
  final double? _estimatedPrice;
  final String imageUrl;
  final String description;
  final bool isPopular;

  double get estimatedPrice {
    if (_estimatedPrice != null && _estimatedPrice > 0) {
      return _estimatedPrice;
    }
    final ratePerGram = purity.contains('18') ? 5960.0 : 7280.0;
    return (grossWeightGrams * ratePerGram) +
        (makingChargesPerGram * grossWeightGrams);
  }

  JewelleryDesign copyWith({
    String? id,
    String? name,
    String? code,
    JewelleryCategory? category,
    String? purity,
    double? grossWeightGrams,
    double? defaultGrossWeightGrams,
    double? netGoldWeightGrams,
    double? diamondCarats,
    int? makingChargesPerGram,
    Color? accentColor,
    double? estimatedPrice,
    String? imageUrl,
    String? description,
    bool? isPopular,
  }) {
    return JewelleryDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      category: category ?? this.category,
      purity: purity ?? this.purity,
      grossWeightGrams: grossWeightGrams ?? this.grossWeightGrams,
      defaultGrossWeightGrams:
          defaultGrossWeightGrams ?? this.defaultGrossWeightGrams,
      netGoldWeightGrams: netGoldWeightGrams ?? this.netGoldWeightGrams,
      diamondCarats: diamondCarats ?? this.diamondCarats,
      makingChargesPerGram: makingChargesPerGram ?? this.makingChargesPerGram,
      accentColor: accentColor ?? this.accentColor,
      estimatedPrice: estimatedPrice ?? _estimatedPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isPopular: isPopular ?? this.isPopular,
    );
  }
}

class CartItem {
  const CartItem({
    required this.design,
    required this.quantity,
    required this.selectedPurity,
  });

  final JewelleryDesign design;
  final int quantity;
  final String selectedPurity;

  double get totalGrossWeight => design.grossWeightGrams * quantity;
  double get totalEstimatedPrice => design.estimatedPrice * quantity;

  CartItem copyWith({int? quantity, String? selectedPurity}) {
    return CartItem(
      design: design,
      quantity: quantity ?? this.quantity,
      selectedPurity: selectedPurity ?? this.selectedPurity,
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.clientFirmName,
    required this.clientCity,
    required this.itemsCount,
    required this.totalGrossGrams,
    required this.estimatedTotalAmount,
    required this.status,
    required this.promiseDate,
    required this.createdAt,
    required this.itemsSummary,
    this.currentWorkshopStage = 'N/A',
    this.responsibleManager = 'Arjun · PM',
    this.isBlocked = false,
    this.blockedReason,
  });

  final String id;
  final String clientFirmName;
  final String clientCity;
  final int itemsCount;
  final double totalGrossGrams;
  final double estimatedTotalAmount;
  final OrderStatus status;
  final String promiseDate;
  final DateTime createdAt;
  final String itemsSummary;
  final String currentWorkshopStage;
  final String responsibleManager;
  final bool isBlocked;
  final String? blockedReason;

  CustomerOrder copyWith({
    String? id,
    String? clientFirmName,
    String? clientCity,
    int? itemsCount,
    double? totalGrossGrams,
    double? estimatedTotalAmount,
    OrderStatus? status,
    String? promiseDate,
    DateTime? createdAt,
    String? itemsSummary,
    String? currentWorkshopStage,
    String? responsibleManager,
    bool? isBlocked,
    String? blockedReason,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      clientFirmName: clientFirmName ?? this.clientFirmName,
      clientCity: clientCity ?? this.clientCity,
      itemsCount: itemsCount ?? this.itemsCount,
      totalGrossGrams: totalGrossGrams ?? this.totalGrossGrams,
      estimatedTotalAmount: estimatedTotalAmount ?? this.estimatedTotalAmount,
      status: status ?? this.status,
      promiseDate: promiseDate ?? this.promiseDate,
      createdAt: createdAt ?? this.createdAt,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      currentWorkshopStage: currentWorkshopStage ?? this.currentWorkshopStage,
      responsibleManager: responsibleManager ?? this.responsibleManager,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedReason: (isBlocked != null && !isBlocked)
          ? null
          : (blockedReason ?? this.blockedReason),
    );
  }
}

class ClientInfo {
  const ClientInfo({
    required this.id,
    required this.firmName,
    required this.city,
    required this.contactPerson,
    required this.phone,
    required this.creditLimitLakhs,
    required this.outstandingBalance,
    required this.activeOrdersCount,
  });

  final String id;
  final String firmName;
  final String city;
  final String contactPerson;
  final String phone;
  final double creditLimitLakhs;
  final double outstandingBalance;
  final int activeOrdersCount;
}

class WorkshopLot {
  const WorkshopLot({
    required this.id,
    required this.orderId,
    required this.designCode,
    required this.productTitle,
    required this.stage,
    required this.assignedEmployee,
    required this.assignedEmployeeRole,
    required this.pieces,
    required this.issueWeightGrams,
    required this.targetWeightGrams,
    required this.tone,
    required this.blockerReason,
    required this.lastUpdatedTime,
  });

  final String id;
  final String orderId;
  final String designCode;
  final String productTitle;
  final WorkshopStage stage;
  final String assignedEmployee;
  final String assignedEmployeeRole;
  final int pieces;
  final double issueWeightGrams;
  final double targetWeightGrams;
  final HealthTone tone;
  final String? blockerReason;
  final String lastUpdatedTime;

  WorkshopLot copyWith({
    WorkshopStage? stage,
    String? assignedEmployee,
    String? assignedEmployeeRole,
    HealthTone? tone,
    String? blockerReason,
    String? lastUpdatedTime,
  }) {
    return WorkshopLot(
      id: id,
      orderId: orderId,
      designCode: designCode,
      productTitle: productTitle,
      stage: stage ?? this.stage,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      assignedEmployeeRole: assignedEmployeeRole ?? this.assignedEmployeeRole,
      pieces: pieces,
      issueWeightGrams: issueWeightGrams,
      targetWeightGrams: targetWeightGrams,
      tone: tone ?? this.tone,
      blockerReason: blockerReason ?? this.blockerReason,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.craft,
    required this.shift,
    required this.activeLotsCount,
    required this.status,
    required this.todayEfficiencyPercent,
    required this.currentAssignment,
  });

  final String id;
  final String name;
  final String craft;
  final String shift;
  final int activeLotsCount;
  final EmployeeStatus status;
  final int todayEfficiencyPercent;
  final String currentAssignment;
}

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.purityOrGrade,
    required this.totalAvailable,
    required this.reservedInLots,
    required this.unit,
    required this.vaultLocation,
    required this.discrepancyGrams,
  });

  final String id;
  final String name;
  final StockCategory category;
  final String purityOrGrade;
  final double totalAvailable;
  final double reservedInLots;
  final String unit;
  final String vaultLocation;
  final double discrepancyGrams;

  double get netFreeQuantity => totalAvailable - reservedInLots;
}

class GoldRates {
  const GoldRates({
    required this.gold24KPerGram,
    required this.gold22KPerGram,
    required this.gold18KPerGram,
    required this.silverPerKg,
    required this.lastUpdatedTime,
  });

  final double gold24KPerGram;
  final double gold22KPerGram;
  final double gold18KPerGram;
  final double silverPerKg;
  final String lastUpdatedTime;
}

enum CadTaskStatus {
  newTask,
  inProgress,
  completed,
  revision;

  String get label => switch (this) {
    CadTaskStatus.newTask => 'New',
    CadTaskStatus.inProgress => 'In Progress',
    CadTaskStatus.completed => 'Completed',
    CadTaskStatus.revision => 'Revision',
  };
}

class CadDesignTask {
  CadDesignTask({
    required this.id,
    required this.orderId,
    required this.designCode,
    required this.productTitle,
    required this.clientName,
    required this.specs,
    required this.notes,
    required this.estimatedWeightGrams,
    required this.status,
    this.hasVoiceNote = false,
    this.hasSketchImage = false,
    this.hasStlFile = false,
    required this.assignedTo,
    required this.receivedAt,
    this.lastUpdated = 'Just now',
    this.revisionNotes,
    this.hasRevisionVoice = false,
    this.volumeCubicMm,
    this.modelFileUrl,
  });

  final String id;
  final String orderId;
  final String designCode;
  final String productTitle;
  final String clientName;
  final String specs;
  final String notes;
  final double estimatedWeightGrams;
  CadTaskStatus status;
  bool hasVoiceNote;
  bool hasSketchImage;
  bool hasStlFile;
  final String assignedTo;
  final DateTime receivedAt;
  String lastUpdated;
  String? revisionNotes;
  bool hasRevisionVoice;
  double? volumeCubicMm;
  final String? modelFileUrl;

  CadDesignTask copyWith({
    CadTaskStatus? status,
    bool? hasVoiceNote,
    bool? hasSketchImage,
    bool? hasStlFile,
    String? lastUpdated,
    String? revisionNotes,
    bool? hasRevisionVoice,
    double? volumeCubicMm,
    String? specs,
    String? modelFileUrl,
  }) {
    return CadDesignTask(
      id: id,
      orderId: orderId,
      designCode: designCode,
      productTitle: productTitle,
      clientName: clientName,
      specs: specs ?? this.specs,
      notes: notes,
      estimatedWeightGrams: estimatedWeightGrams,
      status: status ?? this.status,
      hasVoiceNote: hasVoiceNote ?? this.hasVoiceNote,
      hasSketchImage: hasSketchImage ?? this.hasSketchImage,
      hasStlFile: hasStlFile ?? this.hasStlFile,
      assignedTo: assignedTo,
      receivedAt: receivedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      revisionNotes: revisionNotes ?? this.revisionNotes,
      hasRevisionVoice: hasRevisionVoice ?? this.hasRevisionVoice,
      volumeCubicMm: volumeCubicMm ?? this.volumeCubicMm,
      modelFileUrl: modelFileUrl ?? this.modelFileUrl,
    );
  }
}
