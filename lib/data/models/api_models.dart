library;

/// Centralized Data Transfer Objects (DTOs) for KaratFlow Live Backend

// ── 1. Auth Models ──────────────────────────────────────────────────
class AuthResponseData {
  const AuthResponseData({
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponseData.fromJson(Map<String, dynamic> json) {
    return AuthResponseData(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 300,
      user: json['user'] != null
          ? ApiUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  final String token;
  final String refreshToken;
  final int expiresIn;
  final ApiUser? user;
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'ADMIN',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
}

// ── 2. Employee Models ──────────────────────────────────────────────
class ApiEmployee {
  const ApiEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.keycloakId = '',
    this.skills = const [],
    this.specialty = '',
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
    this.workerAssignmentsCount = 0,
    this.activeAssignmentsCount = 0,
  });

  factory ApiEmployee.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final parsedSkills = rawSkills is List
        ? rawSkills.map((e) => e.toString()).toList()
        : <String>[];

    final totalCount = (json['_count'] is Map
        ? (json['_count']['workerAssignments'] as num?)?.toInt() ?? 0
        : 0);

    final activeCount = (json['activeAssignmentsCount'] as num?)?.toInt() ?? 0;

    return ApiEmployee(
      id: json['id'] as String? ?? '',
      keycloakId: json['keycloakId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'CRAFTSMAN',
      skills: parsedSkills,
      specialty: json['specialty'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      workerAssignmentsCount: totalCount > 0 ? totalCount : activeCount,
      activeAssignmentsCount: activeCount,
    );
  }

  final String id;
  final String keycloakId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final List<String> skills;
  final String specialty;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final int workerAssignmentsCount;
  final int activeAssignmentsCount;
}

class ApiEmployeeAssignment {
  const ApiEmployeeAssignment({
    required this.id,
    required this.status,
    required this.instructions,
    this.startedAt,
    this.completedAt,
    this.createdAt = '',
    this.stageName = '',
    this.stageNumber = 0,
    this.designNumber = '',
    this.orderNumber = '',
    this.customerName = '',
    this.quantity = 0,
    this.grossWeight = 0.0,
  });

  factory ApiEmployeeAssignment.fromJson(Map<String, dynamic> json) {
    final stageMap = json['stage'] as Map<String, dynamic>? ?? {};
    final partMap = json['orderPart'] as Map<String, dynamic>? ?? {};
    final orderMap = partMap['order'] as Map<String, dynamic>? ?? {};
    final customerMap = orderMap['customer'] as Map<String, dynamic>? ?? {};

    return ApiEmployeeAssignment(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'ASSIGNED',
      instructions: json['instructions'] as String? ?? '',
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      stageName: stageMap['name'] as String? ?? '',
      stageNumber: (stageMap['stageNumber'] as num?)?.toInt() ?? 0,
      designNumber: partMap['designNumber'] as String? ?? '',
      orderNumber: orderMap['orderNumber'] as String? ?? '',
      customerName: customerMap['name'] as String? ?? '',
      quantity: (partMap['quantity'] as num?)?.toInt() ?? 0,
      grossWeight: (partMap['grossWeight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String id;
  final String status;
  final String instructions;
  final String? startedAt;
  final String? completedAt;
  final String createdAt;
  final String stageName;
  final int stageNumber;
  final String designNumber;
  final String orderNumber;
  final String customerName;
  final int quantity;
  final double grossWeight;
}

// ── 3. Customer / Client Models ─────────────────────────────────────
class ApiCustomer {
  const ApiCustomer({
    required this.id,
    required this.name,
    required this.city,
    required this.contactPerson,
    required this.phone,
    this.email = '',
    this.creditLimitLakhs = 0.0,
    this.outstandingLakhs = 0.0,
    this.ordersCount = 0,
  });

  factory ApiCustomer.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['_count'] is Map) {
      count = json['_count']['orders'] as int? ?? 0;
    }
    return ApiCustomer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      creditLimitLakhs: (json['creditLimitLakhs'] as num?)?.toDouble() ?? 0.0,
      outstandingLakhs: (json['outstandingLakhs'] as num?)?.toDouble() ?? 0.0,
      ordersCount: count,
    );
  }

  final String id;
  final String name;
  final String city;
  final String contactPerson;
  final String phone;
  final String email;
  final double creditLimitLakhs;
  final double outstandingLakhs;
  final int ordersCount;

  int get activeOrdersCount => ordersCount;
}

// ── 4. Production Stage Models ──────────────────────────────────────
class ApiStage {
  const ApiStage({
    required this.id,
    required this.name,
    required this.stageNumber,
    this.isActive = true,
  });

  factory ApiStage.fromJson(Map<String, dynamic> json) {
    return ApiStage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stageNumber: json['stageNumber'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final int stageNumber;
  final bool isActive;
}

// ── 5. Raw 2D Sketch Models ─────────────────────────────────────────
class ApiSketch {
  const ApiSketch({
    required this.id,
    required this.designNumber,
    required this.title,
    required this.sketchUrl,
    required this.status,
    this.version = 1,
    this.adminInstructions,
    this.feedbackAudioUrl,
    this.feedbackImageUrl,
    this.designer,
    this.designerId = '',
    this.createdAt,
    this.updatedAt,
    this.category,
    this.price,
  });

  factory ApiSketch.fromJson(Map<String, dynamic> json) {
    final rawUrl =
        json['sketchUrl'] as String? ??
        json['imageUrl'] as String? ??
        json['url'] as String? ??
        json['image'] as String? ??
        json['sketchPath'] as String? ??
        json['filePath'] as String? ??
        '';

    return ApiSketch(
      id: json['id'] as String? ?? '',
      designNumber: json['designNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sketchUrl: rawUrl,
      status: json['status'] as String? ?? 'PENDING',
      version: json['version'] as int? ?? 1,
      adminInstructions: json['adminInstructions'] as String?,
      feedbackAudioUrl: json['feedbackAudioUrl'] as String?,
      feedbackImageUrl: json['feedbackImageUrl'] as String?,
      designer: json['designer'] != null
          ? ApiUser.fromJson(json['designer'] as Map<String, dynamic>)
          : null,
      designerId: json['designerId'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      category: json['category'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String designNumber;
  final String title;
  final String sketchUrl;
  final String status;
  final int version;
  final String? adminInstructions;
  final String? feedbackAudioUrl;
  final String? feedbackImageUrl;
  final ApiUser? designer;
  final String designerId;
  final String? createdAt;
  final String? updatedAt;
  final String? category;
  final double? price;
}

// ── 6. 3D CAD Models ────────────────────────────────────────────────
class ApiPriceBreakdown {
  const ApiPriceBreakdown({
    this.purity = '',
    this.goldRatePerGram = 0.0,
    this.netGoldWeight = 0.0,
    this.grossWeight = 0.0,
    this.totalGoldCost = 0.0,
    this.gemQuantity = 0,
    this.gemRate = 0.0,
    this.totalGemCost = 0.0,
    this.subtotal = 0.0,
    this.gstPercent = 0.0,
    this.gstAmount = 0.0,
    this.finalPrice = 0.0,
  });

  factory ApiPriceBreakdown.fromJson(Map<String, dynamic> json) {
    return ApiPriceBreakdown(
      purity: json['purity'] as String? ?? '',
      goldRatePerGram: (json['goldRatePerGram'] as num?)?.toDouble() ?? 0.0,
      netGoldWeight: (json['netGoldWeight'] as num?)?.toDouble() ?? 0.0,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0.0,
      totalGoldCost: (json['totalGoldCost'] as num?)?.toDouble() ?? 0.0,
      gemQuantity: (json['gemQuantity'] as num?)?.toInt() ?? 0,
      gemRate: (json['gemRate'] as num?)?.toDouble() ?? 0.0,
      totalGemCost: (json['totalGemCost'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String purity;
  final double goldRatePerGram;
  final double netGoldWeight;
  final double grossWeight;
  final double totalGoldCost;
  final int gemQuantity;
  final double gemRate;
  final double totalGemCost;
  final double subtotal;
  final double gstPercent;
  final double gstAmount;
  final double finalPrice;
}

// ── 6. 3D CAD Models ────────────────────────────────────────────────
class ApiThreeDDesign {
  const ApiThreeDDesign({
    required this.id,
    required this.sketchId,
    required this.totalWeight,
    required this.status,
    this.version = 1,
    this.xtlFileUrl,
    this.bomFileUrl,
    this.gemQuantity = 0,
    this.goldQuantity = 0.0,
    this.otherMetalsQuantity = 0.0,
    this.volumeMm3 = 0.0,
    this.sizeDimensions = '',
    this.makingCode = '',
    this.gemWeightTw = 0.0,
    this.gemBreakdown = const [],
    this.adminInstructions,
    this.feedbackAudioUrl,
    this.feedbackImageUrl,
    this.sketch,
    this.designer,
    this.category,
    this.stock,
    this.stockStatus,
    this.price,
    this.calculatedPrice,
    this.priceBreakdown,
    this.description,
  });

  factory ApiThreeDDesign.fromJson(Map<String, dynamic> json) {
    final gemBreakdownList = json['gemBreakdown'] as List? ?? const [];

    return ApiThreeDDesign(
      id: json['id'] as String? ?? '',
      sketchId: json['sketchId'] as String? ?? '',
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      version: json['version'] as int? ?? 1,
      xtlFileUrl: json['xtlFileUrl'] as String?,
      bomFileUrl: json['bomFileUrl'] as String?,
      gemQuantity: json['gemQuantity'] as int? ?? 0,
      goldQuantity: (json['goldQuantity'] as num?)?.toDouble() ?? 0.0,
      otherMetalsQuantity:
          (json['otherMetalsQuantity'] as num?)?.toDouble() ?? 0.0,
      volumeMm3: (json['volumeMm3'] as num?)?.toDouble() ?? 0.0,
      sizeDimensions: json['sizeDimensions'] as String? ?? '',
      makingCode: json['makingCode'] as String? ?? '',
      gemWeightTw: (json['gemWeightTw'] as num?)?.toDouble() ?? 0.0,
      gemBreakdown: gemBreakdownList
          .map((e) => GemBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      adminInstructions: json['adminInstructions'] as String?,
      feedbackAudioUrl: json['feedbackAudioUrl'] as String?,
      feedbackImageUrl: json['feedbackImageUrl'] as String?,
      sketch: json['sketch'] != null
          ? ApiSketch.fromJson(json['sketch'] as Map<String, dynamic>)
          : null,
      designer: json['designer'] is Map
          ? ApiUser.fromJson(json['designer'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
      stock: json['stock'] as int?,
      stockStatus: json['stockStatus'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      calculatedPrice:
          (json['calculatedPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      priceBreakdown: json['priceBreakdown'] is Map
          ? ApiPriceBreakdown.fromJson(
              json['priceBreakdown'] as Map<String, dynamic>,
            )
          : null,
      description: json['description'] as String?,
    );
  }

  final String id;
  final String sketchId;
  final double totalWeight;
  final String status;
  final int version;
  final String? xtlFileUrl;
  final String? bomFileUrl;
  final int gemQuantity;
  final double goldQuantity;
  final double otherMetalsQuantity;
  final double volumeMm3;
  final String sizeDimensions;
  final String makingCode;
  final double gemWeightTw;
  final List<GemBreakdownItem> gemBreakdown;
  final String? adminInstructions;
  final String? feedbackAudioUrl;
  final String? feedbackImageUrl;
  final ApiSketch? sketch;
  final ApiUser? designer;
  final String? category;
  final int? stock;
  final String? stockStatus;
  final double? price;
  final double? calculatedPrice;
  final ApiPriceBreakdown? priceBreakdown;
  final String? description;
}

// ── 7. Order & Part Models ──────────────────────────────────────────
class ApiOrder {
  const ApiOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customerName = '',
    this.customerCity = '',
    this.dueDate = '',
    this.createdAt,
    this.parts = const [],
  });

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    String cName = '';
    String cCity = '';
    if (json['customer'] is Map) {
      cName = json['customer']['name'] as String? ?? '';
      cCity = json['customer']['city'] as String? ?? '';
    }
    final rawParts = json['parts'] as List? ?? [];
    return ApiOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      customerName: cName,
      customerCity: cCity,
      dueDate: json['dueDate']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      parts: rawParts
          .map((p) => ApiOrderPart.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final String customerCity;
  final String dueDate;
  final DateTime? createdAt;
  final List<ApiOrderPart> parts;
}

class ApiOrderPart {
  const ApiOrderPart({
    required this.id,
    required this.designNumber,
    this.quantity = 0,
    this.grossWeight = 0.0,
    this.currentStage = '',
    this.status = 'ASSIGNED',
    this.isBlocked = false,
    this.blockReason,
  });

  factory ApiOrderPart.fromJson(Map<String, dynamic> json) {
    String stgName = '';
    if (json['currentStage'] is Map) {
      stgName = json['currentStage']['name'] as String? ?? '';
    } else if (json['currentStage'] is String) {
      stgName = json['currentStage'] as String;
    }
    return ApiOrderPart(
      id: json['id'] as String? ?? '',
      designNumber: json['designNumber'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0.0,
      currentStage: stgName,
      status: json['status'] as String? ?? 'ASSIGNED',
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockReason: json['blockReason'] as String?,
    );
  }

  final String id;
  final String designNumber;
  final int quantity;
  final double grossWeight;
  final String currentStage;
  final String status;
  final bool isBlocked;
  final String? blockReason;
}

// ── 8. Workshop Worker Task Models ──────────────────────────────────
class ApiWorkerTaskStage {
  const ApiWorkerTaskStage({
    required this.id,
    required this.name,
    this.stageNumber = 0,
    this.description = '',
  });

  final String id;
  final String name;
  final int stageNumber;
  final String description;

  factory ApiWorkerTaskStage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ApiWorkerTaskStage(id: '', name: 'Bench Operation');
    }
    return ApiWorkerTaskStage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Bench Stage',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
    );
  }
}

class ApiWorkerTaskOrderPart {
  const ApiWorkerTaskOrderPart({
    required this.id,
    this.orderId = '',
    this.designNumber = 'D01',
    this.quantity = 1,
    this.grossWeight = 0.0,
    this.status = 'ASSIGNED',
    this.isBlocked = false,
    this.isStockIssued = false,
    this.orderNumber = '',
    this.sketchUrl = '',
    this.gemQuantity = 0,
    this.goldQuantity = 0.0,
  });

  final String id;
  final String orderId;
  final String designNumber;
  final int quantity;
  final double grossWeight;
  final String status;
  final bool isBlocked;
  final bool isStockIssued;
  final String orderNumber;
  final String sketchUrl;
  final int gemQuantity;
  final double goldQuantity;

  factory ApiWorkerTaskOrderPart.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApiWorkerTaskOrderPart(id: '');
    final orderMap = json['order'] is Map ? Map<String, dynamic>.from(json['order']) : null;
    final sketchMap = json['sketch'] is Map ? Map<String, dynamic>.from(json['sketch']) : null;
    final cadMap = json['threeDDesign'] is Map ? Map<String, dynamic>.from(json['threeDDesign']) : null;

    final isStockIssuedVal =
        json['isStockIssued'] as bool? ??
        json['isIssued'] as bool? ??
        (json['issuance'] != null);

    return ApiWorkerTaskOrderPart(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      designNumber: json['designNumber']?.toString() ?? 'D01',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'ASSIGNED',
      isBlocked: json['isBlocked'] as bool? ?? false,
      isStockIssued: isStockIssuedVal,
      orderNumber: orderMap?['orderNumber']?.toString() ?? json['orderNumber']?.toString() ?? '',
      sketchUrl: sketchMap?['imageUrl']?.toString() ?? sketchMap?['url']?.toString() ?? '',
      gemQuantity: (cadMap?['gemQuantity'] as num?)?.toInt() ?? 0,
      goldQuantity: (cadMap?['goldQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ApiWorkerTask {
  const ApiWorkerTask({
    required this.id,
    this.orderPartId = '',
    this.stageId = '',
    this.assignedEmployeeId = '',
    this.assignedByManagerId = '',
    this.instructions = '',
    required this.status,
    this.startedAt,
    this.completedAt,
    this.failureReason,
    this.createdAt = '',
    this.isStockIssued = false,
    this.issuanceStatus = '',
    this.totalWeightIssued = 0.0,
    this.totalPcsIssued = 0,
    this.itemsIssued = const [],
    this.latestIssuance,
    this.stage = const ApiWorkerTaskStage(id: '', name: 'Bench Operation'),
    this.orderPart = const ApiWorkerTaskOrderPart(id: ''),
    this.assignedByManagerName = '',
  });

  final String id;
  final String orderPartId;
  final String stageId;
  final String assignedEmployeeId;
  final String assignedByManagerId;
  final String instructions;
  final String status; // 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'FAILED'
  final String? startedAt;
  final String? completedAt;
  final String? failureReason;
  final String createdAt;
  final bool isStockIssued;
  final String issuanceStatus;
  final double totalWeightIssued;
  final int totalPcsIssued;
  final List<Map<String, dynamic>> itemsIssued;
  final Map<String, dynamic>? latestIssuance;
  final ApiWorkerTaskStage stage;
  final ApiWorkerTaskOrderPart orderPart;
  final String assignedByManagerName;

  String get designNumber =>
      orderPart.designNumber.isNotEmpty ? orderPart.designNumber : 'D01';
  String get orderId => orderPart.orderNumber.isNotEmpty
      ? orderPart.orderNumber
      : (orderPart.orderId.isNotEmpty ? orderPart.orderId : 'N/A');
  String get stageName => stage.name.isNotEmpty ? stage.name : 'Bench Stage';
  int get quantity => orderPart.quantity > 0 ? orderPart.quantity : 1;
  double get grossWeight => orderPart.grossWeight > 0
      ? orderPart.grossWeight
      : orderPart.goldQuantity;
  bool get effectiveIsStockIssued =>
      isStockIssued ||
      issuanceStatus.toUpperCase() == 'ISSUED' ||
      (latestIssuance != null &&
          latestIssuance!['status']?.toString().toUpperCase() == 'ISSUED') ||
      orderPart.isStockIssued ||
      status.toUpperCase() == 'IN_PROGRESS' ||
      status.toUpperCase() == 'COMPLETED' ||
      status.toUpperCase() == 'STAGE_COMPLETED';
  String get assignedEmployeeName => assignedByManagerName;

  factory ApiWorkerTask.fromJson(Map<String, dynamic> json) {
    final stageMap = json['stage'] is Map ? Map<String, dynamic>.from(json['stage']) : null;
    final partMap = json['orderPart'] is Map ? Map<String, dynamic>.from(json['orderPart']) : null;
    final managerMap = json['assignedByManager'] is Map ? Map<String, dynamic>.from(json['assignedByManager']) : null;

    String dNum =
        partMap?['designNumber']?.toString() ??
        json['designNumber']?.toString() ??
        'D01';
    int qty =
        (partMap?['quantity'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        1;
    double gWt =
        (partMap?['grossWeight'] as num?)?.toDouble() ??
        (json['grossWeight'] as num?)?.toDouble() ??
        0.0;
    String oId = '';
    if (partMap?['order'] is Map) {
      oId =
          partMap!['order']['orderNumber']?.toString() ??
          partMap['order']['id']?.toString() ??
          '';
    }
    if (oId.isEmpty) {
      oId =
          partMap?['orderNumber']?.toString() ??
          json['orderId']?.toString() ??
          '';
    }

    String sName =
        stageMap?['name']?.toString() ??
        json['stageName']?.toString() ??
        'Bench Operation';
    String mgrName =
        managerMap?['name']?.toString() ??
        json['assignedEmployeeName']?.toString() ??
        '';

    final parsedOrderPart = partMap != null
        ? ApiWorkerTaskOrderPart.fromJson(partMap)
        : ApiWorkerTaskOrderPart(
            id: json['orderPartId']?.toString() ?? '',
            designNumber: dNum,
            quantity: qty,
            grossWeight: gWt,
            orderNumber: oId,
          );

    final issStatus = json['issuanceStatus']?.toString() ?? '';
    final latestIss = json['latestIssuance'] is Map ? Map<String, dynamic>.from(json['latestIssuance']) : null;
    final itemsList = (json['itemsIssued'] as List?)
            ?.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .toList() ??
        const <Map<String, dynamic>>[];

    final isIssued =
        json['isStockIssued'] as bool? ??
        json['isIssued'] as bool? ??
        (issStatus.toUpperCase() == 'ISSUED') ||
        (latestIss != null &&
            latestIss['status']?.toString().toUpperCase() == 'ISSUED') ||
        (json['issuance'] != null) ||
        parsedOrderPart.isStockIssued;

    return ApiWorkerTask(
      id: json['id']?.toString() ?? '',
      orderPartId: json['orderPartId']?.toString() ?? '',
      stageId: json['stageId']?.toString() ?? '',
      assignedEmployeeId: json['assignedEmployeeId']?.toString() ?? '',
      assignedByManagerId: json['assignedByManagerId']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ASSIGNED',
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      failureReason:
          json['failureReason']?.toString() ?? json['reason']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      isStockIssued: isIssued,
      issuanceStatus: issStatus,
      totalWeightIssued:
          (json['totalWeightIssued'] as num?)?.toDouble() ?? 0.0,
      totalPcsIssued: (json['totalPcsIssued'] as num?)?.toInt() ?? 0,
      itemsIssued: itemsList,
      latestIssuance: latestIss,
      stage: stageMap != null
          ? ApiWorkerTaskStage.fromJson(stageMap)
          : ApiWorkerTaskStage(id: '', name: sName),
      orderPart: parsedOrderPart,
      assignedByManagerName: mgrName,
    );
  }
}

class ApiWorkerTasksResponse {
  const ApiWorkerTasksResponse({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 10,
    this.totalPages = 1,
  });

  final List<ApiWorkerTask> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory ApiWorkerTasksResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return ApiWorkerTasksResponse(
      items: rawItems
          .map((i) => ApiWorkerTask.fromJson(i as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? rawItems.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

// ── 9. S3 Storage Models ────────────────────────────────────────────
class ApiPresignedUrl {
  const ApiPresignedUrl({
    required this.uploadUrl,
    required this.fileKey,
    required this.fileUrl,
    required this.expiresInSeconds,
  });

  factory ApiPresignedUrl.fromJson(Map<String, dynamic> json) {
    final pUrl =
        json['publicUrl'] as String? ??
        json['viewUrl'] as String? ??
        json['fileUrl'] as String? ??
        json['fileKey'] as String? ??
        '';
    return ApiPresignedUrl(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      fileKey: json['fileKey'] as String? ?? pUrl,
      fileUrl: pUrl,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 3600,
    );
  }

  final String uploadUrl;
  final String fileKey;
  final String fileUrl;
  final int expiresInSeconds;
}

class ApiPresignedDownloadUrl {
  const ApiPresignedDownloadUrl({
    required this.downloadUrl,
    required this.fileKey,
    required this.expiresInSeconds,
  });

  factory ApiPresignedDownloadUrl.fromJson(Map<String, dynamic> json) {
    return ApiPresignedDownloadUrl(
      downloadUrl: json['downloadUrl'] as String? ?? '',
      fileKey: json['fileKey'] as String? ?? '',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 0,
    );
  }

  final String downloadUrl;
  final String fileKey;
  final int expiresInSeconds;
}

class ApiOrderTracking {
  const ApiOrderTracking({
    required this.orderNumber,
    required this.customer,
    required this.orderStatus,
    required this.parts,
  });

  factory ApiOrderTracking.fromJson(Map<String, dynamic> json) {
    final rawParts = json['parts'] as List? ?? const [];
    return ApiOrderTracking(
      orderNumber: json['orderNumber'] as String? ?? '',
      customer: json['customer'] as String? ?? '',
      orderStatus: json['orderStatus'] as String? ?? '',
      parts: rawParts
          .map(
            (part) =>
                ApiTrackedOrderPart.fromJson(part as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String orderNumber;
  final String customer;
  final String orderStatus;
  final List<ApiTrackedOrderPart> parts;
}

class ApiTrackedOrderPart {
  const ApiTrackedOrderPart({
    required this.partId,
    required this.designNumber,
    required this.currentStage,
    required this.status,
    required this.history,
  });

  factory ApiTrackedOrderPart.fromJson(Map<String, dynamic> json) {
    return ApiTrackedOrderPart(
      partId: json['partId'] as String? ?? '',
      designNumber: json['designNumber'] as String? ?? '',
      currentStage: json['currentStage'] as String? ?? '',
      status: json['status'] as String? ?? '',
      history: List<Map<String, dynamic>>.from(
        (json['history'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ),
    );
  }

  final String partId;
  final String designNumber;
  final String currentStage;
  final String status;
  final List<Map<String, dynamic>> history;
}

class ApiHealthStatus {
  const ApiHealthStatus({
    required this.status,
    required this.uptime,
    required this.databaseStatus,
    required this.cacheStatus,
  });

  factory ApiHealthStatus.fromJson(Map<String, dynamic> json) {
    final database = json['database'] as Map?;
    final cache = json['cache'] as Map?;
    return ApiHealthStatus(
      status: json['status'] as String? ?? '',
      uptime: (json['uptime'] as num?)?.toDouble() ?? 0,
      databaseStatus: database?['status'] as String? ?? '',
      cacheStatus: cache?['status'] as String? ?? '',
    );
  }

  final String status;
  final double uptime;
  final String databaseStatus;
  final String cacheStatus;

  bool get isHealthy =>
      status.toLowerCase() == 'ok' &&
      databaseStatus.toLowerCase() == 'healthy' &&
      cacheStatus.toLowerCase() == 'healthy';
}

// ── 12. Master Raw Materials & Pricing Matrix Models ──────────────────
class ApiMaterial {
  const ApiMaterial({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.specification,
    required this.unit,
    required this.presetPricePerUnit,
    this.description = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiMaterial.fromJson(Map<String, dynamic> json) {
    return ApiMaterial(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'METAL',
      specification: json['specification'] as String? ?? '',
      unit: json['unit'] as String? ?? 'g',
      presetPricePerUnit:
          (json['presetPricePerUnit'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'category': category,
    'specification': specification,
    'unit': unit,
    'presetPricePerUnit': presetPricePerUnit,
    'description': description,
  };

  final String id;
  final String code;
  final String name;
  final String category; // METAL | DIAMOND | GEMSTONE | FINDING | MAKING_CHARGE
  final String specification;
  final String unit;
  final double presetPricePerUnit;
  final String description;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
}

// ── 13. Vault & Safe Inventory Stock Models ──────────────────────────
class ApiInventoryItem {
  const ApiInventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.purity,
    required this.totalStock,
    this.reservedWip = 0.0,
    required this.freeBalance,
    required this.unit,
    required this.location,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.createdById,
    this.createdBy,
  });

  factory ApiInventoryItem.fromJson(Map<String, dynamic> json) {
    return ApiInventoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'RAW_GOLD',
      purity: json['purity'] as String? ?? '',
      totalStock: (json['totalStock'] as num?)?.toDouble() ?? 0.0,
      reservedWip: (json['reservedWip'] as num?)?.toDouble() ?? 0.0,
      freeBalance: (json['freeBalance'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'g',
      location: json['location'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdById: json['createdById'] as String?,
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? ApiUser.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'purity': purity,
    'totalStock': totalStock,
    'reservedWip': reservedWip,
    'freeBalance': freeBalance,
    'unit': unit,
    'location': location,
    if (notes != null) 'notes': notes,
  };

  final String id;
  final String name;
  final String category; // RAW_GOLD | DIAMONDS | FINDINGS_CASTS | READY_ALLOY
  final String purity;
  final double totalStock;
  final double reservedWip;
  final double freeBalance;
  final String unit;
  final String location;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String? createdById;
  final ApiUser? createdBy;
}

class ApiInventorySummary {
  const ApiInventorySummary({
    this.totalVaultGold = 0.0,
    this.totalReservedWip = 0.0,
    this.totalFreeBalance = 0.0,
  });

  factory ApiInventorySummary.fromJson(Map<String, dynamic> json) {
    return ApiInventorySummary(
      totalVaultGold: (json['totalVaultGold'] as num?)?.toDouble() ?? 0.0,
      totalReservedWip: (json['totalReservedWip'] as num?)?.toDouble() ?? 0.0,
      totalFreeBalance: (json['totalFreeBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final double totalVaultGold;
  final double totalReservedWip;
  final double totalFreeBalance;
}

class ApiInventoryResponse {
  const ApiInventoryResponse({required this.items, required this.summary});

  factory ApiInventoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    final itemsList = rawItems
        .map((item) => ApiInventoryItem.fromJson(item as Map<String, dynamic>))
        .toList();

    double calcVaultGold = 0.0;
    double calcReservedWip = 0.0;
    double calcFreeBalance = 0.0;
    for (final item in itemsList) {
      calcVaultGold += item.totalStock;
      calcReservedWip += item.reservedWip;
      calcFreeBalance += item.freeBalance > 0
          ? item.freeBalance
          : (item.totalStock - item.reservedWip);
    }

    final summaryObj = json['summary'] is Map
        ? ApiInventorySummary.fromJson(json['summary'] as Map<String, dynamic>)
        : null;

    final summaryData = (summaryObj != null && summaryObj.totalVaultGold > 0)
        ? summaryObj
        : ApiInventorySummary(
            totalVaultGold: calcVaultGold,
            totalReservedWip: calcReservedWip,
            totalFreeBalance: calcFreeBalance,
          );

    return ApiInventoryResponse(items: itemsList, summary: summaryData);
  }

  final List<ApiInventoryItem> items;
  final ApiInventorySummary summary;
}

// ── 14. Floor Directives & Voice Notes Models ────────────────────────
class ApiDirective {
  const ApiDirective({
    required this.id,
    required this.directiveCode,
    required this.title,
    required this.targetType,
    required this.instruction,
    this.audioUrl,
    this.imageUrl,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  factory ApiDirective.fromJson(Map<String, dynamic> json) {
    return ApiDirective(
      id: json['id'] as String? ?? '',
      directiveCode: json['directiveCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetType: json['targetType'] as String? ?? 'ALL_ARTISANS',
      instruction: json['instruction'] as String? ?? '',
      audioUrl: json['audioUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'targetType': targetType,
    'instruction': instruction,
    'audioUrl': audioUrl,
    'imageUrl': imageUrl,
  };

  final String id;
  final String directiveCode;
  final String title;
  final String
  targetType; // THREE_D_DESIGNER | SKETCHER | ALL_ARTISANS | BENCH_ARTISAN
  final String instruction;
  final String? audioUrl;
  final String? imageUrl;
  final String status; // ACTIVE | ACKNOWLEDGED
  final String? createdAt;
}

// ── 15. CAD PaddleOCR Spec Extraction Models ─────────────────────────
class GemSummaryData {
  const GemSummaryData({
    required this.totalCount,
    required this.totalWeightTw,
    required this.densitySpg,
    required this.materialType,
  });

  factory GemSummaryData.fromJson(Map<String, dynamic> json) {
    return GemSummaryData(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      totalWeightTw: (json['totalWeightTw'] as num?)?.toDouble() ?? 0.0,
      densitySpg: (json['densitySpg'] as num?)?.toDouble() ?? 0.0,
      materialType: json['materialType'] as String? ?? '',
    );
  }

  final int totalCount;
  final double totalWeightTw;
  final double densitySpg;
  final String materialType;
}

class GemBreakdownItem {
  const GemBreakdownItem({
    required this.shape,
    required this.dimensions,
    required this.count,
    required this.weightTw,
    this.color = '',
  });

  factory GemBreakdownItem.fromJson(Map<String, dynamic> json) {
    return GemBreakdownItem(
      shape: json['shape'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      weightTw: (json['weightTw'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? '',
    );
  }

  final String shape;
  final String dimensions;
  final int count;
  final double weightTw;
  final String color;
}

class CadOcrExtractedData {
  const CadOcrExtractedData({
    required this.designNumber,
    required this.metalWeightGrams,
    required this.makingCode,
    required this.gemSummary,
    required this.gemBreakdown,
    required this.confidenceScore,
  });

  factory CadOcrExtractedData.fromJson(Map<String, dynamic> json) {
    final gemSummaryMap = json['gemSummary'] as Map<String, dynamic>?;
    final gemBreakdownList = json['gemBreakdown'] as List? ?? const [];

    return CadOcrExtractedData(
      designNumber: json['designNumber'] as String? ?? '',
      metalWeightGrams: (json['metalWeightGrams'] as num?)?.toDouble() ?? 0.0,
      makingCode: json['makingCode'] as String? ?? '',
      gemSummary: gemSummaryMap != null
          ? GemSummaryData.fromJson(gemSummaryMap)
          : const GemSummaryData(
              totalCount: 0,
              totalWeightTw: 0.0,
              densitySpg: 0.0,
              materialType: '',
            ),
      gemBreakdown: gemBreakdownList
          .map((e) => GemBreakdownItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String designNumber;
  final double metalWeightGrams;
  final String makingCode;
  final GemSummaryData gemSummary;
  final List<GemBreakdownItem> gemBreakdown;
  final double confidenceScore;
}

// ── 16. Worker & Stockist Dedicated Models ────────────────────────
class ApiWorker {
  const ApiWorker({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.craft,
    this.specialty = '',
    this.isActive = true,
    this.activeLotsCount = 0,
    this.workerAssignmentsCount = 0,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ApiWorker.fromJson(Map<String, dynamic> json) {
    return ApiWorker(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      craft:
          json['craft'] as String? ??
          json['specialty'] as String? ??
          'GOLDSMITH',
      specialty: json['specialty'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      activeLotsCount: (json['activeLotsCount'] as num?)?.toInt() ?? 0,
      workerAssignmentsCount:
          (json['workerAssignmentsCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'craft': craft,
    'specialty': specialty,
    'isActive': isActive,
  };

  final String id;
  final String name;
  final String email;
  final String phone;
  final String craft;
  final String specialty;
  final bool isActive;
  final int activeLotsCount;
  final int workerAssignmentsCount;
  final String createdAt;
  final String updatedAt;
}

class ApiStockist {
  const ApiStockist({
    required this.id,
    required this.firmName,
    required this.contactPerson,
    required this.phone,
    this.email = '',
    this.location = 'Vault Main',
    this.vaultAccessLevel = 'LEVEL_1',
    this.totalManagedGrams = 0.0,
    this.outstandingBalance = 0.0,
    this.creditLimitLakhs = 0.0,
    this.isActive = true,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory ApiStockist.fromJson(Map<String, dynamic> json) {
    return ApiStockist(
      id: json['id'] as String? ?? '',
      firmName: json['firmName'] as String? ?? json['name'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      location: json['location'] as String? ?? 'Vault Main',
      vaultAccessLevel: json['vaultAccessLevel'] as String? ?? 'LEVEL_1',
      totalManagedGrams: (json['totalManagedGrams'] as num?)?.toDouble() ?? 0.0,
      outstandingBalance:
          (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      creditLimitLakhs: (json['creditLimitLakhs'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firmName': firmName,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'location': location,
    'vaultAccessLevel': vaultAccessLevel,
    'totalManagedGrams': totalManagedGrams,
    'outstandingBalance': outstandingBalance,
    'creditLimitLakhs': creditLimitLakhs,
    'isActive': isActive,
  };

  final String id;
  final String firmName;
  final String contactPerson;
  final String phone;
  final String email;
  final String location;
  final String vaultAccessLevel;
  final double totalManagedGrams;
  final double outstandingBalance;
  final double creditLimitLakhs;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
}

class StoneSpec {
  const StoneSpec({
    required this.name,
    required this.count,
    required this.size,
    required this.shape,
    required this.color,
    required this.clarity,
  });

  final String name;
  final int count;
  final String size;
  final String shape;
  final String color;
  final String clarity;
}

// ── Vault Material & Stones Requisition Model ──────────────────────────────────
class VaultRequisition {
  const VaultRequisition({
    required this.id,
    this.orderPartId = '',
    required this.designNumber,
    required this.orderId,
    this.customerName = '',
    this.dueDate = '',
    required this.artisanName,
    required this.stageName,
    required this.quantity,
    required this.goldWeightGrams,
    this.gemWeightTw = 0.0,
    this.sizeDimensions = '',
    required this.stones,
    this.stoneSpecs = const [],
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String orderPartId;
  final String designNumber;
  final String orderId;
  final String customerName;
  final String dueDate;
  final String artisanName;
  final String stageName;
  final int quantity;
  final double goldWeightGrams;
  final double gemWeightTw;
  final String sizeDimensions;
  final List<String> stones;
  final List<StoneSpec> stoneSpecs;
  final String status; // 'PENDING_ISSUE', 'ISSUED'
  final String timestamp;

  VaultRequisition copyWith({
    String? status,
    List<StoneSpec>? stoneSpecs,
    String? customerName,
    String? dueDate,
    double? gemWeightTw,
    String? sizeDimensions,
    String? orderPartId,
  }) {
    return VaultRequisition(
      id: id,
      orderPartId: orderPartId ?? this.orderPartId,
      designNumber: designNumber,
      orderId: orderId,
      customerName: customerName ?? this.customerName,
      dueDate: dueDate ?? this.dueDate,
      artisanName: artisanName,
      stageName: stageName,
      quantity: quantity,
      goldWeightGrams: goldWeightGrams,
      gemWeightTw: gemWeightTw ?? this.gemWeightTw,
      sizeDimensions: sizeDimensions ?? this.sizeDimensions,
      stones: stones,
      stoneSpecs: stoneSpecs ?? this.stoneSpecs,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }
}

// ── Official Stockist Pending Issuance & Allocation Models ─────────────────────
class ApiAssignedCraftsman {
  const ApiAssignedCraftsman({
    required this.id,
    required this.name,
    this.phone = '',
    this.role = '',
  });

  final String id;
  final String name;
  final String phone;
  final String role;

  factory ApiAssignedCraftsman.fromJson(Map<String, dynamic> json) {
    return ApiAssignedCraftsman(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Craftsman',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

class ApiGemBreakdownItem {
  const ApiGemBreakdownItem({
    required this.shape,
    required this.dimensions,
    required this.color,
    required this.count,
  });

  final String shape;
  final String dimensions;
  final String color;
  final int count;

  factory ApiGemBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ApiGemBreakdownItem(
      shape: json['shape'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      color: json['color'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiCadSpecs {
  const ApiCadSpecs({
    this.gemQuantity = 0,
    this.goldQuantity = 0.0,
    this.gemWeightTw = 0.0,
    this.sizeDimensions = '',
    this.gemBreakdown = const [],
  });

  final int gemQuantity;
  final double goldQuantity;
  final double gemWeightTw;
  final String sizeDimensions;
  final List<ApiGemBreakdownItem> gemBreakdown;

  factory ApiCadSpecs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApiCadSpecs();
    final rawBreakdown = json['gemBreakdown'] as List? ?? [];
    return ApiCadSpecs(
      gemQuantity: (json['gemQuantity'] as num?)?.toInt() ?? 0,
      goldQuantity: (json['goldQuantity'] as num?)?.toDouble() ?? 0.0,
      gemWeightTw: (json['gemWeightTw'] as num?)?.toDouble() ?? 0.0,
      sizeDimensions: json['sizeDimensions'] as String? ?? '',
      gemBreakdown: rawBreakdown
          .map((b) => ApiGemBreakdownItem.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiPendingIssuance {
  const ApiPendingIssuance({
    required this.orderPartId,
    required this.orderId,
    required this.orderNumber,
    required this.designNumber,
    this.customerName = '',
    this.dueDate = '',
    required this.currentStage,
    this.orderPartStatus = '',
    this.assignedCraftsman,
    this.partAssignmentId = '',
    this.cadSpecs = const ApiCadSpecs(),
    this.isStockIssued = false,
    this.issuance,
  });

  final String orderPartId;
  final String orderId;
  final String orderNumber;
  final String designNumber;
  final String customerName;
  final String dueDate;
  final String currentStage;
  final String orderPartStatus;
  final ApiAssignedCraftsman? assignedCraftsman;
  final String partAssignmentId;
  final ApiCadSpecs cadSpecs;
  final bool isStockIssued;
  final ApiMaterialIssuance? issuance;

  factory ApiPendingIssuance.fromJson(Map<String, dynamic> json) {
    final craftsmanMap = json['assignedCraftsman'] as Map<String, dynamic>?;
    final specsMap = json['cadSpecs'] as Map<String, dynamic>?;
    final issuanceMap = json['issuance'] as Map<String, dynamic>?;
    return ApiPendingIssuance(
      orderPartId: json['orderPartId'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      designNumber: json['designNumber'] as String? ?? 'D01',
      customerName: json['customerName'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      currentStage: json['currentStage'] as String? ?? 'Setting',
      orderPartStatus: json['orderPartStatus'] as String? ?? 'ASSIGNED',
      assignedCraftsman: craftsmanMap != null
          ? ApiAssignedCraftsman.fromJson(craftsmanMap)
          : null,
      partAssignmentId: json['partAssignmentId'] as String? ?? '',
      cadSpecs: ApiCadSpecs.fromJson(specsMap),
      isStockIssued: json['isStockIssued'] as bool? ?? false,
      issuance: issuanceMap != null
          ? ApiMaterialIssuance.fromJson(issuanceMap)
          : null,
    );
  }
}

class ApiMaterialIssuance {
  const ApiMaterialIssuance({
    required this.id,
    required this.issueNumber,
    required this.orderPartId,
    this.partAssignmentId = '',
    this.craftsmanId = '',
    this.stockistId = '',
    required this.status,
    this.itemsIssued = const [],
    this.totalWeightIssued = 0.0,
    this.totalPcsIssued = 0,
    this.issuedAt = '',
    this.reconciliationNotes,
    this.craftsmanName = '',
    this.stockistName = '',
  });

  final String id;
  final String issueNumber;
  final String orderPartId;
  final String partAssignmentId;
  final String craftsmanId;
  final String stockistId;
  final String status;
  final List<Map<String, dynamic>> itemsIssued;
  final double totalWeightIssued;
  final int totalPcsIssued;
  final String issuedAt;
  final String? reconciliationNotes;
  final String craftsmanName;
  final String stockistName;

  factory ApiMaterialIssuance.fromJson(Map<String, dynamic> json) {
    final craftsmanMap = json['craftsman'] as Map<String, dynamic>?;
    final stockistMap = json['stockist'] as Map<String, dynamic>?;
    final itemsList = (json['itemsIssued'] as List? ?? [])
        .map((i) => i as Map<String, dynamic>)
        .toList();
    return ApiMaterialIssuance(
      id: json['id'] as String? ?? '',
      issueNumber: json['issueNumber'] as String? ?? '',
      orderPartId: json['orderPartId'] as String? ?? '',
      partAssignmentId: json['partAssignmentId'] as String? ?? '',
      craftsmanId: json['craftsmanId'] as String? ?? '',
      stockistId: json['stockistId'] as String? ?? '',
      status: json['status'] as String? ?? 'ISSUED',
      itemsIssued: itemsList,
      totalWeightIssued: (json['totalWeightIssued'] as num?)?.toDouble() ?? 0.0,
      totalPcsIssued: (json['totalPcsIssued'] as num?)?.toInt() ?? 0,
      issuedAt: json['issuedAt'] as String? ?? '',
      reconciliationNotes: json['reconciliationNotes'] as String?,
      craftsmanName: craftsmanMap?['name'] as String? ?? '',
      stockistName: stockistMap?['name'] as String? ?? '',
    );
  }
}
