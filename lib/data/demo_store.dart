import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/directive_recipients.dart';
import '../routes/app_pages.dart';
import 'mappers/api_domain_mapper.dart';
import 'models/api_models.dart';
import '../domain/models.dart';

class DemoStore extends ChangeNotifier {
  static final DemoStore _instance = DemoStore.empty();
  static DemoStore get instance => _instance;

  AppRole get activeRole {
    if (Get.isRegistered<AppRoleController>()) {
      return Get.find<AppRoleController>().currentRole.value;
    }
    return AppRole.admin;
  }

  /// Empty presentation cache. Data is populated only by successful API BLoCs.
  DemoStore.empty()
    : _workItems = [],
      _instructions = [],
      _designs = [],
      _cart = [],
      _orders = [],
      _clients = [],
      _lots = [],
      _stages = [],
      _recentScans = [],
      _team = [],
      _stock = [],
      _cadTasks = [],
      _goldRates = const GoldRates(
        gold24KPerGram: 0,
        gold22KPerGram: 0,
        gold18KPerGram: 0,
        silverPerKg: 0,
        lastUpdatedTime: '',
      );

  final List<WorkItem> _workItems;
  final List<Instruction> _instructions;
  final List<JewelleryDesign> _designs;
  final List<CartItem> _cart;
  final List<CustomerOrder> _orders;
  final List<ClientInfo> _clients;
  final List<WorkshopLot> _lots;
  final List<ApiStage> _stages;
  final List<WorkshopLot> _recentScans;
  final List<TeamMember> _team;
  final List<StockItem> _stock;
  final List<CadDesignTask> _cadTasks;
  final GoldRates _goldRates;

  final List<Map<String, String>> _adminDirectives = [];

  List<Map<String, String>> get adminDirectives => _adminDirectives;
  List<Map<String, String>> get activeAdminDirectives => _adminDirectives
      .where((directive) => directive['status'] == 'Active')
      .toList(growable: false);

  List<Map<String, String>> directivesForRole(AppRole role) => _adminDirectives
      .where(
        (directive) =>
            directive['status'] == 'Active' &&
            DirectiveRecipients.matchesRole(directive['recipient'] ?? '', role),
      )
      .toList();

  /// Kept for app bootstrap compatibility. Live data is loaded by API BLoCs.
  Future<void> initialize() async {}

  List<Map<String, String>> cadDirectives() => _adminDirectives
      .where(
        (d) =>
            d['recipient'] == 'CAD Designer' ||
            d['recipient'] == 'All' ||
            (d['recipient']?.toLowerCase().contains('cad') ?? false),
      )
      .toList();

  List<Map<String, String>> workshopDirectives() => _adminDirectives
      .where(
        (d) =>
            d['recipient'] == 'Goldsmith (Artisans)' ||
            d['recipient'] == 'QC Team' ||
            d['recipient'] == 'Store Keeper' ||
            d['recipient'] == 'All' ||
            (d['recipient']?.toLowerCase().contains('goldsmith') ?? false) ||
            (d['recipient']?.toLowerCase().contains('artisan') ?? false) ||
            (d['recipient']?.toLowerCase().contains('qc') ?? false),
      )
      .toList();

  void setApiDirectives(List<ApiDirective> directives) {
    final previousIds = _adminDirectives
        .map((directive) => directive['id'])
        .whereType<String>()
        .toSet();
    _instructions.removeWhere(
      (instruction) => previousIds.contains(instruction.id),
    );
    _adminDirectives
      ..clear()
      ..addAll(directives.map(_apiDirectiveMap));
    _instructions.addAll(directives.map(ApiDomainMapper.directive));
    notifyListeners();
  }

  void upsertApiDirective(ApiDirective directive) {
    final index = _adminDirectives.indexWhere(
      (item) => item['id'] == directive.id,
    );
    final mapped = _apiDirectiveMap(directive);
    if (index < 0) {
      _adminDirectives.insert(0, mapped);
    } else {
      _adminDirectives[index] = mapped;
    }
    _instructions.removeWhere((item) => item.id == directive.id);
    _instructions.add(ApiDomainMapper.directive(directive));
    notifyListeners();
  }

  Map<String, String> _apiDirectiveMap(ApiDirective directive) {
    final createdAt = DateTime.tryParse(directive.createdAt ?? '');
    final contentText = directive.instruction.trim().isNotEmpty
        ? directive.instruction.trim()
        : (directive.title.trim().isNotEmpty ? directive.title.trim() : 'Directive Note');
    return {
      'id': directive.id,
      'title': directive.title,
      'date': createdAt == null ? '' : _displayDate(createdAt.toLocal()),
      'createdAt': directive.createdAt ?? '',
      'recipient': _directiveRecipient(directive.targetType),
      'content': contentText,
      'status': directive.status.toUpperCase() == 'ACKNOWLEDGED'
          ? 'Acknowledged'
          : 'Active',
      'audioUrl': directive.audioUrl ?? '',
      'imageUrl': directive.imageUrl ?? '',
    };
  }

