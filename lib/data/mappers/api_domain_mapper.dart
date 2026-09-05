import '../demo_store.dart';
import '../models/api_models.dart';
import '../../domain/models.dart';

abstract final class ApiDomainMapper {
  static String formatDisplayDate(String? raw, {DateTime? fallbackDate}) {
    if (raw != null && raw.trim().isNotEmpty) {
      final text = raw.trim();
      // Handle compact YYYYMMDD e.g. 20260829
      if (text.length == 8 && int.tryParse(text) != null) {
        final year = text.substring(0, 4);
        final month = text.substring(4, 6);
        final day = text.substring(6, 8);
        return '$day/$month/$year';
      }
      // Handle compact YYYYMMDD with suffix
      if (text.length > 8 && int.tryParse(text.substring(0, 8)) != null) {
        final year = text.substring(0, 4);
        final month = text.substring(4, 6);
        final day = text.substring(6, 8);
        return '$day/$month/$year';
      }
      // Try DateTime.tryParse (handles ISO strings e.g. 2026-08-29 or 2026-08-29T12:00:00.000Z)
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        final day = parsed.day.toString().padLeft(2, '0');
        final month = parsed.month.toString().padLeft(2, '0');
        final year = parsed.year.toString();
        return '$day/$month/$year';
      }
      if (text.contains('/') || text.contains('-')) {
        return text;
      }
    }

    if (fallbackDate != null && fallbackDate.year > 2000) {
      final day = fallbackDate.day.toString().padLeft(2, '0');
      final month = fallbackDate.month.toString().padLeft(2, '0');
      final year = fallbackDate.year.toString();
      return '$day/$month/$year';
    }

