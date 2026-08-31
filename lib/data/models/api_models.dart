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
    this.specialty = '',
    this.isActive = true,
    this.workerAssignmentsCount = 0,
  });

  factory ApiEmployee.fromJson(Map<String, dynamic> json) {
    final count =
        (json['activeAssignmentsCount'] as num?)?.toInt() ??
        (json['_count'] is Map
            ? (json['_count']['workerAssignments'] as num?)?.toInt() ?? 0
            : 0);
    return ApiEmployee(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'OTHER_EMPLOYEE',
      specialty: json['specialty'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      workerAssignmentsCount: count,
    );
  }

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String specialty;
  final bool isActive;
  final int workerAssignmentsCount;
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
    return ApiSketch(
      id: json['id'] as String? ?? '',
      designNumber: json['designNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sketchUrl: json['sketchUrl'] as String? ?? '',
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
class ApiWorkerTask {
  const ApiWorkerTask({
    required this.id,
    required this.status,
    required this.instructions,
    required this.designNumber,
    required this.quantity,
    required this.stageName,
    this.orderId = '',
    this.assignedEmployeeName = '',
    this.grossWeight = 0.0,
  });

  factory ApiWorkerTask.fromJson(Map<String, dynamic> json) {
    String dNum = '';
    int qty = 0;
    double gWt = 0.0;
    String oId = '';
    String sName = '';
    String employeeName = '';
    if (json['orderPart'] is Map) {
      dNum = json['orderPart']['designNumber'] as String? ?? '';
      qty = json['orderPart']['quantity'] as int? ?? 0;
      gWt = (json['orderPart']['grossWeight'] as num?)?.toDouble() ?? 0.0;
      if (json['orderPart']['order'] is Map) {
        oId =
            json['orderPart']['order']['orderNumber'] as String? ??
            json['orderPart']['order']['id'] as String? ??
            '';
      }
      oId = oId.isNotEmpty
          ? oId
          : json['orderPart']['orderNumber'] as String? ??
                json['orderPart']['orderId'] as String? ??
                '';
    }
    if (json['stage'] is Map) {
      sName = json['stage']['name'] as String? ?? '';
    }
    final employee =
        json['assignedEmployee'] ??
        json['employee'] ??
        json['artisan'] ??
        json['worker'];
    if (employee is Map) {
      employeeName =
          employee['name'] as String? ?? employee['fullName'] as String? ?? '';
      if (employeeName.isEmpty && employee['firstName'] != null) {
        final fName = employee['firstName'] as String? ?? '';
        final lName = employee['lastName'] as String? ?? '';
        employeeName = '$fName $lName'.trim();
      }
    } else if (employee is String) {
      employeeName = employee;
    }

    final instructionsStr = json['instructions'] as String? ?? '';
    if (employeeName.isEmpty || employeeName.trim().isEmpty) {
      if (instructionsStr.contains('Assigned to ')) {
        final idx = instructionsStr.indexOf('Assigned to ');
        final rest = instructionsStr
            .substring(idx + 'Assigned to '.length)
            .trim();
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

    return ApiWorkerTask(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'ASSIGNED',
      instructions: instructionsStr,
      designNumber: dNum,
      quantity: qty,
      stageName: sName,
      orderId: oId,
      assignedEmployeeName: employeeName,
      grossWeight: gWt,
    );
  }

  final String id;
  final String status;
  final String instructions;
  final String designNumber;
  final int quantity;
  final String stageName;
  final String orderId;
  final String assignedEmployeeName;
  final double grossWeight;
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
    final summaryData = json['summary'] is Map
        ? ApiInventorySummary.fromJson(json['summary'] as Map<String, dynamic>)
        : const ApiInventorySummary();

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
  });

  factory GemBreakdownItem.fromJson(Map<String, dynamic> json) {
    return GemBreakdownItem(
      shape: json['shape'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      weightTw: (json['weightTw'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String shape;
  final String dimensions;
  final int count;
  final double weightTw;
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

