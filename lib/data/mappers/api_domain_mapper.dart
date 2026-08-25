import '../models/api_models.dart';
import '../../domain/models.dart';

abstract final class ApiDomainMapper {
  static ClientInfo customer(ApiCustomer value) => ClientInfo(
    id: value.id,
    firmName: value.name,
    city: value.city,
    contactPerson: value.contactPerson,
    phone: value.phone,
    creditLimitLakhs: value.creditLimitLakhs,
    outstandingBalance: value.outstandingLakhs,
    activeOrdersCount: value.ordersCount,
  );

  static CustomerOrder order(ApiOrder value) {
    final firstPart = value.parts.firstOrNull;
    return CustomerOrder(
      id: value.orderNumber.isNotEmpty ? value.orderNumber : value.id,
      clientFirmName: value.customerName.isNotEmpty
          ? value.customerName
          : 'Client Order',
      clientCity: value.customerCity,
      itemsCount: value.parts.fold(0, (sum, part) => sum + part.quantity),
      totalGrossGrams: value.parts.fold(
        0,
        (sum, part) => sum + part.grossWeight,
      ),
      estimatedTotalAmount: 0,
      status: switch (value.status.toUpperCase()) {
        'DRAFT' || 'PENDING' => OrderStatus.pending,
        'READY' => OrderStatus.ready,
        'CHECKED_OUT' || 'IN_PRODUCTION' => OrderStatus.inWorkshop,
        'DISPATCHED' => OrderStatus.dispatched,
        'DELIVERED' => OrderStatus.delivered,
        'CANCELLED' || 'CANCELED' => OrderStatus.cancelled,
        _ => OrderStatus.inWorkshop,
      },
      promiseDate: value.dueDate,
      createdAt:
          value.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      itemsSummary: value.parts.isEmpty
          ? ''
          : value.parts
                .map((part) => '${part.quantity}x ${part.designNumber}')
                .join(', '),
      currentWorkshopStage: firstPart?.currentStage ?? '',
      responsibleManager: '',
    );
  }

  static String _cleanText(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    if (text.contains('[ 🎙️ Voice Note: ')) {
      final clean = text.substring(0, text.indexOf('[ 🎙️ Voice Note: ')).trim();
      return clean.isNotEmpty ? clean : 'Voice Directive Note Attached';
    }
    return text.trim();
  }

  static JewelleryDesign sketch(ApiSketch value) => JewelleryDesign(
    id: value.id,
    name: value.title,
    code: value.designNumber,
    category: JewelleryCategory.all,
    purity: '',
    grossWeightGrams: 0,
    imageUrl: value.sketchUrl,
    description: _cleanText(value.adminInstructions),
    isPopular: value.status == 'APPROVED',
  );

  static JewelleryDesign threeDDesign(ApiThreeDDesign value) => JewelleryDesign(
    id: value.id,
    name: value.sketchId,
    code: value.id,
    category: JewelleryCategory.all,
    purity: '',
    grossWeightGrams: value.totalWeight,
    imageUrl: value.xtlFileUrl ?? '',
    description: _cleanText(value.adminInstructions).isNotEmpty
        ? _cleanText(value.adminInstructions)
        : value.sizeDimensions,
    isPopular: value.status == 'APPROVED',
  );