    return '';
  }

  static String formatOrderNumber(String rawId, {DateTime? date}) {
    if (rawId.isEmpty) return '';
    final text = rawId.trim();

    final now = date ?? DateTime.now();
    final dd = now.day.toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    String datePrefix = '$dd$mm$yy';

    final dateMatch = RegExp(r'(\d{4})(\d{2})(\d{2})').firstMatch(text);
    if (dateMatch != null) {
      final yearStr = dateMatch.group(1)!;
      final monthStr = dateMatch.group(2)!;
      final dayStr = dateMatch.group(3)!;
      final shortYear = yearStr.substring(2);
      datePrefix = '$dayStr$monthStr$shortYear';
    }

    final seqMatch = RegExp(r'(\d+)$').firstMatch(text);
    String seqStr = '00001';
    if (seqMatch != null) {
      final numVal = int.tryParse(seqMatch.group(1)!);
      if (numVal != null) {
        seqStr = numVal.toString().padLeft(5, '0');
      }
    }

    return '$datePrefix-$seqStr';
  }

  static String formatCleanDesignCode(String raw, {String category = ''}) {
    final text = raw.trim();
    if (text.isEmpty) return 'DSG-0001';

    String catString = category.trim();

    final matched = DemoStore.instance.designs
        .where(
          (d) =>
              d.id.toLowerCase() == text.toLowerCase() ||
              d.code.toLowerCase() == text.toLowerCase() ||
              d.name.toLowerCase() == text.toLowerCase(),
        )
        .firstOrNull;

    if (matched != null && catString.isEmpty) {
      catString = matched.category.name;
    }

    // 1. Extract 3-letter category prefix in UPPERCASE (e.g. NEC, RIN, BAN, EAR, PEN)
    String prefix = '';
    if (catString.isNotEmpty) {
      final cleanCat = catString
          .replaceAll(RegExp(r'[^a-zA-Z]'), '')
          .toUpperCase();
      if (cleanCat.length >= 3) {
        prefix = cleanCat.substring(0, 3);
      } else if (cleanCat.isNotEmpty) {
        prefix = cleanCat.padRight(3, 'X');
      }
    }

    if (prefix.isEmpty || prefix == 'DSG' || prefix == 'LOT' || prefix == 'ALL') {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('neck') || lowerText.contains('haar')) {
        prefix = 'NEC';
      } else if (lowerText.contains('ring') || lowerText.contains('anguthi')) {
        prefix = 'RIN';
      } else if (lowerText.contains('bangle') || lowerText.contains('kangan')) {
        prefix = 'BAN';
      } else if (lowerText.contains('ear') || lowerText.contains('jhumka')) {
        prefix = 'EAR';
      } else if (lowerText.contains('pend')) {
        prefix = 'PEN';
      } else if (lowerText.contains('chain')) {
        prefix = 'CHA';
      } else if (lowerText.contains('mangal')) {
        prefix = 'MAN';
      } else if (lowerText.contains('brace')) {
        prefix = 'BRA';
      } else if (lowerText.contains('bridal')) {
        prefix = 'BRI';
      } else if (text.contains('-')) {
        final p = text
            .split('-')[0]
            .replaceAll(RegExp(r'[^a-zA-Z]'), '')
            .toUpperCase();
        if (p.length >= 3 && p != 'LOT' && p != 'DESIGN' && p != 'PART') {
          prefix = p.substring(0, 3);
        }
      }
    }

    if (prefix.isEmpty) {
      prefix = 'DSG';
    }

    // 2. Extract design sequence number (padded to 4 digits)
    String numPart = '';
    final digitsMatch = RegExp(r'(\d+)').firstMatch(text);
    if (digitsMatch != null) {
      final digits = digitsMatch.group(1)!;
      numPart = digits.length >= 4 ? digits : digits.padLeft(4, '0');
      if (numPart.length > 5) numPart = numPart.substring(numPart.length - 4);
    } else {
      final hash = (text.hashCode.abs() % 9000) + 1000;
      numPart = hash.toString();
    }

    return '$prefix-$numPart';
  }

  static String formatDesignDisplayName({
    required String rawDesignNumber,
    String rawTitle = '',
    String category = '',
  }) {
    final title = rawTitle.trim();
    final code = rawDesignNumber.trim();

    final isCodeUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(code) || (code.length >= 24 && RegExp(r'^[0-9a-fA-F\-]+$').hasMatch(code));

    final isTitleUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(title) || (title.length >= 24 && RegExp(r'^[0-9a-fA-F\-]+$').hasMatch(title));

    // 1. If clean title is already present, use it
    if (title.isNotEmpty && !isTitleUuid) {
      return title;
    }

    // 2. Search in DemoStore designs
    final matchedDesign = DemoStore.instance.designs
        .where(
          (d) =>
              d.id.toLowerCase() == code.toLowerCase() ||
              d.code.toLowerCase() == code.toLowerCase() ||
              (title.isNotEmpty && d.name.toLowerCase() == title.toLowerCase()),
        )
        .firstOrNull;

    if (matchedDesign != null && matchedDesign.name.trim().isNotEmpty) {
      return matchedDesign.name.trim();
    }

    // 3. Search in CAD Tasks
    final matchedCad = DemoStore.instance.cadTasks
        .where(
          (c) =>
              c.id.toLowerCase() == code.toLowerCase() ||
              c.designCode.toLowerCase() == code.toLowerCase() ||
              (title.isNotEmpty && c.productTitle.toLowerCase() == title.toLowerCase()),
        )
        .firstOrNull;

    if (matchedCad != null && matchedCad.productTitle.trim().isNotEmpty) {
      return matchedCad.productTitle.trim();
    }

    // 4. Search in Stock
    final matchedStock = DemoStore.instance.stock
        .where(
          (s) =>
              s.id.toLowerCase() == code.toLowerCase() ||
              s.name.toLowerCase() == code.toLowerCase(),
        )
        .firstOrNull;

    if (matchedStock != null && matchedStock.name.trim().isNotEmpty) {
      return matchedStock.name.trim();
    }

    // 5. If it's a UUID, format cleanly so raw hex isn't shown
    if (isCodeUuid) {
      final clean = code.replaceAll('-', '');
      final shortHex = clean.length >= 6 ? clean.substring(0, 6).toUpperCase() : clean.toUpperCase();
      return 'Custom Design ($shortHex)';
    }

    // 6. Clean numeric design code (e.g. 000244 -> Design #000244)
    if (code.isNotEmpty) {
      if (RegExp(r'^\d+$').hasMatch(code)) {
        return 'Design #$code';
      }
      return code;
    }

    return 'Custom Design';
  }

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
    final rawOrderNum = value.orderNumber.isNotEmpty
        ? value.orderNumber
        : value.id;
    final formattedOrderNum = formatOrderNumber(
      rawOrderNum,
      date: value.createdAt,
    );

    return CustomerOrder(
      id: formattedOrderNum.isNotEmpty ? formattedOrderNum : rawOrderNum,
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
        'READY' || 'COMPLETED' || 'COMPLETE' => OrderStatus.ready,
        'CHECKED_OUT' || 'IN_PRODUCTION' => OrderStatus.inWorkshop,
        'DISPATCHED' => OrderStatus.dispatched,
        'DELIVERED' => OrderStatus.delivered,
        'CANCELLED' || 'CANCELED' => OrderStatus.cancelled,
        _ => OrderStatus.inWorkshop,
      },
      promiseDate: formatDisplayDate(
        value.dueDate,
        fallbackDate: value.createdAt,
      ),
      createdAt:
          value.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      itemsSummary: value.parts.isEmpty
          ? ''
          : value.parts
                .map((part) {
                  final name = formatDesignDisplayName(
                    rawDesignNumber: part.designNumber,
                    rawTitle: part.designName,
                  );
                  return '${part.quantity} pcs · $name';
                })
                .join(', '),
      designs: value.parts
          .map(
            (part) => OrderDesignProgress(
              partId: part.id,
              designNumber: part.designNumber,
              designName: formatDesignDisplayName(
                rawDesignNumber: part.designNumber,
                rawTitle: part.designName,
              ),
              quantity: part.quantity,
              grossWeight: part.grossWeight,
              currentStage:
                  (value.status.toUpperCase() == 'COMPLETED' ||
                      value.status.toUpperCase() == 'COMPLETE' ||
                      part.status.toUpperCase() == 'COMPLETED')
                  ? 'Completed'
                  : part.currentStage,
              status: part.status,
              isBlocked: part.isBlocked,
              blockReason: part.blockReason,
            ),
          )
          .toList(growable: false),
      currentWorkshopStage:
          (value.status.toUpperCase() == 'COMPLETED' ||
              value.status.toUpperCase() == 'COMPLETE')
          ? 'Completed'
          : ((firstPart?.currentStage.trim().isNotEmpty == true)
                ? firstPart!.currentStage
                : 'Waxing'),
      responsibleManager: 'Arjun · PM',
      isBlocked: isBlocked,
      blockedReason: blockReason,
    );
  }

  static String _cleanText(String? raw) {
    if (raw == null) return '';
    var cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (cleaned.contains('|')) {
      final parts = cleaned.split('|');
      final uniqueParts = <String>[];
      final seenMetaKeys = <String>{};
      for (final p in parts) {
        final part = p.trim();
        if (part.isEmpty) continue;
        if (part.contains(':')) {
          final key = part.split(':').first.trim().toLowerCase();
          final val = part.split(':').sublist(1).join(':').trim().toLowerCase();
          if (key == 'price' && (val == '₹0' || val == '0' || val == '₹0.0' || val == '0.0')) {
            continue;
          }
          if (seenMetaKeys.contains(key)) {
            continue;
          } else {
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

  static JewelleryDesign sketch(ApiSketch value) {
    final catName = value.category != null && value.category!.isNotEmpty
        ? value.category!
        : value.title;
    final categoryEnum = parseCategory(catName);
    final rawNum = value.designNumber.isNotEmpty
        ? value.designNumber
        : value.id;
    final code = formatCleanDesignCode(rawNum, category: catName);

    return JewelleryDesign(
      id: value.id,
      name: value.title.isNotEmpty ? value.title : 'Custom Sketch',
      code: code,
      category: categoryEnum,
      purity: '',
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
  }

  static JewelleryDesign threeDDesign(ApiThreeDDesign value) {
    final catName =
        value.category ?? value.sketch?.category ?? value.sketch?.title ?? '';
    final categoryEnum = parseCategory(catName);
    final rawNum = value.sketch?.designNumber.isNotEmpty == true
        ? value.sketch!.designNumber
        : value.id;
    final code = formatCleanDesignCode(rawNum, category: catName);
    final rawPurity = value.priceBreakdown?.purity.isNotEmpty == true
        ? value.priceBreakdown!.purity
        : (value.sizeDimensions.isNotEmpty
              ? value.sizeDimensions
              : '');

    final displayPurity = rawPurity.contains('K') || rawPurity.contains('Gold')
        ? rawPurity
        : '$rawPurity Yellow Gold';

    final isSizePurity =
        value.sizeDimensions.toLowerCase().contains('gold') ||
        value.sizeDimensions.toLowerCase().contains('22k') ||
        value.sizeDimensions.toLowerCase().contains('18k') ||
        value.sizeDimensions.toLowerCase().contains('purity');

    final cleanSize = (!isSizePurity && value.sizeDimensions.isNotEmpty)
        ? value.sizeDimensions
        : null;

    final title = value.sketch?.title.isNotEmpty == true
        ? value.sketch!.title
        : 'Jewellery Design';

    final numPrice =
        (value.calculatedPrice != null && value.calculatedPrice! > 0)
        ? value.calculatedPrice
        : ((value.price != null && value.price! > 0)
              ? value.price
              : ((value.priceBreakdown?.finalPrice != null &&
                        value.priceBreakdown!.finalPrice > 0)
                    ? value.priceBreakdown!.finalPrice
                    : null));

    final calcPrice =
        numPrice ??
        parsePrice(
          null,
          value.adminInstructions ?? value.sketch?.adminInstructions,
        );

    return JewelleryDesign(
      id: value.id,
      name: title,
      code: code,
      category: categoryEnum,
      purity: displayPurity,
      grossWeightGrams: value.totalWeight > 0
          ? value.totalWeight
          : value.goldQuantity,
      netGoldWeightGrams: value.goldQuantity > 0
          ? value.goldQuantity
          : value.totalWeight,
      diamondCarats: value.gemWeightTw > 0 ? value.gemWeightTw : 0.0,
      estimatedPrice: calcPrice,
      imageUrl: (value.sketch?.sketchUrl.isNotEmpty == true)
          ? value.sketch!.sketchUrl
          : (value.xtlFileUrl?.isNotEmpty == true
                ? value.xtlFileUrl!
                : (value.bomFileUrl ?? '')),
      description: _cleanText(value.adminInstructions).isNotEmpty
          ? _cleanText(value.adminInstructions)
          : 'High Quality 3D CAD Designed Jewellery',
      isPopular: value.status == 'APPROVED' || value.totalWeight > 0,
      sizeDimensions: cleanSize,
      priceBreakdown: value.priceBreakdown,
      gemBreakdown: value.gemBreakdown,
      gemQuantity: value.gemQuantity,
    );
  }

  static CadDesignTask cadTask(ApiThreeDDesign value) {
    final rawTitle = value.sketch?.title?.trim() ?? '';
    final sketchTitle = rawTitle.isNotEmpty
        ? rawTitle
        : (value.sizeDimensions.isNotEmpty
              ? value.sizeDimensions
              : (value.category?.isNotEmpty == true
                    ? '${value.category} Design'
                    : 'Custom 3D Design'));

    final code = (value.sketch?.designNumber.isNotEmpty == true)
        ? value.sketch!.designNumber
        : 'CAD-${value.id.substring(0, value.id.length > 6 ? 6 : value.id.length)}';

    final specParts = <String>[];
    if (value.goldQuantity > 0) {
      specParts.add('Gold: ${value.goldQuantity}g');
    }
    if (value.gemQuantity > 0 || value.gemWeightTw > 0) {
      if (value.gemQuantity > 0 && value.gemWeightTw > 0) {
        specParts.add('Gems: ${value.gemQuantity} Pcs (${value.gemWeightTw} Tw)');
      } else if (value.gemQuantity > 0) {
        specParts.add('Gems: ${value.gemQuantity} Pcs');
      } else {
        specParts.add('Gems: ${value.gemWeightTw} Tw');
      }
    }
    if (value.totalWeight > 0) {
      specParts.add('Total: ${value.totalWeight}g');
    }
    final specsStr = specParts.join(' · ');

    // Resolve orderId if this design is part of an active order in DemoStore
    String resolvedOrderId = '';
    for (final order in DemoStore.instance.orders) {
      final matches = order.designs.any(
        (d) =>
            d.designNumber.trim().toLowerCase() == code.trim().toLowerCase() ||
            (code.isNotEmpty &&
                d.designNumber
                    .trim()
                    .toLowerCase()
                    .endsWith(code.trim().toLowerCase())),
      );
      if (matches) {
        resolvedOrderId = order.id;
        break;
      }
    }

    return CadDesignTask(
      id: value.id,
      sketchId: value.sketchId.isNotEmpty
          ? value.sketchId
          : (value.sketch?.id ?? ''),
      orderId: resolvedOrderId,
      designCode: code,
      productTitle: sketchTitle,
      clientName:
          value.designer?.name ??
          value.sketch?.designer?.name ??
          'Client Design',
      specs: specsStr,
      notes: '3D Wax STL Modeling Completed',
      estimatedWeightGrams: value.totalWeight,
      status: switch (value.status.toUpperCase()) {
        'APPROVED' || 'COMPLETED' => CadTaskStatus.completed,
        'REVISION' ||
        'REJECTED' ||
        'CHANGES_REQUESTED' => CadTaskStatus.revision,
        'IN_PROGRESS' ||
        'SUBMITTED' ||
        'PENDING_APPROVAL' => CadTaskStatus.inProgress,
        _ => CadTaskStatus.newTask,
      },
      hasSketchImage: value.sketch?.sketchUrl.isNotEmpty ?? true,
      hasStlFile: value.xtlFileUrl?.isNotEmpty ?? false,
      imageUrl: value.sketch?.sketchUrl ?? '',
      modelFileUrl: value.xtlFileUrl ?? value.sketch?.sketchUrl,
      bomFileUrl: value.bomFileUrl,
      assignedTo: value.designer?.name ?? 'CAD Designer',
      receivedAt:
          DateTime.tryParse(value.sketch?.createdAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      volumeCubicMm: value.volumeMm3,
      goldQuantity: value.goldQuantity,
      gemQuantity: value.gemQuantity,
      gemWeightTw: value.gemWeightTw,
      makingCode: value.makingCode,
      sizeDimensions: value.sizeDimensions,
      gemBreakdown: value.gemBreakdown,
      calculatedPrice: value.calculatedPrice ?? value.price,
      priceBreakdown: value.priceBreakdown,
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
    final rawRole = value.role.toUpperCase();
    final specialty = value.specialty.trim();
    final readableRole = specialty.isNotEmpty
        ? specialty
        : switch (rawRole) {
            'CRAFTSMAN' => 'Craftsman / Artisan',
            'MANAGER' => 'Production Manager',
            'DESIGNER' => '3D CAD Designer',
            'SKETCHER' => '2D Concept Sketcher',
            'FRONTLINER' => 'Front Office / Sales',
            'ADMIN' => 'System Administrator',
            'THREE_D_DESIGNER' => '3D CAD Modeler',
            'RAW_SKETCHER' => '2D Raw Concept Sketcher',
            'GOLDSMITH' => 'Goldsmith Artisan',
            'WORKSHOP_ARTISAN' => 'Workshop Craftsman',
            'ARTISAN' => 'Workshop Craftsman',
            'WAXING' => 'Waxing Specialist',
            'FILING' => 'Filing Artisan',
            'CASTING' => 'Casting Specialist',
            'SETTER' => 'Stone Setter',
            'POLISHER' => 'Polishing Artisan',
            'QUALITY_CHECK' => 'Quality Inspector',
            'PRODUCTION_MANAGER' => 'Production Manager',
            'FRONTIER' => 'Frontier Sales Manager',
            _ => value.role.replaceAll('_', ' '),
          };

    return TeamMember(
      id: value.id,
      name: value.name,
      craft: readableRole,
      shift: rawRole,
      activeLotsCount: value.workerAssignmentsCount,
      status: value.isActive
          ? EmployeeStatus.available
          : EmployeeStatus.blocked,
      todayEfficiencyPercent: 0,
      currentAssignment: value.workerAssignmentsCount > 0
          ? '${value.workerAssignmentsCount} active lots assigned'
          : 'Ready for allocation',
      email: value.email,
      phone: value.phone,
      role: value.role,
      skills: value.skills,
      specialty: value.specialty,
      keycloakId: value.keycloakId,
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
    final rawDesign =
        part['design'] ?? value['design'] ?? part['sketch'] ?? value['sketch'];
    final designMap = rawDesign is Map ? rawDesign : const <String, dynamic>{};
    final designTitle =
        designMap['title'] as String? ??
        designMap['name'] as String? ??
        part['title'] as String? ??
        part['name'] as String? ??
        part['productName'] as String? ??
        value['title'] as String? ??
        value['name'] as String? ??
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
        part['blockReason'] as String? ?? value['blockReason'] as String?;
    final statusStr =
        (part['orderPartStatus'] as String? ??
                part['status'] as String? ??
                value['orderPartStatus'] as String? ??
                value['status'] as String? ??
                '')
            .toUpperCase();
    final isFailedOrHold =
        isBlocked ||
        statusStr == 'FAILED' ||
        statusStr == 'FAILED_STAGE' ||
        statusStr == 'HOLD' ||
        statusStr == 'ON_HOLD';

    return WorkshopLot(
      id: lotId,
      orderId: orderId,
      designCode: designNumber,
      productTitle: designTitle.isNotEmpty
          ? designTitle
          : (designNumber.isNotEmpty ? designNumber : 'Order Part'),
      stage: stageName.isEmpty
          ? (stageId.isNotEmpty ? stage(stageId) : WorkshopStage.inQueue)
          : stage(stageName),
      assignedEmployee: employeeName,
      assignedEmployeeRole:
          latestAssignment['status'] as String? ??
          part['orderPartStatus'] as String? ??
          part['status'] as String? ??
          value['orderPartStatus'] as String? ??
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
    if (lookup.contains('quality') || lookup.contains('qc')) {
      return WorkshopStage.qualityCheck;
    }
    if (lookup.contains('pack') ||
        lookup.contains('ready') ||
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
