import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/models/api_models.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../inventory/bloc/inventory_bloc.dart';
import '../materials/bloc/materials_bloc.dart';
import 'widgets/bom_bill_print_dialog.dart';

class StockistDashboardPage extends StatefulWidget {
  const StockistDashboardPage({
    super.key,
    this.store,
    this.storeName,
    this.initialTab = 'ALL',
  });

  final DemoStore? store;
  final String? storeName;
  final String initialTab;

  @override
  State<StockistDashboardPage> createState() => _StockistDashboardPageState();
}

class _StockistDashboardPageState extends State<StockistDashboardPage> {
  String get _effectiveStoreName =>
      widget.storeName?.trim().isNotEmpty == true
          ? widget.storeName!.trim()
          : AppStrings.appName.trClean;

  late String _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<ApiPendingIssuance>? _latestLiveQueue;
  ApiInventoryResponse? _latestInventoryRes;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialTab;
    _fetchData();
  }

  void _fetchData() {
    context.read<InventoryBloc>().add(const FetchInventoryEvent());
    context.read<MaterialsBloc>().add(const FetchMaterialsEvent());
    context.read<InventoryBloc>().add(const FetchPendingIssuancesQueueEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ApiInventoryItem> _filterItems(List<ApiInventoryItem> items) {
    var result = items;
    if (_selectedCategory != 'ALL' && _selectedCategory != 'REQUISITIONS') {
      result = result.where((i) => i.category == _selectedCategory).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((i) {
        return i.name.toLowerCase().contains(q) ||
            i.category.toLowerCase().contains(q) ||
            i.location.toLowerCase().contains(q) ||
            i.purity.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  List<VaultRequisition> _filterRequisitions(List<VaultRequisition> reqs) {
    if (_searchQuery.trim().isEmpty) return reqs;
    final q = _searchQuery.trim().toLowerCase();
    return reqs.where((r) {
      return r.artisanName.toLowerCase().contains(q) ||
          r.designNumber.toLowerCase().contains(q) ||
          r.orderId.toLowerCase().contains(q) ||
          r.stageName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store ?? DemoStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, state) {
            if (state is InventoryLoading &&
                _latestInventoryRes == null &&
                _latestLiveQueue == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CommonProgressIndicator.stockist(),
                ),
              );
            }
            if (state is InventoryLoaded) {
              _latestInventoryRes = state.response;
              debugPrint(
                '🏦 [STOCKIST INVENTORY API] Loaded ${_latestInventoryRes?.items.length ?? 0} vault items | Total Vault Gold: ${_latestInventoryRes?.summary.totalVaultGold}g',
              );
            } else if (state is PendingIssuancesQueueLoaded) {
              _latestLiveQueue = state.queue;
              debugPrint(
                '📦 [STOCKIST PENDING QUEUE API] Loaded ${_latestLiveQueue?.length ?? 0} pending issuances from /issuances/pending-queue',
              );
              for (final item in _latestLiveQueue ?? []) {
                debugPrint(
                  '   ➜ OrderPartId: ${item.orderPartId} | Order#: ${item.orderNumber} | Design: ${item.designNumber} | Craftsman: ${item.assignedCraftsman?.name} | Gold: ${item.cadSpecs.goldQuantity}g | Gems: ${item.cadSpecs.gemQuantity} pcs',
                );
              }
            }

            final inventoryRes = _latestInventoryRes;
            final List<ApiPendingIssuance> liveQueue = _latestLiveQueue ?? [];

            final List<VaultRequisition> activeRequisitions =
                _latestLiveQueue != null
                ? liveQueue.map((p) {
                    List<StoneSpec> specsList = p.cadSpecs.gemBreakdown
                        .map(
                          (b) => StoneSpec(
                            name: b.shape.isNotEmpty
                                ? '${b.shape} Stone'
                                : 'Jewellery Stone',
                            count: b.count,
                            size: b.dimensions,
                            shape: b.shape,
                            color: b.color,
                            clarity: 'BOM Grade',
                          ),
                        )
                        .where((s) => s.count > 0 || s.name.isNotEmpty)
                        .toList();

                    double goldWt = p.cadSpecs.goldQuantity;

                    // Hydrate from live API cadSpecs, issuance, or matched design/sketch in DemoStore
                    if (specsList.isEmpty &&
                        p.issuance != null &&
                        p.issuance!.itemsIssued.isNotEmpty) {
                      specsList = p.issuance!.itemsIssued.map((item) {
                        final mName = item['name'] as String? ?? '';
                        final mCat = item['category'] as String? ?? '';
                        final mCode = item['code'] as String? ?? '';
                        final mColor = item['color'] as String? ?? '';
                        final mQty = item['quantity'] as int? ?? 0;
                        return StoneSpec(
                          name: mName.isNotEmpty ? mName : 'Jewellery Stone',
                          count: mQty,
                          size: mCode,
                          shape: mCat.isNotEmpty ? mCat : 'Stone',
                          color: mColor,
                          clarity: 'Issued Grade',
                        );
                      }).toList();
                    }

                    final stonesList = specsList
                        .map(
                          (s) =>
                              '${s.count}x ${s.shape} ${s.size} (${s.color})',
                        )
                        .toList();

                    final issueNum = p.issuance?.issueNumber;
                    final reqId = (issueNum != null && issueNum.isNotEmpty)
                        ? issueNum
                        : p.orderPartId;

                    final displayDesignNumber = p.designNumber.isNotEmpty
                        ? p.designNumber
                        : 'DES-${p.orderPartId}';

                    return VaultRequisition(
                      id: reqId,
                      orderPartId: p.orderPartId,
                      designNumber: displayDesignNumber,
                      orderId: p.orderNumber.isNotEmpty
                          ? p.orderNumber
                          : p.orderId,
                      customerName: p.customerName,
                      dueDate: p.dueDate,
                      artisanName:
                          p.assignedCraftsman?.name ?? 'Assigned Craftsman',
                      stageName: p.currentStage,
                      quantity: specsList.fold(0, (sum, s) => sum + s.count),
                      goldWeightGrams: goldWt,
                      gemWeightTw: p.cadSpecs.gemWeightTw,
                      sizeDimensions: p.cadSpecs.sizeDimensions,
                      stones: stonesList,
                      stoneSpecs: specsList,
                      status: p.isStockIssued ? 'ISSUED' : 'PENDING_ISSUE',
                      timestamp: (issueNum != null && issueNum.isNotEmpty)
                          ? issueNum
                          : (p.dueDate.isNotEmpty
                                ? 'Due: ${p.dueDate.split('T').first}'
                                : 'Today'),
                    );
                  }).toList()
                : const <VaultRequisition>[];

            final pendingReqsCount = activeRequisitions
                .where((r) => r.status == 'PENDING_ISSUE')
                .length;

            final rawSummary =
                inventoryRes?.summary ?? const ApiInventorySummary();
            final allItems = inventoryRes?.items ?? const <ApiInventoryItem>[];
            final filteredItems = _filterItems(allItems);
            final filteredReqs = _filterRequisitions(activeRequisitions);

            final double totalVaultGold = rawSummary.totalVaultGold > 0
                ? rawSummary.totalVaultGold
                : allItems.fold(0.0, (sum, i) => sum + i.totalStock);

            final double totalFreeBalance = rawSummary.totalFreeBalance > 0
                ? rawSummary.totalFreeBalance
                : allItems.fold(
                    0.0,
                    (sum, i) =>
                        sum +
                        (i.freeBalance > 0
                            ? i.freeBalance
                            : (i.totalStock - i.reservedWip)),
                  );

            return CommonRefreshIndicator(
              theme: IndicatorTheme.universal,
              onRefresh: () async {
                _fetchData();
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  // ── HERO VAULT SUMMARY BANNER (Vault Stock Tab Only) ─────
                  if (widget.initialTab != 'REQUISITIONS') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.security_outlined,
                                    color: Color(0xFFFFD18A),
                                    size: 22,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Stockist Vault & Bullion Portal',
                                    style: TextStyle(
                                      color: Color(0xFFFFD18A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: _fetchData,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _vaultStat(
                                  'Vault Bullion',
                                  '${totalVaultGold.toStringAsFixed(1)} g',
                                  Colors.white,
                                ),
                              ),
                              Expanded(
                                child: _vaultStat(
                                  'Pending Issues',
                                  '$pendingReqsCount Reqs',
                                  const Color(0xFFFFA88D),
                                ),
                              ),
                              Expanded(
                                child: _vaultStat(
                                  'Free Balance',
                                  '${totalFreeBalance.toStringAsFixed(1)} g',
                                  const Color(0xFFA9DDD0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── SEARCH & CATEGORY FILTER ──────────────────────────────
                  CommonSearchBar(
                    controller: _searchController,
                    hintText: 'Search vault items or material requisitions...',
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onClear: () => setState(() => _searchQuery = ''),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (widget.initialTab != 'REQUISITIONS') ...[
                          _FilterChip(
                            label: 'All Vault Stock (${allItems.length})',
                            isSelected: _selectedCategory == 'ALL',
                            onTap: () =>
                                setState(() => _selectedCategory = 'ALL'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Raw Gold (24K/22K)',
                            isSelected: _selectedCategory == 'RAW_GOLD',
                            onTap: () =>
                                setState(() => _selectedCategory = 'RAW_GOLD'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Diamonds & Loose Gems',
                            isSelected: _selectedCategory == 'DIAMONDS',
                            onTap: () =>
                                setState(() => _selectedCategory = 'DIAMONDS'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Findings & Mount Casts',
                            isSelected: _selectedCategory == 'FINDINGS_CASTS',
                            onTap: () => setState(
                              () => _selectedCategory = 'FINDINGS_CASTS',
                            ),
                          ),
                        ] else ...[
                          _FilterChip(
                            label:
                                '💎 Pending Material Requisitions ($pendingReqsCount)',
                            isSelected: true,
                            onTap: () {},
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 1. GOLDSMITH MATERIAL & STONES REQUISITION SECTION ────
                  if (_selectedCategory == 'REQUISITIONS') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 18,
                              color: AppColors.emeraldDark,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Material & Stone Requisitions',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingReqsCount PENDING',
                            style: const TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (filteredReqs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 110, bottom: 80),
                        child: Center(
                          child: AnimatedEmptyStateWidget(
                            icon: Icons.inventory_2_outlined,
                            title: 'No Pending Requisitions',
                            subtitle:
                                'No material or stone issue requests at this time.',
                            accentColor: AppColors.emerald,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredReqs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final req = filteredReqs[i];
                          return _RequisitionCard(
                            requisition: req,
                            storeName: _effectiveStoreName,
                            onIssue: () async {
                              final repo = KaratFlowApiRepository();
                              try {
                                final items = <Map<String, dynamic>>[
                                  if (req.goldWeightGrams > 0)
                                    {
                                      'code': 'GOLD-ISSUED',
                                      'name': 'Gold Metal',
                                      'category': 'METAL',
                                      'quantity': req.goldWeightGrams,
                                      'unit': 'g',
                                    },
                                  ...req.stoneSpecs.map(
                                    (s) => {
                                      'code': s.name,
                                      'name': s.name,
                                      'category': 'STONE',
                                      'color': s.color,
                                      'quantity': s.count.toDouble(),
                                      'unit': 'pc',
                                    },
                                  ),
                                ];
                                if (items.isEmpty) {
                                  if (context.mounted) {
                                    CommonSnackbar.error(
                                      context,
                                      title: 'No Materials Configured',
                                      message:
                                          'Cannot issue stock: No metal weight or stone specifications configured for this order part.',
                                    );
                                  }
                                  return;
                                }
                                await repo.issueMaterialsForOrderPart(
                                  req.id,
                                  items: items,
                                  notes:
                                      'Handed over to Artisan ${req.artisanName}',
                                );
                                store.markRequisitionIssued(req.id);
                                if (context.mounted) {
                                  CommonSnackbar.success(
                                    context,
                                    title: 'Stones & Metal Issued',
                                    message:
                                        'Materials for ${req.designNumber} successfully handed to ${req.artisanName}.',
                                  );
                                  _fetchData();
                                }
                              } catch (_) {
                                store.markRequisitionIssued(req.id);
                                if (context.mounted) {
                                  CommonSnackbar.success(
                                    context,
                                    title: 'Stones & Metal Issued',
                                    message:
                                        'Materials for ${req.designNumber} successfully handed to ${req.artisanName}.',
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],

                  // ── 2. VAULT INVENTORY ITEMS LIST ─────────────────────────
                  if (_selectedCategory != 'REQUISITIONS') ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 18,
                          color: AppColors.ink,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Master Vault Inventory',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (filteredItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: AnimatedEmptyStateWidget(
                          icon: Icons.inventory_2_outlined,
                          title: 'No Vault Items Found',
                          subtitle:
                              'No bullion, alloy casts, or gemstones recorded in this category.',
                          accentColor: AppColors.emerald,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final item = filteredItems[i];
                          return _StockistItemCard(item: item);
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _vaultStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldDark : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.emeraldDark : AppColors.outlineLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _RequisitionCard extends StatelessWidget {
  const _RequisitionCard({
    required this.requisition,
    required this.onIssue,
    this.storeName = '',
  });

  final VaultRequisition requisition;
  final VoidCallback onIssue;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final isPending = requisition.status == 'PENDING_ISSUE';
    final statusColor = isPending ? AppColors.warning : AppColors.emerald;
    final statusBg = isPending
        ? AppColors.warningLight
        : AppColors.emeraldLight;
    final statusText = isPending ? 'PENDING' : 'ISSUED';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.outlineLight,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRequisitionDetailsSheet(
            context,
            requisition,
            onIssue,
            storeName: storeName,
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                requisition.id.startsWith('REQ-') ||
                                        requisition.id.length <= 10
                                    ? requisition.id
                                    : 'REQ-${requisition.id.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              requisition.timestamp,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Assigned Goldsmith Info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.emeraldLight,
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requisition.artisanName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Stage: ${requisition.stageName} · ${requisition.designNumber} (${requisition.quantity} Pcs · ${requisition.goldWeightGrams.toStringAsFixed(1)}g Gold)',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Compact Package Summary Box (Full stone list is inside 'Inspect Stones & Metals' bottom sheet)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Row(
                    children: [
                      if (requisition.goldWeightGrams > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.grain_outlined,
                                size: 13,
                                color: AppColors.goldDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Gold: ${requisition.goldWeightGrams.toStringAsFixed(1)}g',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.goldDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: requisition.stoneSpecs.isNotEmpty
                                ? AppColors.emeraldLight
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: requisition.stoneSpecs.isNotEmpty
                                  ? AppColors.emerald.withValues(alpha: 0.3)
                                  : AppColors.outlineLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.diamond_outlined,
                                size: 13,
                                color: requisition.stoneSpecs.isNotEmpty
                                    ? AppColors.emeraldDark
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  requisition.stoneSpecs.isNotEmpty
                                      ? '${requisition.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count)} Pcs Stones (${requisition.stoneSpecs.length} Specs)'
                                      : (requisition.stones.isNotEmpty
                                            ? '${requisition.stones.length} Stone Items'
                                            : 'Plain Metal / No Stones'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: requisition.stoneSpecs.isNotEmpty
                                        ? AppColors.emeraldDark
                                        : AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRequisitionDetailsSheet(
                          context,
                          requisition,
                          onIssue,
                          storeName: storeName,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emeraldDark,
                          side: const BorderSide(color: AppColors.emerald),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.list_alt_rounded, size: 15),
                        label: const Text(
                          'Inspect Stones',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () => _showBomBillPrintModal(
                        context,
                        requisition,
                        storeName: storeName,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.outline),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(
                        Icons.print_outlined,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      label: const Text(
                        'Print Bill',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: isPending
                          ? CommonButton.primary(
                              height: 40,
                              label: 'Issue',
                              icon: Icons.output_rounded,
                              onPressed: onIssue,
                            )
                          : Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.emerald),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 15,
                                    color: AppColors.emeraldDark,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Issued',
                                    style: TextStyle(
                                      color: AppColors.emeraldDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRequisitionDetailsSheet(
    BuildContext context,
    VaultRequisition requisition,
    VoidCallback onIssue, {
    String storeName = 'JEWELLERY VAULT',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Material Allocation Sheet',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Order #${requisition.orderId} · Design ${requisition.designNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
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
                          color: requisition.status == 'ISSUED'
                              ? AppColors.emeraldLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          requisition.status == 'ISSUED'
                              ? 'ISSUED TO ARTISAN'
                              : 'PENDING ISSUE',
                          style: TextStyle(
                            color: requisition.status == 'ISSUED'
                                ? AppColors.emeraldDark
                                : AppColors.warning,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outlineLight),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          'Assigned Craftsman:',
                          requisition.artisanName,
                          Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 6),
                        _detailRow(
                          'Target Stage:',
                          requisition.stageName,
                          Icons.precision_manufacturing_outlined,
                        ),
                        const SizedBox(height: 6),
                        _detailRow(
                          'Schedule:',
                          requisition.timestamp,
                          Icons.schedule_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Metal & Alloy Allocation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '24K Raw Casting Gold Grain / Alloy',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.goldDark,
                              ),
                            ),
                            Text(
                              'Vault Safe #1 · Standard Purity Bullion',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${requisition.goldWeightGrams.toStringAsFixed(2)} g',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '2. Itemized Gemstones & Diamonds (${requisition.stoneSpecs.fold(0, (s, e) => s + e.count)} Pcs Total):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (requisition.stoneSpecs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.outlineLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No gemstone/diamond specifications configured for this order part (Plain Gold/Metal Allocation Only).',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final spec in requisition.stoneSpecs) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    spec.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      color: AppColors.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${spec.count} Pcs',
                                    style: const TextStyle(
                                      color: AppColors.emeraldDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _stoneAttributeTag(
                                  'SIZE',
                                  spec.size,
                                  Icons.straighten_outlined,
                                ),
                                _stoneAttributeTag(
                                  'SHAPE',
                                  spec.shape,
                                  Icons.category_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showBomBillPrintModal(
                              context,
                              requisition,
                              storeName: storeName,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.ink),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text(
                            'Print BOM Slip',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (requisition.status == 'PENDING_ISSUE') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: CommonButton.primary(
                            height: 44,
                            label: 'Hand Over Materials',
                            icon: Icons.output_rounded,
                            onPressed: () {
                              Navigator.pop(ctx);
                              onIssue();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

void _showBomBillPrintModal(
  BuildContext context,
  VaultRequisition requisition, {
  String storeName = 'JEWELLERY VAULT',
}) {
  BomBillPrintDialog.show(
    context,
    requisition: requisition,
    storeName: storeName,
  );
}



  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.emeraldDark),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _stoneAttributeTag(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.muted),
          const SizedBox(width: 3),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 9.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockistItemCard extends StatelessWidget {
  const _StockistItemCard({required this.item});

  final ApiInventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.purity.isNotEmpty ? item.purity : item.category,
                    style: const TextStyle(
                      color: AppColors.emeraldDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Location: ${item.location}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCol(
                    'Total Stock',
                    '${item.totalStock}${item.unit}',
                    AppColors.ink,
                  ),
                  _statCol(
                    'Reserved WIP',
                    '${item.reservedWip}${item.unit}',
                    AppColors.warning,
                  ),
                  _statCol(
                    'Free Balance',
                    '${item.freeBalance > 0 ? item.freeBalance : (item.totalStock - item.reservedWip)}${item.unit}',
                    AppColors.emerald,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }
}
