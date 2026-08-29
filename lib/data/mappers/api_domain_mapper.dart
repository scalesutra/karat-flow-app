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
      apiId: value.id,
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
      designs: value.parts
          .map(
            (part) => OrderDesignProgress(
              partId: part.id,
              designNumber: part.designNumber,
              quantity: part.quantity,
              grossWeight: part.grossWeight,
              currentStage: part.currentStage,
              status: part.status,
              isBlocked: part.isBlocked,
              blockReason: part.blockReason,
            ),
          )
          .toList(growable: false),
      currentWorkshopStage: (firstPart?.currentStage.trim().isNotEmpty == true)
          ? firstPart!.currentStage.trim()
          : 'Unassigned',
      responsibleManager: '',
      isBlocked: isBlocked,
      blockedReason: blockReason,
    );
  }

  static String _cleanText(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    var cleaned = text.trim();
    if (cleaned.contains('[ 🎙️ Voice Note: ')) {
      cleaned = cleaned
          .substring(0, cleaned.indexOf('[ 🎙️ Voice Note: '))
          .trim();
    }
    if (cleaned.contains('Price:') ||
        cleaned.contains('Stock:') ||
        cleaned.contains('Status:')) {
      final parts = cleaned.split('|').map((p) => p.trim()).toList();
      final uniqueParts = <String>[];
      final seenMetaKeys = <String>{};
      for (final part in parts) {
        if (part.contains(':')) {
          final key = part.split(':').first.trim().toLowerCase();
          if (key == 'price' || key == 'stock' || key == 'status') {
            if (seenMetaKeys.contains(key)) continue;
            seenMetaKeys.add(key);
          }
        }
        uniqueParts.add(part);
      }
      cleaned = uniqueParts.join(' | ');
    }
    return cleaned;
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

  static double? parsePrice(dynamic jsonValue, String? adminInstructions) {
    if (jsonValue != null && jsonValue is num && jsonValue > 0) {
      return jsonValue.toDouble();
    }
    if (adminInstructions != null && adminInstructions.isNotEmpty) {
      final reg = RegExp(
        r'Price:\s*₹?\s*(\d+(?:\.\d+)?)',
        caseSensitive: false,
      );
      final match = reg.firstMatch(adminInstructions);
      if (match != null) {
        final parsedStr = match.group(1);
        if (parsedStr != null) {
          final val = double.tryParse(parsedStr);
          if (val != null && val > 0) return val;
        }
      }
    }
    return null;
  }

  static JewelleryDesign sketch(ApiSketch value) => JewelleryDesign(
    id: value.id,
    name: value.title.isNotEmpty ? value.title : 'Custom Sketch',
    code: value.designNumber.isNotEmpty
        ? value.designNumber
        : 'DSG-${value.id.substring(0, value.id.length > 6 ? 6 : value.id.length)}',
    category: parseCategory(
      value.category != null && value.category!.isNotEmpty
          ? value.category
          : value.title,
    ),
    purity: '22KT',
    grossWeightGrams: 0,
    estimatedPrice: parsePrice(value.price, value.adminInstructions),
    imageUrl: value.sketchUrl,
    description: _cleanText(value.adminInstructions).isNotEmpty
        ? _cleanText(value.adminInstructions)
        : (value.status == 'APPROVED'
              ? 'Approved 2D Sketch'
              : 'New Design Sketch'),
    isPopular: value.status == 'APPROVED',
  );

  static JewelleryDesign threeDDesign(ApiThreeDDesign value) => JewelleryDesign(
    id: value.id,
    name: value.sketch?.title.isNotEmpty == true
        ? value.sketch!.title
        : (value.sizeDimensions.isNotEmpty
              ? value.sizeDimensions
              : '3D CAD Design'),
    code: value.sketch?.designNumber.isNotEmpty == true
        ? value.sketch!.designNumber
        : (value.id.length > 8
              ? value.id.substring(0, 8).toUpperCase()
              : value.id),
    category: parseCategory(
      value.category ?? value.sketch?.category ?? value.sketch?.title,
    ),
    purity: '22KT',
    grossWeightGrams: value.totalWeight,
    estimatedPrice: parsePrice(
      value.price ?? value.sketch?.price,
      value.adminInstructions ?? value.sketch?.adminInstructions,
    ),
    imageUrl: (value.sketch?.sketchUrl.isNotEmpty == true)
        ? value.sketch!.sketchUrl
        : (value.xtlFileUrl?.isNotEmpty == true
              ? value.xtlFileUrl!
              : (value.bomFileUrl ?? '')),
    description: _cleanText(value.adminInstructions).isNotEmpty
        ? _cleanText(value.adminInstructions)
        : value.sizeDimensions,
    isPopular: value.status == 'APPROVED' || value.totalWeight > 0,
    sizeDimensions: value.sizeDimensions.isNotEmpty
        ? value.sizeDimensions
        : null,
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
        'APPROVED' || 'COMPLETED' || 'READY' => CadTaskStatus.completed,
        'REVISION' ||
        'REJECTED' ||
        'CHANGES_REQUESTED' => CadTaskStatus.revision,
        'IN_PROGRESS' =>
          (value.xtlFileUrl?.isNotEmpty == true)
              ? CadTaskStatus.completed
              : CadTaskStatus.inProgress,
        _ =>
          (value.xtlFileUrl?.isNotEmpty == true)
              ? CadTaskStatus.completed
              : CadTaskStatus.newTask,
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

    final available = value.stock != null
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
      shift: '',
      activeLotsCount: value.workerAssignmentsCount,
      status: value.isActive
          ? EmployeeStatus.available
          : EmployeeStatus.blocked,
      todayEfficiencyPercent: 0,
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

    var empName = value.assignedEmployeeName;
    if (empName.isEmpty || empName.trim().isEmpty) {
      if (value.instructions.contains('Assigned to ')) {
        final idx = value.instructions.indexOf('Assigned to ');
        final rest = value.instructions
            .substring(idx + 'Assigned to '.length)
            .trim();
        final cleanName = rest.contains(':')
            ? rest.substring(0, rest.indexOf(':')).trim()
            : (rest.contains('\n')
                  ? rest.substring(0, rest.indexOf('\n')).trim()
                  : rest);
        if (cleanName.isNotEmpty) {
          empName = cleanName;
        }
      }
    }

    return WorkshopLot(
      id: lotCode,
      orderId: value.orderId,
      designCode: value.designNumber,
      productTitle: value.designNumber.isNotEmpty
          ? value.designNumber
          : 'Jewellery Lot $lotCode',
      stage: stage(value.stageName),
      assignedEmployee: empName.isNotEmpty ? empName : 'Unassigned',
      assignedEmployeeRole: value.status,
      pieces: value.quantity,
      issueWeightGrams: value.grossWeight,
      targetWeightGrams: value.grossWeight,
      tone: value.status == 'FAILED' ? HealthTone.critical : HealthTone.healthy,
      blockerReason: value.status == 'FAILED' ? value.instructions : null,
      lastUpdatedTime: '',
      apiStageName: value.stageName,
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
        value['_orderId'] as String? ??
        value['_orderNumber'] as String? ??
        '';
    final designNumber =
        part['designNumber'] as String? ??
        value['designNumber'] as String? ??
        '';
    final grossWeight =
        (part['grossWeight'] as num?)?.toDouble() ??
        (value['grossWeight'] as num?)?.toDouble() ??
        0;
    final assignments = part['assignments'] is List
        ? part['assignments'] as List
        : part['workerAssignments'] is List
        ? part['workerAssignments'] as List
        : value['assignments'] is List
        ? value['assignments'] as List
        : value['workerAssignments'] is List
        ? value['workerAssignments'] as List
        : const [];
    final latestAssignment = _currentWorkerAssignment(
      assignments,
      part: part,
      value: value,
    );
    // The part's current stage is authoritative. Worker assignments can include
    // historical stages and are only a fallback when the part omits it.
    final rawStage =
        part['currentStage'] ??
        part['stage'] ??
        value['currentStage'] ??
        value['stage'] ??
        latestAssignment['stage'];
    String stageName = rawStage is Map
        ? rawStage['name'] as String? ?? ''
        : rawStage as String? ?? '';
    final stageId =
        part['currentStageId'] as String? ??
        part['stageId'] as String? ??
        value['currentStageId'] as String? ??
        value['stageId'] as String? ??
        latestAssignment['stageId'] as String? ??
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
        latestAssignment['artisan'] ??
        latestAssignment['worker'] ??
        latestAssignment['assignedTo'] ??
        latestAssignment['user'] ??
        part['assignedEmployee'] ??
        part['employee'] ??
        part['artisan'] ??
        part['worker'] ??
        part['assignedTo'] ??
        part['user'] ??
        value['assignedEmployee'] ??
        value['employee'] ??
        value['artisan'] ??
        value['worker'] ??
        value['assignedTo'] ??
        value['user'];

    String employeeName = '';
    if (rawEmployee is Map) {
      employeeName =
          rawEmployee['name'] as String? ??
          rawEmployee['fullName'] as String? ??
          rawEmployee['username'] as String? ??
          '';
      if (employeeName.isEmpty && rawEmployee['firstName'] != null) {
        final fName = rawEmployee['firstName'] as String? ?? '';
        final lName = rawEmployee['lastName'] as String? ?? '';
        employeeName = '$fName $lName'.trim();
      }
    } else if (rawEmployee is String) {
      final matched = DemoStore.instance.team
          .where((member) => member.id == rawEmployee)
          .firstOrNull;
      employeeName = matched?.name ?? rawEmployee;
    }

    final empId =
        latestAssignment['assignedEmployeeId'] as String? ??
        latestAssignment['employeeId'] as String? ??
        latestAssignment['artisanId'] as String? ??
        latestAssignment['workerId'] as String? ??
        latestAssignment['userId'] as String? ??
        part['assignedEmployeeId'] as String? ??
        part['employeeId'] as String? ??
        part['artisanId'] as String? ??
        part['workerId'] as String? ??
        part['userId'] as String? ??
        value['assignedEmployeeId'] as String? ??
        value['employeeId'] as String? ??
        value['artisanId'] as String? ??
        value['workerId'] as String? ??
        value['userId'] as String? ??
        '';

    if ((employeeName.isEmpty ||
            employeeName.trim().isEmpty ||
            employeeName.toLowerCase() == 'unassigned') &&
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

    if (employeeName.isEmpty ||
        employeeName.trim().isEmpty ||
        employeeName.toLowerCase() == 'unassigned') {
      final instructions =
          latestAssignment['instructions'] as String? ??
          part['instructions'] as String? ??
          value['instructions'] as String? ??
          '';
      if (instructions.contains('Assigned to ')) {
        final idx = instructions.indexOf('Assigned to ');
        final rest = instructions.substring(idx + 'Assigned to '.length).trim();
        final cleanName = rest.contains(':')
            ? rest.substring(0, rest.indexOf(':')).trim()
            : (rest.contains('\n')
                  ? rest.substring(0, rest.indexOf('\n')).trim()
                  : rest);
        if (cleanName.isNotEmpty) {
          employeeName = cleanName;
        }
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
      id: lotId,
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
      apiStageId: stageId,
      apiStageName: stageName,
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

  static Map<String, dynamic> _currentWorkerAssignment(
    List<dynamic> assignments, {
    required Map<String, dynamic> part,
    required Map<String, dynamic> value,
  }) {
    final candidates = assignments
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (candidates.isEmpty) return const <String, dynamic>{};

    final rawCurrentStage =
        part['currentStage'] ??
        part['stage'] ??
        value['currentStage'] ??
        value['stage'];
    final currentStageId =
        part['currentStageId'] as String? ??
        part['stageId'] as String? ??
        value['currentStageId'] as String? ??
        value['stageId'] as String? ??
        (rawCurrentStage is Map ? rawCurrentStage['id'] as String? : null) ??
        '';
    final currentStageName = (rawCurrentStage is Map
        ? rawCurrentStage['name'] as String? ?? ''
        : rawCurrentStage as String? ?? '');

    bool isActive(Map<String, dynamic> assignment) {
      final status = (assignment['status'] as String? ?? '').toUpperCase();
      return status.isEmpty ||
          status == 'ASSIGNED' ||
          status == 'IN_PROGRESS' ||
          status == 'ACTIVE' ||
          status == 'PAUSED';
    }

    bool matchesCurrentStage(Map<String, dynamic> assignment) {
      final rawStage = assignment['stage'];
      final assignmentStageId =
          assignment['stageId'] as String? ??
          (rawStage is Map ? rawStage['id'] as String? : null) ??
          '';
      final assignmentStageName = (rawStage is Map
          ? rawStage['name'] as String? ?? ''
          : rawStage as String? ?? '');
      if (currentStageId.isNotEmpty && assignmentStageId.isNotEmpty) {
        return currentStageId == assignmentStageId;
      }
      return currentStageName.isNotEmpty &&
          assignmentStageName.trim().toLowerCase() ==
              currentStageName.trim().toLowerCase();
    }

    final currentActive = candidates
        .where((item) => isActive(item) && matchesCurrentStage(item))
        .toList();
    final active = candidates.where(isActive).toList();
    final pool = currentActive.isNotEmpty
        ? currentActive
        : active.isNotEmpty
        ? active
        : candidates;
    // The orders contract places the latest assignment at index 0. Prefer
    // timestamps when present, otherwise retain that documented ordering.
    final dated = pool
        .map(
          (assignment) => (
            assignment: assignment,
            time: DateTime.tryParse(
              assignment['updatedAt'] as String? ??
                  assignment['createdAt'] as String? ??
                  '',
            ),
          ),
        )
        .where((entry) => entry.time != null)
        .toList();
    if (dated.isEmpty) return pool.first;
    dated.sort((a, b) => a.time!.compareTo(b.time!));
    return dated.last.assignment;
  }

  static Instruction directive(ApiDirective value) {
    final isAck = value.status.toUpperCase() == 'ACKNOWLEDGED';
    var message = '${value.title}: ${value.instruction}';
    if (value.audioUrl?.isNotEmpty == true) {
      message += ' [ 🎙️ Voice Note: ${value.audioUrl} ]';
    }
    if (value.imageUrl?.isNotEmpty == true) {
      message += ' [ 🖼️ Image: ${value.imageUrl} ]';
    }
    return Instruction(
      id: value.id,
      targetId: value.targetType,
      targetLabel: value.directiveCode.isNotEmpty
          ? value.directiveCode
          : value.targetType.replaceAll('_', ' '),
      message: message,
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
