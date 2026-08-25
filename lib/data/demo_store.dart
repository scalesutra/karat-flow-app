import 'package:flutter/material.dart';
import 'models/api_models.dart';
import '../domain/models.dart';

class DemoStore extends ChangeNotifier {
  static final DemoStore _instance = DemoStore.empty();
  static DemoStore get instance => _instance;

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

  void addAdminDirective(String recipient, String content) {
    final id = 'DIR-00${_adminDirectives.length + 1}';
    _adminDirectives.insert(0, {
      'id': id,
      'date': '25-08-2026',
      'recipient': recipient,
      'content': content,
      'status': 'Active',
    });

    _instructions.insert(
      0,
      Instruction(
        id: id,
        targetId: id,
        targetLabel: 'Directive to $recipient',
        message: content,
        createdBy: 'Admin',
        assignedTo: recipient,
        urgency: InstructionUrgency.urgent,
        status: InstructionStatus.sent,
        createdAt: DateTime.now(),
        hasPhoto: false,
        hasVoice: false,
      ),
    );

    notifyListeners();
  }

  void acknowledgeDirective(String id) {
    final index = _adminDirectives.indexWhere((d) => d['id'] == id);
    if (index >= 0) {
      _adminDirectives[index] = {
        ..._adminDirectives[index],
        'status': 'Acknowledged',
      };
      notifyListeners();
    }
  }

  void deleteDirective(String id) {
    _adminDirectives.removeWhere((d) => d['id'] == id);
    notifyListeners();
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
          .map(
            (order) => WorkItem(
              id: order.id,
              pivot: pivot,
              title: order.clientFirmName,
              subtitle: [
                order.itemsSummary,
                order.currentWorkshopStage,
              ].where((value) => value.isNotEmpty).join(' · '),
              status: order.status.label,
              quantity: '${order.itemsCount} pcs',
              owner: order.responsibleManager,
              tone: order.isBlocked ? HealthTone.critical : HealthTone.healthy,
              metrics: {
                'Weight': '${order.totalGrossGrams}g',
                'Due': order.promiseDate,
                'Stage': order.currentWorkshopStage,
              },
              timeline: const [],
            ),
          )
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
              metrics: {
                'Active lots': '${member.activeLotsCount}',
                'Efficiency': '${member.todayEfficiencyPercent}%',
              },
              timeline: const [],
            ),
          )
          .toList(growable: false);
    }
    return _stages
        .map((stage) {
          final stageIndex = (stage.stageNumber - 1)
              .clamp(0, WorkshopStage.values.length - 1)
              .toInt();
          final lotCount = _lots
              .where((lot) => lot.stage == WorkshopStage.values[stageIndex])
              .length;
          return WorkItem(
            id: stage.name,
            pivot: pivot,
            title: stage.name,
            subtitle: 'Stage ${stage.stageNumber} · Production Routing',
            status: lotCount > 0 ? '$lotCount Lots Active' : 'Idle',
            quantity: '$lotCount lots in floor',
            owner: 'Workshop Manager',
            tone: HealthTone.healthy,
            metrics: {
              'Active lots': '$lotCount',
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

  void setInstructionStatus(String id, InstructionStatus status) {
    final index = _instructions.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _instructions[index] = _instructions[index].copyWith(status: status);
    notifyListeners();
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

  List<ClientInfo> get clients => List.unmodifiable(_clients);

  void addClient(ClientInfo client) {
    _clients.insert(0, client);
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // WORKSHOP: LOTS & SCANNER
  // -----------------------------------------------------------------
  List<WorkshopLot> get lots => List.unmodifiable(_lots);
  List<ApiStage> get stages => List.unmodifiable(_stages);
  List<WorkshopLot> get recentScans => List.unmodifiable(_recentScans);

  void allocateLotArtisan(String lotId, String artisanName) {
    final idx = _lots.indexWhere((l) => l.id == lotId);
    if (idx != -1) {
      _lots[idx] = _lots[idx].copyWith(
        assignedEmployee: artisanName,
        lastUpdatedTime: 'Just now',
      );
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
        assignedEmployee: assignedEmployee,
        lastUpdatedTime: 'Just now',
        tone: newStage == WorkshopStage.readyForDispatch
            ? HealthTone.healthy
            : _lots[index].tone,
      );
      _lots[index] = updated;
      recordScan(updated);
      notifyListeners();
    }
  }

  void advanceLotStage(String lotId) {
    final index = _lots.indexWhere((l) => l.id == lotId);
    if (index >= 0) {
      final currentStage = _lots[index].stage;
      final nextIndex = currentStage.index + 1;
      if (nextIndex < WorkshopStage.values.length) {
        final newStage = WorkshopStage.values[nextIndex];
        _lots[index] = _lots[index].copyWith(
          stage: newStage,
          lastUpdatedTime: 'Just now',
          tone: newStage == WorkshopStage.readyForDispatch
              ? HealthTone.healthy
              : _lots[index].tone,
        );
        recordScan(_lots[index]);
        notifyListeners();
      }
    }
  }

  void assignLotToEmployee(String lotId, String employeeName, String role) {
    final index = _lots.indexWhere((l) => l.id == lotId);
    if (index >= 0) {
      _lots[index] = _lots[index].copyWith(
        assignedEmployee: employeeName,
        assignedEmployeeRole: role,
        lastUpdatedTime: 'Just now',
      );
      recordScan(_lots[index]);
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
    final index = _cadTasks.indexWhere((t) => t.id == taskId);
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
    _orders
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  void setClients(List<ClientInfo> clients) {
    _clients
      ..clear()
      ..addAll(clients);
    notifyListeners();
  }

  void setLots(List<WorkshopLot> lots) {
    _lots
      ..clear()
      ..addAll(lots);
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
