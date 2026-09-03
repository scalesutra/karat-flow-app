import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../core/widgets/common_3d_viewer.dart';
import '../../data/demo_store.dart';
import '../../data/models/api_models.dart';
import '../../data/mappers/api_domain_mapper.dart';
import '../../domain/models.dart';
import '../admin/widgets/add_artisan_sheet.dart';
import 'bloc/workshop_bloc.dart';

class StageOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const StageOverviewScreen({super.key, required this.orderData});

  @override
  State<StageOverviewScreen> createState() => _StageOverviewScreenState();
}

class _StageOverviewScreenState extends State<StageOverviewScreen> {
  WorkshopStage? _selectedStageFilter;
  final Map<String, bool> _expandedItems = {};

  late final String _orderId;
  late final String _apiOrderId;
  late final String _title;
  late final String _client;
  late final String _artisan;
  late final String _purity;
  late final bool _allowStageChange;
  late List<ParentJewelleryItem> _parentItems;
  bool _requestedLiveData = false;

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderData['id'] as String? ?? '';
    _apiOrderId = widget.orderData['apiId'] as String? ?? '';
    _title = widget.orderData['title'] as String? ?? '';
    _client = widget.orderData['client'] as String? ?? '';
    _artisan = widget.orderData['artisan'] as String? ?? '';
    _purity = widget.orderData['purity'] as String? ?? '';
    _allowStageChange = widget.orderData['allowStageChange'] as bool? ?? false;

    // Generate or query parts and group them by jewellery items
    _parentItems = _getParentItems();

