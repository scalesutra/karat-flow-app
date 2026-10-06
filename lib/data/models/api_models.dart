library;

import 'package:flutter/material.dart';
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

    final rawUser = json['user'] is Map ? json['user'] as Map : null;
    final rawProfile = json['profile'] is Map ? json['profile'] as Map : null;

    bool isUuidString(String s) {
      final t = s.trim();
      return t.length >= 28 &&
          RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}').hasMatch(t);
    }

    String resolvedName = json['name']?.toString().trim() ?? '';
    if (resolvedName.isEmpty || isUuidString(resolvedName)) {
      final fromUser = rawUser?['name']?.toString().trim() ??
          rawUser?['fullName']?.toString().trim() ??
          rawUser?['displayName']?.toString().trim() ??
          '';
      if (fromUser.isNotEmpty && !isUuidString(fromUser)) {
        resolvedName = fromUser;
      }
    }
    if (resolvedName.isEmpty || isUuidString(resolvedName)) {
      final fromProfile = rawProfile?['name']?.toString().trim() ??
          rawProfile?['fullName']?.toString().trim() ??
          '';
      if (fromProfile.isNotEmpty && !isUuidString(fromProfile)) {
        resolvedName = fromProfile;
      }
    }
    if (resolvedName.isEmpty || isUuidString(resolvedName)) {
      final fName = json['firstName']?.toString().trim() ??
          rawUser?['firstName']?.toString().trim() ??
          '';
      final lName = json['lastName']?.toString().trim() ??
          rawUser?['lastName']?.toString().trim() ??
          '';
      final combined = '$fName $lName'.trim();
      if (combined.isNotEmpty && !isUuidString(combined)) {
        resolvedName = combined;
      }
    }
    if (resolvedName.isEmpty || isUuidString(resolvedName)) {
      final uname = json['username']?.toString().trim() ??
          rawUser?['username']?.toString().trim() ??
          '';
      if (uname.isNotEmpty && !isUuidString(uname)) {
        resolvedName = uname;
      }
    }
    if (resolvedName.isEmpty || isUuidString(resolvedName)) {
      final email = json['email']?.toString().trim() ??
          rawUser?['email']?.toString().trim() ??
          '';
      if (email.contains('@')) {
        final emailPrefix = email.split('@').first.trim();
        if (emailPrefix.isNotEmpty && !isUuidString(emailPrefix)) {
          resolvedName = emailPrefix
              .replaceAll('.', ' ')
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ')
              .trim();
        }
      }
    }
    if (resolvedName.isEmpty || isUuidString(resolvedName)) {
      final specialty = json['specialty']?.toString().trim() ?? '';
      final role = json['role']?.toString().trim() ?? 'CRAFTSMAN';
      final roleLabel = specialty.isNotEmpty
          ? specialty
          : (role.replaceAll('_', ' ').toLowerCase().split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '));
      final idStr = (json['id']?.toString() ?? '').replaceAll('-', '');
      final shortTag = idStr.length >= 4 ? idStr.substring(0, 4).toUpperCase() : '01';
      resolvedName = '$roleLabel #$shortTag';
    }

    return ApiEmployee(
      id: json['id'] as String? ?? '',
      keycloakId: json['keycloakId'] as String? ?? '',
      name: resolvedName,
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
      page =
          (pMap['page'] as num?)?.toInt() ??
          int.tryParse(pMap['page']?.toString() ?? '') ??
          fallbackPage;
      limit =
          (pMap['limit'] as num?)?.toInt() ??
          int.tryParse(pMap['limit']?.toString() ?? '') ??
          fallbackLimit;
      total =
          (pMap['total'] as num?)?.toInt() ??
          (pMap['totalCount'] as num?)?.toInt() ??
          int.tryParse(pMap['total']?.toString() ?? '') ??
          int.tryParse(pMap['totalCount']?.toString() ?? '') ??
          orders.length;
      totalPages =
          (pMap['totalPages'] as num?)?.toInt() ??
          (pMap['pages'] as num?)?.toInt() ??
          int.tryParse(pMap['totalPages']?.toString() ?? '') ??
          int.tryParse(pMap['pages']?.toString() ?? '') ??
          (limit > 0 && total > 0
              ? (total / limit).ceil()
              : (orders.length >= limit ? page + 1 : page));
    } else {
      page =
          (json['page'] as num?)?.toInt() ??
          int.tryParse(json['page']?.toString() ?? '') ??
          fallbackPage;
      limit =
          (json['limit'] as num?)?.toInt() ??
          int.tryParse(json['limit']?.toString() ?? '') ??
          fallbackLimit;
      total =
          (json['total'] as num?)?.toInt() ??
          (json['totalCount'] as num?)?.toInt() ??
          orders.length;
      totalPages =
          (json['totalPages'] as num?)?.toInt() ??
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

// ── 16. Department Operations & Floor Logs DTOs ─────────────────────────────

class CastingSubmitPayload {
  const CastingSubmitPayload({
    required this.lotNumber,
    required this.craftsmanId,
    this.previousBalance = 0.0,
    this.freshMetalIssue = 0.0,
    required this.finishedCastingWeight,
    this.runnerReturnScrap = 0.0,
    this.notes = '',
  });

  final String lotNumber;
  final String craftsmanId;
  final double previousBalance;
  final double freshMetalIssue;
  final double finishedCastingWeight;
  final double runnerReturnScrap;
  final String notes;

  double get closingBalance =>
      (previousBalance + freshMetalIssue) -
      (finishedCastingWeight + runnerReturnScrap);

  Map<String, dynamic> toJson() => {
    'lotNumber': lotNumber.trim(),
    'craftsmanId': craftsmanId.trim(),
    'previousBalance': previousBalance,
    'freshMetalIssue': freshMetalIssue,
    'finishedCastingWeight': finishedCastingWeight,
    'runnerReturnScrap': runnerReturnScrap,
  };
}

class CastingLogResponse {
  const CastingLogResponse({
    required this.id,
    this.craftsmanId = '',
    this.lotNumber = '',
    this.previousBalance = 0.0,
    this.freshMetalIssue = 0.0,
    this.finishedCastingWeight = 0.0,
    this.runnerReturnScrap = 0.0,
    this.closingBalance = 0.0,
    this.notes = '',
    this.createdAt = '',
  });

  final String id;
  final String craftsmanId;
  final String lotNumber;
  final double previousBalance;
  final double freshMetalIssue;
  final double finishedCastingWeight;
  final double runnerReturnScrap;
  final double closingBalance;
  final String notes;
  final String createdAt;

  factory CastingLogResponse.fromJson(Map<String, dynamic> json) {
    final prev = (json['previousBalance'] as num?)?.toDouble() ?? 0.0;
    final fresh = (json['freshMetalIssue'] as num?)?.toDouble() ??
        (json['freshIssueWeight'] as num?)?.toDouble() ??
        0.0;
    final fin = (json['finishedCastingWeight'] as num?)?.toDouble() ??
        (json['finishedWeight'] as num?)?.toDouble() ??
        0.0;
    final scrap = (json['runnerReturnScrap'] as num?)?.toDouble() ??
        (json['runnerScrapWeight'] as num?)?.toDouble() ??
        0.0;
    final close = (json['closingBalance'] as num?)?.toDouble() ??
        ((prev + fresh) - (fin + scrap));

    return CastingLogResponse(
      id: json['id']?.toString() ?? '',
      craftsmanId: json['craftsmanId']?.toString() ?? '',
      lotNumber: json['lotNumber']?.toString() ??
          json['jobCode']?.toString() ??
          '',
      previousBalance: prev,
      freshMetalIssue: fresh,
      finishedCastingWeight: fin,
      runnerReturnScrap: scrap,
      closingBalance: close,
      notes: json['notes']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class CastingLastBalanceResponse {
  const CastingLastBalanceResponse({
    required this.metalType,
    required this.lastClosingBalance,
    this.lastLotNumber = '',
  });

  final String metalType;
  final double lastClosingBalance;
  final String lastLotNumber;

  factory CastingLastBalanceResponse.fromJson(Map<String, dynamic> json) {
    return CastingLastBalanceResponse(
      metalType: json['metalType']?.toString() ?? 'Gold',
      lastClosingBalance:
          (json['previousBalance'] as num?)?.toDouble() ??
          (json['closingBalance'] as num?)?.toDouble() ??
          (json['lastClosingBalance'] as num?)?.toDouble() ??
          (json['balance'] as num?)?.toDouble() ??
          0.0,
      lastLotNumber: json['lastLotNumber']?.toString() ?? '',
    );
  }
}

class FilingSubmitPayload {
  const FilingSubmitPayload({
    required this.craftsmanId,
    this.jobCode,
    required this.issueWeight,
    required this.fineReceivedWeight,
    required this.runnerReturnWeight,
    required this.wastageDifference,
    this.notes = '',
  });

  final String craftsmanId;
  final String? jobCode;
  final double issueWeight;
  final double fineReceivedWeight;
  final double runnerReturnWeight;
  final double wastageDifference;
  final String notes;

  Map<String, dynamic> toJson() => {
    'craftsmanId': craftsmanId,
    if (jobCode != null && jobCode!.trim().isNotEmpty)
      'jobCode': jobCode!.trim(),
    'issueWeight': issueWeight,
    'fineReceived': fineReceivedWeight,
    'fineReceivedWeight': fineReceivedWeight,
    'runnerReturn': runnerReturnWeight,
    'runnerReturnWeight': runnerReturnWeight,
    'wastageDifference': wastageDifference,
    if (notes.isNotEmpty) 'notes': notes,
  };
}

class FilingLogResponse {
  const FilingLogResponse({
    required this.id,
    required this.craftsmanId,
    this.craftsmanName = '',
    this.jobCode,
    required this.issueWeight,
    required this.fineReceivedWeight,
    required this.runnerReturnWeight,
    required this.wastageDifference,
    this.notes = '',
    this.createdAt = '',
  });

  final String id;
  final String craftsmanId;
  final String craftsmanName;
  final String? jobCode;
  final double issueWeight;
  final double fineReceivedWeight;
  final double runnerReturnWeight;
  final double wastageDifference;
  final String notes;
  final String createdAt;

  factory FilingLogResponse.fromJson(Map<String, dynamic> json) {
    final craftsmanMap = json['craftsman'] as Map<String, dynamic>?;
    return FilingLogResponse(
      id: json['id']?.toString() ?? '',
      craftsmanId: json['craftsmanId']?.toString() ?? '',
      craftsmanName:
          craftsmanMap?['name']?.toString() ??
          json['craftsmanName']?.toString() ??
          '',
      jobCode: json['jobCode']?.toString(),
      issueWeight: (json['issueWeight'] as num?)?.toDouble() ?? 0.0,
      fineReceivedWeight:
          (json['fineReceived'] as num?)?.toDouble() ??
          (json['fineReceivedWeight'] as num?)?.toDouble() ??
          0.0,
      runnerReturnWeight:
          (json['runnerReturn'] as num?)?.toDouble() ??
          (json['runnerReturnWeight'] as num?)?.toDouble() ??
          0.0,
      wastageDifference: (json['wastageDifference'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PolishingSubmitPayload {
  const PolishingSubmitPayload({
    required this.craftsmanId,
    this.jobCode,
    required this.directPcs,
    required this.indirectPcs,
    required this.filingPcs,
    required this.beltPcs,
    required this.totalPcs,
    this.notes = '',
  });

  final String craftsmanId;
  final String? jobCode;
  final int directPcs;
  final int indirectPcs;
  final int filingPcs;
  final int beltPcs;
  final int totalPcs;
  final String notes;

  Map<String, dynamic> toJson() => {
    'craftsmanId': craftsmanId,
    if (jobCode != null && jobCode!.trim().isNotEmpty)
      'jobCode': jobCode!.trim(),
    'directPcs': directPcs,
    'indirectPcs': indirectPcs,
    'filingPcs': filingPcs,
    'beltPcs': beltPcs,
    'totalPcs': totalPcs,
    if (notes.isNotEmpty) 'notes': notes,
  };
}

class PolishingLogResponse {
  const PolishingLogResponse({
    required this.id,
    required this.craftsmanId,
    this.craftsmanName = '',
    this.jobCode,
    required this.directPcs,
    required this.indirectPcs,
    required this.filingPcs,
    required this.beltPcs,
    required this.totalPcs,
    this.notes = '',
    this.createdAt = '',
  });

  final String id;
  final String craftsmanId;
  final String craftsmanName;
  final String? jobCode;
  final int directPcs;
  final int indirectPcs;
  final int filingPcs;
  final int beltPcs;
  final int totalPcs;
  final String notes;
  final String createdAt;

  factory PolishingLogResponse.fromJson(Map<String, dynamic> json) {
    final craftsmanMap = json['craftsman'] as Map<String, dynamic>?;
    return PolishingLogResponse(
      id: json['id']?.toString() ?? '',
      craftsmanId: json['craftsmanId']?.toString() ?? '',
      craftsmanName:
          craftsmanMap?['name']?.toString() ??
          json['craftsmanName']?.toString() ??
          '',
      jobCode: json['jobCode']?.toString(),
      directPcs: (json['directPcs'] as num?)?.toInt() ?? 0,
      indirectPcs: (json['indirectPcs'] as num?)?.toInt() ?? 0,
      filingPcs: (json['filingPcs'] as num?)?.toInt() ?? 0,
      beltPcs: (json['beltPcs'] as num?)?.toInt() ?? 0,
      totalPcs: (json['totalPcs'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class HandSettingSubmitPayload {
  const HandSettingSubmitPayload({
    required this.craftsmanId,
    this.jobCode,
    required this.stoneType,
    required this.shape,
    required this.color,
    required this.size,
    required this.usedStonesCount,
    required this.brokenStonesCount,
    this.replacementRequested = false,
    this.notes = '',
  });

  final String craftsmanId;
  final String? jobCode;
  final String stoneType;
  final String shape;
  final String color;
  final String size;
  final int usedStonesCount;
  final int brokenStonesCount;
  final bool replacementRequested;
  final String notes;

  Map<String, dynamic> toJson() {
    final usedItem = {
      'size': size,
      'color': color,
      'stoneType': stoneType,
      'shape': shape,
      'usedQty': usedStonesCount,
      'quantity': usedStonesCount,
      'count': usedStonesCount,
      'pieces': usedStonesCount,
      'stonesCount': usedStonesCount,
      'used': usedStonesCount,
    };
    final brokenItem = {
      'size': size,
      'color': color,
      'stoneType': stoneType,
      'shape': shape,
      'brokenQty': brokenStonesCount,
      'quantity': brokenStonesCount,
      'count': brokenStonesCount,
      'pieces': brokenStonesCount,
      'brokenCount': brokenStonesCount,
      'broken': brokenStonesCount,
      'reason': notes.isNotEmpty ? notes : 'Workshop floor breakage',
    };

    return {
      'craftsmanId': craftsmanId,
      if (jobCode != null && jobCode!.trim().isNotEmpty)
        'jobCode': jobCode!.trim(),
      'stoneType': stoneType,
      'shape': shape,
      'color': color,
      'size': size,
      // Array structures expected by backend
      'openStonesUsed': usedStonesCount > 0 ? [usedItem] : [],
      'crashedStones': brokenStonesCount > 0 ? [brokenItem] : [],
      // Flat fields for backwards/alternative backend compatibility
      'openStonesUsedCount': usedStonesCount,
      'crashedStonesCount': brokenStonesCount,
      'usedStonesCount': usedStonesCount,
      'openStonesCount': usedStonesCount,
      'stonesSet': usedStonesCount,
      'usedStones': usedStonesCount,
      'openStones': usedStonesCount,
      'stonesCount': usedStonesCount,
      'pieces': usedStonesCount,
      'count': usedStonesCount,
      'quantity': usedStonesCount,
      'brokenStonesCount': brokenStonesCount,
      'brokenStones': brokenStonesCount,
      'stonesBroken': brokenStonesCount,
      'brokenCount': brokenStonesCount,
      'replacementRequested': replacementRequested,
      if (notes.isNotEmpty) 'notes': notes,
    };
  }
}

class HandSettingLogResponse {
  const HandSettingLogResponse({
    required this.id,
    required this.craftsmanId,
    this.craftsmanName = '',
    this.craftsmanPhone = '',
    this.recordedByName = '',
    this.jobCode,
    required this.stoneType,
    required this.shape,
    required this.color,
    required this.size,
    required this.usedStonesCount,
    required this.brokenStonesCount,
    this.replacementRequested = false,
    this.notes = '',
    this.createdAt = '',
    this.openStonesUsed = const [],
    this.crashedStones = const [],
  });

  final String id;
  final String craftsmanId;
  final String craftsmanName;
  final String craftsmanPhone;
  final String recordedByName;
  final String? jobCode;
  final String stoneType;
  final String shape;
  final String color;
  final String size;
  final int usedStonesCount;
  final int brokenStonesCount;
  final bool replacementRequested;
  final String notes;
  final String createdAt;
  final List<dynamic> openStonesUsed;
  final List<dynamic> crashedStones;

  String get displayWorkerName {
    if (craftsmanName.trim().isNotEmpty && craftsmanName.length < 28) {
      return craftsmanName.trim();
    }
    final short = craftsmanId.replaceAll('-', '');
    final tag = short.length >= 4 ? short.substring(0, 4).toUpperCase() : 'SETTER';
    return 'Setter #$tag';
  }

  factory HandSettingLogResponse.fromJson(Map<String, dynamic> json) {
    final craftsmanMap = json['craftsman'] as Map<String, dynamic>?;
    final recordedByMap = json['recordedBy'] as Map<String, dynamic>?;

    final openList = (json['openStonesUsed'] as List?) ??
        (json['openStones'] as List?) ??
        (json['stonesUsed'] as List?);
    final crashedList = (json['crashedStones'] as List?) ??
        (json['brokenStones'] as List?);

    int calculatedUsed = (json['usedStonesCount'] as num?)?.toInt() ??
        (json['openStonesUsedCount'] as num?)?.toInt() ??
        (json['openStonesCount'] as num?)?.toInt() ??
        (json['stonesSet'] as num?)?.toInt() ??
        (json['usedStones'] as num?)?.toInt() ??
        (json['openStones'] as num?)?.toInt() ??
        (json['stonesCount'] as num?)?.toInt() ??
        (json['pieces'] as num?)?.toInt() ??
        (json['count'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        0;

    if (calculatedUsed == 0 && openList != null && openList.isNotEmpty) {
      for (final item in openList) {
        if (item is Map) {
          final c = (item['usedQty'] as num?)?.toInt() ??
              (item['quantity'] as num?)?.toInt() ??
              (item['count'] as num?)?.toInt() ??
              (item['pieces'] as num?)?.toInt() ??
              (item['used'] as num?)?.toInt() ??
              (item['stonesCount'] as num?)?.toInt() ??
              0;
          calculatedUsed += c;
        } else if (item is num) {
          calculatedUsed += item.toInt();
        }
      }
      if (calculatedUsed == 0) calculatedUsed = openList.length;
    }

    int calculatedBroken = (json['brokenStonesCount'] as num?)?.toInt() ??
        (json['crashedStonesCount'] as num?)?.toInt() ??
        (json['brokenStones'] as num?)?.toInt() ??
        (json['stonesBroken'] as num?)?.toInt() ??
        (json['brokenCount'] as num?)?.toInt() ??
        (json['broken'] as num?)?.toInt() ??
        0;

    if (calculatedBroken == 0 && crashedList != null && crashedList.isNotEmpty) {
      for (final item in crashedList) {
        if (item is Map) {
          final c = (item['brokenQty'] as num?)?.toInt() ??
              (item['quantity'] as num?)?.toInt() ??
              (item['count'] as num?)?.toInt() ??
              (item['pieces'] as num?)?.toInt() ??
              (item['broken'] as num?)?.toInt() ??
              (item['brokenCount'] as num?)?.toInt() ??
              0;
          calculatedBroken += c;
        } else if (item is num) {
          calculatedBroken += item.toInt();
        }
      }
      if (calculatedBroken == 0) calculatedBroken = crashedList.length;
    }

    Map? firstStoneMap;
    if (openList != null && openList.isNotEmpty && openList.first is Map) {
      firstStoneMap = openList.first as Map;
    } else if (crashedList != null && crashedList.isNotEmpty && crashedList.first is Map) {
      firstStoneMap = crashedList.first as Map;
    }

    final sType = json['stoneType']?.toString() ??
        firstStoneMap?['stoneType']?.toString() ??
        firstStoneMap?['type']?.toString() ??
        '';
    final sShape = json['shape']?.toString() ??
        firstStoneMap?['shape']?.toString() ??
        (sType.isNotEmpty ? sType : '');
    final sColor = json['color']?.toString() ??
        firstStoneMap?['color']?.toString() ??
        '';
    final sSize = json['size']?.toString() ??
        firstStoneMap?['size']?.toString() ??
        '';

    final rawCraftsmanName = craftsmanMap?['name']?.toString() ??
        json['craftsmanName']?.toString() ??
        '';

    return HandSettingLogResponse(
      id: json['id']?.toString() ?? '',
      craftsmanId: json['craftsmanId']?.toString() ?? '',
      craftsmanName: rawCraftsmanName,
      craftsmanPhone: craftsmanMap?['phone']?.toString() ?? '',
      recordedByName: recordedByMap?['name']?.toString() ??
          json['recordedByName']?.toString() ??
          '',
      jobCode: json['jobCode']?.toString(),
      stoneType: sType,
      shape: sShape,
      color: sColor,
      size: sSize,
      usedStonesCount: calculatedUsed,
      brokenStonesCount: calculatedBroken,
      replacementRequested: json['replacementRequested'] as bool? ?? false,
      notes: json['notes']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      openStonesUsed: openList != null ? List<dynamic>.from(openList) : const [],
      crashedStones: crashedList != null ? List<dynamic>.from(crashedList) : const [],
    );
  }
}

// ── 17. Physical Stone Inventory Models (Strictly Zero Currency) ─────────────

class StoneInwardPayload {
  const StoneInwardPayload({
    required this.stoneType,
    required this.shape,
    required this.color,
    required this.size,
    required this.quantity,
    this.lotNumber,
    this.supplierRef,
    this.notes = '',
  });

  final String stoneType;
  final String shape;
  final String color;
  final String size;
  final int quantity;
  final String? lotNumber;
  final String? supplierRef;
  final String notes;

  Map<String, dynamic> toJson() => {
    'stoneType': stoneType,
    'shape': shape,
    'color': color,
    'size': size,
    'quantity': quantity,
    if (lotNumber != null && lotNumber!.isNotEmpty) 'lotNumber': lotNumber,
    if (supplierRef != null && supplierRef!.isNotEmpty)
      'supplierRef': supplierRef,
    if (notes.isNotEmpty) 'notes': notes,
  };
}

class StoneDeductPayload {
  const StoneDeductPayload({
    required this.stoneType,
    required this.shape,
    required this.color,
    required this.size,
    required this.quantity,
    required this.reason,
    this.notes = '',
  });

  final String stoneType;
  final String shape;
  final String color;
  final String size;
  final int quantity;
  final String reason;
  final String notes;

  Map<String, dynamic> toJson() => {
    'stoneType': stoneType,
    'shape': shape,
    'color': color,
    'size': size,
    'quantity': quantity,
    'reason': reason,
    if (notes.isNotEmpty) 'notes': notes,
  };
}

class StoneBreakdownItem {
  const StoneBreakdownItem({
    required this.size,
    required this.color,
    required this.stoneType,
    required this.quantity,
  });

  final String size;
  final String color;
  final String stoneType;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'size': size,
    'color': color,
    'stoneType': stoneType,
    'quantity': quantity,
  };

  factory StoneBreakdownItem.fromJson(Map<String, dynamic> json) {
    return StoneBreakdownItem(
      size: json['size']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      stoneType: json['stoneType']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class StoneMatrixItem {
  const StoneMatrixItem({
    required this.size,
    required this.color,
    this.stoneType = 'Round',
    required this.quantity,
    this.availableQuantity,
    this.reservedQuantity,
  });

  final String size;
  final String color;
  final String stoneType;
  final int quantity;
  final int? availableQuantity;
  final int? reservedQuantity;

  factory StoneMatrixItem.fromJson(Map<String, dynamic> json) {
    return StoneMatrixItem(
      size: json['size']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      stoneType: json['stoneType']?.toString() ?? 'Round',
      quantity:
          (json['quantity'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          (json['total'] as num?)?.toInt() ??
          0,
      availableQuantity:
          (json['availableQuantity'] as num?)?.toInt() ??
          (json['available'] as num?)?.toInt(),
      reservedQuantity:
          (json['reservedQuantity'] as num?)?.toInt() ??
          (json['reserved'] as num?)?.toInt(),
    );
  }
}

class StoneMatrixResponse {
  const StoneMatrixResponse({
    this.sizes = const [],
    this.colors = const [],
    this.items = const [],
    this.grid = const {},
  });

  final List<String> sizes;
  final List<String> colors;
  final List<StoneMatrixItem> items;
  final Map<String, Map<String, int>> grid;

  factory StoneMatrixResponse.fromJson(dynamic json) {
    final items = <StoneMatrixItem>[];
    final sizeSet = <String>{};
    final colorSet = <String>{};
    final grid = <String, Map<String, int>>{};

    if (json is List) {
      for (final raw in json) {
        if (raw is Map) {
          final item = StoneMatrixItem.fromJson(Map<String, dynamic>.from(raw));
          items.add(item);
          if (item.size.isNotEmpty) sizeSet.add(item.size);
          if (item.color.isNotEmpty) colorSet.add(item.color);

          grid.putIfAbsent(item.size, () => {})[item.color] = item.quantity;
        }
      }
    } else if (json is Map) {
      if (json['items'] is List) {
        for (final raw in json['items'] as List) {
          if (raw is Map) {
            final item = StoneMatrixItem.fromJson(
              Map<String, dynamic>.from(raw),
            );
            items.add(item);
            if (item.size.isNotEmpty) sizeSet.add(item.size);
            if (item.color.isNotEmpty) colorSet.add(item.color);

            grid.putIfAbsent(item.size, () => {})[item.color] = item.quantity;
          }
        }
      }
      if (json['sizes'] is List) {
        for (final s in json['sizes'] as List) {
          if (s != null) sizeSet.add(s.toString());
        }
      }
      if (json['colors'] is List) {
        for (final c in json['colors'] as List) {
          if (c != null) colorSet.add(c.toString());
        }
      }
      if (json['matrix'] is Map || json['grid'] is Map) {
        final matrixMap = (json['matrix'] ?? json['grid']) as Map;
        for (final sizeKey in matrixMap.keys) {
          final sStr = sizeKey.toString();
          sizeSet.add(sStr);
          final inner = matrixMap[sizeKey];
          if (inner is Map) {
            for (final colorKey in inner.keys) {
              final cStr = colorKey.toString();
              colorSet.add(cStr);
              final qty = (inner[colorKey] as num?)?.toInt() ?? 0;
              grid.putIfAbsent(sStr, () => {})[cStr] = qty;
            }
          }
        }
      }
    }

    return StoneMatrixResponse(
      sizes: sizeSet.toList(),
      colors: colorSet.toList(),
      items: items,
      grid: grid,
    );
  }

  int getQuantity(String size, String color) {
    return grid[size]?[color] ?? 0;
  }
}

// ── 18. Craftsman Monthly Ledger Models (Physical Weights & Pieces ONLY) ───

class CraftsmanLedgerJobSheet {
  const CraftsmanLedgerJobSheet({
    required this.id,
    this.date = '',
    this.department = '',
    this.jobCode = '',
    this.orderNumber = '',
    this.partName = '',
    this.issueWeight = 0.0,
    this.fineWeight = 0.0,
    this.runnerReturnWeight = 0.0,
    this.wastageWeight = 0.0,
    this.directPcs = 0,
    this.indirectPcs = 0,
    this.filingPcs = 0,
    this.beltPcs = 0,
    this.pieces = 0,
    this.stoneType = '',
    this.stoneSize = '',
    this.stonesSet = 0,
    this.stonesBroken = 0,
    this.replacementRequested = false,
    this.notes = '',
    this.recordedByName = '',
  });

  final String id;
  final String date;
  final String department;
  final String jobCode;
  final String orderNumber;
  final String partName;
  final double issueWeight;
  final double fineWeight;
  final double runnerReturnWeight;
  final double wastageWeight;
  final int directPcs;
  final int indirectPcs;
  final int filingPcs;
  final int beltPcs;
  final int pieces;
  final String stoneType;
  final String stoneSize;
  final int stonesSet;
  final int stonesBroken;
  final bool replacementRequested;
  final String notes;
  final String recordedByName;

  factory CraftsmanLedgerJobSheet.fromJson(Map<String, dynamic> json) {
    final recBy = json['recordedBy'] is Map ? json['recordedBy'] as Map : null;
    final jCode =
        json['lotNumber']?.toString() ??
        json['jobCode']?.toString() ??
        json['orderNumber']?.toString() ??
        '';

    final d = (json['directPcs'] as num?)?.toInt() ?? 0;
    final i = (json['indirectPcs'] as num?)?.toInt() ?? 0;
    final f = (json['filingPcs'] as num?)?.toInt() ?? 0;
    final b = (json['beltPcs'] as num?)?.toInt() ?? 0;
    final totPcs =
        (json['totalPcs'] as num?)?.toInt() ??
        (json['pieces'] as num?)?.toInt() ??
        (d + i + f + b);

    return CraftsmanLedgerJobSheet(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? json['createdAt']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      jobCode: jCode,
      orderNumber: jCode,
      partName: json['partName']?.toString() ?? '',
      issueWeight:
          (json['issueWeight'] as num?)?.toDouble() ??
          (json['totalMetalIssue'] as num?)?.toDouble() ??
          (json['freshMetalIssue'] as num?)?.toDouble() ??
          0.0,
      fineWeight:
          (json['fineReceived'] as num?)?.toDouble() ??
          (json['fineWeight'] as num?)?.toDouble() ??
          (json['fineReceivedWeight'] as num?)?.toDouble() ??
          (json['finishedCastingWeight'] as num?)?.toDouble() ??
          (json['finishedWeight'] as num?)?.toDouble() ??
          0.0,
      runnerReturnWeight:
          (json['runnerReturn'] as num?)?.toDouble() ??
          (json['runnerReturnWeight'] as num?)?.toDouble() ??
          (json['runnerReturnScrap'] as num?)?.toDouble() ??
          (json['runnerScrapWeight'] as num?)?.toDouble() ??
          0.0,
      wastageWeight:
          (json['wastageDifference'] as num?)?.toDouble() ??
          (json['wastageWeight'] as num?)?.toDouble() ??
          (json['closingBalance'] as num?)?.toDouble() ??
          0.0,
      directPcs: d,
      indirectPcs: i,
      filingPcs: f,
      beltPcs: b,
      pieces: totPcs,
      stoneType:
          json['stoneType']?.toString() ??
          json['type']?.toString() ??
          json['stone']?.toString() ??
          json['stoneName']?.toString() ??
          '',
      stoneSize:
          json['size']?.toString() ?? json['stoneSize']?.toString() ?? '',
      stonesSet:
          (json['usedStonesCount'] as num?)?.toInt() ??
          (json['openStonesCount'] as num?)?.toInt() ??
          (json['stonesSet'] as num?)?.toInt() ??
          (json['usedStones'] as num?)?.toInt() ??
          (json['openStones'] as num?)?.toInt() ??
          (json['stonesCount'] as num?)?.toInt() ??
          (json['pieces'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      stonesBroken:
          (json['brokenStonesCount'] as num?)?.toInt() ??
          (json['brokenStones'] as num?)?.toInt() ??
          (json['stonesBroken'] as num?)?.toInt() ??
          (json['brokenCount'] as num?)?.toInt() ??
          (json['damagedCount'] as num?)?.toInt() ??
          (json['broken'] as num?)?.toInt() ??
          0,
      replacementRequested: json['replacementRequested'] as bool? ?? false,
      notes: json['notes']?.toString() ?? '',
      recordedByName: recBy?['name']?.toString() ?? '',
    );
  }
}

class CraftsmanDeptSummary {
  const CraftsmanDeptSummary({
    required this.department,
    this.totalJobs = 0,
    this.gramsHandled = 0.0,
    this.fineReceived = 0.0,
    this.runnerReturn = 0.0,
    this.wastageGrams = 0.0,
    this.directPcs = 0,
    this.indirectPcs = 0,
    this.filingPcs = 0,
    this.beltPcs = 0,
    this.pieces = 0,
    this.stonesHandled = 0,
    this.stonesBroken = 0,
    this.replacementRequests = 0,
  });

  final String department;
  final int totalJobs;
  final double gramsHandled;
  final double fineReceived;
  final double runnerReturn;
  final double wastageGrams;
  final int directPcs;
  final int indirectPcs;
  final int filingPcs;
  final int beltPcs;
  final int pieces;
  final int stonesHandled;
  final int stonesBroken;
  final int replacementRequests;

  factory CraftsmanDeptSummary.fromJson(Map<String, dynamic> json) {
    return CraftsmanDeptSummary(
      department: json['department']?.toString() ?? '',
      totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
      gramsHandled:
          (json['gramsHandled'] as num?)?.toDouble() ??
          (json['issueWeight'] as num?)?.toDouble() ??
          (json['totalIssueWeight'] as num?)?.toDouble() ??
          0.0,
      fineReceived:
          (json['fineReceived'] as num?)?.toDouble() ??
          (json['totalFineReceived'] as num?)?.toDouble() ??
          0.0,
      runnerReturn:
          (json['runnerReturn'] as num?)?.toDouble() ??
          (json['totalRunnerReturn'] as num?)?.toDouble() ??
          0.0,
      wastageGrams:
          (json['wastageGrams'] as num?)?.toDouble() ??
          (json['wastageDifference'] as num?)?.toDouble() ??
          (json['totalWastageDifference'] as num?)?.toDouble() ??
          0.0,
      directPcs:
          (json['directPcs'] as num?)?.toInt() ??
          (json['totalDirectPcs'] as num?)?.toInt() ??
          0,
      indirectPcs:
          (json['indirectPcs'] as num?)?.toInt() ??
          (json['totalIndirectPcs'] as num?)?.toInt() ??
          0,
      filingPcs:
          (json['filingPcs'] as num?)?.toInt() ??
          (json['totalFilingPcs'] as num?)?.toInt() ??
          0,
      beltPcs:
          (json['beltPcs'] as num?)?.toInt() ??
          (json['totalBeltPcs'] as num?)?.toInt() ??
          0,
      pieces:
          (json['pieces'] as num?)?.toInt() ??
          (json['totalPcsPolished'] as num?)?.toInt() ??
          (json['totalPcs'] as num?)?.toInt() ??
          0,
      stonesHandled:
          (json['stonesHandled'] as num?)?.toInt() ??
          (json['totalOpenStonesCount'] as num?)?.toInt() ??
          (json['usedStonesCount'] as num?)?.toInt() ??
          (json['totalUsedStones'] as num?)?.toInt() ??
          (json['totalStonesSet'] as num?)?.toInt() ??
          (json['openStonesCount'] as num?)?.toInt() ??
          (json['stonesSet'] as num?)?.toInt() ??
          0,
      stonesBroken:
          (json['stonesBroken'] as num?)?.toInt() ??
          (json['totalBrokenStonesCount'] as num?)?.toInt() ??
          (json['brokenStonesCount'] as num?)?.toInt() ??
          (json['totalStonesBroken'] as num?)?.toInt() ??
          (json['brokenStones'] as num?)?.toInt() ??
          0,
      replacementRequests:
          (json['replacementRequests'] as num?)?.toInt() ??
          (json['replacementRequestsCount'] as num?)?.toInt() ??
          0,
    );
  }
}

class CraftsmanMonthlyLedger {
  const CraftsmanMonthlyLedger({
    required this.craftsmanId,
    this.craftsmanName = '',
    required this.yearMonth,
    this.totalGramsHandled = 0.0,
    this.totalFineReceived = 0.0,
    this.totalRunnerScrap = 0.0,
    this.totalWastageGrams = 0.0,
    this.wastagePercentage = 0.0,
    this.totalPiecesDone = 0,
    this.totalStonesSet = 0,
    this.totalStonesBroken = 0,
    this.departmentSummaries = const [],
    this.jobSheets = const [],
  });

  final String craftsmanId;
  final String craftsmanName;
  final String yearMonth;
  final double totalGramsHandled;
  final double totalFineReceived;
  final double totalRunnerScrap;
  final double totalWastageGrams;
  final double wastagePercentage;
  final int totalPiecesDone;
  final int totalStonesSet;
  final int totalStonesBroken;
  final List<CraftsmanDeptSummary> departmentSummaries;
  final List<CraftsmanLedgerJobSheet> jobSheets;

  static int _parseSafeInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) {
      final d = double.tryParse(val.trim());
      if (d != null) return d.toInt();
    }
    if (val is List) {
      if (val.isEmpty) return 0;
      int sum = 0;
      for (final item in val) {
        if (item is num) {
          sum += item.toInt();
        } else if (item is Map) {
          final count = (item['quantity'] as num?)?.toInt() ??
              (item['count'] as num?)?.toInt() ??
              (item['pieces'] as num?)?.toInt() ??
              (item['used'] as num?)?.toInt() ??
              (item['broken'] as num?)?.toInt() ??
              (item['stonesCount'] as num?)?.toInt() ??
              (item['brokenCount'] as num?)?.toInt() ??
              0;
          sum += count;
        }
      }
      return sum > 0 ? sum : val.length;
    }
    return 0;
  }

  static int _extractFieldInt(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final v = _parseSafeInt(m[k]);
        if (v != 0) return v;
      }
    }
    // Check case-insensitive and snake-insensitive matching in m
    for (final k in keys) {
      final lowerK = k.toLowerCase().replaceAll('_', '');
      for (final entry in m.entries) {
        final entryKey = entry.key.toString().toLowerCase().replaceAll('_', '');
        if (entryKey == lowerK && entry.value != null) {
          final v = _parseSafeInt(entry.value);
          if (v != 0) return v;
        }
      }
    }
    // Check nested maps & lists: 'openStonesUsed', 'crashedStones', 'stone', 'details', 'metadata', 'stoneDetails', 'data'
    for (final sub in [
      'openStonesUsed',
      'crashedStones',
      'stone',
      'details',
      'metadata',
      'stoneDetails',
      'data',
    ]) {
      if (m[sub] is List && (m[sub] as List).isNotEmpty) {
        final v = _parseSafeInt(m[sub]);
        if (v != 0) return v;
      }
      if (m[sub] is Map) {
        final subMap = m[sub] as Map;
        for (final k in keys) {
          if (subMap.containsKey(k) && subMap[k] != null) {
            final v = _parseSafeInt(subMap[k]);
            if (v != 0) return v;
          }
        }
      }
    }
    return 0;
  }

  static String _extractFieldString(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final str = m[k].toString().trim();
        if (str.isNotEmpty && str.toLowerCase() != 'null') return str;
      }
    }
    for (final k in keys) {
      final lowerK = k.toLowerCase().replaceAll('_', '');
      for (final entry in m.entries) {
        final entryKey = entry.key.toString().toLowerCase().replaceAll('_', '');
        if (entryKey == lowerK && entry.value != null) {
          final str = entry.value.toString().trim();
          if (str.isNotEmpty && str.toLowerCase() != 'null') return str;
        }
      }
    }
    for (final sub in [
      'openStonesUsed',
      'crashedStones',
      'stone',
      'details',
      'metadata',
      'stoneDetails',
      'data',
    ]) {
      if (m[sub] is List && (m[sub] as List).isNotEmpty) {
        final first = (m[sub] as List).first;
        if (first is Map) {
          for (final k in keys) {
            if (first.containsKey(k) && first[k] != null) {
              final str = first[k].toString().trim();
              if (str.isNotEmpty && str.toLowerCase() != 'null') return str;
            }
          }
          final lowerKeys =
              keys.map((k) => k.toLowerCase().replaceAll('_', '')).toSet();
          for (final entry in first.entries) {
            final entryKey =
                entry.key.toString().toLowerCase().replaceAll('_', '');
            if (lowerKeys.contains(entryKey) && entry.value != null) {
              final str = entry.value.toString().trim();
              if (str.isNotEmpty && str.toLowerCase() != 'null') return str;
            }
          }
        }
      }
      if (m[sub] is Map) {
        final subMap = m[sub] as Map;
        for (final k in keys) {
          if (subMap.containsKey(k) && subMap[k] != null) {
            final str = subMap[k].toString().trim();
            if (str.isNotEmpty && str.toLowerCase() != 'null') return str;
          }
        }
      }
    }
    return '';
  }

  factory CraftsmanMonthlyLedger.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : (rawJson['data'] is Map
              ? Map<String, dynamic>.from(rawJson['data'])
              : rawJson);

    final craftsmanMap = json['craftsman'] is Map
        ? Map<String, dynamic>.from(json['craftsman'] as Map)
        : null;
    final craftsmanId =
        json['craftsmanId']?.toString() ??
        craftsmanMap?['id']?.toString() ??
        '';
    final craftsmanName =
        json['craftsmanName']?.toString() ??
        craftsmanMap?['name']?.toString() ??
        '';
    final yearMonth = json['yearMonth']?.toString() ?? '';

    // 1. Filing Section
    final filingMap = json['filing'] is Map
        ? Map<String, dynamic>.from(json['filing'] as Map)
        : null;
    final filingSummary = filingMap?['summary'] is Map
        ? Map<String, dynamic>.from(filingMap!['summary'] as Map)
        : null;
    final filingLogs = filingMap?['logs'] as List?;

    final filingJobs = (filingSummary?['totalJobs'] as num?)?.toInt() ?? 0;
    final filingIssue =
        (filingSummary?['totalIssueWeight'] as num?)?.toDouble() ?? 0.0;
    final filingFine =
        (filingSummary?['totalFineReceived'] as num?)?.toDouble() ?? 0.0;
    final filingRunner =
        (filingSummary?['totalRunnerReturn'] as num?)?.toDouble() ?? 0.0;
    final filingWastage =
        (filingSummary?['totalWastageDifference'] as num?)?.toDouble() ?? 0.0;

    // 2. Polishing Section
    final polishingMap = json['polishing'] is Map
        ? Map<String, dynamic>.from(json['polishing'] as Map)
        : null;
    final polishingSummary = polishingMap?['summary'] is Map
        ? Map<String, dynamic>.from(polishingMap!['summary'] as Map)
        : null;
    final polishingLogs = polishingMap?['logs'] as List?;

    final polishingJobs =
        (polishingSummary?['totalJobs'] as num?)?.toInt() ?? 0;
    final polishingDirect =
        (polishingSummary?['totalDirectPcs'] as num?)?.toInt() ?? 0;
    final polishingIndirect =
        (polishingSummary?['totalIndirectPcs'] as num?)?.toInt() ?? 0;
    final polishingFiling =
        (polishingSummary?['totalFilingPcs'] as num?)?.toInt() ?? 0;
    final polishingBelt =
        (polishingSummary?['totalBeltPcs'] as num?)?.toInt() ?? 0;
    final polishingTotalPcs =
        (polishingSummary?['totalPcsPolished'] as num?)?.toInt() ?? 0;

    // 3. Hand Setting Section
    final settingMap =
        (json['handSetting'] is Map
            ? Map<String, dynamic>.from(json['handSetting'] as Map)
            : null) ??
        (json['hand_setting'] is Map
            ? Map<String, dynamic>.from(json['hand_setting'] as Map)
            : null) ??
        (json['hand-setting'] is Map
            ? Map<String, dynamic>.from(json['hand-setting'] as Map)
            : null) ??
        (json['setting'] is Map
            ? Map<String, dynamic>.from(json['setting'] as Map)
            : null) ??
        (json['stoneSetting'] is Map
            ? Map<String, dynamic>.from(json['stoneSetting'] as Map)
            : null);
    final settingSummary = settingMap?['summary'] is Map
        ? Map<String, dynamic>.from(settingMap!['summary'] as Map)
        : null;
    final settingLogs =
        (settingMap?['logs'] as List?) ??
        (settingMap?['jobSheets'] as List?) ??
        (settingMap?['entries'] as List?) ??
        (json['handSettingLogs'] as List?) ??
        (json['hand_setting_logs'] as List?);

    final settingJobs = (settingSummary?['totalJobs'] as num?)?.toInt() ?? 0;
    final settingOpenStones =
        (settingSummary?['totalOpenStonesCount'] as num?)?.toInt() ??
        (settingSummary?['totalUsedStones'] as num?)?.toInt() ??
        (settingSummary?['totalStonesSet'] as num?)?.toInt() ??
        (settingSummary?['openStonesCount'] as num?)?.toInt() ??
        (settingSummary?['usedStonesCount'] as num?)?.toInt() ??
        (settingSummary?['totalStones'] as num?)?.toInt() ??
        0;
    final settingBrokenStones =
        (settingSummary?['totalBrokenStonesCount'] as num?)?.toInt() ??
        (settingSummary?['totalStonesBroken'] as num?)?.toInt() ??
        (settingSummary?['brokenStonesCount'] as num?)?.toInt() ??
        (settingSummary?['totalBrokenStones'] as num?)?.toInt() ??
        (settingSummary?['brokenStones'] as num?)?.toInt() ??
        0;
    final settingReplacements =
        (settingSummary?['replacementRequestsCount'] as num?)?.toInt() ??
        (settingSummary?['replacementRequests'] as num?)?.toInt() ??
        0;

    // Department summaries list (only show active departments)
    final summaries = <CraftsmanDeptSummary>[];
    if (filingJobs > 0 ||
        filingIssue > 0 ||
        (filingLogs != null && filingLogs.isNotEmpty)) {
      summaries.add(
        CraftsmanDeptSummary(
          department: 'Filing',
          totalJobs: filingJobs > 0 ? filingJobs : (filingLogs?.length ?? 0),
          gramsHandled: filingIssue,
          fineReceived: filingFine,
          runnerReturn: filingRunner,
          wastageGrams: filingWastage,
        ),
      );
    }
    if (polishingJobs > 0 ||
        polishingTotalPcs > 0 ||
        (polishingLogs != null && polishingLogs.isNotEmpty)) {
      summaries.add(
        CraftsmanDeptSummary(
          department: 'Polishing',
          totalJobs: polishingJobs > 0
              ? polishingJobs
              : (polishingLogs?.length ?? 0),
          directPcs: polishingDirect,
          indirectPcs: polishingIndirect,
          filingPcs: polishingFiling,
          beltPcs: polishingBelt,
          pieces: polishingTotalPcs,
        ),
      );
    }
    if (settingJobs > 0 ||
        settingOpenStones > 0 ||
        (settingLogs != null && settingLogs.isNotEmpty)) {
      summaries.add(
        CraftsmanDeptSummary(
          department: 'Hand Setting',
          totalJobs: settingJobs > 0 ? settingJobs : (settingLogs?.length ?? 0),
          stonesHandled: settingOpenStones,
          stonesBroken: settingBrokenStones,
          replacementRequests: settingReplacements,
        ),
      );
    }

    // 4. Casting Section
    final castingMap = (json['casting'] is Map
            ? Map<String, dynamic>.from(json['casting'] as Map)
            : null) ??
        (json['furnace'] is Map
            ? Map<String, dynamic>.from(json['furnace'] as Map)
            : null);
    final castingSummary = castingMap?['summary'] is Map
        ? Map<String, dynamic>.from(castingMap!['summary'] as Map)
        : null;
    final castingLogs = (castingMap?['logs'] as List?) ??
        (castingMap?['jobSheets'] as List?) ??
        (castingMap?['entries'] as List?) ??
        (json['castingLogs'] as List?) ??
        (json['casting_logs'] as List?);

    final castingJobs = (castingSummary?['totalJobs'] as num?)?.toInt() ??
        (castingSummary?['totalLots'] as num?)?.toInt() ??
        (castingLogs?.length ?? 0);
    final castingIssue = (castingSummary?['totalIssueWeight'] as num?)?.toDouble() ??
        (castingSummary?['totalMetalIssue'] as num?)?.toDouble() ??
        (castingSummary?['gramsHandled'] as num?)?.toDouble() ??
        (castingLogs != null
            ? castingLogs.fold<double>(0.0, (acc, item) {
                if (item is Map) {
                  return acc +
                      ((item['totalMetalIssue'] as num?)?.toDouble() ??
                          ((item['freshMetalIssue'] as num?)?.toDouble() ?? 0.0) +
                              ((item['previousBalance'] as num?)?.toDouble() ?? 0.0));
                }
                return acc;
              })
            : 0.0);
    final castingFin = (castingSummary?['totalFinishedWeight'] as num?)?.toDouble() ??
        (castingSummary?['totalFineReceived'] as num?)?.toDouble() ??
        (castingLogs != null
            ? castingLogs.fold<double>(0.0, (acc, item) {
                if (item is Map) {
                  return acc +
                      ((item['finishedCastingWeight'] as num?)?.toDouble() ??
                          (item['finishedWeight'] as num?)?.toDouble() ??
                          0.0);
                }
                return acc;
              })
            : 0.0);
    final castingRunner = (castingSummary?['totalRunnerScrap'] as num?)?.toDouble() ??
        (castingSummary?['totalRunnerReturn'] as num?)?.toDouble() ??
        (castingLogs != null
            ? castingLogs.fold<double>(0.0, (acc, item) {
                if (item is Map) {
                  return acc +
                      ((item['runnerReturnScrap'] as num?)?.toDouble() ??
                          (item['runnerScrapWeight'] as num?)?.toDouble() ??
                          0.0);
                }
                return acc;
              })
            : 0.0);
    final castingClosing = (castingSummary?['netClosingBalance'] as num?)?.toDouble() ??
        (castingSummary?['closingBalance'] as num?)?.toDouble() ??
        (castingSummary?['totalWastageDifference'] as num?)?.toDouble() ??
        (castingIssue - (castingFin + castingRunner));

    if (castingJobs > 0 ||
        castingIssue > 0 ||
        (castingLogs != null && castingLogs.isNotEmpty)) {
      summaries.add(
        CraftsmanDeptSummary(
          department: 'Casting',
          totalJobs: castingJobs > 0 ? castingJobs : (castingLogs?.length ?? 0),
          gramsHandled: castingIssue,
          fineReceived: castingFin,
          runnerReturn: castingRunner,
          wastageGrams: castingClosing,
        ),
      );
    }

    // If explicit departmentSummaries list was sent by backend
    if (summaries.isEmpty && json['departmentSummaries'] is List) {
      for (final s in json['departmentSummaries'] as List) {
        if (s is Map) {
          summaries.add(
            CraftsmanDeptSummary.fromJson(Map<String, dynamic>.from(s)),
          );
        }
      }
    }

    // Build Job Sheets from department logs
    final jobs = <CraftsmanLedgerJobSheet>[];

    // Casting logs
    if (castingLogs != null) {
      for (final raw in castingLogs) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final recBy = m['recordedBy'] is Map ? m['recordedBy'] as Map : null;
          final lot = m['lotNumber']?.toString() ??
              m['jobCode']?.toString() ??
              '';
          final issue = (m['totalMetalIssue'] as num?)?.toDouble() ??
              ((m['freshMetalIssue'] as num?)?.toDouble() ?? 0.0) +
                  ((m['previousBalance'] as num?)?.toDouble() ?? 0.0);
          final fin = (m['finishedCastingWeight'] as num?)?.toDouble() ??
              (m['finishedWeight'] as num?)?.toDouble() ??
              0.0;
          final runner = (m['runnerReturnScrap'] as num?)?.toDouble() ??
              (m['runnerScrapWeight'] as num?)?.toDouble() ??
              0.0;
          final closeBal = (m['closingBalance'] as num?)?.toDouble() ??
              (issue - (fin + runner));

          jobs.add(
            CraftsmanLedgerJobSheet(
              id: m['id']?.toString() ?? '',
              date: m['createdAt']?.toString() ?? '',
              department: 'Casting',
              jobCode: lot,
              orderNumber: lot,
              issueWeight: issue,
              fineWeight: fin,
              runnerReturnWeight: runner,
              wastageWeight: closeBal,
              notes: m['notes']?.toString() ?? '',
              recordedByName: recBy?['name']?.toString() ?? '',
            ),
          );
        }
      }
    }

    // Filing logs
    if (filingLogs != null) {
      for (final raw in filingLogs) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final recBy = m['recordedBy'] is Map ? m['recordedBy'] as Map : null;
          final jCode = m['jobCode']?.toString() ?? '';
          jobs.add(
            CraftsmanLedgerJobSheet(
              id: m['id']?.toString() ?? '',
              date: m['createdAt']?.toString() ?? '',
              department: 'Filing',
              jobCode: jCode,
              orderNumber: jCode,
              issueWeight: (m['issueWeight'] as num?)?.toDouble() ?? 0.0,
              fineWeight:
                  (m['fineReceived'] as num?)?.toDouble() ??
                  (m['fineReceivedWeight'] as num?)?.toDouble() ??
                  0.0,
              runnerReturnWeight:
                  (m['runnerReturn'] as num?)?.toDouble() ??
                  (m['runnerReturnWeight'] as num?)?.toDouble() ??
                  0.0,
              wastageWeight:
                  (m['wastageDifference'] as num?)?.toDouble() ??
                  (m['wastageWeight'] as num?)?.toDouble() ??
                  0.0,
              notes: m['notes']?.toString() ?? '',
              recordedByName: recBy?['name']?.toString() ?? '',
            ),
          );
        }
      }
    }

    // Polishing logs
    if (polishingLogs != null) {
      for (final raw in polishingLogs) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final recBy = m['recordedBy'] is Map ? m['recordedBy'] as Map : null;
          final jCode = m['jobCode']?.toString() ?? '';
          final d = (m['directPcs'] as num?)?.toInt() ?? 0;
          final i = (m['indirectPcs'] as num?)?.toInt() ?? 0;
          final f = (m['filingPcs'] as num?)?.toInt() ?? 0;
          final b = (m['beltPcs'] as num?)?.toInt() ?? 0;
          final tot = (m['totalPcs'] as num?)?.toInt() ?? (d + i + f + b);
          jobs.add(
            CraftsmanLedgerJobSheet(
              id: m['id']?.toString() ?? '',
              date: m['createdAt']?.toString() ?? '',
              department: 'Polishing',
              jobCode: jCode,
              orderNumber: jCode,
              directPcs: d,
              indirectPcs: i,
              filingPcs: f,
              beltPcs: b,
              pieces: tot,
              notes: m['notes']?.toString() ?? '',
              recordedByName: recBy?['name']?.toString() ?? '',
            ),
          );
        }
      }
    }

    // Hand Setting logs
    if (settingLogs != null) {
      for (final raw in settingLogs) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final recBy = m['recordedBy'] is Map ? m['recordedBy'] as Map : null;
          final jCode = _extractFieldString(m, [
            'jobCode',
            'job_code',
            'tag',
            'code',
            'job',
            'pouchRef',
            'pouch_ref',
          ]);
          final used = _extractFieldInt(m, [
            'openStonesUsed',
            'open_stones_used',
            'openStonesUsedCount',
            'open_stones_used_count',
            'usedStonesCount',
            'used_stones_count',
            'openStonesCount',
            'open_stones_count',
            'stonesSet',
            'stones_set',
            'usedStones',
            'used_stones',
            'openStones',
            'open_stones',
            'stonesCount',
            'stoneCount',
            'stones_count',
            'stone_count',
            'stonesUsed',
            'stones_used',
            'pieces',
            'count',
            'quantity',
            'qty',
            'used',
            'total',
            'stones',
          ]);
          final broken = _extractFieldInt(m, [
            'crashedStones',
            'crashed_stones',
            'crashedStonesCount',
            'crashed_stones_count',
            'brokenStonesCount',
            'broken_stones_count',
            'brokenStones',
            'broken_stones',
            'stonesBroken',
            'stones_broken',
            'brokenCount',
            'broken_count',
            'damagedCount',
            'damaged_count',
            'damagedStones',
            'damaged_stones',
            'broken',
            'damage',
            'damaged',
          ]);
          final repl =
              m['replacementRequested'] as bool? ??
              (m['replacement'] as bool?) ??
              false;
          final stoneType = _extractFieldString(m, [
            'stoneType',
            'stone_type',
            'type',
            'stone',
            'stoneName',
            'stone_name',
            'name',
            'gemType',
            'gem_type',
            'material',
          ]);
          final stoneSize = _extractFieldString(m, [
            'size',
            'stoneSize',
            'stone_size',
            'dimension',
            'dimensions',
            'mm',
          ]);
          final logId = _extractFieldString(m, ['id', '_id']);
          final logDate = _extractFieldString(m, [
            'createdAt',
            'created_at',
            'date',
            'updatedAt',
            'updated_at',
          ]);

          debugPrint(
            '💎 [HAND SETTING LOG PARSED]: id=$logId, tag=$jCode, used=$used, broken=$broken, type="$stoneType", size="$stoneSize" | rawKeys=${m.keys.toList()}',
          );

          jobs.add(
            CraftsmanLedgerJobSheet(
              id: logId,
              date: logDate,
              department: 'Hand Setting',
              jobCode: jCode,
              orderNumber: jCode,
              stoneType: stoneType,
              stoneSize: stoneSize,
              stonesSet: used,
              stonesBroken: broken,
              replacementRequested: repl,
              notes: m['notes']?.toString() ?? '',
              recordedByName: recBy?['name']?.toString() ?? '',
            ),
          );
        }
      }
    }

    // Legacy fallback
    if (jobs.isEmpty) {
      final rawJobs = json['jobSheets'] ?? json['logs'] ?? json['entries'];
      if (rawJobs is List) {
        for (final j in rawJobs) {
          if (j is Map) {
            jobs.add(
              CraftsmanLedgerJobSheet.fromJson(Map<String, dynamic>.from(j)),
            );
          }
        }
      }
    }

    // Sort logs descending by date
    jobs.sort((a, b) => b.date.compareTo(a.date));

    // Overall Totals
    final grams = (filingIssue + castingIssue) > 0
        ? (filingIssue + castingIssue)
        : ((json['totalGramsHandled'] as num?)?.toDouble() ??
              (json['totalGrams'] as num?)?.toDouble() ??
              0.0);
    final fine = (filingFine + castingFin) > 0
        ? (filingFine + castingFin)
        : ((json['totalFineReceived'] as num?)?.toDouble() ?? 0.0);
    final runner = (filingRunner + castingRunner) > 0
        ? (filingRunner + castingRunner)
        : ((json['totalRunnerScrap'] as num?)?.toDouble() ??
              (json['totalRunnerReturn'] as num?)?.toDouble() ??
              0.0);
    final wastage = (filingSummary != null || castingSummary != null)
        ? (filingWastage + castingClosing)
        : ((json['totalWastageGrams'] as num?)?.toDouble() ??
              (json['totalWastage'] as num?)?.toDouble() ??
              0.0);
    final calculatedPercent = grams > 0 ? (wastage / grams) * 100 : 0.0;

    final pieces = polishingTotalPcs > 0
        ? polishingTotalPcs
        : ((json['totalPiecesDone'] as num?)?.toInt() ??
              (json['totalPieces'] as num?)?.toInt() ??
              0);
    final stones = settingOpenStones > 0
        ? settingOpenStones
        : ((json['totalStonesSet'] as num?)?.toInt() ??
              (json['totalOpenStonesCount'] as num?)?.toInt() ??
              (json['totalUsedStones'] as num?)?.toInt() ??
              0);
    final stonesBroken = settingBrokenStones > 0
        ? settingBrokenStones
        : ((json['totalStonesBroken'] as num?)?.toInt() ??
              (json['totalBrokenStonesCount'] as num?)?.toInt() ??
              0);

    return CraftsmanMonthlyLedger(
      craftsmanId: craftsmanId,
      craftsmanName: craftsmanName,
      yearMonth: yearMonth,
      totalGramsHandled: grams,
      totalFineReceived: fine,
      totalRunnerScrap: runner,
      totalWastageGrams: wastage,
      wastagePercentage: calculatedPercent,
      totalPiecesDone: pieces,
      totalStonesSet: stones,
      totalStonesBroken: stonesBroken,
      departmentSummaries: summaries,
      jobSheets: jobs,
    );
  }
}

// ── 19. Master Colors & Shapes DTOs ─────────────────────────────────────────

class ApiMasterAttribute {
  const ApiMasterAttribute({
    required this.id,
    required this.name,
    this.code = '',
    this.hexCode = '',
    this.description = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final String hexCode;
  final String description;
  final bool isActive;

  factory ApiMasterAttribute.fromJson(dynamic json) {
    if (json is String) {
      return ApiMasterAttribute(id: json, name: json);
    }
    if (json is Map) {
      return ApiMasterAttribute(
        id: json['id']?.toString() ?? json['name']?.toString() ?? '',
        name: json['name']?.toString() ?? json['label']?.toString() ?? '',
        code: json['code']?.toString() ?? json['value']?.toString() ?? '',
        hexCode: json['hexCode']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      );
    }
    return const ApiMasterAttribute(id: '', name: '');
  }
}
