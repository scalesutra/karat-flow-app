import '../demo_store.dart';
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
    final blockedPart = value.parts.where((p) => p.isBlocked).firstOrNull;
    final isBlocked = blockedPart != null;
    final blockReason = blockedPart?.blockReason;

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
      isBlocked: isBlocked,
      blockedReason: blockReason,
    );
  }

  static String _cleanText(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    if (text.contains('[ 🎙️ Voice Note: ')) {
      final clean = text
          .substring(0, text.indexOf('[ 🎙️ Voice Note: '))
          .trim();
      return clean.isNotEmpty ? clean : 'Voice Directive Note Attached';
    }
    return text.trim();
  }

  static JewelleryCategory parseCategory(String? value) {
    if (value == null || value.trim().isEmpty) return JewelleryCategory.all;
    final lower = value.toLowerCase();
    if (lower.contains('ring')) return JewelleryCategory.rings;
    if (lower.contains('necklace') ||
        lower.contains('choker') ||
        lower.contains('pendant')) {
      return JewelleryCategory.necklaces;
    }
    if (lower.contains('earring') || lower.contains('stud')) {
      return JewelleryCategory.earrings;
    }
    if (lower.contains('bangle') || lower.contains('bracelet')) {
      return JewelleryCategory.bangles;
    }
    if (lower.contains('chain')) return JewelleryCategory.chains;
    if (lower.contains('bridal') || lower.contains('set')) {
      return JewelleryCategory.bridalSets;
    }
    return JewelleryCategory.all;
  }

  static JewelleryDesign sketch(ApiSketch value) => JewelleryDesign(
    id: value.id,
    name: value.title,
    code: value.designNumber,
    category: parseCategory(value.category),
    purity: '',
    grossWeightGrams: 0,
    imageUrl: value.sketchUrl,
    description: _cleanText(value.adminInstructions),
    isPopular: value.status == 'APPROVED',
  );

  static JewelleryDesign threeDDesign(ApiThreeDDesign value) => JewelleryDesign(
    id: value.id,
    name: value.sketch?.title.isNotEmpty == true
        ? value.sketch!.title
        : value.sketchId,
    code: value.id,
    category: parseCategory(value.category ?? value.sketch?.category),
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

  static StockItem stockItem(ApiThreeDDesign value) {
    final title = (value.sketch?.title.isNotEmpty == true)
        ? value.sketch!.title
        : ((value.sketch?.designNumber.isNotEmpty == true)
              ? value.sketch!.designNumber
              : (value.sizeDimensions.isNotEmpty
                    ? value.sizeDimensions
                    : '3D CAD Product'));

    final code = (value.sketch?.designNumber.isNotEmpty == true)
        ? value.sketch!.designNumber
        : 'SKU-${value.id.substring(0, value.id.length > 6 ? 6 : value.id.length)}';

    final categoryName = (value.category?.isNotEmpty == true)
        ? value.category!
        : ((value.sketch?.category?.isNotEmpty == true)
              ? value.sketch!.category!
              : 'Jewellery Atelier');

    final stockCategory = switch (categoryName.toLowerCase()) {
      'raw gold' || 'gold' => StockCategory.rawGold,
      'findings' || 'finding' => StockCategory.findings,
      'gemstones' ||
      'gems' ||
      'diamond' ||
      'diamonds' => StockCategory.cutDiamonds,
      'finished' ||
      'finished goods' ||
      'necklaces' ||
      'rings' => StockCategory.finishedGoods,
      _ => StockCategory.rawGold,
    };

    final available = (value.stock != null && value.stock! > 0)
        ? value.stock!.toDouble()
        : (value.goldQuantity > 0 ? value.goldQuantity : value.totalWeight);

    final unitLabel = value.stock != null ? 'pcs' : 'grams';
    final statusLabel = value.stockStatus?.isNotEmpty == true
        ? ' · ${value.stockStatus}'
        : '';

    return StockItem(
      id: value.id,
      name: '$title ($code)',
      category: stockCategory,
      purityOrGrade: '$categoryName$statusLabel',
      totalAvailable: available,
      reservedInLots: 0.0,
      unit: unitLabel,
      vaultLocation: 'Main Atelier Vault · Safe #1',
      discrepancyGrams: 0.0,
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
    final lotId = part['id'] as String? ?? value['id'] as String? ?? '';
    final orderId =
        order['id'] as String? ??
        order['orderNumber'] as String? ??
        part['orderId'] as String? ??
        part['orderNumber'] as String? ??
        value['orderId'] as String? ??
        value['orderNumber'] as String? ??
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
    String stageName = rawStage is Map
        ? rawStage['name'] as String? ?? ''
        : rawStage as String? ?? '';
    final stageId =
        latestAssignment['stageId'] as String? ??
        part['currentStageId'] as String? ??
        part['stageId'] as String? ??
        value['currentStageId'] as String? ??
        value['stageId'] as String? ??
        '';
    if (stageId.isNotEmpty) {
      final matched = DemoStore.instance.stages
          .where((s) => s.id == stageId)
          .firstOrNull;
      if (matched != null && matched.name.isNotEmpty) {
        stageName = matched.name;
      }
    }

    final rawEmployee =
        latestAssignment['assignedEmployee'] ??
        latestAssignment['employee'] ??
        part['assignedEmployee'] ??
        value['assignedEmployee'];
    String employeeName = rawEmployee is Map
        ? rawEmployee['name'] as String? ?? ''
        : rawEmployee as String? ?? '';

    if (employeeName.isEmpty || employeeName.trim().isEmpty) {
      final instructions =
          latestAssignment['instructions'] as String? ??
          part['instructions'] as String? ??
          value['instructions'] as String? ??
          '';
      if (instructions.startsWith('Assigned to ')) {
        employeeName = instructions.substring('Assigned to '.length).trim();
      }
    }

    final empId =
        latestAssignment['assignedEmployeeId'] as String? ??
        part['assignedEmployeeId'] as String? ??
        value['assignedEmployeeId'] as String? ??
        '';
    if ((employeeName.isEmpty || employeeName.trim().isEmpty) &&
        empId.isNotEmpty) {
      final matched = DemoStore.instance.team
          .where(
            (m) =>
                m.id == empId || (m.name.isNotEmpty && empId.contains(m.name)),
          )
          .firstOrNull;
      if (matched != null) {
        employeeName = matched.name;
      }
    }

    // Preserve previously assigned worker from store if API omits employee details
    if (employeeName.isEmpty || employeeName.trim().isEmpty) {
      final existingLot = DemoStore.instance.lots
          .where(
            (l) =>
                l.id == lotId ||
                (l.orderId.isNotEmpty &&
                    l.orderId == orderId &&
                    l.designCode == designNumber),
          )
          .firstOrNull;
      if (existingLot != null &&
          existingLot.assignedEmployee.isNotEmpty &&
          existingLot.assignedEmployee != 'Unassigned') {
        employeeName = existingLot.assignedEmployee;
      }
    }

    if (employeeName.isEmpty || employeeName.trim().isEmpty) {
      employeeName = 'Unassigned';
    }
    final isBlocked =
        part['isBlocked'] as bool? ?? value['isBlocked'] as bool? ?? false;
    final blockReason =
        part['blockReason'] as String? ??
        part['notes'] as String? ??
        value['blockReason'] as String? ??
        value['notes'];
    final statusStr =
        (part['status'] as String? ?? value['status'] as String? ?? '')
            .toUpperCase();
    final isFailedOrHold =
        isBlocked ||
        statusStr == 'FAILED' ||
        statusStr == 'HOLD' ||
        statusStr == 'ON_HOLD';

    return WorkshopLot(
      id: part['id'] as String? ?? value['id'] as String? ?? '',
      orderId: orderId,
      designCode: designNumber,
      productTitle: designNumber.isNotEmpty ? designNumber : 'Order Part',
      stage: stageName.isEmpty
          ? (stageId.isNotEmpty ? stage(stageId) : WorkshopStage.inQueue)
          : stage(stageName),
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
      tone: isFailedOrHold ? HealthTone.critical : HealthTone.healthy,
      blockerReason: isFailedOrHold
          ? (blockReason?.isNotEmpty == true
                ? blockReason
                : 'Part placed on hold / failed in process')
          : null,
      lastUpdatedTime: '',
    );
  }

  static WorkshopStage stage(String nameOrId) {
    if (nameOrId.trim().isEmpty) return WorkshopStage.inQueue;

    // Resolve stage UUID ID if passed
    final matchedApiStage = DemoStore.instance.stages
        .where((s) => s.id == nameOrId)
        .firstOrNull;
    final lookup = (matchedApiStage?.name ?? nameOrId).trim().toLowerCase();

    if (lookup.contains('queue')) return WorkshopStage.inQueue;
    if (lookup.contains('wax')) return WorkshopStage.cadAndWax;
    if (lookup.contains('cast')) return WorkshopStage.casting;
    if (lookup.contains('filing') || lookup.contains('assembly')) {
      return WorkshopStage.filingAndAssembly;
    }
    if (lookup.contains('setting') || lookup.contains('stone')) {
      return WorkshopStage.stoneSetting;
    }
    if (lookup.contains('polish')) return WorkshopStage.polishing;
    if (lookup.contains('quality') ||
        lookup.contains('qc') ||
        lookup.contains('pack')) {
      return WorkshopStage.qualityCheck;
    }
    if (lookup.contains('ready') ||
        lookup.contains('dispatch') ||
        lookup.contains('completed') ||
        lookup.contains('complete') ||
        lookup.contains('all_stages_completed')) {
      return WorkshopStage.readyForDispatch;
    }
    return WorkshopStage.inQueue;
  }

  static Instruction directive(ApiDirective value) {
    final isAck = value.status.toUpperCase() == 'ACKNOWLEDGED';
    return Instruction(
      id: value.directiveCode.isNotEmpty ? value.directiveCode : value.id,
      targetId: value.targetType,
      targetLabel: value.targetType.replaceAll('_', ' '),
      message: '${value.title}: ${value.instruction}',
      createdBy: 'Admin / PM',
      assignedTo: value.targetType.replaceAll('_', ' '),
      urgency: InstructionUrgency.urgent,
      status: isAck ? InstructionStatus.acknowledged : InstructionStatus.sent,
      createdAt: DateTime.tryParse(value.createdAt ?? '') ?? DateTime.now(),
      hasPhoto: value.imageUrl != null && value.imageUrl!.isNotEmpty,
      hasVoice: value.audioUrl != null && value.audioUrl!.isNotEmpty,
    );
  }
}
