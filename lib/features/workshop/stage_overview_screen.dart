import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    for (final lot in DemoStore.instance.lots) {
      if (lot.orderId == _orderId && lot.designCode == part.code) {
        return lot.id;
      }
    }
    return null;
  }

  void _assignLivePart(
    BuildContext context,
    JewelleryPart part,
    String workerName,
  ) {
    final partId = _livePartId(part);
    final workers = DemoStore.instance.team
        .where((worker) => worker.name == workerName)
        .toList();
    final stages =
        DemoStore.instance.stages.where((stage) => stage.isActive).toList()
          ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
    if (partId == null || workers.isEmpty || stages.isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Assignment Unavailable',
        message: 'Live part, artisan, and stage IDs are required.',
      );
      return;
    }
    final targetStages = stages
        .where((stage) => _domainStage(stage).index > part.stage.index)
        .toList();
    final targetStage = targetStages.isNotEmpty
        ? targetStages.first
        : stages.first;
    context.read<WorkshopBloc>().add(
      AllocateLotArtisanEvent(
        lotId: partId,
        artisanName: workers.first.name,
        artisanId: workers.first.id,
        stageId: targetStage.id,
      ),
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

  void _advanceLivePart(BuildContext context, JewelleryPart part) {
    final partId = _livePartId(part);
    if (partId == null) {
      CommonSnackbar.error(
        context,
        title: 'Part Not Found',
        message: 'A live backend part ID is required.',
      );
      return;
    }
    context.read<WorkshopBloc>().add(AdvanceLotStageEvent(partId));
  }

  void _rollbackLivePart(
    BuildContext context,
    JewelleryPart part,
    WorkshopStage target,
  ) {
    final partId = _livePartId(part);
    final stages = DemoStore.instance.stages.where(
      (stage) => stage.name.toLowerCase() == target.label.toLowerCase(),
    );
    if (partId == null || stages.isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Rollback Unavailable',
        message: 'Live part and target stage IDs are required.',
      );
      return;
    }
    context.read<WorkshopBloc>().add(
      RollbackLotStageEvent(
        lotId: partId,
        targetStageId: stages.first.id,
        reason: 'Manual rollback from the KaratFlow mobile app',
      ),
    );
  }

  void _showUnsupportedSplit(BuildContext context) {
    CommonSnackbar.error(
      context,
      title: 'Piece Split Unsupported',
      message: 'The backend API does not expose a piece-level split endpoint.',
    );
  }

  // Group and construct our pieces & sub-parts
  List<ParentJewelleryItem> _getParentItems() {
    final List<ParentJewelleryItem> items = [];

    final String statusStr = widget.orderData['status'] as String? ?? '';
    final String stageStr = widget.orderData['stage'] as String? ?? '';
    final bool isCompletedOrder =
        statusStr.toLowerCase() == 'complete' ||
        statusStr.toLowerCase() == 'delivered' ||
        stageStr.toLowerCase() == 'ready for dispatch' ||
        stageStr.toLowerCase() == 'delivered';

    // Parts are populated only from live worker-task data.
    final storeLots = DemoStore.instance.lots
        .where((l) => l.orderId == _orderId)
        .toList();

    if (storeLots.isNotEmpty) {
      final parts = storeLots.map((lot) {
        return JewelleryPart(
          name: lot.productTitle,
          code: lot.designCode,
          pieces: lot.pieces,
          passedPieces: lot.pieces,
          stage: isCompletedOrder ? WorkshopStage.readyForDispatch : lot.stage,
          assignedEmployee: isCompletedOrder
              ? (_artisan.isNotEmpty ? _artisan : 'Completed')
              : (lot.assignedEmployee.isEmpty
                    ? 'Unassigned'
                    : lot.assignedEmployee),
          blockerReason: lot.blockerReason,
          weight: lot.issueWeightGrams,
        );
      }).toList();

      items.add(
        ParentJewelleryItem(
          name: _title.isNotEmpty ? _title : 'Jewellery Order',
          code: _orderId,
          category: _title.contains('Ring') ? 'Rings' : 'Necklace',
          parts: parts,
        ),
      );
      return items;
    }

    return items;
  }

  Future<void> _showAssignArtisanModal(
    BuildContext context,
    JewelleryPart part,
  ) async {
    var workers = DemoStore.instance.team;
    if (workers.isEmpty) {
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
      CommonSnackbar.error(
        context,
        title: 'Workers unavailable',
        message: 'No workers were returned by the employees API.',
      );
      return;
    }
    String selectedWorker = workers.first.name;
    int selectedQuantity = part.pieces;
    final TextEditingController quantityController = TextEditingController(
      text: '$selectedQuantity',
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
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
                    ),
                  ),
                  Text(
                    part.name,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity Selector with Manual Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assign Quantity (Pieces):',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.ink,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (selectedQuantity > 1) {
                                setModalState(() {
                                  selectedQuantity--;
                                  quantityController.text = '$selectedQuantity';
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: SizedBox(
                              width: 54,
                              height: 34,
                              child: TextField(
                                controller: quantityController,
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
                                  final parsed = int.tryParse(val.trim());
                                  if (parsed != null &&
                                      parsed > 0 &&
                                      parsed <= part.pieces) {
                                    setModalState(() {
                                      selectedQuantity = parsed;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (selectedQuantity < part.pieces) {
                                setModalState(() {
                                  selectedQuantity++;
                                  quantityController.text = '$selectedQuantity';
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
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: DemoStore.instance.team.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = DemoStore.instance.team[index];
                        final isSelected = member.name == selectedWorker;
                        return InkWell(
                          onTap: () =>
                              setModalState(() => selectedWorker = member.name),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
                                  backgroundColor: AppColors.emerald.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Text(
                                    member.name[0],
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${member.name} (${member.craft})',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 12,
                                    ),
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
                      setState(() {
                        _parentItems = _getParentItems();
                      });
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Assigned $selectedWorker ($selectedQuantity pcs) to ${part.name}',
                          ),
                          backgroundColor: AppColors.emerald,
                        ),
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

  void _showStageCompletionModal(BuildContext context, JewelleryPart part) {
    int totalPcs = part.pieces;
    int passedPcs = part.passedPieces > 0 ? part.passedPieces : totalPcs;
    int defectivePcs = totalPcs - passedPcs;
    final passedController = TextEditingController(text: '$passedPcs');

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
                  const SizedBox(height: 20),

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
                                  'Move $passedPcs Pcs to Next Stage (${values[currentIdx + 1].label}) →',
                              onPressed: () {
                                final nextStage = values[currentIdx + 1];

                                // 1. Move passed pieces to next stage
                                _advanceLivePart(context, part);

                                // 2. If defective pieces exist, log defective lot sent back to In Queue for recasting
                                if (defectivePcs > 0) {
                                  _showUnsupportedSplit(context);
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
                                          ? 'Moved $passedPcs pcs → ${nextStage.label}. $defectivePcs defective pcs sent back for Recasting!'
                                          : 'Moved $passedPcs pcs → ${nextStage.label}!',
                                    ),
                                    backgroundColor: AppColors.emerald,
                                  ),
                                );
                              },
                            ),
                          if (DemoStore.instance.activeRole ==
                                  AppRole.processManager &&
                              currentIdx > 0) ...[
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
    if (currentIdx <= 0) return;

    // Get all previous stages
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
                                    final parsed = int.tryParse(val.trim());
                                    if (parsed != null &&
                                        parsed > 0 &&
                                        parsed <= totalPcs) {
                                      setModalState(() {
                                        selectedPieces = parsed;
                                      });
                                    }
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
                            _rollbackLivePart(context, part, stage);

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

  int _getPiecesCountForStage(WorkshopStage stage) {
    int count = 0;
    for (var item in _parentItems) {
      for (var part in item.parts) {
        if (part.stage == stage) {
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
        subtitle: 'Order $_orderId · $_client',
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
    final String statusStr = widget.orderData['status'] as String? ?? '';
    final String stageStr = widget.orderData['stage'] as String? ?? '';
    final bool isCompleted =
        statusStr.toLowerCase() == 'complete' ||
        statusStr.toLowerCase() == 'delivered' ||
        stageStr.toLowerCase() == 'ready for dispatch' ||
        stageStr.toLowerCase() == 'delivered';

    final String displayStatus = isCompleted
        ? (statusStr.toLowerCase() == 'complete'
              ? 'Completed'
              : (stageStr.isNotEmpty ? stageStr : 'Completed'))
        : (stageStr.isNotEmpty ? stageStr : 'In Workshop');

    final Color badgeColor = isCompleted
        ? AppColors.emerald
        : AppColors.goldDark;
    final String badgeText = isCompleted ? 'Completed' : 'Active Pouch';

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
    final apiStages = DemoStore.instance.stages;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: apiStages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final apiStage = apiStages[index];
        final stage =
            WorkshopStage.values[(apiStage.stageNumber - 1)
                .clamp(0, WorkshopStage.values.length - 1)
                .toInt()];
        final count = _getPiecesCountForStage(stage);
        final isSelected = _selectedStageFilter == stage;
        final stageColor = _getStageColor(stage);

        // Find parts in this stage
        final stageParts = <JewelleryPart>[];
        for (final parent in _parentItems) {
          for (final part in parent.parts) {
            if (part.stage == stage) {
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
                    : (isSelected ? AppColors.emerald : AppColors.outline),
                width: hasBlockedParts || isSelected ? 1.8 : 1,
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
                                : stageColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasBlockedParts
                                ? Icons.pause_circle_filled_rounded
                                : _getStageIcon(stage),
                            size: 20,
                            color: hasBlockedParts
                                ? AppColors.danger
                                : stageColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    apiStage.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  if (hasBlockedParts) ...[
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
                                    : count > 0
                                    ? '$count pieces in progress'
                                    : 'No active pieces',
                                style: TextStyle(
                                  color: hasBlockedParts
                                      ? AppColors.danger
                                      : count > 0
                                      ? AppColors.emeraldDark
                                      : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                            color: isSelected
                                ? AppColors.emerald
                                : (hasBlockedParts
                                      ? AppColors.dangerLight
                                      : stageColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: Text(
                            '$count Pcs',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.pureWhite
                                  : (hasBlockedParts
                                        ? AppColors.danger
                                        : stageColor),
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
                                              Text(
                                                'Assigned: ${part.assignedEmployee ?? "Unassigned"}',
                                                style: const TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
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

                                    // Action Buttons Row (Below Text) - Only visible when _allowStageChange is true (Process Manager)
                                    if (_allowStageChange) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (part.assignedEmployee == null ||
                                              part.assignedEmployee ==
                                                  'Unassigned' ||
                                              part.assignedEmployee ==
                                                  'Unassigned (In Queue)')
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
                                                child: const Text(
                                                  '+ Assign Worker',
                                                  style: TextStyle(
                                                    color: AppColors.pureWhite,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else if (part.blockerReason != null)
                                            InkWell(
                                              onTap: () =>
                                                  _unblockPart(context, part),
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
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.play_arrow_rounded,
                                                      color:
                                                          AppColors.pureWhite,
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Resume Stage',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.pureWhite,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 11,
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
                                                      horizontal: 8,
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
                                                      size: 12,
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Block / Hold',
                                                      style: TextStyle(
                                                        color: AppColors.danger,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 11,
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
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => _movePartBackStage(
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
                                                      SizedBox(width: 3),
                                                      Text(
                                                        'Back Stage',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.warning,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 11,
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
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () =>
                                                    _showStageCompletionModal(
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
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      SizedBox(width: 3),
                                                      Icon(
                                                        Icons.arrow_forward,
                                                        color:
                                                            AppColors.pureWhite,
                                                        size: 11,
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
                child: CommonText.bodyMedium(
                  part.name,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                ),
                child: CommonText.bodySmall(
                  part.stage.label,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: stageColor,
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
                  if (_allowStageChange) ...[
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
                ],
              ),
            ),
          ],
        ],
      ),
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
                label: 'Custom Explanation / Karigar Note',
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
                        Navigator.pop(ctx);
                        CommonSnackbar.error(
                          context,
                          title: 'Order Hold API Unavailable',
                          message:
                              'The backend does not expose an order-hold endpoint.',
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
    CommonSnackbar.error(
      context,
      title: 'Order Hold API Unavailable',
      message: 'The backend does not expose an order-hold endpoint.',
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
  final String? assignedEmployee;
  final String? blockerReason;
  final double? weight;

  JewelleryPart({
    required this.name,
    required this.code,
    int? pieces,
    int? passedPieces,
    int? defectivePieces,
    required this.stage,
    this.assignedEmployee,
    this.blockerReason,
    this.weight,
  }) : pieces = pieces ?? 1,
       defectivePieces = defectivePieces ?? 0,
       passedPieces = passedPieces ?? ((pieces ?? 1) - (defectivePieces ?? 0));

  JewelleryPart copyWith({
    String? name,
    String? code,
    int? pieces,
    int? passedPieces,
    int? defectivePieces,
    WorkshopStage? stage,
    String? assignedEmployee,
    String? blockerReason,
    bool clearBlocker = false,
    double? weight,
  }) {
    return JewelleryPart(
      name: name ?? this.name,
      code: code ?? this.code,
      pieces: pieces ?? this.pieces,
      passedPieces: passedPieces ?? this.passedPieces,
      defectivePieces: defectivePieces ?? this.defectivePieces,
      stage: stage ?? this.stage,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      blockerReason: clearBlocker
          ? null
          : (blockerReason ?? this.blockerReason),
      weight: weight ?? this.weight,
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

/*
class _MockVoiceRecorder extends StatefulWidget {
  const _MockVoiceRecorder({required this.onRecordComplete});

  final ValueChanged<bool> onRecordComplete;

  @override
  State<_MockVoiceRecorder> createState() => _MockVoiceRecorderState();
}

class _MockVoiceRecorderState extends State<_MockVoiceRecorder> {
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
      });
      widget.onRecordComplete(true);
    } else {
      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _seconds++;
        });
      });
    }
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isRecording
                    ? 'Recording voice instructions...'
                    : _hasRecorded
                    ? 'Audio attached successfully!'
                    : 'Tap mic to record audio note:',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
              if (_isRecording)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_seconds),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: _toggleRecording,
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : AppColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording
                          ? AppColors.danger
                          : AppColors.outline,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? AppColors.danger : AppColors.muted,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _isRecording
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(8, (index) {
                          return _AudioBar(index: index);
                        }),
                      )
                    : _hasRecorded
                    ? Row(
                        children: [
                          const Icon(
                            Icons.audiotrack,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'voice_note_${widget.hashCode.toString().substring(0, 3)}.wav (${_formatTime(_seconds)})',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Provide detailed voice instructions for revision.',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioBar extends StatefulWidget {
  const _AudioBar({required this.index});
  final int index;

  @override
  State<_AudioBar> createState() => _AudioBarState();
}

class _AudioBarState extends State<_AudioBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 70)),
    );
    _animation = Tween<double>(
      begin: 4,
      end: 24,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        width: 3,
        height: _animation.value,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
*/
