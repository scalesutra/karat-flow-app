import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/api_error_handler.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/models/api_models.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../inventory/bloc/inventory_bloc.dart';
import 'widgets/bom_bill_print_dialog.dart';
import 'widgets/stone_stock_matrix_view.dart';
import 'services/stockist_bom_mapper.dart';

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
  String get _effectiveStoreName => widget.storeName?.trim().isNotEmpty == true
      ? widget.storeName!.trim()
      : AppStrings.appName.trClean;

  late String _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<ApiPendingIssuance>? _latestLiveQueue;
  ApiInventoryResponse? _latestInventoryRes;
  final Set<String> _issuingParts = {};

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialTab;
    _fetchData();
  }

  void _fetchData() {
    if (_selectedCategory == 'REQUISITIONS') {
      context.read<InventoryBloc>().add(
        const FetchPendingIssuancesQueueEvent(),
      );
    } else if (_selectedCategory != 'STONE_MATRIX') {
      context.read<InventoryBloc>().add(const FetchInventoryEvent());
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    if (category == 'REQUISITIONS') {
      if (_latestLiveQueue == null) {
        context.read<InventoryBloc>().add(
          const FetchPendingIssuancesQueueEvent(),
        );
      }
    } else if (category != 'STONE_MATRIX') {
      if (_latestInventoryRes == null) {
        context.read<InventoryBloc>().add(const FetchInventoryEvent());
      }
    }
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
            final isRequisitions = _selectedCategory == 'REQUISITIONS';
            final isStoneMatrix = _selectedCategory == 'STONE_MATRIX';

            if (state is InventoryLoading) {
              if (isRequisitions && _latestLiveQueue == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CommonProgressIndicator.stockist(),
                  ),
                );
              } else if (!isRequisitions &&
                  !isStoneMatrix &&
                  _latestInventoryRes == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CommonProgressIndicator.stockist(),
                  ),
                );
              }
            }
            if (state is InventoryLoaded) {
              _latestInventoryRes = state.response;
            } else if (state is PendingIssuancesQueueLoaded) {
              _latestLiveQueue = state.queue;
            }

            final inventoryRes = _latestInventoryRes;
            final List<ApiPendingIssuance> liveQueue = _latestLiveQueue ?? [];

            final List<VaultRequisition> activeRequisitions =
                _latestLiveQueue != null
                ? liveQueue.map(StockistBomMapper.requisition).toList()
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
              showIndicator: false,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 9.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(10.r),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.security_outlined,
                                    color: const Color(0xFFFFD18A),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    'Stockist Vault & Bullion Portal',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD18A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5.sp,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white70,
                                  size: 16.sp,
                                ),
                                onPressed: _fetchData,
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
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
                            onTap: () => _onCategorySelected('ALL'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Raw Gold (24K/22K)',
                            isSelected: _selectedCategory == 'RAW_GOLD',
                            onTap: () => _onCategorySelected('RAW_GOLD'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Diamonds & Loose Gems',
                            isSelected: _selectedCategory == 'DIAMONDS',
                            onTap: () => _onCategorySelected('DIAMONDS'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Findings & Mount Casts',
                            isSelected: _selectedCategory == 'FINDINGS_CASTS',
                            onTap: () => _onCategorySelected('FINDINGS_CASTS'),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: '💎 Live Stone Matrix (Zero ₹)',
                            isSelected: _selectedCategory == 'STONE_MATRIX',
                            onTap: () => _onCategorySelected('STONE_MATRIX'),
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

                  // ── 0. LIVE STONE STOCK MATRIX (Zero Currency) ────────────
                  if (_selectedCategory == 'STONE_MATRIX') ...[
                    const StoneStockMatrixView(),
                  ],

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
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final req = filteredReqs[i];
                          return _RequisitionCard(
                            requisition: req,
                            storeName: _effectiveStoreName,
                            isIssuing: _issuingParts.contains(req.orderPartId),
                            onIssue: () async {
                              if (_issuingParts.contains(req.orderPartId) ||
                                  req.status == 'ISSUED') {
                                return;
                              }
                              if (req.isDispatchedOrCompleted) {
                                CommonSnackbar.info(
                                  context,
                                  title: 'Order Already in Final Stage',
                                  message:
                                      'Materials cannot be issued because this order part is already at ${req.stageName}.',
                                );
                                return;
                              }
                              if (req.quantity <= 0) {
                                CommonSnackbar.error(
                                  context,
                                  title: 'Jewellery quantity unavailable',
                                  message:
                                      'Backend batch quantity is required to calculate and issue the BOM. Please refresh.',
                                );
                                return;
                              }
                              final repo = KaratFlowApiRepository();
                              setState(
                                () => _issuingParts.add(req.orderPartId),
                              );
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
                                      if (s.color.isNotEmpty) 'color': s.color,
                                      if (s.shape.isNotEmpty) 'shape': s.shape,
                                      'quantity': s.count,
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
                                final stonesBreakdown = req.stoneSpecs
                                    .where((s) => s.count > 0)
                                    .map(
                                      (s) => StoneBreakdownItem(
                                        size: s.size.isNotEmpty ? s.size : '1.5mm',
                                        color: s.color.isNotEmpty ? s.color : 'White',
                                        stoneType: s.shape.isNotEmpty ? s.shape : 'Round',
                                        quantity: s.count,
                                      ),
                                    )
                                    .toList();

                                await repo.issueMaterialsForOrderPart(
                                  req.orderPartId,
                                  items: items,
                                  stonesBreakdown: stonesBreakdown,
                                  notes: req.artisanName.isNotEmpty
                                      ? 'Handed over to Artisan ${req.artisanName}'
                                      : 'Issued from Stockist Vault',
                                );
                                if (context.mounted) {
                                  CommonSnackbar.success(
                                    context,
                                    title: 'Stones & Metal Issued',
                                    message:
                                        'Materials for ${req.designNumber} successfully handed to ${req.artisanName.isNotEmpty ? req.artisanName : "artisan"}.',
                                  );
                                  _fetchData();
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  final errorMessage = ApiErrorHandler.parseMessage(
                                    error,
                                    fallback:
                                        'Could not confirm material issuance. Refresh the queue before retrying.',
                                  );
                                  CommonSnackbar.error(
                                    context,
                                    title: 'Issue not confirmed',
                                    message: errorMessage,
                                  );
                                  _fetchData();
                                }
                              } finally {
                                if (mounted) {
                                  setState(
                                    () => _issuingParts.remove(req.orderPartId),
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
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
            fontSize: 12.5.sp,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 9.sp),
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
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emeraldDark : AppColors.paper,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.emeraldDark : AppColors.outlineLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.ink,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 10.sp,
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
    this.isIssuing = false,
  });

  final VaultRequisition requisition;
  final VoidCallback onIssue;
  final String storeName;
  final bool isIssuing;

  @override
  Widget build(BuildContext context) {
    final isDispatched = requisition.isDispatchedOrCompleted;
    final isPending = requisition.status == 'PENDING_ISSUE' && !isDispatched;
    final statusColor = isDispatched
        ? AppColors.muted
        : isPending
        ? AppColors.warning
        : AppColors.emerald;
    final statusBg = isDispatched
        ? AppColors.canvas
        : isPending
        ? AppColors.warningLight
        : AppColors.emeraldLight;
    final statusText = isDispatched
        ? (requisition.stageName.toLowerCase().contains('dispatch')
              ? 'DISPATCH'
              : 'COMPLETED')
        : isPending
        ? 'PENDING'
        : 'ISSUED';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.outlineLight,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
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
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                requisition.id.startsWith('REQ-') ||
                                        requisition.id.length <= 10
                                    ? requisition.id
                                    : 'REQ-${requisition.id.substring(0, 6).toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              requisition.timestamp,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10.5.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

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
                            requisition.quantity > 0
                                ? 'Stage: ${requisition.stageName} · ${requisition.designNumber} (${requisition.quantity} Jewellery Pcs)'
                                : 'Jewellery quantity unavailable — refresh required',
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

                // Compact Package Summary Box (Full stone list is inside 'Inspect Stones' bottom sheet)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Row(
                    children: [
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
                                  requisition.quantity <= 0
                                      ? 'BOM total unavailable: missing batch quantity'
                                      : requisition.stoneSpecs.isNotEmpty
                                      ? '${requisition.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count)} Pcs Stones (${requisition.stoneSpecs.length} Specs)'
                                      : (requisition.stones.isNotEmpty
                                            ? '${requisition.stones.length} Stone Items'
                                            : 'No Stones'),
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
                      child: isDispatched
                          ? Container(
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.canvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 15,
                                    color: AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    requisition.stageName
                                            .toLowerCase()
                                            .contains('dispatch')
                                        ? 'Ready to Dispatch'
                                        : 'Completed',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : isPending
                          ? CommonButton.primary(
                              height: 32,
                              label: 'Issue',
                              isLoading: isIssuing,
                              icon: Icons.output_rounded,
                              onPressed: onIssue,
                            )
                          : Container(
                              height: 32,
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
                                    size: 14,
                                    color: AppColors.emeraldDark,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Issued',
                                    style: TextStyle(
                                      color: AppColors.emeraldDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.5,
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
    if (requisition.quantity <= 0) {
      CommonSnackbar.error(
        context,
        title: 'Jewellery quantity unavailable',
        message:
            'Backend batch quantity is required to calculate the BOM. Please refresh.',
      );
      return;
    }
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
                  Text(
                    'Itemized Gemstones & Diamonds (${requisition.stoneSpecs.fold(0, (s, e) => s + e.count)} Pcs Total):',
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
                              'No gemstone/diamond specifications configured for this order part.',
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
                      if (requisition.status == 'PENDING_ISSUE' &&
                          !requisition.isDispatchedOrCompleted) ...[
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
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.sp,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    item.purity.isNotEmpty ? item.purity : item.category,
                    style: TextStyle(
                      color: AppColors.emeraldDark,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Location: ${item.location}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10.sp,
                color: AppColors.muted,
              ),
            ),
            SizedBox(height: 5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(6.r),
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
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 10.5.sp,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 8.5.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