  static CadDesignTask cadTask(ApiThreeDDesign value) {
    final sketchTitle = (value.sketch?.title.isNotEmpty == true)
        ? value.sketch!.title
        : ((value.sketch?.designNumber.isNotEmpty == true)
              ? value.sketch!.designNumber
              : (value.sizeDimensions.isNotEmpty
                    ? value.sizeDimensions
                    : '3D CAD Design'));

    final code = (value.sketch?.designNumber.isNotEmpty == true)
        ? value.sketch!.designNumber
        : 'CAD-${value.id.substring(0, value.id.length > 6 ? 6 : value.id.length)}';

    return CadDesignTask(
      id: value.id,
      orderId: code,
      designCode: code,
      productTitle: sketchTitle,
      clientName: value.sketch?.designer?.name ?? 'Client Design',
      specs: 'Weight: ${value.totalWeight}g · Volume: ${value.volumeMm3}mm³',
      notes: '3D Wax STL Modeling Completed',
      estimatedWeightGrams: value.totalWeight,
      status: switch (value.status.toUpperCase()) {
        'APPROVED' => CadTaskStatus.completed,
        'REVISION' || 'REJECTED' => CadTaskStatus.revision,
        'IN_PROGRESS' => CadTaskStatus.inProgress,
        _ => CadTaskStatus.completed,
      },
      hasSketchImage: value.sketch?.sketchUrl.isNotEmpty ?? true,
      hasStlFile: value.xtlFileUrl?.isNotEmpty ?? false,
      modelFileUrl: value.xtlFileUrl ?? value.sketch?.sketchUrl,
      assignedTo: 'CAD Designer',
      receivedAt:
          DateTime.tryParse(value.sketch?.createdAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      volumeCubicMm: value.volumeMm3,
    );
  }

  static TeamMember employee(ApiEmployee value) {
    final readableRole = switch (value.role.toUpperCase()) {
      'THREE_D_DESIGNER' => '3D CAD Modeler',
      'RAW_SKETCHER' => '2D Raw Concept Sketcher',
      'GOLDSMITH' => 'Goldsmith Artisan',
      'PRODUCTION_MANAGER' => 'Production Manager',
      'ADMIN' => 'System Administrator',
      'FRONTIER' => 'Frontier Sales Manager',
      _ => value.role.replaceAll('_', ' '),
    };

    return TeamMember(
      id: value.id,
      name: value.name,
      craft: readableRole,
      shift: 'Day Shift (9 AM - 7 PM)',
      activeLotsCount: value.workerAssignmentsCount,
      status: value.isActive
          ? EmployeeStatus.available
          : EmployeeStatus.blocked,
      todayEfficiencyPercent: 95,
      currentAssignment: value.workerAssignmentsCount > 0
          ? '${value.workerAssignmentsCount} active lots assigned'
          : 'Ready for allocation',
    );
  }

  static WorkshopLot workerTask(ApiWorkerTask value) {
    final lotCode = value.designNumber.isNotEmpty
        ? value.designNumber
        : (value.id.length > 10
              ? 'LOT-${value.id.substring(0, 6).toUpperCase()}'
              : value.id);

    return WorkshopLot(
      id: lotCode,
      orderId: value.orderId,
      designCode: value.designNumber,
      productTitle: value.designNumber.isNotEmpty
          ? value.designNumber
          : 'Jewellery Lot $lotCode',
      stage: stage(value.stageName),
      assignedEmployee: value.assignedEmployeeName,
      assignedEmployeeRole: value.status,
      pieces: value.quantity,
      issueWeightGrams: value.grossWeight,
      targetWeightGrams: value.grossWeight,
      tone: value.status == 'FAILED' ? HealthTone.critical : HealthTone.healthy,
      blockerReason: value.status == 'FAILED' ? value.instructions : null,
      lastUpdatedTime: '',
    );
  }

  static WorkshopLot pendingPart(Map<String, dynamic> value) {
    final part = value['orderPart'] is Map
        ? Map<String, dynamic>.from(value['orderPart'] as Map)
        : value;
    final rawOrder = part['order'] ?? value['order'];
    final order = rawOrder is Map ? rawOrder : const <String, dynamic>{};
    final orderId =
        order['orderNumber'] as String? ??
        order['id'] as String? ??
        part['orderNumber'] as String? ??
        part['orderId'] as String? ??
        value['orderNumber'] as String? ??
        value['orderId'] as String? ??
        '';
    final designNumber =
        part['designNumber'] as String? ??
        value['designNumber'] as String? ??
        '';
    final grossWeight =
        (part['grossWeight'] as num?)?.toDouble() ??
        (value['grossWeight'] as num?)?.toDouble() ??
        0;
    final assignments = part['workerAssignments'] is List
        ? part['workerAssignments'] as List
        : value['workerAssignments'] is List
        ? value['workerAssignments'] as List
        : const [];
    final latestAssignment = assignments.isNotEmpty && assignments.last is Map
        ? Map<String, dynamic>.from(assignments.last as Map)
        : const <String, dynamic>{};
    final rawStage =
        latestAssignment['stage'] ??
        part['currentStage'] ??
        part['stage'] ??
        value['currentStage'] ??
        value['stage'];
    final stageName = rawStage is Map
        ? rawStage['name'] as String? ?? ''
        : rawStage as String? ?? '';
    final rawEmployee =
        latestAssignment['assignedEmployee'] ??
        latestAssignment['employee'] ??
        part['assignedEmployee'] ??
        value['assignedEmployee'];
    final employeeName = rawEmployee is Map
        ? rawEmployee['name'] as String? ?? ''
        : rawEmployee as String? ?? '';
    return WorkshopLot(
      id: part['id'] as String? ?? value['id'] as String? ?? '',
      orderId: orderId,
      designCode: designNumber,
      productTitle: designNumber.isNotEmpty ? designNumber : 'Order Part',
      stage: stageName.isEmpty ? WorkshopStage.inQueue : stage(stageName),
      assignedEmployee: employeeName,
      assignedEmployeeRole:
          latestAssignment['status'] as String? ??
          value['status'] as String? ??
          '',
      pieces:
          (part['quantity'] as num?)?.toInt() ??
          (value['quantity'] as num?)?.toInt() ??
          0,
      issueWeightGrams: grossWeight,
      targetWeightGrams: grossWeight,
      tone: HealthTone.healthy,
      blockerReason: null,
      lastUpdatedTime: '',
    );
  }

  static WorkshopStage stage(String name) => switch (name.toLowerCase()) {
    'queue' || 'in queue' => WorkshopStage.inQueue,
    'waxing' || 'cad & wax' || 'cad and wax' => WorkshopStage.cadAndWax,
    'casting' => WorkshopStage.casting,
    'filing & assembly' || 'filing' => WorkshopStage.filingAndAssembly,
    'stone setting' || 'setting' => WorkshopStage.stoneSetting,
    'polishing' => WorkshopStage.polishing,
    'quality check & packing' ||
    'quality check' ||
    'qc' => WorkshopStage.qualityCheck,
    'ready' || 'ready for dispatch' => WorkshopStage.readyForDispatch,
    _ => WorkshopStage.inQueue,
  };
}