  String _directiveRecipient(String targetType) =>
      switch (targetType.trim().toUpperCase()) {
        'THREE_D_DESIGNER' || 'CAD_DESIGNER' || 'CAD' => 'CAD Designer',
        'SKETCHER' || 'SKETCH' || 'RAW_DESIGNER' || 'SKETCH_DESIGNER' => 'Raw Designer',
        'ALL_ARTISANS' || 'BENCH_ARTISAN' || 'ARTISAN' || 'ARTISANS' => 'Workshop Artisan',
        'PROCESS_MANAGER' || 'PRODUCTION_MANAGER' => 'Product Manager',
        'FRONT_OFFICE' || 'SALES' => 'Front Office',
        'ALL' || 'ALL_TEAMS' => DirectiveRecipients.allTeams,
        _ => targetType.replaceAll('_', ' '),
      };

  String _displayDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day-$month-${value.year}';
  }

  void approveSketch(String designCode) {
    final index = _designs.indexWhere((d) => d.code == designCode);
    if (index >= 0) {
      _designs[index] = _designs[index].copyWith(
        name: '${_designs[index].name} (Sketch Approved)',
      );
      notifyListeners();
    }
  }

  void approveCadTask(String taskId) {
    final index = _cadTasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _cadTasks[index] = _cadTasks[index].copyWith(
        status: CadTaskStatus.completed,
        specs: '${_cadTasks[index].specs} (Approved)',
        lastUpdated: 'Just now',
      );
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // ORIGINAL GETTERS & ACTIONS (For backward compatibility)
  // -----------------------------------------------------------------
  List<WorkItem> workItemsFor(StatusPivot pivot) {
    if (pivot == StatusPivot.orders) {
      return _orders
          .map((order) {
            final partIds = order.designs
                .map((design) => design.partId)
                .where((id) => id.isNotEmpty)
                .toSet();
            final orderLots = _lots.where(
              (lot) =>
                  lot.orderId == order.id ||
                  (order.apiId.isNotEmpty && lot.orderId == order.apiId) ||
                  partIds.contains(lot.id),
            );
            final blockedLots = orderLots
                .where((lot) => lot.blockerReason?.isNotEmpty == true)
                .toList(growable: false);
            final activeStages = orderLots
                .map((lot) => lot.stage.label)
                .where((stage) => stage.isNotEmpty)
                .toSet();
            final stageLabel = activeStages.length > 1
                ? '${activeStages.length} active stages'
                : activeStages.firstOrNull ?? order.currentWorkshopStage;
            final isOnHold = order.isBlocked || blockedLots.isNotEmpty;
            final holdReason =
                order.blockedReason ?? blockedLots.firstOrNull?.blockerReason;

            return WorkItem(
              id: order.id,
              pivot: pivot,
              title: order.clientFirmName,
              subtitle: [
                order.designs.isEmpty
                    ? order.itemsSummary
                    : '${order.designs.length} designs',
                stageLabel,
              ].where((value) => value.isNotEmpty).join(' · '),
              status: isOnHold
                  ? 'ON HOLD${holdReason?.isNotEmpty == true ? ' · $holdReason' : ''}'
                  : order.status.label,
              quantity: '${order.itemsCount} pcs',
              owner: order.responsibleManager,
              tone: isOnHold ? HealthTone.critical : HealthTone.healthy,
              metrics: {
                'Designs': '${order.designs.length}',
                'Pieces': '${order.itemsCount}',
                'Stage': stageLabel,
              },
              timeline: const [],
            );
          })
          .toList(growable: false);
    }
    if (pivot == StatusPivot.people) {
      return _team
          .map(
            (member) => WorkItem(
              id: member.id,
              pivot: pivot,
              title: member.name,
              subtitle: member.craft,
              status: member.status.label,
              quantity: '${member.activeLotsCount} lots',
              owner: member.shift,
              tone: member.status.tone,
              metrics: {'Active lots': '${member.activeLotsCount}'},
              timeline: const [],
            ),
          )
          .toList(growable: false);
    }
    return (_stages.toList()
          ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber)))
        .map((stage) {
          final stageLots = lotsForStage(stage);
          final lotCount = stageLots.length;
          final pieceCount = stageLots.fold<int>(
            0,
            (sum, lot) => sum + lot.pieces,
          );
          final heldCount = stageLots.where((lot) => lot.isOnHold).length;
          return WorkItem(
            id: stage.name,
            pivot: pivot,
            title: stage.name,
            subtitle: 'Stage ${stage.stageNumber}',
            status: heldCount > 0
                ? '$heldCount on hold'
                : pieceCount > 0
                ? '$pieceCount pieces active'
                : 'No active work',
            quantity: '$pieceCount pcs · $lotCount lots',
            owner: '',
            tone: heldCount > 0 ? HealthTone.critical : HealthTone.healthy,
            metrics: {
              'Active lots': '$lotCount',
              'Pieces': '$pieceCount',
              'On hold': '$heldCount',
              'Stage No.': '${stage.stageNumber}',
            },
            timeline: const [],
          );
        })
        .toList(growable: false);
  }

  List<Instruction> get instructions =>
      List.unmodifiable(_instructions.reversed);

  int get actionableInstructionCount => _instructions
      .where((item) => item.status != InstructionStatus.resolved)
      .length;

  Instruction addInstruction({
    required WorkItem target,
    required String message,
    required InstructionUrgency urgency,
    bool hasPhoto = false,
    bool hasVoice = false,
  }) {
    final instruction = Instruction(
      id: 'INS-${(_instructions.length + 15).toString().padLeft(3, '0')}',
      targetId: target.id,
      targetLabel: '${target.pivot.singularLabel} ${target.id}',
      message: message.trim().isEmpty
          ? 'Voice instruction attached.'
          : message.trim(),
      createdBy: 'Ramesh Pareek',
      assignedTo: 'Arjun · Process Manager',
      urgency: urgency,
      status: InstructionStatus.sent,
      createdAt: DateTime.now(),
      hasPhoto: hasPhoto,
      hasVoice: hasVoice,
    );
    _instructions.add(instruction);
    notifyListeners();
    return instruction;
  }

  // -----------------------------------------------------------------
  // FRONT OFFICE: DESIGNS & CART
  // -----------------------------------------------------------------
  List<JewelleryDesign> get designs => List.unmodifiable(_designs);

  void addDesign(JewelleryDesign design) {
    _designs.insert(0, design);
    notifyListeners();
  }

  void approveDesign(String id) {
    final index = _designs.indexWhere((item) => item.id == id);
    if (index != -1) {
      final old = _designs[index];
      _designs[index] = JewelleryDesign(
        id: old.id,
        name: old.name.contains('(Sketch Approved)')
            ? old.name
            : '${old.name} (Sketch Approved)',
        code: old.code,
        category: old.category,
        purity: old.purity,
        grossWeightGrams: old.grossWeightGrams,
        imageUrl: old.imageUrl,
        description: old.description,
        isPopular: true,
        estimatedPrice: old.estimatedPrice,
      );

      final taskExists = _cadTasks.any(
        (t) => t.id == old.id || t.designCode == old.code,
      );
      if (!taskExists) {
        _cadTasks.insert(
          0,
          CadDesignTask(
            id: 'CAD-${old.code}',
            orderId: 'ORD-2026-CAD',
            designCode: old.code,
            productTitle: '${old.name} (Approved 2D Sketch)',
            clientName: 'Approved Client Sketch',
            specs: 'Approved 2D Concept · Ready for 3D STL & BOM Modeling',
            notes: old.description.isNotEmpty
                ? old.description
                : 'Approved for CAD Modeling',
            estimatedWeightGrams: old.grossWeightGrams > 0
                ? old.grossWeightGrams
                : 16.0,
            status: CadTaskStatus.newTask,
            hasSketchImage: old.imageUrl.isNotEmpty,
            hasStlFile: false,
            modelFileUrl: old.imageUrl,
            assignedTo: 'Rahul CAD Designer',
            receivedAt: DateTime.now(),
            volumeCubicMm: 1250,
          ),
        );
      }

      notifyListeners();
    }
  }

  List<JewelleryDesign> designsForCategory(JewelleryCategory category) {
    if (category == JewelleryCategory.all) return designs;
    return _designs
        .where((d) => d.category == category)
        .toList(growable: false);
  }

  List<CartItem> get cart => List.unmodifiable(_cart);

  int get cartItemsCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotalGrossWeight =>
      _cart.fold(0.0, (sum, item) => sum + item.totalGrossWeight);

  double get cartTotalEstimatedPrice =>
      _cart.fold(0.0, (sum, item) => sum + item.totalEstimatedPrice);

  void addToCart(
    JewelleryDesign design, {
    int quantity = 1,
    String purity = '22KT',
  }) {
    final existingIndex = _cart.indexWhere(
      (item) => item.design.id == design.id,
    );
    if (existingIndex >= 0) {
      final current = _cart[existingIndex];
      _cart[existingIndex] = current.copyWith(
        quantity: current.quantity + quantity,
      );
    } else {
      _cart.add(
        CartItem(design: design, quantity: quantity, selectedPurity: purity),
      );
    }
    notifyListeners();
  }

  void updateCartQuantity(String designId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(designId);
      return;
    }
    final index = _cart.indexWhere((item) => item.design.id == designId);
    if (index >= 0) {
      _cart[index] = _cart[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void removeFromCart(String designId) {
    _cart.removeWhere((item) => item.design.id == designId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // FRONT OFFICE: ORDERS & CLIENTS
  // -----------------------------------------------------------------
  List<CustomerOrder> get orders => List.unmodifiable(_orders);

  List<CustomerOrder> get pendingOrders =>
      _orders.where((o) => o.status == OrderStatus.pending).toList();

  CustomerOrder placeOrder({
    required ClientInfo client,
    required String promiseDate,
    String notes = '',
  }) {
    final orderId = 'JO-${10483 + _orders.length}';
    final itemsDesc = _cart
        .map((c) => '${c.quantity}x ${c.design.name}')
        .join(', ');

    final newOrder = CustomerOrder(
      id: orderId,
      clientFirmName: client.firmName,
      clientCity: client.city,
      itemsCount: cartItemsCount,
      totalGrossGrams: double.parse(cartTotalGrossWeight.toStringAsFixed(2)),
      estimatedTotalAmount: cartTotalEstimatedPrice,
      status: OrderStatus.pending,
      promiseDate: promiseDate,
      createdAt: DateTime.now(),
      itemsSummary: itemsDesc.isEmpty ? 'Custom jewellery lot' : itemsDesc,
    );

    // Generate CAD Tasks for each item in the cart before clearing it
    for (final item in _cart) {
      final taskIdx = _cadTasks.length + 1;
      _cadTasks.insert(
        0,
        CadDesignTask(
          id: 'CAD-${taskIdx.toString().padLeft(3, '0')}',
          orderId: orderId,
          designCode: item.design.code,
          productTitle: item.design.name,
          clientName: client.firmName,
          specs: '${item.selectedPurity} gold, ${item.design.purity} purity',
          notes: 'New design task generated from order $orderId.',
          estimatedWeightGrams: item.design.grossWeightGrams,
          status: CadTaskStatus.newTask,
          hasVoiceNote: false,
          hasSketchImage: false,
          assignedTo: 'Vikram · CAD',
          receivedAt: DateTime.now(),
        ),
      );
    }

    _orders.insert(0, newOrder);
    _cart.clear();

    // Also add to active WorkItems
    _workItems.insert(
      0,
      WorkItem(
        id: orderId,
        pivot: StatusPivot.orders,
        title: '${client.firmName} · ${client.city}',
        subtitle: 'Due $promiseDate · $itemsDesc',
        status: 'Order Placed · Awaiting CAD',
        quantity: '$cartItemsCount items ($cartTotalGrossWeight g)',
        owner: 'Front Office',
        tone: HealthTone.healthy,
        metrics: {
          'Ordered': '$cartItemsCount pcs',
          'Weight': '${cartTotalGrossWeight.toStringAsFixed(1)} g',
          'Value':
              '₹${(cartTotalEstimatedPrice / 100000).toStringAsFixed(2)} L',
        },
        timeline: [
          TimelineEntry(
            title: 'Order Placed',
            detail: 'Due $promiseDate · Front Office committed',
            time: 'Just now',
          ),
        ],
      ),
    );

    notifyListeners();
    return newOrder;
  }

  CustomerOrder createDirectOrder({
    required ClientInfo client,
    required List<Map<String, dynamic>>
    items, // [{'design': CatalogueDesign, 'quantity': int}]
    required String dueDate,
    String notes = '',
  }) {
    final orderId = 'JO-${10483 + _orders.length}';
    int totalPcs = 0;
    double totalWeight = 0.0;
    double totalAmount = 0.0;
    final List<String> summaryParts = [];

    for (final it in items) {
      final design = it['design'] as JewelleryDesign;
      final qty = it['quantity'] as int;
      totalPcs += qty;
      totalWeight += design.grossWeightGrams * qty;
      totalAmount += design.estimatedPrice * qty;
      summaryParts.add('${qty}x ${design.name}');

      // Auto generate CAD Task for each design item
      final taskIdx = _cadTasks.length + 1;
      _cadTasks.insert(
        0,
        CadDesignTask(
          id: 'CAD-${taskIdx.toString().padLeft(3, '0')}',
          orderId: orderId,
          designCode: design.code,
          productTitle: design.name,
          clientName: client.firmName,
          specs: '${design.purity} Gold, ${design.grossWeightGrams}g',
          notes: notes.isNotEmpty ? notes : 'Direct wholesale order $orderId.',
          estimatedWeightGrams: design.grossWeightGrams * qty,
          status: CadTaskStatus.newTask,
          hasVoiceNote: false,
          hasSketchImage: false,
          assignedTo: 'Vikram · CAD',
          receivedAt: DateTime.now(),
        ),
      );
    }

    final newOrder = CustomerOrder(
      id: orderId,
      clientFirmName: client.firmName,
      clientCity: client.city,
      itemsCount: totalPcs,
      totalGrossGrams: double.parse(totalWeight.toStringAsFixed(2)),
      estimatedTotalAmount: totalAmount,
      status: OrderStatus.pending,
      promiseDate: dueDate,
      createdAt: DateTime.now(),
      itemsSummary: summaryParts.isEmpty
          ? 'Wholesale order'
          : summaryParts.join(', '),
      currentWorkshopStage: 'In Queue (Unassigned)',
      responsibleManager: 'Unassigned',
    );

    _orders.insert(0, newOrder);

    _workItems.insert(
      0,
      WorkItem(
        id: orderId,
        pivot: StatusPivot.orders,
        title: '${client.firmName} · ${client.city}',
        subtitle: 'Due $dueDate · ${summaryParts.join(', ')}',
        status: 'Order Placed · In Queue',
        quantity: '$totalPcs pcs (${totalWeight.toStringAsFixed(1)} g)',
        owner: 'Front Office',
        tone: HealthTone.healthy,
        metrics: {
          'Ordered': '$totalPcs pcs',
          'Weight': '${totalWeight.toStringAsFixed(1)} g',
          'Value': '₹${(totalAmount / 100000).toStringAsFixed(2)} L',
        },
        timeline: [
          TimelineEntry(
            title: 'Order Placed',
            detail: 'Due $dueDate · Front Office committed',
            time: 'Just now',
          ),
        ],
      ),
    );

    notifyListeners();
    return newOrder;
  }

  void addCustomerOrder(CustomerOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  void toggleOrderHold(
    String orderId, {
    required bool isBlocked,
    String? reason,
  }) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(
        isBlocked: isBlocked,
        blockedReason: isBlocked ? reason : null,
      );
      notifyListeners();
    }
  }

  void toggleLotHold(String lotId, {required bool isBlocked, String? reason}) {
    if (lotId.isEmpty) return;
    bool updated = false;
    final lowerLotId = lotId.toLowerCase();

    for (int i = 0; i < _lots.length; i++) {
      final lot = _lots[i];
      final matchesLot =
          lot.id == lotId ||
          lot.designCode.toLowerCase() == lowerLotId ||
          lot.productTitle.toLowerCase() == lowerLotId ||
          (lot.id.isNotEmpty &&
              (lot.id.contains(lotId) || lotId.contains(lot.id))) ||
          (lot.designCode.isNotEmpty &&
              (lot.designCode.toLowerCase().contains(lowerLotId) ||
                  lowerLotId.contains(lot.designCode.toLowerCase())));

      if (matchesLot) {
        _lots[i] = lot.copyWith(
          tone: isBlocked ? HealthTone.critical : HealthTone.healthy,
          blockerReason: isBlocked
              ? (reason?.isNotEmpty == true ? reason : 'On Hold')
              : null,
          clearBlocker: !isBlocked,
          lastUpdatedTime: 'Just now',
        );
        updated = true;

        for (int j = 0; j < _orders.length; j++) {
          if (_orders[j].id == lot.orderId ||
              (lot.orderId.isNotEmpty &&
                  (_orders[j].id.contains(lot.orderId) ||
                      lot.orderId.contains(_orders[j].id))) ||
              (lot.designCode.isNotEmpty &&
                  _orders[j].itemsSummary.toLowerCase().contains(
                    lot.designCode.toLowerCase(),
                  ))) {
            _orders[j] = _orders[j].copyWith(
              isBlocked: isBlocked,
              blockedReason: isBlocked ? reason : null,
            );
          }
        }
      }
    }

    // Direct match with orders
    for (int j = 0; j < _orders.length; j++) {
      if (_orders[j].id.toLowerCase() == lowerLotId ||
          _orders[j].id.contains(lotId) ||
          lotId.contains(_orders[j].id) ||
          (lowerLotId.length > 3 &&
              _orders[j].itemsSummary.toLowerCase().contains(lowerLotId))) {
        _orders[j] = _orders[j].copyWith(
          isBlocked: isBlocked,
          blockedReason: isBlocked ? reason : null,
        );
        // Also toggle matching lots for this order
        for (int i = 0; i < _lots.length; i++) {
          if (_lots[i].orderId == _orders[j].id ||
              (_lots[i].orderId.isNotEmpty &&
                  _orders[j].id.contains(_lots[i].orderId)) ||
              (_lots[i].designCode.isNotEmpty &&
                  _orders[j].itemsSummary.toLowerCase().contains(
                    _lots[i].designCode.toLowerCase(),
                  ))) {
            _lots[i] = _lots[i].copyWith(
              tone: isBlocked ? HealthTone.critical : HealthTone.healthy,
              blockerReason: isBlocked
                  ? (reason?.isNotEmpty == true ? reason : 'On Hold')
                  : null,
              clearBlocker: !isBlocked,
              lastUpdatedTime: 'Just now',
            );
          }
        }
        updated = true;
      }
    }

    if (updated) {
      notifyListeners();
    }
  }

  List<ClientInfo> get clients => List.unmodifiable(_clients);

  void addClient(ClientInfo client) {
    _clients.insert(0, client);
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // WORKSHOP: LOTS & SCANNER
  // -----------------------------------------------------------------
  List<WorkshopLot> get lots => List.unmodifiable(_lots);
  int get heldLotsCount => _lots.where((lot) => lot.isOnHold).length;

  List<WorkshopLot> lotsForStage(ApiStage apiStage) {
    final normalizedName = _normalizedStageName(apiStage.name);
    final domainStage = ApiDomainMapper.stage(apiStage.name);

    return _lots
        .where((lot) {
          if (lot.apiStageId.isNotEmpty && apiStage.id.isNotEmpty) {
            return lot.apiStageId == apiStage.id;
          }
          if (lot.apiStageName.isNotEmpty) {
            return _normalizedStageName(lot.apiStageName) == normalizedName;
          }
          return lot.stage == domainStage;
        })
        .toList(growable: false);
  }

  List<WorkshopLot> lotsForStageName(String stageName) {
    final apiStage = _stages
        .where(
          (stage) =>
              stage.id == stageName ||
              _normalizedStageName(stage.name) ==
                  _normalizedStageName(stageName),
        )
        .firstOrNull;
    if (apiStage != null) return lotsForStage(apiStage);

    final domainStage = ApiDomainMapper.stage(stageName);
    return _lots
        .where(
          (lot) =>
              lot.apiStageId.isEmpty &&
              (lot.apiStageName.isEmpty
                  ? lot.stage == domainStage
                  : _normalizedStageName(lot.apiStageName) ==
                        _normalizedStageName(stageName)),
        )
        .toList(growable: false);
  }

  String _normalizedStageName(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  List<ApiStage> get stages => List.unmodifiable(_stages);
  List<WorkshopLot> get recentScans => List.unmodifiable(_recentScans);

  void allocateLotArtisan(String lotId, String artisanName) {
    bool updated = false;
    for (int i = 0; i < _lots.length; i++) {
      if (_lots[i].id == lotId ||
          _lots[i].designCode == lotId ||
          (lotId.isNotEmpty && _lots[i].id.contains(lotId))) {
        _lots[i] = _lots[i].copyWith(
          assignedEmployee: artisanName,
          lastUpdatedTime: 'Just now',
        );
        updated = true;
      }
    }
    if (artisanName.isNotEmpty) {
      final tIndex = _team.indexWhere(
        (t) =>
            t.name.toLowerCase() == artisanName.toLowerCase() ||
            t.id == artisanName,
      );
      if (tIndex >= 0) {
        final member = _team[tIndex];
        _team[tIndex] = member.copyWith(
          status: EmployeeStatus.working,
          activeLotsCount: member.activeLotsCount + 1,
          currentAssignment: 'Lot #$lotId',
        );
        updated = true;
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  WorkshopLot? lookupLot(String query) {
    final q = query.trim().toUpperCase();
    try {
      return _lots.firstWhere(
        (lot) =>
            lot.id.toUpperCase() == q ||
            lot.orderId.toUpperCase() == q ||
            lot.designCode.toUpperCase() == q,
      );
    } catch (_) {
      return null;
    }
  }

  void updateLotStage(
    String lotId,
    WorkshopStage newStage, {
    String? assignedEmployee,
  }) {
    final index = _lots.indexWhere((l) => l.id == lotId);
    if (index >= 0) {
      final updated = _lots[index].copyWith(
        stage: newStage,
        assignedEmployee: assignedEmployee ?? _lots[index].assignedEmployee,
        lastUpdatedTime: 'Just now',
        tone: newStage == WorkshopStage.readyForDispatch
            ? HealthTone.healthy
            : _lots[index].tone,
      );
      _lots[index] = updated;

      final empName = assignedEmployee ?? updated.assignedEmployee;
      if (empName.isNotEmpty) {
        final tIndex = _team.indexWhere(
          (t) =>
              t.name.toLowerCase() == empName.toLowerCase() || t.id == empName,
        );
        if (tIndex >= 0) {
          final member = _team[tIndex];
          _team[tIndex] = member.copyWith(
            status: EmployeeStatus.working,
            activeLotsCount: member.activeLotsCount + 1,
            currentAssignment: '${updated.productTitle} (${updated.id})',
          );
        }
      }

      recordScan(updated);
      notifyListeners();
    }
  }

  void advanceLotStage(String lotId) {
    bool updated = false;
    for (int i = 0; i < _lots.length; i++) {
      if (_lots[i].id == lotId ||
          _lots[i].designCode == lotId ||
          (lotId.isNotEmpty && _lots[i].id.contains(lotId))) {
        final currentStage = _lots[i].stage;
        final nextIndex = currentStage.index + 1;
        if (nextIndex < WorkshopStage.values.length) {
          final newStage = WorkshopStage.values[nextIndex];
          _lots[i] = _lots[i].copyWith(
            stage: newStage,
            lastUpdatedTime: 'Just now',
            tone: newStage == WorkshopStage.readyForDispatch
                ? HealthTone.healthy
                : _lots[i].tone,
          );
          recordScan(_lots[i]);
          updated = true;
        }
      }
    }
    if (updated) {
      notifyListeners();
    }
  }

  void splitWorkshopLot({
    required String lotId,
    required int movedPieces,
    required WorkshopStage targetStage,
  }) {
    final index = _lots.indexWhere((l) => l.id == lotId);
    if (index >= 0) {
      final sourceLot = _lots[index];
      if (movedPieces >= sourceLot.pieces) {
        _lots[index] = sourceLot.copyWith(
          stage: targetStage,
          lastUpdatedTime: 'Just now',
        );
      } else {
        final originalCount = sourceLot.pieces;
        final remainingPieces = (originalCount - movedPieces).clamp(
          1,
          originalCount,
        );
        _lots[index] = sourceLot.copyWith(
          pieces: remainingPieces,
          lastUpdatedTime: 'Just now',
        );
        final newLotId = sourceLot.id;
        final splitLot = WorkshopLot(
          id: newLotId,
          orderId: sourceLot.orderId,
          designCode: sourceLot.designCode,
          productTitle: sourceLot.productTitle,
          stage: targetStage,
          assignedEmployee: 'Unassigned',
          assignedEmployeeRole: sourceLot.assignedEmployeeRole,
          pieces: movedPieces,
          issueWeightGrams:
              sourceLot.issueWeightGrams * (movedPieces / originalCount),
          targetWeightGrams:
              sourceLot.targetWeightGrams * (movedPieces / originalCount),
          tone: HealthTone.healthy,
          blockerReason: null,
          lastUpdatedTime: 'Just now',
        );
        _lots.insert(0, splitLot);
      }
      notifyListeners();
    }
  }

  void addWorkshopLot({
    required String orderId,
    required String designCode,
    required String productTitle,
    required WorkshopStage stage,
    required String assignedEmployee,
    required String assignedEmployeeRole,
    required int pieces,
    required double issueWeightGrams,
    required double targetWeightGrams,
  }) {
    final existingIndex = _lots.indexWhere(
      (l) =>
          l.orderId == orderId &&
          (l.designCode == designCode || l.productTitle == productTitle),
    );
    final newLotId = existingIndex >= 0
        ? _lots[existingIndex].id
        : 'LOT-${100 + _lots.length + 1}';

    final lot = WorkshopLot(
      id: newLotId,
      orderId: orderId,
      designCode: designCode,
      productTitle: productTitle,
      stage: stage,
      assignedEmployee: assignedEmployee,
      assignedEmployeeRole: assignedEmployeeRole,
      pieces: pieces,
      issueWeightGrams: issueWeightGrams,
      targetWeightGrams: targetWeightGrams,
      tone: HealthTone.healthy,
      blockerReason: null,
      lastUpdatedTime: 'Just now',
    );

    if (existingIndex >= 0) {
      _lots[existingIndex] = lot;
    } else {
      _lots.insert(0, lot);
    }

    // Update parent order status and stage reactively
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx >= 0) {
      final ord = _orders[orderIdx];
      _orders[orderIdx] = ord.copyWith(
        status: OrderStatus.inWorkshop,
        currentWorkshopStage: '${stage.label} ($assignedEmployee)',
        responsibleManager: assignedEmployee,
      );
    }

    recordScan(lot);
    notifyListeners();
  }

  void recordScan(WorkshopLot lot) {
    _recentScans.removeWhere((item) => item.id == lot.id);
    _recentScans.insert(0, lot);
    if (_recentScans.length > 8) _recentScans.removeLast();
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // WORKSHOP: TEAM & WORKLOAD
  // -----------------------------------------------------------------
  List<TeamMember> get team => List.unmodifiable(_team);

  void addTeamMember(TeamMember member) {
    _team.insert(0, member);
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // ADMIN: STOCK & GOLD RATES
  // -----------------------------------------------------------------
  List<StockItem> get stock => List.unmodifiable(_stock);
  GoldRates get goldRates => _goldRates;

  void updateStockDiscrepancy(String stockId, double newDiscrepancy) {
    final index = _stock.indexWhere((s) => s.id == stockId);
    if (index >= 0) {
      final item = _stock[index];
      _stock[index] = StockItem(
        id: item.id,
        name: item.name,
        category: item.category,
        purityOrGrade: item.purityOrGrade,
        totalAvailable: item.totalAvailable,
        reservedInLots: item.reservedInLots,
        unit: item.unit,
        vaultLocation: item.vaultLocation,
        discrepancyGrams: newDiscrepancy,
      );
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // CAD DESIGNER: TASKS
  // -----------------------------------------------------------------
  List<CadDesignTask> get cadTasks => List.unmodifiable(_cadTasks);

  void addCadTask(CadDesignTask task) {
    _cadTasks.insert(0, task);
    notifyListeners();
  }

  List<CadDesignTask> cadTasksByStatus(CadTaskStatus status) =>
      _cadTasks.where((t) => t.status == status).toList(growable: false);

  int get cadNewCount =>
      _cadTasks.where((t) => t.status == CadTaskStatus.newTask).length;

  int get cadInProgressCount =>
      _cadTasks.where((t) => t.status == CadTaskStatus.inProgress).length;

  int get cadCompletedCount =>
      _cadTasks.where((t) => t.status == CadTaskStatus.completed).length;

  int get cadRevisionCount =>
      _cadTasks.where((t) => t.status == CadTaskStatus.revision).length;

  void updateCadTaskStatus(String taskId, CadTaskStatus newStatus) {
    final index = _cadTasks.indexWhere(
      (t) => t.id == taskId || t.designCode == taskId || t.orderId == taskId,
    );
    if (index >= 0) {
      _cadTasks[index] = _cadTasks[index].copyWith(
        status: newStatus,
        lastUpdated: 'Just now',
      );
      notifyListeners();
    }
  }

  void rejectCadTask(String taskId, String notes, bool hasVoice) {
    final index = _cadTasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _cadTasks[index] = _cadTasks[index].copyWith(
        status: CadTaskStatus.revision,
        revisionNotes: notes,
        hasRevisionVoice: hasVoice,
        lastUpdated: 'Just now',
      );
      notifyListeners();
    }
  }

  void uploadStlFile(String taskId, double volumeCubicMm, String newSpecs) {
    final index = _cadTasks.indexWhere(
      (t) => t.id == taskId || t.designCode == taskId || t.orderId == taskId,
    );
    if (index >= 0) {
      _cadTasks[index] = _cadTasks[index].copyWith(
        hasStlFile: true,
        volumeCubicMm: volumeCubicMm,
        status: CadTaskStatus.completed,
        specs: newSpecs,
        lastUpdated: 'Just now',
      );
      notifyListeners();
    }
  }

  void markCadTaskStlUploaded(String taskId) {
    final index = _cadTasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      _cadTasks[index] = _cadTasks[index].copyWith(
        hasStlFile: true,
        lastUpdated: 'Just now',
      );
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------
  // LIVE API SYNC SETTERS (PURE API DRIVEN)
  // -----------------------------------------------------------------
  void setTeam(List<TeamMember> team) {
    _team
      ..clear()
      ..addAll(team);
    notifyListeners();
  }

  void setOrders(List<CustomerOrder> orders) {
    final uniqueOrders = <CustomerOrder>[];
    final seenIds = <String>{};
    for (final o in orders) {
      final key = o.apiId.isNotEmpty ? o.apiId : o.id;
      if (seenIds.add(key)) {
        uniqueOrders.add(o);
      }
    }
    _orders
      ..clear()
      ..addAll(uniqueOrders);
    notifyListeners();
  }

  void setClients(List<ClientInfo> clients) {
    _clients
      ..clear()
      ..addAll(clients);
    notifyListeners();
  }

  void setLots(List<WorkshopLot> lots) {
    final uniqueLots = <WorkshopLot>[];
    final seenIds = <String>{};
    for (final lot in lots) {
      final lotKey = lot.id.isNotEmpty
          ? lot.id
          : '${lot.orderId}_${lot.designCode}';
      if (lotKey.isEmpty || seenIds.add(lotKey)) {
        uniqueLots.add(lot);
      }
    }
    _lots
      ..clear()
      ..addAll(uniqueLots);
    notifyListeners();
  }

  void setStages(List<ApiStage> stages) {
    _stages
      ..clear()
      ..addAll(stages.where((stage) => stage.isActive));
    _stages.sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
    notifyListeners();
  }

  void setCadTasks(List<CadDesignTask> tasks) {
    _cadTasks
      ..clear()
      ..addAll(tasks);
    notifyListeners();
  }

  void setDesigns(List<JewelleryDesign> designs) {
    _designs
      ..clear()
      ..addAll(designs);
    notifyListeners();
  }

  void setStock(List<StockItem> stock) {
    _stock
      ..clear()
      ..addAll(stock);
    notifyListeners();
  }
}
