library;

import 'package:jewellery_ops_mobile/core/network/api_endpoints.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'isActive': isActive,
  };
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'contactPerson': contactPerson,
    'phone': phone,
    'email': email,
    'creditLimitLakhs': creditLimitLakhs,
    'outstandingLakhs': outstandingLakhs,
    '_count': {'orders': ordersCount},
  };
}

// ── 4. Production Stage Models ──────────────────────────────────────
class ApiStage {
  const ApiStage({
    required this.id,
    required this.name,
    required this.stageNumber,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory ApiStage.fromJson(Map<String, dynamic> json) {
    final rawDesc =
        json['description'] as String? ??
        json['desc'] as String? ??
        json['details'] as String? ??
        json['stageDescription'] as String? ??
        json['stage_description'] as String? ??
        json['instructions'] as String? ??
        json['sop'] as String? ??
        json['notes'] as String? ??
        json['info'] as String?;

    return ApiStage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stageNumber: (json['stageNumber'] is num)
          ? (json['stageNumber'] as num).toInt()
          : int.tryParse(json['stageNumber']?.toString() ?? '0') ?? 0,
      description: rawDesc?.trim(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  final String id;
  final String name;
  final int stageNumber;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get effectiveDescription {
    final rawDesc = description?.trim();
    if (rawDesc != null && rawDesc.isNotEmpty) {
      return rawDesc;
    }
    final lower = name.toLowerCase();
    if (lower.contains('cad') ||
        lower.contains('cam') ||
        lower.contains('design') ||
        lower.contains('3d')) {
      return '3D computer-aided modeling, stone layout & resin prototype slicing';
    }
    if (lower.contains('wax') ||
        lower.contains('tree') ||
        lower.contains('mould')) {
      return 'Precision rubber vulcanizing, wax injection & tree assembling';
    }
    if (lower.contains('cast') || lower.contains('dhalai')) {
      return 'Vacuum induction casting with purity alloy & flask burnout';
    }
    if (lower.contains('filing') ||
        lower.contains('ghat') ||
        lower.contains('clean') ||
        lower.contains('grind') ||
        lower.contains('assembly')) {
      return 'Sprue cutting, emery filing, assembly soldering & weight calibration';
    }
    if (lower.contains('setting') ||
        lower.contains('jadayi') ||
        lower.contains('stone') ||
        lower.contains('diamond') ||
        lower.contains('prong') ||
        lower.contains('pave')) {
      return 'Microscope prong, pave, bezel & channel gem stone placement';
    }
    if (lower.contains('polish') ||
        lower.contains('buff') ||
        lower.contains('chilai') ||
        lower.contains('ghissai') ||
        lower.contains('luster')) {
      return 'Magnetic tumbling, preliminary tripoli & final rouge mirror finish';
    }
    if (lower.contains('plate') ||
        lower.contains('rhodium') ||
        lower.contains('wash') ||
        lower.contains('dip') ||
        lower.contains('color')) {
      return 'Electro-chemical degreasing & high-micron rhodium/gold plating';
    }
    if (lower.contains('hallmark') ||
        lower.contains('qc') ||
        lower.contains('quality') ||
        lower.contains('check') ||
        lower.contains('audit') ||
        lower.contains('bis')) {
      return 'BIS XRF purity assaying, weight verification & laser hallmark engraving';
    }
    if (lower.contains('pack') ||
        lower.contains('dispatch') ||
        lower.contains('vault') ||
        lower.contains('tag')) {
      return 'Safe vault transfer, tag labeling & tamper-proof customer packaging';
    }
    return 'Step $stageNumber production routing & quality assurance checkpoint';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stageNumber': stageNumber,
    if (description != null) 'description': description,
    'isActive': isActive,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  ApiStage copyWith({
    String? id,
    String? name,
    int? stageNumber,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiStage(
      id: id ?? this.id,
      name: name ?? this.name,
      stageNumber: stageNumber ?? this.stageNumber,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
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
    String? fileUrlFromMap(dynamic f) {
      if (f is String && f.isNotEmpty) return f;
      if (f is Map) {
        return f['url'] as String? ??
            f['path'] as String? ??
            f['fileKey'] as String? ??
            f['key'] as String?;
      }
      return null;
    }

    final rawUrl =
        json['sketchUrl'] as String? ??
        json['sketch_url'] as String? ??
        json['imageUrl'] as String? ??
        json['image_url'] as String? ??
        json['url'] as String? ??
        json['image'] as String? ??
        json['photoUrl'] as String? ??
        json['photo'] as String? ??
        json['renderImageUrl'] as String? ??
        json['renderUrl'] as String? ??
        json['sketchPath'] as String? ??
        json['filePath'] as String? ??
        json['fileUrl'] as String? ??
        json['file_url'] as String? ??
        json['storageKey'] as String? ??
        json['cdnUrl'] as String? ??
        fileUrlFromMap(json['file']) ??
        fileUrlFromMap(json['attachment']) ??
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'designNumber': designNumber,
    'title': title,
    'sketchUrl': sketchUrl,
    'status': status,
    'version': version,
    if (adminInstructions != null) 'adminInstructions': adminInstructions,
    if (feedbackAudioUrl != null) 'feedbackAudioUrl': feedbackAudioUrl,
    if (feedbackImageUrl != null) 'feedbackImageUrl': feedbackImageUrl,
    if (designer != null) 'designer': designer!.toJson(),
    'designerId': designerId,
    if (createdAt != null) 'createdAt': createdAt,
    if (updatedAt != null) 'updatedAt': updatedAt,
    if (category != null) 'category': category,
    if (price != null) 'price': price,
  };
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
    final subtotalVal =
        (json['subtotal'] as num?)?.toDouble() ??
        (json['sub_total'] as num?)?.toDouble() ??
        0.0;
    final gstPercentVal =
        (json['gstPercent'] as num?)?.toDouble() ??
        (json['gst_percent'] as num?)?.toDouble() ??
        (json['gstPercentage'] as num?)?.toDouble() ??
        (json['taxPercent'] as num?)?.toDouble() ??
        (json['tax_percent'] as num?)?.toDouble() ??
        (json['gstRate'] as num?)?.toDouble() ??
        (json['gst_rate'] as num?)?.toDouble() ??
        0.0;
    final gstAmountVal =
        (json['gstAmount'] as num?)?.toDouble() ??
        (json['gst_amount'] as num?)?.toDouble() ??
        (json['gst'] as num?)?.toDouble() ??
        (json['taxAmount'] as num?)?.toDouble() ??
        (json['tax_amount'] as num?)?.toDouble() ??
        (json['tax'] as num?)?.toDouble() ??
        (gstPercentVal > 0 && subtotalVal > 0
            ? (subtotalVal * gstPercentVal / 100)
            : 0.0);
    final finalPriceVal =
        (json['finalPrice'] as num?)?.toDouble() ??
        (json['final_price'] as num?)?.toDouble() ??
        (json['totalPrice'] as num?)?.toDouble() ??
        (json['total_price'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        0.0;

    return ApiPriceBreakdown(
      purity: json['purity'] as String? ?? '',
      goldRatePerGram:
          (json['goldRatePerGram'] as num?)?.toDouble() ??
          (json['gold_rate_per_gram'] as num?)?.toDouble() ??
          0.0,
      netGoldWeight:
          (json['netGoldWeight'] as num?)?.toDouble() ??
          (json['net_gold_weight'] as num?)?.toDouble() ??
          0.0,
      grossWeight:
          (json['grossWeight'] as num?)?.toDouble() ??
          (json['gross_weight'] as num?)?.toDouble() ??
          0.0,
      totalGoldCost:
          (json['totalGoldCost'] as num?)?.toDouble() ??
          (json['total_gold_cost'] as num?)?.toDouble() ??
          0.0,
      gemQuantity:
          (json['gemQuantity'] as num?)?.toInt() ??
          (json['gem_quantity'] as num?)?.toInt() ??
          0,
      gemRate:
          (json['gemRate'] as num?)?.toDouble() ??
          (json['gem_rate'] as num?)?.toDouble() ??
          0.0,
      totalGemCost:
          (json['totalGemCost'] as num?)?.toDouble() ??
          (json['total_gem_cost'] as num?)?.toDouble() ??
          0.0,
      subtotal: subtotalVal,
      gstPercent: gstPercentVal,
      gstAmount: gstAmountVal,
      finalPrice: finalPriceVal > 0
          ? finalPriceVal
          : (subtotalVal + gstAmountVal),
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

  Map<String, dynamic> toJson() => {
    'purity': purity,
    'goldRatePerGram': goldRatePerGram,
    'netGoldWeight': netGoldWeight,
    'grossWeight': grossWeight,
    'totalGoldCost': totalGoldCost,
    'gemQuantity': gemQuantity,
    'gemRate': gemRate,
    'totalGemCost': totalGemCost,
    'subtotal': subtotal,
    'gstPercent': gstPercent,
    'gstAmount': gstAmount,
    'finalPrice': finalPrice,
  };
}

// ── 5B. Catalog Gallery Images ───────────────────────────────────────
class ApiGalleryImage {
  const ApiGalleryImage({
    this.id = '',
    required this.url,
    this.name = '',
    this.isBomCrop = false,
    this.isPrimary = false,
  });

  factory ApiGalleryImage.fromJson(Map<String, dynamic> json) {
    return ApiGalleryImage(
      id: json['id'] as String? ?? '',
      url: ApiEndpoints.resolveImageUrl(json['url'] as String?),
      name: json['name'] as String? ?? '',
      isBomCrop:
          json['isBomCrop'] as bool? ?? json['is_bom_crop'] as bool? ?? false,
      isPrimary:
          json['isPrimary'] as bool? ?? json['is_primary'] as bool? ?? false,
    );
  }

  final String id;
  final String url;
  final String name;
  final bool isBomCrop;
  final bool isPrimary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'name': name,
    'isBomCrop': isBomCrop,
    'isPrimary': isPrimary,
  };
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
    this.imageUrl,
    this.renderImageUrl,
    this.rawInstructions,
    this.cleanDesignUrl,
    this.galleryImages = const [],
    this.heroImageUrl,
    this.croppedImageUrl,
    this.sketchUrl,
    this.title,
    this.designNumber,
  });

  factory ApiThreeDDesign.fromJson(Map<String, dynamic> json) {
    final gemBreakdownList = json['gemBreakdown'] as List? ?? const [];
    final imgUrl =
        json['imageUrl'] as String? ??
        json['image'] as String? ??
        json['thumbnailUrl'] as String? ??
        json['previewUrl'] as String? ??
        json['designImageUrl'] as String? ??
        json['designImage'] as String? ??
        json['photoUrl'] as String? ??
        json['photo'] as String? ??
        json['fileUrl'] as String? ??
        (json['file'] is String ? json['file'] as String : null) ??
        json['sketchUrl'] as String?;
    final renderUrl =
        json['renderImageUrl'] as String? ??
        json['renderUrl'] as String? ??
        json['renderImage'] as String? ??
        json['render'] as String?;

    final cleanUrl =
        json['cleanDesignUrl'] as String? ??
        json['croppedDesignUrl'] as String?;

    final rawSketchId =
        json['sketchId'] as String? ??
        json['sketch_id'] as String? ??
        (json['sketch'] is String ? json['sketch'] as String : '');

    final galleryList =
        json['galleryImages'] as List? ??
        json['gallery_images'] as List? ??
        const [];
    final parsedGallery = galleryList
        .whereType<Map>()
        .map((g) => ApiGalleryImage.fromJson(Map<String, dynamic>.from(g)))
        .toList();

    final heroImg =
        json['heroImageUrl'] as String? ?? json['hero_image_url'] as String?;
    final croppedImg =
        json['croppedImageUrl'] as String? ??
        json['cropped_image_url'] as String?;
    final sketchUrlVal =
        json['sketchUrl'] as String? ?? json['sketch_url'] as String?;
    final titleVal = json['title'] as String? ?? json['designTitle'] as String?;
    final designNumberVal =
        json['designNumber'] as String? ?? json['design_number'] as String?;
    final bomUrl =
        json['bomFileUrl'] as String? ?? json['bom_file_url'] as String?;

    final sketchRaw = json['sketch'];
    final parsedSketch = sketchRaw is Map<String, dynamic>
        ? ApiSketch.fromJson(sketchRaw)
        : (sketchRaw is Map
              ? ApiSketch.fromJson(Map<String, dynamic>.from(sketchRaw))
              : null);

    final rawInstructions =
        json['rawInstructions'] as String? ??
        json['adminInstructions'] as String?;

    int? parsedStock = json['stock'] as int?;
    if (parsedStock == null &&
        rawInstructions != null &&
        rawInstructions.isNotEmpty) {
      final stockMatch = RegExp(
        r'Stock:\s*(\d+)',
        caseSensitive: false,
      ).firstMatch(rawInstructions);
      if (stockMatch != null) {
        parsedStock = int.tryParse(stockMatch.group(1)!);
      }
    }

    String? parsedStockStatus = json['stockStatus'] as String?;
    if ((parsedStockStatus == null || parsedStockStatus.isEmpty) &&
        rawInstructions != null &&
        rawInstructions.isNotEmpty) {
      final statusMatch = RegExp(
        r'Status:\s*([^\r\n,]+)',
        caseSensitive: false,
      ).firstMatch(rawInstructions);
      if (statusMatch != null) {
        parsedStockStatus = statusMatch.group(1)!.trim();
      }
    }

    return ApiThreeDDesign(
      id: json['id'] as String? ?? '',
      sketchId: rawSketchId,
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      version: json['version'] as int? ?? 1,
      xtlFileUrl: json['xtlFileUrl'] as String?,
      bomFileUrl: ApiEndpoints.resolveImageUrl(bomUrl),
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
      sketch: parsedSketch,
      designer: json['designer'] is Map
          ? ApiUser.fromJson(json['designer'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
      stock: parsedStock,
      stockStatus: parsedStockStatus,
      price: (json['price'] as num?)?.toDouble(),
      calculatedPrice:
          (json['calculatedPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
      priceBreakdown: (json['priceBreakdown'] is Map)
          ? ApiPriceBreakdown.fromJson(
              json['priceBreakdown'] as Map<String, dynamic>,
            )
          : ((json['price_breakdown'] is Map)
                ? ApiPriceBreakdown.fromJson(
                    json['price_breakdown'] as Map<String, dynamic>,
                  )
                : ((json['pricingBreakdown'] is Map)
                      ? ApiPriceBreakdown.fromJson(
                          json['pricingBreakdown'] as Map<String, dynamic>,
                        )
                      : ((json['pricing'] is Map)
                            ? ApiPriceBreakdown.fromJson(
                                json['pricing'] as Map<String, dynamic>,
                              )
                            : null))),
      description: json['description'] as String?,
      imageUrl: ApiEndpoints.resolveImageUrl(imgUrl),
      renderImageUrl: ApiEndpoints.resolveImageUrl(renderUrl),
      rawInstructions: rawInstructions,
      cleanDesignUrl: ApiEndpoints.resolveImageUrl(cleanUrl),
      galleryImages: parsedGallery,
      heroImageUrl: ApiEndpoints.resolveImageUrl(heroImg),
      croppedImageUrl: ApiEndpoints.resolveImageUrl(croppedImg),
      sketchUrl: ApiEndpoints.resolveImageUrl(sketchUrlVal),
      title: titleVal,
      designNumber: designNumberVal,
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
  final String? imageUrl;
  final String? renderImageUrl;
  final String? rawInstructions;
  final String? cleanDesignUrl;
  final List<ApiGalleryImage> galleryImages;
  final String? heroImageUrl;
  final String? croppedImageUrl;
  final String? sketchUrl;
  final String? title;
  final String? designNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sketchId': sketchId,
    'totalWeight': totalWeight,
    'status': status,
    'version': version,
    if (xtlFileUrl != null) 'xtlFileUrl': xtlFileUrl,
    if (bomFileUrl != null) 'bomFileUrl': bomFileUrl,
    'gemQuantity': gemQuantity,
    'goldQuantity': goldQuantity,
    'otherMetalsQuantity': otherMetalsQuantity,
    'volumeMm3': volumeMm3,
    'sizeDimensions': sizeDimensions,
    'makingCode': makingCode,
    'gemWeightTw': gemWeightTw,
    'gemBreakdown': gemBreakdown.map((e) => e.toJson()).toList(),
    if (adminInstructions != null) 'adminInstructions': adminInstructions,
    if (rawInstructions != null) 'rawInstructions': rawInstructions,
    if (feedbackAudioUrl != null) 'feedbackAudioUrl': feedbackAudioUrl,
    if (feedbackImageUrl != null) 'feedbackImageUrl': feedbackImageUrl,
    if (sketch != null) 'sketch': sketch!.toJson(),
    if (designer != null) 'designer': designer!.toJson(),
    if (category != null) 'category': category,
    if (stock != null) 'stock': stock,
    if (stockStatus != null) 'stockStatus': stockStatus,
    if (price != null) 'price': price,
    if (calculatedPrice != null) 'calculatedPrice': calculatedPrice,
    if (priceBreakdown != null) 'priceBreakdown': priceBreakdown!.toJson(),
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (renderImageUrl != null) 'renderImageUrl': renderImageUrl,
    if (cleanDesignUrl != null) 'cleanDesignUrl': cleanDesignUrl,
  };
}

// ── 7. Order & Part Models ──────────────────────────────────────────
class ApiOrderStageSnapshot {
  const ApiOrderStageSnapshot({
    required this.id,
    required this.stageNumber,
    required this.name,
    this.isFinal = false,
  });

  factory ApiOrderStageSnapshot.fromJson(Map<String, dynamic> json) {
    return ApiOrderStageSnapshot(
      id: json['id']?.toString() ?? '',
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      isFinal: json['isFinal'] as bool? ?? false,
    );
  }

  final String id;
  final int stageNumber;
  final String name;
  final bool isFinal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'stageNumber': stageNumber,
    'name': name,
    'isFinal': isFinal,
  };
}

class ApiPartAssignment {
  const ApiPartAssignment({
    required this.id,
    this.assignedEmployeeId = '',
    this.assignedEmployeeName = '',
    this.assignedEmployeeRole = '',
    this.status = 'PENDING',
  });

  factory ApiPartAssignment.fromJson(Map<String, dynamic> json) {
    String empId = '';
    String empName = '';
    String empRole = '';
    if (json['assignedEmployee'] is Map) {
      final emp = json['assignedEmployee'] as Map<String, dynamic>;
      empId = emp['id']?.toString() ?? '';
      empName = emp['name']?.toString() ?? emp['fullName']?.toString() ?? '';
      empRole = emp['role']?.toString() ?? '';
    } else if (json['employee'] is Map) {
      final emp = json['employee'] as Map<String, dynamic>;
      empId = emp['id']?.toString() ?? '';
      empName = emp['name']?.toString() ?? emp['fullName']?.toString() ?? '';
      empRole = emp['role']?.toString() ?? '';
    }

    return ApiPartAssignment(
      id: json['id']?.toString() ?? '',
      assignedEmployeeId: empId,
      assignedEmployeeName: empName,
      assignedEmployeeRole: empRole,
      status: json['status']?.toString() ?? 'PENDING',
    );
  }

  final String id;
  final String assignedEmployeeId;
  final String assignedEmployeeName;
  final String assignedEmployeeRole;
  final String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'assignedEmployee': {
      'id': assignedEmployeeId,
      'name': assignedEmployeeName,
      'role': assignedEmployeeRole,
    },
    'status': status,
  };
}

class ApiOrder {
  const ApiOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.customerName = '',
    this.customerCity = '',
    this.dueDate = '',
    this.createdAt,
    this.totalPieces = 0,
    this.stagesSnapshot = const [],
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
    final rawStages = json['stagesSnapshot'] as List? ?? [];
    final partsList = rawParts
        .map((p) => ApiOrderPart.fromJson(p as Map<String, dynamic>))
        .toList();

    int totalP = (json['totalPieces'] as num?)?.toInt() ?? 0;
    if (totalP == 0 && partsList.isNotEmpty) {
      totalP = partsList.fold(0, (sum, p) => sum + p.quantity);
    }

    return ApiOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      customerName: cName,
      customerCity: cCity,
      dueDate: json['dueDate']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      totalPieces: totalP,
      stagesSnapshot: rawStages
          .map((s) => ApiOrderStageSnapshot.fromJson(s as Map<String, dynamic>))
          .toList(),
      parts: partsList,
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final String customerCity;
  final String dueDate;
  final DateTime? createdAt;
  final int totalPieces;
  final List<ApiOrderStageSnapshot> stagesSnapshot;
  final List<ApiOrderPart> parts;

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'status': status,
    'customer': {'name': customerName, 'city': customerCity},
    'dueDate': dueDate,
    'totalPieces': totalPieces,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'stagesSnapshot': stagesSnapshot.map((s) => s.toJson()).toList(),
    'parts': parts.map((p) => p.toJson()).toList(),
  };
}

class ApiOrderPart {
  const ApiOrderPart({
    required this.id,
    required this.designNumber,
    this.designName = '',
    this.quantity = 0,
    this.grossWeight = 0.0,
    this.currentStageId = '',
    this.currentStage = '',
    this.status = 'ASSIGNED',
    this.isBlocked = false,
    this.blockReason,
    this.priceLockedAt,
    this.assignments = const [],
  });

  bool get isPriceLocked => priceLockedAt != null;

  factory ApiOrderPart.fromJson(Map<String, dynamic> json) {
    String stgName = '';
    String stgId = json['currentStageId']?.toString() ?? '';
    if (json['currentStage'] is Map) {
      stgName = json['currentStage']['name'] as String? ?? '';
      if (stgId.isEmpty) {
        stgId = json['currentStage']['id']?.toString() ?? '';
      }
    } else if (json['currentStage'] is String) {
      stgName = json['currentStage'] as String;
    }

    String dNum = json['designNumber'] as String? ?? '';
    String dName = '';

    if (json['design'] is Map) {
      final d = json['design'] as Map;
      dName = d['title'] as String? ?? d['name'] as String? ?? '';
      if (dNum.isEmpty) {
        dNum = d['designNumber'] as String? ?? d['code'] as String? ?? '';
      }
    } else if (json['threeDDesign'] is Map) {
      final t = json['threeDDesign'] as Map;
      dName = t['title'] as String? ?? t['name'] as String? ?? '';
      if (dNum.isEmpty) {
        dNum = t['designNumber'] as String? ?? t['code'] as String? ?? '';
      }
    } else if (json['sketch'] is Map) {
      final s = json['sketch'] as Map;
      dName = s['title'] as String? ?? s['name'] as String? ?? '';
      if (dNum.isEmpty) {
        dNum = s['designNumber'] as String? ?? '';
      }
    }

    if (dName.isEmpty) {
      dName =
          json['designName'] as String? ??
          json['designTitle'] as String? ??
          json['productTitle'] as String? ??
          json['title'] as String? ??
          json['name'] as String? ??
          '';
    }

    final rawAssignments = json['assignments'] as List? ?? [];
    DateTime? priceLockedTime;
    if (json['priceLockedAt'] != null) {
      priceLockedTime = DateTime.tryParse(json['priceLockedAt'].toString());
    }

    return ApiOrderPart(
      id: json['id'] as String? ?? '',
      designNumber: dNum,
      designName: dName,
      quantity: json['quantity'] as int? ?? 0,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0.0,
      currentStageId: stgId,
      currentStage: stgName,
      status: json['status'] as String? ?? 'ASSIGNED',
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockReason: json['blockReason'] as String?,
      priceLockedAt: priceLockedTime,
      assignments: rawAssignments
          .map((a) => ApiPartAssignment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String designNumber;
  final String designName;
  final int quantity;
  final double grossWeight;
  final String currentStageId;
  final String currentStage;
  final String status;
  final bool isBlocked;
  final String? blockReason;
  final DateTime? priceLockedAt;
  final List<ApiPartAssignment> assignments;

  Map<String, dynamic> toJson() => {
    'id': id,
    'designNumber': designNumber,
    'designName': designName,
    'quantity': quantity,
    'grossWeight': grossWeight,
    'currentStageId': currentStageId,
    'currentStage': currentStage,
    'status': status,
    'isBlocked': isBlocked,
    if (blockReason != null) 'blockReason': blockReason,
    if (priceLockedAt != null)
      'priceLockedAt': priceLockedAt!.toIso8601String(),
    'assignments': assignments.map((a) => a.toJson()).toList(),
  };
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
    final orderMap = json['order'] is Map
        ? Map<String, dynamic>.from(json['order'])
        : null;
    final sketchMap = json['sketch'] is Map
        ? Map<String, dynamic>.from(json['sketch'])
        : null;
    final cadMap = json['threeDDesign'] is Map
        ? Map<String, dynamic>.from(json['threeDDesign'])
        : null;

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
      orderNumber:
          orderMap?['orderNumber']?.toString() ??
          json['orderNumber']?.toString() ??
          '',
      sketchUrl:
          sketchMap?['imageUrl']?.toString() ??
          sketchMap?['url']?.toString() ??
          '',
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
    this.splitQuantity,
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
  final int? splitQuantity;

  int? get effectiveSplitQuantity {
    if (splitQuantity != null && splitQuantity! > 0) return splitQuantity;
    final reg = RegExp(r'\[splitQty:\s*(\d+)\]', caseSensitive: false);
    final match = reg.firstMatch(instructions);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  int get assignedPieces => effectiveSplitQuantity ?? quantity;

  String get cleanInstructions {
    return instructions
        .replaceAll(RegExp(r'\[splitQty:\s*\d+\]\s*', caseSensitive: false), '')
        .trim();
  }

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
    final stageMap = json['stage'] is Map
        ? Map<String, dynamic>.from(json['stage'])
        : null;
    final partMap = json['orderPart'] is Map
        ? Map<String, dynamic>.from(json['orderPart'])
        : null;
    final managerMap = json['assignedByManager'] is Map
        ? Map<String, dynamic>.from(json['assignedByManager'])
        : null;

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
    final latestIss = json['latestIssuance'] is Map
        ? Map<String, dynamic>.from(json['latestIssuance'])
        : null;
    final itemsList =
        (json['itemsIssued'] as List?)
            ?.map(
              (e) =>
                  e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
            )
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

    final rawInstr = json['instructions']?.toString() ?? '';
    int? sQty = (json['splitQuantity'] as num?)?.toInt();
    if (sQty == null && rawInstr.isNotEmpty) {
      final reg = RegExp(r'\[splitQty:\s*(\d+)\]', caseSensitive: false);
      final match = reg.firstMatch(rawInstr);
      if (match != null) {
        sQty = int.tryParse(match.group(1)!);
      }
    }

    return ApiWorkerTask(
      id: json['id']?.toString() ?? '',
      orderPartId: json['orderPartId']?.toString() ?? '',
      stageId: json['stageId']?.toString() ?? '',
      assignedEmployeeId: json['assignedEmployeeId']?.toString() ?? '',
      assignedByManagerId: json['assignedByManagerId']?.toString() ?? '',
      instructions: rawInstr,
      status: json['status']?.toString() ?? 'ASSIGNED',
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      failureReason:
          json['failureReason']?.toString() ?? json['reason']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      isStockIssued: isIssued,
      issuanceStatus: issStatus,
      totalWeightIssued: (json['totalWeightIssued'] as num?)?.toDouble() ?? 0.0,
      totalPcsIssued: (json['totalPcsIssued'] as num?)?.toInt() ?? 0,
      itemsIssued: itemsList,
      latestIssuance: latestIss,
      stage: stageMap != null
          ? ApiWorkerTaskStage.fromJson(stageMap)
          : ApiWorkerTaskStage(id: '', name: sName),
      orderPart: parsedOrderPart,
      assignedByManagerName: mgrName,
      splitQuantity: sQty,
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

  Map<String, dynamic> toJson() => {
    'shape': shape,
    'dimensions': dimensions,
    'count': count,
    'weightTw': weightTw,
    'color': color,
  };
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
    this.orderPartStatus = '',
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
  final String orderPartStatus;
  final int quantity;
  final double goldWeightGrams;
  final double gemWeightTw;
  final String sizeDimensions;
  final List<String> stones;
  final List<StoneSpec> stoneSpecs;
  final String status; // 'PENDING_ISSUE', 'ISSUED'
  final String timestamp;

  bool get isDispatchedOrCompleted {
    final s = stageName.trim().toLowerCase();
    final st = orderPartStatus.trim().toLowerCase();
    return s.contains('dispatch') ||
        s.contains('completed') ||
        s.contains('delivered') ||
        st.contains('dispatch') ||
        st.contains('completed') ||
        st.contains('delivered');
  }

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
    final rawCount =
        json['count'] ?? json['quantity'] ?? json['qty'] ?? json['pieces'];
    return ApiGemBreakdownItem(
      shape:
          (json['shape'] ?? json['stone_shape'] ?? json['name'] ?? '')
              as String? ??
          '',
      dimensions:
          (json['dimensions'] ?? json['size'] ?? json['dim'] ?? '')
              as String? ??
          '',
      color: (json['color'] ?? json['clr'] ?? '') as String? ?? '',
      count: (rawCount is num)
          ? rawCount.toInt()
          : (int.tryParse(rawCount?.toString() ?? '') ?? 0),
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
    this.quantity,
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

  /// Jewellery pieces in this requisition, never gemstone count.
  final int? quantity;

  static int? _batchQuantity(Map<String, dynamic> json) {
    int? positiveInteger(Object? value) {
      final number = num.tryParse(value?.toString() ?? '');
      return number != null &&
              number.isFinite &&
              number > 0 &&
              number == number.roundToDouble()
          ? number.toInt()
          : null;
    }

    if (json['splitQuantity'] != null) {
      return positiveInteger(json['splitQuantity']);
    }
    final part = json['orderPart'] is Map ? json['orderPart'] as Map : const {};
    final assignmentId = json['partAssignmentId'] as String? ?? '';
    final assignments = (part['assignments'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final embedded = json['partAssignment'];
    final assignment =
        embedded is Map &&
            (assignmentId.isEmpty || embedded['id'] == assignmentId)
        ? embedded
        : assignments
              .where((a) => assignmentId.isNotEmpty && a['id'] == assignmentId)
              .firstOrNull;
    if (assignment != null) {
      final split = assignment['splitQuantity'] ?? assignment['splitQty'];
      if (split != null) return positiveInteger(split);
      final match = RegExp(
        r'\[splitQty:\s*(\d+)\]',
        caseSensitive: false,
      ).firstMatch(assignment['instructions'] as String? ?? '');
      if (match != null) return positiveInteger(match.group(1));
    }
    if (json['quantity'] != null) return positiveInteger(json['quantity']);
    // A parent count is safe only when it is not shared across worker batches.
    final active = assignments
        .where(
          (a) => const {
            'ASSIGNED',
            'IN_PROGRESS',
            'ACTIVE',
            'PAUSED',
            '',
          }.contains((a['status'] as String? ?? '').toUpperCase()),
        )
        .toList();
    if (active.length > 1 ||
        (assignmentId.isNotEmpty &&
            assignments.isNotEmpty &&
            assignment == null)) {
      return null;
    }
    return positiveInteger(part['quantity']);
  }

  factory ApiPendingIssuance.fromJson(Map<String, dynamic> json) {
    final craftsmanMap = json['assignedCraftsman'] as Map<String, dynamic>?;
    final specsMap = json['cadSpecs'] as Map<String, dynamic>?;
    final issuanceMap = json['issuance'] as Map<String, dynamic>?;
    return ApiPendingIssuance(
      orderPartId: json['orderPartId'] as String? ?? '',
      quantity: _batchQuantity(json),
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

/// A server-authoritative page from GET /orders.
class ApiOrdersPage {
  const ApiOrdersPage({
    required this.orders,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
  final List<ApiOrder> orders;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  factory ApiOrdersPage.fromJson(
    Map<String, dynamic> json, {
    int fallbackPage = 1,
    int fallbackLimit = 50,
  }) {
    if (json['success'] == false) {
      final message = json['message']?.toString();
      throw FormatException(
        message != null && message.isNotEmpty
            ? message
            : 'Invalid order search response.',
      );
    }

    final rawData = json['data'];
    List<dynamic> dataList;
    if (rawData is List) {
      dataList = rawData;
    } else if (rawData is Map && rawData['orders'] is List) {
      dataList = rawData['orders'] as List;
    } else if (rawData is Map && rawData['data'] is List) {
      dataList = rawData['data'] as List;
    } else if (json['orders'] is List) {
      dataList = json['orders'] as List;
    } else {
      throw const FormatException('Invalid order search response.');
    }

    final orders = <ApiOrder>[];
    for (final row in dataList) {
      if (row is Map) {
        orders.add(ApiOrder.fromJson(Map<String, dynamic>.from(row)));
      }
    }

    final pagination = json['pagination'];
    int page = fallbackPage;
    int limit = fallbackLimit;
    int total = orders.length;
    int totalPages = 1;

    if (pagination is Map) {
      final pMap = Map<String, dynamic>.from(pagination);
      page = (pMap['page'] as num?)?.toInt() ??
          int.tryParse(pMap['page']?.toString() ?? '') ??
          fallbackPage;
      limit = (pMap['limit'] as num?)?.toInt() ??
          int.tryParse(pMap['limit']?.toString() ?? '') ??
          fallbackLimit;
      total = (pMap['total'] as num?)?.toInt() ??
          (pMap['totalCount'] as num?)?.toInt() ??
          int.tryParse(pMap['total']?.toString() ?? '') ??
          int.tryParse(pMap['totalCount']?.toString() ?? '') ??
          orders.length;
      totalPages = (pMap['totalPages'] as num?)?.toInt() ??
          (pMap['pages'] as num?)?.toInt() ??
          int.tryParse(pMap['totalPages']?.toString() ?? '') ??
          int.tryParse(pMap['pages']?.toString() ?? '') ??
          (limit > 0 && total > 0
              ? (total / limit).ceil()
              : (orders.length >= limit ? page + 1 : page));
    } else {
      page = (json['page'] as num?)?.toInt() ??
          int.tryParse(json['page']?.toString() ?? '') ??
          fallbackPage;
      limit = (json['limit'] as num?)?.toInt() ??
          int.tryParse(json['limit']?.toString() ?? '') ??
          fallbackLimit;
      total = (json['total'] as num?)?.toInt() ??
          (json['totalCount'] as num?)?.toInt() ??
          orders.length;
      totalPages = (json['totalPages'] as num?)?.toInt() ??
          (json['pages'] as num?)?.toInt() ??
          (limit > 0 && total > 0
              ? (total / limit).ceil()
              : (orders.length >= limit ? page + 1 : page));
    }

    if (page < 1) page = 1;
    if (limit < 1) limit = 50;
    if (total < 0) total = orders.length;
    if (totalPages < 1) totalPages = 1;

    return ApiOrdersPage(
      orders: orders,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }
}