    // Default to expand all items
    for (var item in _parentItems) {
      _expandedItems[item.code] = true;
    }
    DemoStore.instance.addListener(_onStoreChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLiveData) return;
    _requestedLiveData = true;
    context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final refreshedItems = _getParentItems();
    for (final item in refreshedItems) {
      _expandedItems.putIfAbsent(item.code, () => true);
    }
    setState(() => _parentItems = refreshedItems);
  }

  @override
  void dispose() {
    DemoStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  String? _livePartId(JewelleryPart part) {
    final pCodeLower = part.code.toLowerCase();
    final pNameLower = part.name.toLowerCase();

    // 1. Search raw order parts inside widget.orderData['parts'] or widget.orderData['orderParts']
    final rawParts =
        widget.orderData['parts'] ?? widget.orderData['orderParts'];
    if (rawParts is List && rawParts.isNotEmpty) {
      for (final p in rawParts) {
        if (p is Map) {
          final pid = p['id'] as String? ?? '';
          final dNum = (p['designNumber'] as String? ?? '').toLowerCase();
          final pName = (p['name'] as String? ?? '').toLowerCase();
          final sId = (p['sketchId'] as String? ?? '').toLowerCase();
          final tId = (p['threeDDesignId'] as String? ?? '').toLowerCase();

          final matches =
              pid == part.code ||
              (dNum.isNotEmpty && dNum == pCodeLower) ||
              (pName.isNotEmpty && pName == pNameLower) ||
              (sId.isNotEmpty && sId == pCodeLower) ||
              (tId.isNotEmpty && tId == pCodeLower);

          if (matches &&
              pid.length > 20 &&
              pid.contains('-') &&
              !pid.toUpperCase().startsWith('ORD-')) {
            return pid;
          }
        }
      }
    }

    // 2. Match API lots from DemoStore belonging to this order/part.
    for (final lot in DemoStore.instance.lots) {
      final matchesOrder =
          lot.orderId == _orderId ||
          (_apiOrderId.isNotEmpty && lot.orderId == _apiOrderId);
      final matchesPart =
          lot.id.toLowerCase() == pCodeLower ||
          (matchesOrder &&
              (lot.designCode.toLowerCase() == pCodeLower ||
                  lot.productTitle.toLowerCase() == pNameLower));
      if (matchesPart) {
        if (lot.id.length > 20 &&
            lot.id.contains('-') &&
            !lot.id.toUpperCase().startsWith('ORD-')) {
          return lot.id;
        }
      }
    }

    // 3. Direct API part ID from payload
    final directPartId =
        widget.orderData['orderPartId'] as String? ??
        widget.orderData['partId'] as String? ??
        widget.orderData['livePartId'] as String? ??
        '';
    if (directPartId.length > 20 &&
        directPartId.contains('-') &&
        !directPartId.toUpperCase().startsWith('ORD-')) {
      return directPartId;
    }

    // 4. Direct part UUID from part.code if nothing else matched
    if (part.code.length > 20 &&
        part.code.contains('-') &&
        !part.code.toUpperCase().startsWith('ORD-')) {
      return part.code;
    }

    return null;
  }

  void _assignLivePart(
    BuildContext context,
    JewelleryPart part,
    String workerName,
  ) {
    final partId = _livePartId(part);
    final selectedMember = DemoStore.instance.team
        .where(
          (worker) =>
              worker.name.trim().toLowerCase() ==
                  workerName.trim().toLowerCase() ||
              worker.id == workerName,
        )
        .firstOrNull;
    final workerId = selectedMember?.id ?? workerName;
    final workerDisplayName = selectedMember?.name ?? workerName;

    final stages =
        DemoStore.instance.stages.where((stage) => stage.isActive).toList()
          ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

    if (partId == null || workerName.trim().isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Assignment Unavailable',
        message: 'Live part and artisan details are required.',
      );
      return;
    }

    if (part.blockerReason != null) {
      widget.orderData['isBlocked'] = false;
      widget.orderData['blockReason'] = null;
      widget.orderData['blockedReason'] = null;
      DemoStore.instance.toggleLotHold(partId, isBlocked: false);
      context.read<WorkshopBloc>().add(
        UnblockLotPartEvent(
          partId: partId,
          notes: 'Auto unblock on worker assignment',
        ),
      );
    }

    final sortedStages = List<ApiStage>.from(stages)
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

    final firstStage = sortedStages.isNotEmpty ? sortedStages.first : null;

    final currentStageMatches = sortedStages
        .where((stage) => _domainStage(stage) == part.stage)
        .toList();

    final targetStage =
        (part.stage == WorkshopStage.inQueue && firstStage != null)
        ? firstStage
        : (currentStageMatches.isNotEmpty
              ? currentStageMatches.first
              : (sortedStages
                        .where(
                          (stage) =>
                              _domainStage(stage).index >= part.stage.index,
                        )
                        .firstOrNull ??
                    firstStage));

    final String stageId = targetStage != null
        ? targetStage.id
        : (sortedStages.firstOrNull?.id ??
              'b467cd15-4845-4ba3-a30e-cbcc42809b76');

    context.read<WorkshopBloc>().add(
      AllocateLotArtisanEvent(
        lotId: partId,
        artisanName: workerDisplayName,
        artisanId: workerId,
        stageId: stageId,
      ),
    );

    final String oId =
        (widget.orderData['orderNumber'] as String?)?.isNotEmpty == true
        ? widget.orderData['orderNumber'] as String
        : ((widget.orderData['id'] as String?)?.isNotEmpty == true
              ? widget.orderData['id'] as String
              : 'ORD-${partId.length > 4 ? partId.substring(0, 4) : partId}');

    DemoStore.instance.createRequisitionForAssignment(
      designNumber: part.code.isNotEmpty ? part.code : part.name,
      orderId: oId,
      artisanName: workerDisplayName,
      stageName: targetStage != null ? targetStage.name : part.stage.label,
      quantity: part.pieces,
      grossWeight: part.weight,
    );
  }

  WorkshopStage _domainStage(ApiStage apiStage) {
    final byName = ApiDomainMapper.stage(apiStage.name);
    if (byName != WorkshopStage.inQueue ||
        apiStage.name.trim().toLowerCase().contains('queue')) {
      return byName;
    }
    final index = (apiStage.stageNumber - 1).clamp(
      0,
      WorkshopStage.values.length - 1,
    );
    return WorkshopStage.values[index.toInt()];
  }

  void _advanceLivePart(
    BuildContext context,
    JewelleryPart part, {
    int? quantity,
    String? nextWorkerName,
  }) {
    final nextIdx = part.stage.index + 1;
    final movingWholePart = quantity == null || quantity >= part.pieces;
    if (movingWholePart) {
      if (nextIdx < WorkshopStage.values.length) {
        final nextStage = WorkshopStage.values[nextIdx];
        widget.orderData['currentStageName'] = nextStage.label;
        widget.orderData['stage'] = nextStage.label;
      } else {
        widget.orderData['status'] = 'complete';
        widget.orderData['currentStageName'] = 'Completed';
        DemoStore.instance.updateOrderStatus(_orderId, OrderStatus.ready);
      }
    }

    final partId = _livePartId(part);
    if (partId == null) {
      CommonSnackbar.error(
        context,
        title: 'Part Not Found',
        message: 'Order part ID is required.',
      );
      return;
    }
    context.read<WorkshopBloc>().add(
      AdvanceLotStageEvent(partId, quantity: quantity),
    );

    if (nextWorkerName != null &&
        nextWorkerName.isNotEmpty &&
        nextWorkerName.toLowerCase() != 'unassigned') {
      final selectedMember = DemoStore.instance.team
          .where(
            (m) =>
                m.name.toLowerCase() == nextWorkerName.toLowerCase() ||
                m.id == nextWorkerName,
          )
          .firstOrNull;
      final workerId = selectedMember?.id ?? nextWorkerName;
      final workerDisplayName = selectedMember?.name ?? nextWorkerName;

      final stages =
          DemoStore.instance.stages.where((stage) => stage.isActive).toList()
            ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
      final nextStageIndex = (part.stage.index + 1).clamp(0, stages.length - 1);
      final targetStage = stages.isNotEmpty ? stages[nextStageIndex] : null;

      if (targetStage != null) {
        context.read<WorkshopBloc>().add(
          AllocateLotArtisanEvent(
            lotId: partId,
            artisanName: workerDisplayName,
            artisanId: workerId,
            stageId: targetStage.id,
          ),
        );
      }
    }
  }

  void _rollbackLivePart(
    BuildContext context,
    JewelleryPart part,
    WorkshopStage target, {
    int? quantity,
  }) {
    final partId = _livePartId(part);
    final stages = DemoStore.instance.stages.where(
      (stage) => _domainStage(stage) == target,
    );
    if (partId == null || stages.isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Rollback Unavailable',
        message: 'Live part and target stage IDs are required.',
      );
      return;
    }
    if (quantity == null || quantity >= part.pieces) {
      widget.orderData['currentStageName'] = target.label;
      widget.orderData['stage'] = target.label;
    }
    context.read<WorkshopBloc>().add(
      RollbackLotStageEvent(
        lotId: partId,
        targetStageId: stages.first.id,
        reason: 'Manual rollback from the KaratFlow mobile app',
        quantity: quantity,
      ),
    );
  }

  // Group and construct our pieces & sub-parts
  List<ParentJewelleryItem> _getParentItems() {
    final List<ParentJewelleryItem> items = [];

    final String statusStr = (widget.orderData['status'] as String? ?? '')
        .toLowerCase();
    final String stageStr = (widget.orderData['stage'] as String? ?? '')
        .toLowerCase();
    final bool isCompletedOrder =
        statusStr == 'complete' ||
        statusStr == 'completed' ||
        statusStr == 'ready' ||
        statusStr == 'delivered' ||
        stageStr == 'completed' ||
        stageStr == 'all_stages_completed';

    final bool isOrderExplicitlyUnblocked =
        widget.orderData['isBlocked'] == false ||
        (widget.orderData['isBlocked'] == null &&
            widget.orderData['blockReason'] == null &&
            widget.orderData['blockedReason'] == null);

    final rawId = widget.orderData['id'] as String? ?? '';
    final orderNum =
        widget.orderData['orderNumber'] as String? ??
        widget.orderData['code'] as String? ??
        '';
    final designNum =
        widget.orderData['designNumber'] as String? ??
        widget.orderData['designCode'] as String? ??
        '';

    final partIdParam =
        widget.orderData['orderPartId'] as String? ??
        widget.orderData['partId'] as String? ??
        widget.orderData['livePartId'] as String? ??
        '';
    final rawDesignRows = widget.orderData['designs'];
    final designRows = rawDesignRows is List
        ? rawDesignRows.cast<Map<String, Object?>>()
        : const <Map<String, Object?>>[];
    final partIds = designRows
        .map((row) => row['partId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final storeLots = DemoStore.instance.lots.where((l) {
      if (partIdParam.isNotEmpty && l.id == partIdParam) return true;
      if (partIds.contains(l.id)) return true;
      return l.orderId == _orderId ||
          (_apiOrderId.isNotEmpty && l.orderId == _apiOrderId) ||
          (rawId.isNotEmpty && l.orderId == rawId) ||
          (orderNum.isNotEmpty && l.orderId == orderNum);
    }).toList();

    if (storeLots.isNotEmpty) {
      final parts = storeLots.map((lot) {
        final matchedDesign = DemoStore.instance.designs
            .where(
              (d) =>
                  (lot.designCode.isNotEmpty &&
                      d.code.toLowerCase() == lot.designCode.toLowerCase()) ||
                  (d.id.isNotEmpty && d.id == lot.id) ||
                  (lot.productTitle.isNotEmpty &&
                      d.name.toLowerCase() == lot.productTitle.toLowerCase()),
            )
            .firstOrNull;

        final designTitle = (matchedDesign?.name.isNotEmpty == true)
            ? matchedDesign!.name
            : (lot.productTitle.isNotEmpty ? lot.productTitle : lot.designCode);

        final apiStageName = DemoStore.instance.stages
            .where((s) => _domainStage(s) == lot.stage)
            .firstOrNull
            ?.name;

        final isLotComplete =
            isCompletedOrder ||
            lot.apiStageName.toLowerCase() == 'completed' ||
            lot.apiStageName.toUpperCase() == 'ALL_STAGES_COMPLETED' ||
            lot.apiStageName.toUpperCase() == 'STAGE_COMPLETED' ||
            (lot.stage == WorkshopStage.readyForDispatch && isCompletedOrder);

        return JewelleryPart(
          name: designTitle,
          code: lot.designCode.isNotEmpty ? lot.designCode : lot.id,
          pieces: lot.pieces,
          passedPieces: lot.pieces,
          stage: lot.stage,
          stageName: apiStageName ?? lot.stage.label,
          assignedEmployee:
              ((lot.assignedEmployee.isEmpty ||
                  lot.assignedEmployee == 'Unassigned')
              ? _extractWorkerName(widget.orderData)
              : lot.assignedEmployee),
          blockerReason: isOrderExplicitlyUnblocked ? null : lot.blockerReason,
          weight: lot.issueWeightGrams,
          isCompleted: isLotComplete,
        );
      }).toList();

      items.add(
        ParentJewelleryItem(
          name: _title.isNotEmpty
              ? _title
              : (designNum.isNotEmpty ? designNum : 'Jewellery Order'),
          code: _orderId,
          category: _title.contains('Ring') ? 'Rings' : 'Necklace',
          parts: parts,
        ),
      );
      return items;
    }

    if (designRows.isNotEmpty) {
      final parts = designRows.map((row) {
        final dNumber = row['designNumber'] as String? ?? 'Jewellery Part';
        final pId = row['partId'] as String? ?? '';
        final rawTitle = row['title'] as String? ?? row['name'] as String?;
        final matchedDesign = DemoStore.instance.designs
            .where(
              (d) =>
                  (dNumber.isNotEmpty &&
                      d.code.toLowerCase() == dNumber.toLowerCase()) ||
                  (pId.isNotEmpty && d.id == pId),
            )
            .firstOrNull;
        final designTitle =
            rawTitle ??
            matchedDesign?.name ??
            (dNumber.isNotEmpty ? dNumber : 'Jewellery Item');

        final qty = (row['quantity'] as num?)?.toInt() ?? 1;
        final rawStg = row['stage'] as String? ?? '';
        final stg = rawStg.isNotEmpty
            ? ApiDomainMapper.stage(rawStg)
            : WorkshopStage.inQueue;
        final apiStageName = rawStg.isNotEmpty
            ? rawStg
            : DemoStore.instance.stages
                  .where((s) => _domainStage(s) == stg)
                  .firstOrNull
                  ?.name;
        final workerName = (row['artisan'] as String? ?? '').trim();
        final rowStatus =
            (row['orderPartStatus'] as String? ??
                    row['status'] as String? ??
                    '')
                .toUpperCase();

        final isRowComplete =
            isCompletedOrder ||
            rowStatus == 'STAGE_COMPLETED' ||
            rowStatus == 'COMPLETED' ||
            rawStg.toUpperCase() == 'ALL_STAGES_COMPLETED' ||
            (stg == WorkshopStage.readyForDispatch &&
                (statusStr == 'complete' || statusStr == 'completed'));

        return JewelleryPart(
          name: designTitle,
          code: dNumber.isNotEmpty ? dNumber : (pId.isNotEmpty ? pId : 'Part'),
          pieces: qty,
          passedPieces: qty,
          stage: stg,
          stageName: apiStageName ?? stg.label,
          assignedEmployee: workerName.isNotEmpty
              ? workerName
              : _extractWorkerName(widget.orderData),
          blockerReason: isOrderExplicitlyUnblocked
              ? null
              : row['blockReason'] as String?,
          weight: 0.0,
          isCompleted: isRowComplete,
        );
      }).toList();

      items.add(
        ParentJewelleryItem(
          name: _title.isNotEmpty
              ? _title
              : (designNum.isNotEmpty ? designNum : 'Jewellery Order'),
          code: _orderId,
          category: _title.contains('Ring') ? 'Rings' : 'Necklace',
          parts: parts,
        ),
      );
      return items;
    }

    final totalQty =
        (widget.orderData['itemsCount'] as num?)?.toInt() ??
        (widget.orderData['quantity'] as num?)?.toInt() ??
        (widget.orderData['pieces'] as num?)?.toInt() ??
        1;
    final rawStg =
        widget.orderData['currentStageName'] as String? ??
        widget.orderData['stage'] as String? ??
        '';
    final stg = rawStg.isNotEmpty
        ? ApiDomainMapper.stage(rawStg)
        : WorkshopStage.inQueue;
    final apiStageName = rawStg.isNotEmpty
        ? rawStg
        : DemoStore.instance.stages
              .where((s) => _domainStage(s) == stg)
              .firstOrNull
              ?.name;

    final rawAssignments = widget.orderData['assignments'];
    bool hasCompletedAssignment = false;
    String? assignmentFailureReason;

    if (rawAssignments is List && rawAssignments.isNotEmpty) {
      for (final a in rawAssignments) {
        if (a is Map) {
          final st = (a['status'] as String? ?? '').toUpperCase();
          if (st == 'COMPLETED' || st == 'PASSED' || a['completedAt'] != null) {
            hasCompletedAssignment = true;
          }
          if (st == 'FAILED' &&
              a['failureReason'] != null &&
              !isOrderExplicitlyUnblocked) {
            assignmentFailureReason = a['failureReason'] as String;
          }
        }
      }
    }

    final isOrderComplete =
        isCompletedOrder ||
        (widget.orderData['status'] as String? ?? '').toLowerCase() ==
            'complete' ||
        (widget.orderData['status'] as String? ?? '').toLowerCase() ==
            'completed' ||
        (widget.orderData['status'] as String? ?? '').toLowerCase() ==
            'delivered';

    final singlePart = JewelleryPart(
      name: _title.isNotEmpty ? _title : 'Jewellery Item',
      code: designNum.isNotEmpty
          ? designNum
          : (_orderId.isNotEmpty ? _orderId : 'Part-1'),
      pieces: totalQty,
      passedPieces: totalQty,
      stage: stg,
      stageName: apiStageName ?? stg.label,
      assignedEmployee: _extractWorkerName(widget.orderData),
      blockerReason: isOrderExplicitlyUnblocked
          ? null
          : (assignmentFailureReason ??
                widget.orderData['blockReason'] as String? ??
                widget.orderData['blockedReason'] as String?),
      weight: (widget.orderData['grossWeight'] as num?)?.toDouble() ?? 0.0,
      isCompleted: isOrderComplete,
    );

    items.add(
      ParentJewelleryItem(
        name: _title.isNotEmpty ? _title : 'Jewellery Order',
        code: _orderId,
        category: _title.contains('Ring') ? 'Rings' : 'Necklace',
        parts: [singlePart],
      ),
    );

    return items;
  }

  String _extractWorkerName(Map<String, dynamic> data) {
    // 0. Check live API 'assignments' array
    final rawAssignments = data['assignments'];
    if (rawAssignments is List && rawAssignments.isNotEmpty) {
      final lastAssign = rawAssignments.last;
      if (lastAssign is Map) {
        final emp = lastAssign['assignedEmployee'];
        if (emp is Map) {
          final empName =
              emp['name'] as String? ?? emp['fullName'] as String? ?? '';
          if (empName.isNotEmpty) return empName;
        } else if (emp is String && emp.isNotEmpty) {
          return emp;
        }
      }
    }

    final empObj = data['assignedEmployee'];
    if (empObj is Map) {
      final empName =
          empObj['name'] as String? ?? empObj['fullName'] as String? ?? '';
      if (empName.isNotEmpty) return empName;
    }

    final direct =
        data['assignedEmployee'] as String? ?? data['artisan'] as String? ?? '';
    if (direct.isNotEmpty && direct.toLowerCase() != 'unassigned') {
      return direct;
    }

    final notes =
        data['notes'] as String? ?? data['instructions'] as String? ?? '';
    if (notes.contains('Assigned to ')) {
      final idx = notes.indexOf('Assigned to ');
      final extracted = notes.substring(idx + 'Assigned to '.length).trim();
      final clean = extracted.contains(':')
          ? extracted.substring(0, extracted.indexOf(':')).trim()
          : (extracted.contains('\n')
                ? extracted.substring(0, extracted.indexOf('\n')).trim()
                : extracted);
      if (clean.isNotEmpty) return clean;
    }

    for (final member in DemoStore.instance.team) {
      if (notes.toLowerCase().contains(member.name.toLowerCase())) {
        return member.name;
      }
    }

    final id = data['id'] as String? ?? '';
    final code =
        data['designNumber'] as String? ?? data['designCode'] as String? ?? '';
    final storeMatch = DemoStore.instance.lots
        .where(
          (l) =>
              (id.isNotEmpty && l.id == id) ||
              (code.isNotEmpty && l.designCode == code),
        )
        .firstOrNull;
    if (storeMatch != null &&
        storeMatch.assignedEmployee.isNotEmpty &&
        storeMatch.assignedEmployee != 'Unassigned') {
      return storeMatch.assignedEmployee;
    }

    return 'Unassigned';
  }

  bool _isWorkerSkillMatch(TeamMember member, String stageName) {
    final stageLower = stageName.trim().toLowerCase();
    final craftLower = member.craft.toLowerCase();
    final roleLower = member.shift.toLowerCase();

    if (stageLower.contains('wax') &&
        (craftLower.contains('wax') || roleLower.contains('wax'))) {
      return true;
    }
    if (stageLower.contains('filing') &&
        (craftLower.contains('fil') ||
            roleLower.contains('fil') ||
            craftLower.contains('gold'))) {
      return true;
    }
    if (stageLower.contains('cast') &&
        (craftLower.contains('cast') || roleLower.contains('cast'))) {
      return true;
    }
    if (stageLower.contains('polish') &&
        (craftLower.contains('polish') ||
            roleLower.contains('polish') ||
            craftLower.contains('buff'))) {
      return true;
    }
    if ((stageLower.contains('qc') || stageLower.contains('quality')) &&
        (craftLower.contains('qual') ||
            craftLower.contains('qc') ||
            roleLower.contains('qual') ||
            roleLower.contains('qc'))) {
      return true;
    }
    if (stageLower.contains('pack') &&
        (craftLower.contains('pack') ||
            roleLower.contains('pack') ||
            craftLower.contains('dispatch'))) {
      return true;
    }
    if (stageLower.contains('set') &&
        (craftLower.contains('set') ||
            roleLower.contains('set') ||
            craftLower.contains('stone') ||
            craftLower.contains('diamond'))) {
      return true;
    }
    return false;
  }

  List<TeamMember> _getCraftWorkersForStage(String stageName) {
    final all = DemoStore.instance.team;

    // 1. Filter: workshop craftsmen only (exclude non-craftsman management roles)
    final craftsmen = all.where((m) {
      final roleUpper = m.shift.toUpperCase();
      final craftLower = m.craft.toLowerCase();

      final isNonWorkshop =
          roleUpper == 'ADMIN' ||
          roleUpper == 'PRODUCTION_MANAGER' ||
          roleUpper == 'PROCESS_MANAGER' ||
          roleUpper == 'FRONTIER' ||
          roleUpper == 'FRONT_OFFICE' ||
          roleUpper == 'THREE_D_DESIGNER' ||
          roleUpper == 'RAW_SKETCHER' ||
          craftLower.contains('manager') ||
          craftLower.contains('admin') ||
          craftLower.contains('sales') ||
          craftLower.contains('sketcher') ||
          craftLower.contains('cad');

      return !isNonWorkshop;
    }).toList();

    final pool = craftsmen.isNotEmpty ? craftsmen : all;

    // 2. Sort by skill match for stage
    final matchingSkill = <TeamMember>[];
    final otherCraftsmen = <TeamMember>[];

    for (final m in pool) {
      if (_isWorkerSkillMatch(m, stageName)) {
        matchingSkill.add(m);
      } else {
        otherCraftsmen.add(m);
      }
    }

    return [...matchingSkill, ...otherCraftsmen];
  }

  Future<void> _showAssignArtisanModal(
    BuildContext context,
    JewelleryPart part,
  ) async {
    var workers = DemoStore.instance.team;
    if (workers.isEmpty) {
      try {
        final apiEmployees = await KaratFlowApiRepository().listEmployees();
        final team = apiEmployees.map(ApiDomainMapper.employee).toList();
        if (team.isNotEmpty) {
          DemoStore.instance.setTeam(team);
          workers = team;
        }
      } catch (e) {
        debugPrint('Could not fetch employees directly: $e');
      }
    }
    if (workers.isEmpty) {
      if (!context.mounted) return;
      final workshopBloc = context.read<WorkshopBloc>();
      final refresh = workshopBloc.stream.firstWhere(
        (state) => state is WorkshopLoaded || state is WorkshopError,
      );
      workshopBloc.add(const FetchWorkshopLotsEvent());
      try {
        await refresh.timeout(const Duration(seconds: 15));
      } on TimeoutException {
        if (!context.mounted) return;
        CommonSnackbar.error(
          context,
          title: 'Workers unavailable',
          message: 'Employees API did not respond. Please try again.',
        );
        return;
      }
      if (!context.mounted) return;
      workers = DemoStore.instance.team;
    }
    if (workers.isEmpty) {
      if (!context.mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Workers unavailable',
        message: 'No workers were returned by the employees API.',
      );
      return;
    }

    final stages = DemoStore.instance.stages.where((s) => s.isActive).toList()
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
    final currentStageName =
        (part.stage == WorkshopStage.inQueue && stages.isNotEmpty)
        ? stages.first.name
        : part.stage.label;

    final craftWorkers = _getCraftWorkersForStage(currentStageName);
    if (craftWorkers.isNotEmpty) {
      workers = craftWorkers;
    }

    String selectedWorker =
        (part.assignedEmployee != null &&
            part.assignedEmployee!.isNotEmpty &&
            part.assignedEmployee != 'Unassigned')
        ? part.assignedEmployee!
        : workers.first.name;
    int selectedQuantity = part.pieces;
    final TextEditingController quantityController = TextEditingController(
      text: '$selectedQuantity',
    );

    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Assign Worker & Set Quantity · ${part.code}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${part.name} · Total ${part.pieces} Pcs',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity Selector with Manual Input matching Next Stage Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assign Quantity (Pieces):',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          Text(
                            'Allocated to selected artisan',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (selectedQuantity > 1) {
                                setModalState(() {
                                  selectedQuantity--;
                                  quantityController.text = '$selectedQuantity';
                                  quantityController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: quantityController.text.length,
                                    ),
                                  );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.emeraldDark,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.emerald,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val.isEmpty) {
                                  setModalState(() {
                                    selectedQuantity = 1;
                                  });
                                  return;
                                }
                                int parsed = int.tryParse(val.trim()) ?? 1;
                                if (parsed > part.pieces) {
                                  parsed = part.pieces;
                                  quantityController.text = '${part.pieces}';
                                  quantityController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: quantityController.text.length,
                                    ),
                                  );
                                } else if (parsed < 1) {
                                  parsed = 1;
                                  quantityController.text = '1';
                                  quantityController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: quantityController.text.length,
                                    ),
                                  );
                                }
                                setModalState(() {
                                  selectedQuantity = parsed;
                                });
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (selectedQuantity < part.pieces) {
                                setModalState(() {
                                  selectedQuantity++;
                                  quantityController.text = '$selectedQuantity';
                                  quantityController
                                      .selection = TextSelection.fromPosition(
                                    TextPosition(
                                      offset: quantityController.text.length,
                                    ),
                                  );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Artisan:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                      if (DemoStore.instance.activeRole == AppRole.admin)
                        InkWell(
                          onTap: () async {
                            final newMember = await AddArtisanSheet.show(
                              context,
                              DemoStore.instance,
                            );
                            if (newMember != null) {
                              setModalState(() {
                                selectedWorker = newMember.name;
                              });
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 14,
                                color: AppColors.emeraldDark,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '+ New Artisan',
                                style: TextStyle(
                                  color: AppColors.emeraldDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: workers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = workers[index];
                        final isSelected = member.name == selectedWorker;
                        final isSkillMatch = _isWorkerSkillMatch(
                          member,
                          currentStageName,
                        );
                        return InkWell(
                          onTap: () =>
                              setModalState(() => selectedWorker = member.name),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emeraldLight
                                  : AppColors.paper,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.emerald
                                    : AppColors.outline,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected
                                      ? AppColors.emerald
                                      : AppColors.emerald.withValues(
                                          alpha: 0.15,
                                        ),
                                  child: Text(
                                    member.name.isNotEmpty
                                        ? member.name[0].toUpperCase()
                                        : 'A',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.pureWhite
                                          : AppColors.emerald,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            member.name,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                              fontSize: 12,
                                              color: isSelected
                                                  ? AppColors.emeraldDark
                                                  : AppColors.ink,
                                            ),
                                          ),
                                          if (isSkillMatch) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.emerald,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'SKILL MATCH',
                                                style: TextStyle(
                                                  color: AppColors.pureWhite,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        member.craft.isNotEmpty
                                            ? member.craft
                                            : 'Workshop Craftsman',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.emerald,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CommonButton.primary(
                    label: 'Confirm Assignment',
                    onPressed: () {
                      _assignLivePart(context, part, selectedWorker);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStageCompletionModal(BuildContext context, JewelleryPart part) {
    int totalPcs = part.pieces;
    int passedPcs = part.passedPieces > 0 ? part.passedPieces : totalPcs;
    int defectivePcs = totalPcs - passedPcs;
    final passedController = TextEditingController(text: '$passedPcs');

    final values = WorkshopStage.values;
    final currentIdx = values.indexOf(part.stage);
    final nextStageLabel = (currentIdx < values.length - 1)
        ? values[currentIdx + 1].label
        : '';
    final nextCraftWorkers = _getCraftWorkersForStage(nextStageLabel);
    final workers = nextCraftWorkers.isNotEmpty
        ? nextCraftWorkers
        : DemoStore.instance.team;

    String selectedNextWorker =
        (part.assignedEmployee != null &&
            part.assignedEmployee!.isNotEmpty &&
            part.assignedEmployee != 'Unassigned')
        ? part.assignedEmployee!
        : (workers.isNotEmpty ? workers.first.name : '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Complete Stage & Log Defective Pieces',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${part.name} (${part.code}) · Total $totalPcs Pcs',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Passed Pieces counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Passed Pieces (Next Stage):',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                          const Text(
                            'Moves to next stage',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (passedPcs > 0) {
                                setModalState(() {
                                  passedPcs--;
                                  defectivePcs = totalPcs - passedPcs;
                                  passedController.text = '$passedPcs';
                                  passedController.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(
                                          offset: passedController.text.length,
                                        ),
                                      );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              controller: passedController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.emeraldDark,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.emerald,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                if (val.isEmpty) {
                                  setModalState(() {
                                    passedPcs = 0;
                                    defectivePcs = totalPcs;
                                  });
                                  return;
                                }
                                int parsed = int.tryParse(val) ?? 0;
                                if (parsed > totalPcs) {
                                  parsed = totalPcs;
                                  passedController.text = '$totalPcs';
                                  passedController.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(
                                          offset: passedController.text.length,
                                        ),
                                      );
                                } else if (parsed < 0) {
                                  parsed = 0;
                                  passedController.text = '0';
                                  passedController.selection =
                                      TextSelection.fromPosition(
                                        const TextPosition(offset: 1),
                                      );
                                }
                                setModalState(() {
                                  passedPcs = parsed;
                                  defectivePcs = totalPcs - passedPcs;
                                });
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (passedPcs < totalPcs) {
                                setModalState(() {
                                  passedPcs++;
                                  defectivePcs = totalPcs - passedPcs;
                                  passedController.text = '$passedPcs';
                                  passedController.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(
                                          offset: passedController.text.length,
                                        ),
                                      );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Defective Pieces display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Defective / Broken Pieces:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                          const Text(
                            'Sent back to In-Queue for Recasting',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '$defectivePcs pcs',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Next Stage Artisan Selector
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assign Next Stage To (Artisan):',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                      if (DemoStore.instance.activeRole == AppRole.admin)
                        InkWell(
                          onTap: () async {
                            final newMember = await AddArtisanSheet.show(
                              context,
                              DemoStore.instance,
                            );
                            if (newMember != null) {
                              setModalState(() {
                                selectedNextWorker = newMember.name;
                              });
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 14,
                                color: AppColors.emeraldDark,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add Artisan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: workers.length,
                      itemBuilder: (ctx, i) {
                        final member = workers[i];
                        final isSelected = member.name == selectedNextWorker;
                        final isSkillMatch = _isWorkerSkillMatch(
                          member,
                          nextStageLabel,
                        );
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedNextWorker = member.name;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.emerald.withValues(alpha: 0.08)
                                  : AppColors.canvas,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.emerald
                                    : AppColors.outline,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isSelected
                                      ? AppColors.emerald
                                      : AppColors.outline,
                                  child: Text(
                                    member.name.isNotEmpty
                                        ? member.name[0].toUpperCase()
                                        : 'A',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.pureWhite
                                          : AppColors.ink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            member.name,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.emeraldDark
                                                  : AppColors.ink,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (isSkillMatch) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.emerald,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: const Text(
                                                'SKILL MATCH',
                                                style: TextStyle(
                                                  color: AppColors.pureWhite,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        member.craft.isNotEmpty
                                            ? member.craft
                                            : 'Workshop Craftsman',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.emerald,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  Builder(
                    builder: (context) {
                      final values = WorkshopStage.values;
                      final currentIdx = values.indexOf(part.stage);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentIdx < values.length - 1)
                            CommonButton.primary(
                              label:
                                  (currentIdx == values.length - 2 ||
                                      values[currentIdx + 1] ==
                                          WorkshopStage.readyForDispatch)
                                  ? 'Complete Order / Dispatch ($passedPcs Pcs) ✅'
                                  : 'Move $passedPcs Pcs to Next Stage (${values[currentIdx + 1].label}) →',
                              onPressed: () {
                                final nextStage = values[currentIdx + 1];
                                final partId = _livePartId(part);

                                if (partId != null) {
                                  if (passedPcs > 0) {
                                    _advanceLivePart(
                                      context,
                                      part,
                                      quantity: passedPcs,
                                      nextWorkerName: selectedNextWorker,
                                    );
                                  }
                                  if (passedPcs >= totalPcs &&
                                      nextStage ==
                                          WorkshopStage.readyForDispatch) {
                                    widget.orderData['status'] = 'complete';
                                    DemoStore.instance.updateOrderStatus(
                                      _orderId,
                                      OrderStatus.ready,
                                    );
                                  }
                                }

                                Navigator.pop(ctx);
                                setState(() {
                                  _parentItems = _getParentItems();
                                });
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    content: Text(
                                      defectivePcs > 0
                                          ? 'Moved $passedPcs pcs → ${nextStage.label} (Assigned to $selectedNextWorker). $defectivePcs pcs remaining in ${part.stage.label}!'
                                          : 'Moved $passedPcs pcs → ${nextStage.label} (Assigned to $selectedNextWorker)!',
                                    ),
                                    backgroundColor: AppColors.emerald,
                                  ),
                                );
                              },
                            ),
                          if (DemoStore.instance.activeRole ==
                              AppRole.processManager) ...[
                            const SizedBox(height: 10),
                            CommonButton.outlined(
                              label: '↺ Move Back to Any Previous Stage',
                              onPressed: () {
                                Navigator.pop(ctx);
                                _movePartBackStage(context, part);
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _movePartBackStage(BuildContext context, JewelleryPart part) {
    final values = WorkshopStage.values;
    final currentIdx = values.indexOf(part.stage);

    if (currentIdx <= 0) {
      CommonSnackbar.error(
        context,
        title: 'Cannot Move Back',
        message:
            '${part.name} is already at the initial stage (${part.stage.label}).',
      );
      return;
    }

    // Get all previous stages (including In Queue)
    final previousStages = values.sublist(0, currentIdx);
    int selectedPieces = part.pieces;
    final int totalPcs = part.pieces;
    final TextEditingController backPiecesController = TextEditingController(
      text: '$selectedPieces',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Move Back to Which Stage?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${part.name} (${part.code}) · Currently at ${part.stage.label}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Pieces Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pieces to Move Back:',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Total: $totalPcs pieces',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (selectedPieces > 1) {
                                  setModalState(() {
                                    selectedPieces--;
                                    backPiecesController.text =
                                        '$selectedPieces';
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: SizedBox(
                                width: 54,
                                height: 34,
                                child: TextField(
                                  controller: backPiecesController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: AppColors.ink,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.emerald,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val.trim().isEmpty) {
                                      setModalState(() {
                                        selectedPieces = 1;
                                      });
                                      return;
                                    }
                                    int parsed = int.tryParse(val.trim()) ?? 1;
                                    if (parsed > totalPcs) {
                                      parsed = totalPcs;
                                      backPiecesController.text = '$totalPcs';
                                      backPiecesController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset: backPiecesController
                                                  .text
                                                  .length,
                                            ),
                                          );
                                    } else if (parsed < 1) {
                                      parsed = 1;
                                      backPiecesController.text = '1';
                                      backPiecesController.selection =
                                          TextSelection.fromPosition(
                                            const TextPosition(offset: 1),
                                          );
                                    }
                                    setModalState(() {
                                      selectedPieces = parsed;
                                    });
                                  },
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                if (selectedPieces < totalPcs) {
                                  setModalState(() {
                                    selectedPieces++;
                                    backPiecesController.text =
                                        '$selectedPieces';
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Select Target Stage:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: previousStages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        // Show stages in reverse order (nearest first)
                        final stage =
                            previousStages[previousStages.length - 1 - index];
                        final stageIdx = values.indexOf(stage);
                        final stepsBack = currentIdx - stageIdx;

                        return InkWell(
                          onTap: () {
                            _rollbackLivePart(
                              context,
                              part,
                              stage,
                              quantity: selectedPieces,
                            );

                            Navigator.pop(ctx);
                            setState(() {
                              _parentItems = _getParentItems();
                            });

                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Moved $selectedPieces pcs of ${part.name} ↺ back to ${stage.label}',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: stepsBack == 1
                                  ? AppColors.warning.withValues(alpha: 0.08)
                                  : AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: stepsBack == 1
                                    ? AppColors.warning.withValues(alpha: 0.4)
                                    : AppColors.outlineLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getStageColor(
                                      stage,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getStageIcon(stage),
                                    size: 18,
                                    color: _getStageColor(stage),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stage.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      Text(
                                        '$stepsBack stage${stepsBack > 1 ? 's' : ''} back',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$selectedPieces pcs →',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.warning,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBlockReasonModal(BuildContext context, JewelleryPart part) {
    final TextEditingController reasonController = TextEditingController();
    final List<String> commonReasons = [
      'Missing stones / diamonds',
      'Casting porosity / surface defect',
      'Client size or spec revision request',
      'Gold karat assay mismatch',
      'Laser / sprue machine breakdown',
      'Excessive metal loss during filing',
    ];
    String selectedReason = commonReasons.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pause_circle_filled_rounded,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CommonText.headlineMedium(
                          'Put Stage On Hold / Block',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${part.name} (${part.code}) · Stage: ${part.stage.label}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const CommonText.bodySmall(
                'Select reason for stopping work on this stage:',
                color: AppColors.muted,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: commonReasons.map((r) {
                  final isSel = selectedReason == r;
                  return InkWell(
                    onTap: () {
                      setModalState(() {
                        selectedReason = r;
                        reasonController.text = r;
                      });
                    },
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.danger : AppColors.canvas,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(
                          color: isSel
                              ? AppColors.danger
                              : AppColors.outlineLight,
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? AppColors.pureWhite : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                controller: reasonController,
                label: 'Custom Explanation / Artisan Note',
                hintText: selectedReason,
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: CommonButton.outlined(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CommonButton.primary(
                      label: 'Confirm Block & Hold',
                      onPressed: () {
                        final reason = reasonController.text.trim().isNotEmpty
                            ? reasonController.text.trim()
                            : selectedReason;
                        if (reason.length < 3) {
                          CommonSnackbar.error(
                            context,
                            title: 'Reason required',
                            message:
                                'Please provide at least 3 characters for hold reason.',
                          );
                          return;
                        }
                        final partId = _livePartId(part);
                        if (partId != null) {
                          widget.orderData['isBlocked'] = true;
                          widget.orderData['blockReason'] = reason;
                          widget.orderData['blockedReason'] = reason;
                          DemoStore.instance.toggleLotHold(
                            partId,
                            isBlocked: true,
                            reason: reason,
                          );
                          context.read<WorkshopBloc>().add(
                            BlockLotPartEvent(partId: partId, reason: reason),
                          );
                        }
                        Navigator.pop(ctx);
                        setState(() {
                          _parentItems = _getParentItems();
                        });
                        CommonSnackbar.warning(
                          context,
                          title: 'Order Part Placed on Hold',
                          message: '${part.name} placed ON HOLD: $reason',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _unblockPart(BuildContext context, JewelleryPart part) {
    final partId = _livePartId(part);
    if (partId == null) {
      CommonSnackbar.error(
        context,
        title: 'Part Not Found',
        message: 'Order part ID is required.',
      );
      return;
    }

    widget.orderData['isBlocked'] = false;
    widget.orderData['status'] = 'IN_PRODUCTION';
    widget.orderData['blockReason'] = null;
    widget.orderData['blockedReason'] = null;

    final rawAssignments = widget.orderData['assignments'];
    if (rawAssignments is List) {
      for (final a in rawAssignments) {
        if (a is Map) {
          if ((a['status'] as String? ?? '').toUpperCase() == 'FAILED') {
            a['status'] = 'UNBLOCKED';
            a['failureReason'] = null;
          }
        }
      }
    }

    DemoStore.instance.toggleLotHold(partId, isBlocked: false);
    if (part.code.isNotEmpty) {
      DemoStore.instance.toggleLotHold(part.code, isBlocked: false);
    }
    if (part.name.isNotEmpty) {
      DemoStore.instance.toggleLotHold(part.name, isBlocked: false);
    }
    if (_orderId.isNotEmpty) {
      DemoStore.instance.toggleLotHold(_orderId, isBlocked: false);
    }

    context.read<WorkshopBloc>().add(
      UnblockLotPartEvent(
        partId: partId,
        notes: 'Unhold from KaratFlow mobile app',
      ),
    );

    setState(() {
      _parentItems = _getParentItems();
    });

    CommonSnackbar.success(
      context,
      title: 'Hold Released',
      message: 'Production resumed for ${part.name}.',
    );
  }

  int _getPiecesCountForStage(WorkshopStage stage) {
    int count = 0;
    for (var item in _parentItems) {
      for (var part in item.parts) {
        if (part.stage == stage && !part.isCompleted) {
          count += part.pieces;
        }
      }
    }
    return count;
  }

  IconData _getStageIcon(WorkshopStage stage) {
    return switch (stage) {
      WorkshopStage.inQueue => Icons.hourglass_top_outlined,
      WorkshopStage.cadAndWax => Icons.design_services_outlined,
      WorkshopStage.casting => Icons.local_fire_department_outlined,
      WorkshopStage.filingAndAssembly => Icons.build_circle_outlined,
      WorkshopStage.stoneSetting => Icons.diamond_outlined,
      WorkshopStage.polishing => Icons.brush_outlined,
      WorkshopStage.qualityCheck => Icons.assignment_turned_in_outlined,
      WorkshopStage.readyForDispatch => Icons.local_shipping_outlined,
    };
  }

  Color _getStageColor(WorkshopStage stage) {
    if (_selectedStageFilter == stage) {
      return AppColors.emerald;
    }
    return switch (stage) {
      WorkshopStage.inQueue => AppColors.warning,
      WorkshopStage.cadAndWax => AppColors.ink,
      WorkshopStage.casting => AppColors.gold,
      WorkshopStage.filingAndAssembly => AppColors.muted,
      WorkshopStage.stoneSetting => AppColors.warning,
      WorkshopStage.polishing => AppColors.emerald,
      WorkshopStage.qualityCheck => AppColors.success,
      WorkshopStage.readyForDispatch => AppColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CommonAppBar(
        showBrand: false,
        showBackButton: true,
        title: 'Stage Overview',
        subtitle:
            'Order ${ApiDomainMapper.formatOrderNumber(_orderId)} · $_client',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space20,
            vertical: AppDimensions.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Order Info Card
              _buildOrderInfoCard(),
              const SizedBox(height: 20),

              // 2. Production Stages Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CommonText.titleMedium('Production Stages'),
                  if (_selectedStageFilter != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedStageFilter = null),
                      child: const CommonText.labelSmall(
                        'Clear Filter',
                        color: AppColors.emerald,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Unique Expandable Stage List
              _buildStagesList(),
              const SizedBox(height: 24),

              // 4. Jewellery Items & Parts Section Header
              const CommonText.titleMedium('Jewellery Breakdown & Parts'),
              const SizedBox(height: 12),

              // 5. Parent items and breakdown
              _buildBreackdownList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showRevisionDialog(BuildContext context, CadDesignTask task) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, _) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.rate_review, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'Reject CAD & Request Revision',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request changes to 3D model ${task.designCode} (${task.productTitle}).',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              CommonTextField(
                controller: feedbackController,
                labelText: 'Revision Instructions',
                hintText:
                    'e.g., Thicken the prongs by 0.2mm and add diamond halo',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            CommonButton.primary(
              height: 38,
              backgroundColor: AppColors.danger,
              label: 'Submit Revision',
              onPressed: () {
                final text = feedbackController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter instructions')),
                  );
                  return;
                }
                Navigator.pop(context);
                CommonSnackbar.error(
                  context,
                  title: 'Revision API Unavailable',
                  message:
                      'The backend does not expose a CAD revision-request endpoint.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    final String statusStr = (widget.orderData['status'] as String? ?? '')
        .toLowerCase();
    final String stageStr = (widget.orderData['stage'] as String? ?? '')
        .toLowerCase();
    final bool hasUnfinishedParts = _parentItems.any(
      (item) => item.parts.any(
        (p) =>
            !p.isCompleted &&
            p.stage != WorkshopStage.readyForDispatch &&
            !p.stage.label.toLowerCase().contains('pack') &&
            !p.stage.label.toLowerCase().contains('dispatch'),
      ),
    );

    final bool isCompleted =
        !hasUnfinishedParts &&
        (statusStr == 'complete' ||
            statusStr == 'completed' ||
            statusStr == 'ready' ||
            statusStr == 'delivered' ||
            stageStr == 'completed' ||
            stageStr == 'all_stages_completed' ||
            (_parentItems.isNotEmpty &&
                _parentItems.every(
                  (item) => item.parts.every((p) => p.isCompleted),
                )));

    final hasBlockedPart = _parentItems.any(
      (item) => item.parts.any((p) => p.blockerReason != null),
    );

    final String displayStatus = isCompleted
        ? 'Completed'
        : (hasBlockedPart
              ? 'ON CRITICAL HOLD'
              : (stageStr.isNotEmpty
                    ? (widget.orderData['stage'] as String? ?? 'In Workshop')
                    : 'In Workshop'));

    final Color badgeColor = isCompleted
        ? AppColors.emerald
        : (hasBlockedPart ? AppColors.danger : AppColors.goldDark);
    final String badgeText = isCompleted
        ? 'Completed'
        : (hasBlockedPart ? 'ON HOLD' : 'IN PRODUCTION');

    return SlideInFade(
      child: CommonCard(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText.titleMedium(
                        _title,
                        fontWeight: FontWeight.w800,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      CommonText.bodySmall(
                        'Purity Details: $_purity',
                        color: AppColors.muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: CommonText.labelSmall(badgeText, color: badgeColor),
                ),
              ],
            ),
            const Divider(color: AppColors.outlineLight, height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoDetail(
                    'Manager / Artisan',
                    _liveArtisanName(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoDetail('Order Status', displayStatus),
                ),
              ],
            ),
            // CAD DESIGNER TASKS SYNC SECTION
            Builder(
              builder: (context) {
                final orderCadTasks = DemoStore.instance.cadTasks
                    .where((t) => t.orderId == _orderId)
                    .toList();
                if (orderCadTasks.isEmpty) return const SizedBox.shrink();

                final hasStl = orderCadTasks.any((t) => t.hasStlFile);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.outlineLight, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonText.labelSmall(
                              '3D CAD Designer Work',
                              color: AppColors.muted,
                            ),
                            SizedBox(height: 2),
                            CommonText.bodyMedium(
                              'Live CAD task',
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hasStl
                                ? AppColors.emeraldLight
                                : AppColors.goldLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasStl
                                  ? AppColors.emerald.withValues(alpha: 0.3)
                                  : AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasStl
                                    ? Icons.view_in_ar
                                    : Icons.pending_actions,
                                size: 12,
                                color: hasStl
                                    ? AppColors.emeraldDark
                                    : AppColors.goldDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasStl ? 'STL Models Ready' : 'CAD In Progress',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: hasStl
                                      ? AppColors.emeraldDark
                                      : AppColors.goldDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // List the individual CAD tasks for this order
                    ...orderCadTasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              task.hasStlFile
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 14,
                              color: task.hasStlFile
                                  ? AppColors.success
                                  : AppColors.subtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${task.designCode}: ${task.productTitle} (${task.status.label})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: task.hasStlFile
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: task.hasStlFile
                                      ? AppColors.ink
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                            if (task.hasStlFile) ...[
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => Common3DViewer(
                                      designCode: task.designCode,
                                      productTitle: task.productTitle,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.view_in_ar,
                                  size: 12,
                                  color: AppColors.emerald,
                                ),
                                label: const Text(
                                  'View 3D',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.emerald,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: AppColors.emeraldDark,
                                      content: Text(
                                        'Opening STL File: Downloading and viewing ${task.designCode.toLowerCase()}_v1.stl in 3D viewer...',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.pureWhite,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.download,
                                  size: 12,
                                  color: AppColors.emerald,
                                ),
                                label: const Text(
                                  'Get STL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.emerald,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (task.status != CadTaskStatus.completed) ...[
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  _showRevisionDialog(context, task);
                                },
                                icon: const Icon(
                                  Icons.rate_review_outlined,
                                  size: 12,
                                  color: AppColors.danger,
                                ),
                                label: const Text(
                                  'Revision',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText.labelSmall(label, color: AppColors.muted),
        const SizedBox(height: 2),
        CommonText.bodyMedium(value, fontWeight: FontWeight.bold),
      ],
    );
  }

  String _liveArtisanName() {
    if (_artisan.isNotEmpty) return _artisan;
    for (final item in _parentItems) {
      for (final part in item.parts) {
        final name = part.assignedEmployee?.trim() ?? '';
        if (name.isNotEmpty && name.toLowerCase() != 'unassigned') return name;
      }
    }
    return 'Unassigned';
  }

  Widget _buildStagesList() {
    final seen = <WorkshopStage>{};
    final apiStages = <ApiStage>[];
    for (final s in DemoStore.instance.stages) {
      final domain = _domainStage(s);
      if (seen.add(domain)) {
        apiStages.add(s);
      }
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apiStages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final apiStage = apiStages[index];
        final stage = _domainStage(apiStage);
        final count = _getPiecesCountForStage(stage);
        final isSelected = _selectedStageFilter == stage;
        final stageColor = _getStageColor(stage);

        // Check if worker task or orderPart is STAGE_COMPLETED or passed
        final rawOrderPartStatus =
            (widget.orderData['orderPartStatus'] as String? ??
                    widget.orderData['status'] as String? ??
                    '')
                .toUpperCase();

        final hasWorkerStageCompleted = DemoStore.instance.workerTasks.any((t) {
          final isDone =
              t.status.toUpperCase() == 'STAGE_COMPLETED' ||
              t.status.toUpperCase() == 'COMPLETED';
          if (!isDone) return false;

          final tStageName = t.stage.name.toLowerCase().trim();
          final targetStageName = apiStage.name.toLowerCase().trim();
          final matchesStage =
              tStageName.contains(targetStageName) ||
              targetStageName.contains(tStageName) ||
              (tStageName.contains('wax') && targetStageName.contains('wax')) ||
              (tStageName.contains('cast') &&
                  targetStageName.contains('cast')) ||
              (tStageName.contains('fil') && targetStageName.contains('fil')) ||
              (tStageName.contains('set') && targetStageName.contains('set')) ||
              (tStageName.contains('pol') && targetStageName.contains('pol'));
          if (!matchesStage) return false;

          final tPartId = t.orderPartId.trim().toUpperCase();
          final tOrderId = t.orderId.trim().toUpperCase();
          final tOrderNumber = t.orderPart.orderNumber.trim().toUpperCase();
          final tDesign = t.designNumber.trim().toUpperCase();
          final targetOrder = _orderId.trim().toUpperCase();

          final matchesOrder =
              targetOrder.isEmpty ||
              tPartId == targetOrder ||
              tOrderId == targetOrder ||
              tOrderNumber == targetOrder ||
              targetOrder.contains(tDesign) ||
              tDesign.contains(targetOrder) ||
              (tOrderNumber.isNotEmpty &&
                  (tOrderNumber.endsWith(targetOrder) ||
                      targetOrder.endsWith(tOrderNumber))) ||
              (tOrderId.isNotEmpty &&
                  (tOrderId.endsWith(targetOrder) ||
                      targetOrder.endsWith(tOrderId)));

          return matchesOrder;
        });

        final isStagePassed = _parentItems.any(
          (parent) => parent.parts.any(
            (p) => p.stage.index > stage.index || p.isCompleted,
          ),
        );

        final isCurrentStageCompleted =
            hasWorkerStageCompleted ||
            rawOrderPartStatus == 'STAGE_COMPLETED' ||
            _parentItems.any(
              (parent) => parent.parts.any(
                (p) =>
                    p.stage == stage &&
                    (hasWorkerStageCompleted ||
                        rawOrderPartStatus == 'STAGE_COMPLETED' ||
                        p.isCompleted),
              ),
            );

        final isStageDone = isStagePassed || isCurrentStageCompleted;

        // Find parts in this stage (or completed for this stage)
        final stageParts = <JewelleryPart>[];
        for (final parent in _parentItems) {
          for (final part in parent.parts) {
            if (part.stage == stage ||
                (isStageDone && part.stage.index >= stage.index)) {
              stageParts.add(part);
            }
          }
        }

        final hasBlockedParts = stageParts.any((p) => p.blockerReason != null);
        final blockedPartsCount = stageParts
            .where((p) => p.blockerReason != null)
            .length;

        return SlideInFade(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasBlockedParts
                    ? AppColors.danger
                    : (isStageDone
                          ? AppColors.emerald
                          : (isSelected
                                ? AppColors.emerald
                                : AppColors.outline)),
                width: hasBlockedParts || isSelected || isStageDone ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.06 : 0.02,
                  ),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_selectedStageFilter == stage) {
                        _selectedStageFilter = null;
                      } else {
                        _selectedStageFilter = stage;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: hasBlockedParts
                                ? AppColors.dangerLight
                                : (isStageDone
                                      ? AppColors.emeraldLight
                                      : stageColor.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasBlockedParts
                                ? Icons.pause_circle_filled_rounded
                                : (isStageDone
                                      ? Icons.check_circle_rounded
                                      : _getStageIcon(stage)),
                            size: 20,
                            color: hasBlockedParts
                                ? AppColors.danger
                                : (isStageDone
                                      ? AppColors.emeraldDark
                                      : stageColor),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      apiStage.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (isStageDone) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emeraldLight,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppColors.emerald.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        '✓ STAGE COMPLETED',
                                        style: TextStyle(
                                          color: AppColors.emeraldDark,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ] else if (hasBlockedParts) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'ON HOLD',
                                        style: TextStyle(
                                          color: AppColors.pureWhite,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasBlockedParts
                                    ? '⚠️ $blockedPartsCount part(s) blocked / on hold'
                                    : (isStageDone
                                          ? '✓ Stage work finished · Ready for next stage'
                                          : (count > 0
                                                ? '$count pieces in progress'
                                                : 'No active pieces')),
                                style: TextStyle(
                                  color: hasBlockedParts
                                      ? AppColors.danger
                                      : (isStageDone
                                            ? AppColors.emeraldDark
                                            : (count > 0
                                                  ? AppColors.emeraldDark
                                                  : AppColors.muted)),
                                  fontSize: 12,
                                  fontWeight: isStageDone || count > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isStageDone
                                ? AppColors.emeraldLight
                                : (isSelected
                                      ? AppColors.emerald
                                      : (hasBlockedParts
                                            ? AppColors.dangerLight
                                            : stageColor.withValues(
                                                alpha: 0.1,
                                              ))),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: Text(
                            isStageDone ? '✓ Done' : '$count Pcs',
                            style: TextStyle(
                              color: isStageDone
                                  ? AppColors.emeraldDark
                                  : (isSelected
                                        ? AppColors.pureWhite
                                        : (hasBlockedParts
                                              ? AppColors.danger
                                              : stageColor)),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Stage Detail List when selected
                if (isSelected) ...[
                  const Divider(height: 1, color: AppColors.outlineLight),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stage Parts & Artisan Details:',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (stageParts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No parts currently in this stage.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          for (final part in stageParts)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: part.blockerReason != null
                                        ? AppColors.danger.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppColors.outlineLight,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Code Badge + Title / Worker + Pieces/Weight
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.emeraldLight,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            part.code,
                                            style: const TextStyle(
                                              color: AppColors.emeraldDark,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                part.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Builder(
                                                builder: (context) {
                                                  final isWorkerDone =
                                                      part.isCompleted ||
                                                      isStageDone ||
                                                      hasWorkerStageCompleted ||
                                                      DemoStore.instance
                                                          .isWorkerTaskCompletedForPart(
                                                            part.code,
                                                            designNumber:
                                                                part.code,
                                                            stageName:
                                                                apiStage.name,
                                                            artisanName: part
                                                                .assignedEmployee,
                                                          );
                                                  if (isWorkerDone) {
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .emeraldLight,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .emerald
                                                              .withValues(
                                                                alpha: 0.4,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: AppColors
                                                                .emeraldDark,
                                                            size: 12,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            '${part.assignedEmployee ?? "Worker"} · WORK COMPLETED',
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .emeraldDark,
                                                              fontSize: 10.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                  return Text(
                                                    'Assigned: ${part.assignedEmployee ?? "Unassigned"}',
                                                    style: const TextStyle(
                                                      color: AppColors.muted,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${part.pieces} pcs${part.weight != null ? " · ${part.weight}g" : ""}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (part.defectivePieces > 0) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '⚠️ ${part.passedPieces} Passed · ${part.defectivePieces} Defective/Recast',
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],

                                    // Hold / Blocker Banner
                                    if (part.blockerReason != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.dangerLight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: AppColors.danger.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.pause_circle_filled_rounded,
                                              color: AppColors.danger,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'ON CRITICAL HOLD: ${part.blockerReason}',
                                                style: const TextStyle(
                                                  color: AppColors.danger,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (_allowStageChange ||
                                        DemoStore.instance.activeRole ==
                                            AppRole.processManager) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _showAssignArtisanModal(
                                                  context,
                                                  part,
                                                ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.emerald,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (part.assignedEmployee ==
                                                            null ||
                                                        part.assignedEmployee ==
                                                            'Unassigned' ||
                                                        part.assignedEmployee ==
                                                            'Unassigned (In Queue)')
                                                    ? '+ Assign Worker'
                                                    : '✏️ Reassign Worker',
                                                style: const TextStyle(
                                                  color: AppColors.pureWhite,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ],

                                    // Action Buttons Row (Below Text) - Only visible when _allowStageChange is true (Process Manager)
                                    if (_allowStageChange) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (part.blockerReason != null)
                                            InkWell(
                                              onTap: () =>
                                                  _unblockPart(context, part),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 9,
                                                      vertical: 4.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.emerald,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.play_arrow_rounded,
                                                      color:
                                                          AppColors.pureWhite,
                                                      size: 13,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Resume',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.pureWhite,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else ...[
                                            // Block Stage Button
                                            InkWell(
                                              onTap: () =>
                                                  _showBlockReasonModal(
                                                    context,
                                                    part,
                                                  ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.dangerLight,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: AppColors.danger
                                                        .withValues(alpha: 0.4),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.pause,
                                                      color: AppColors.danger,
                                                      size: 11,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Hold',
                                                      style: TextStyle(
                                                        color: AppColors.danger,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 10.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (WorkshopStage.values.indexOf(
                                                  part.stage,
                                                ) >
                                                0) ...[
                                              const SizedBox(width: 5),
                                              InkWell(
                                                onTap: () => _movePartBackStage(
                                                  context,
                                                  part,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warning
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors.warning
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.arrow_back,
                                                        color:
                                                            AppColors.warning,
                                                        size: 11,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        'Back',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.warning,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 10.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (part.stage !=
                                                WorkshopStage
                                                    .readyForDispatch) ...[
                                              const SizedBox(width: 5),
                                              InkWell(
                                                onTap: () =>
                                                    _showStageCompletionModal(
                                                      context,
                                                      part,
                                                    ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.ink,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Next Stage',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .pureWhite,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 10.5,
                                                        ),
                                                      ),
                                                      SizedBox(width: 2),
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color:
                                                            AppColors.pureWhite,
                                                        size: 10,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ] else ...[
                                              const SizedBox(width: 5),
                                              InkWell(
                                                onTap: () => _advanceLivePart(
                                                  context,
                                                  part,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.emerald,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color:
                                                            AppColors.pureWhite,
                                                        size: 11,
                                                      ),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'Complete Stage',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .pureWhite,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 10.5,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBreackdownList() {
    // Filter parts if there is a selected stage filter
    final filteredItems = _parentItems
        .map((item) {
          final matchingParts = item.parts.where((part) {
            if (_selectedStageFilter == null) return true;
            return part.stage == _selectedStageFilter;
          }).toList();

          return ParentJewelleryItem(
            name: item.name,
            code: item.code,
            category: item.category,
            parts: matchingParts,
          );
        })
        .where((item) => item.parts.isNotEmpty)
        .toList();

    if (filteredItems.isEmpty) {
      return const SlideInFade(
        child: CommonEmptyState(
          title: 'No Parts in Stage',
          description:
              'There are no jewellery parts currently in the selected workshop stage.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final isExpanded = _expandedItems[item.code] ?? false;

        return SlideInFade(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Tap to expand/collapse)
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedItems[item.code] = !isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusMedium),
                    bottom: isExpanded
                        ? Radius.zero
                        : Radius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                item.category == 'Necklace'
                                    ? Icons.diamond_outlined
                                    : item.category == 'Earrings'
                                    ? Icons.flare_outlined
                                    : item.category == 'Rings'
                                    ? Icons.trip_origin
                                    : Icons.auto_awesome_mosaic_outlined,
                                color: AppColors.emerald,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommonText.titleSmall(
                                      item.name,
                                      fontWeight: FontWeight.bold,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    CommonText.bodySmall(
                                      '${item.code} · ${item.parts.length} lots/parts in stage',
                                      color: AppColors.muted,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),

                if (isExpanded) ...[
                  const Divider(color: AppColors.outlineLight, height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: item.parts
                          .map((part) => _buildPartTile(part))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPartTile(JewelleryPart part) {
    final stageColor = _getStageColor(part.stage);
    final isBlocked = part.blockerReason != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: isBlocked
              ? AppColors.danger.withValues(alpha: 0.2)
              : AppColors.outlineLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText.bodyMedium(
                      part.name,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                    if (part.code.isNotEmpty &&
                        part.code.toLowerCase() != part.name.toLowerCase()) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Text(
                              'Design #${part.code}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: part.isCompleted
                      ? AppColors.emerald.withValues(alpha: 0.12)
                      : stageColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: part.isCompleted
                        ? AppColors.emerald.withValues(alpha: 0.4)
                        : stageColor.withValues(alpha: 0.3),
                  ),
                ),
                child: CommonText.bodySmall(
                  part.isCompleted
                      ? 'Completed'
                      : ((part.stageName != null && part.stageName!.isNotEmpty)
                            ? part.stageName!
                            : part.stage.label),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: part.isCompleted ? AppColors.emeraldDark : stageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pin_outlined,
                    size: 13,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  CommonText.bodySmall(
                    '${part.pieces} pcs',
                    color: AppColors.muted,
                  ),
                  if (part.weight != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.scale_outlined,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    CommonText.bodySmall(
                      '${part.weight!.toStringAsFixed(1)} g',
                      color: AppColors.muted,
                    ),
                  ],
                ],
              ),
              if (part.assignedEmployee != null)
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    CommonText.bodySmall(
                      part.assignedEmployee!,
                      color: AppColors.muted,
                    ),
                  ],
                ),
            ],
          ),
          if (isBlocked) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pause_circle_filled_rounded,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STAGE ON HOLD',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CommonText.bodySmall(
                          part.blockerReason!,
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _unblockPart(context, part),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.pureWhite,
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Resume',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Builder(
            builder: (ctx) {
              final stages =
                  DemoStore.instance.stages.where((s) => s.isActive).toList()
                    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
              final firstStageName = stages.isNotEmpty
                  ? stages.first.name
                  : 'Stage 1';
              final isUnassigned =
                  !part.isCompleted &&
                  (part.assignedEmployee == null ||
                      part.assignedEmployee!.trim().isEmpty ||
                      part.assignedEmployee!.toLowerCase() == 'unassigned' ||
                      part.stage == WorkshopStage.inQueue);

              if (isUnassigned) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldDark,
                      foregroundColor: AppColors.pureWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      elevation: 0,
                    ),
                    onPressed: () => _showAssignArtisanModal(context, part),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: Text(
                      'Assign Artisan & Start $firstStageName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// Data Classes for parts representation
class JewelleryPart {
  final String name;
  final String code;
  final int pieces;
  final int passedPieces;
  final int defectivePieces;
  final WorkshopStage stage;
  final String? stageName;
  final String? assignedEmployee;
  final String? blockerReason;
  final double? weight;
  final bool isCompleted;

  JewelleryPart({
    required this.name,
    required this.code,
    required this.pieces,
    required this.passedPieces,
    this.defectivePieces = 0,
    required this.stage,
    this.stageName,
    this.assignedEmployee,
    this.blockerReason,
    this.weight,
    this.isCompleted = false,
  });

  JewelleryPart copyWith({
    String? name,
    String? code,
    int? pieces,
    int? passedPieces,
    int? defectivePieces,
    WorkshopStage? stage,
    String? stageName,
    String? assignedEmployee,
    String? blockerReason,
    bool clearBlocker = false,
    double? weight,
    bool? isCompleted,
  }) {
    return JewelleryPart(
      name: name ?? this.name,
      code: code ?? this.code,
      pieces: pieces ?? this.pieces,
      passedPieces: passedPieces ?? this.passedPieces,
      defectivePieces: defectivePieces ?? this.defectivePieces,
      stage: stage ?? this.stage,
      stageName: stageName ?? this.stageName,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      blockerReason: clearBlocker
          ? null
          : (blockerReason ?? this.blockerReason),
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ParentJewelleryItem {
  final String name;
  final String code;
  final String category;
  final List<JewelleryPart> parts;

  ParentJewelleryItem({
    required this.name,
    required this.code,
    required this.category,
    required this.parts,
  });
}

// Subtle slide-in and fade transition helper widget
class SlideInFade extends StatelessWidget {
  final Widget child;

  const SlideInFade({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
