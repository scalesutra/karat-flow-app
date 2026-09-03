import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/models/api_models.dart';
import '../inventory/bloc/inventory_bloc.dart';
import '../materials/bloc/materials_bloc.dart';

class AdminStockPage extends StatefulWidget {
  const AdminStockPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<AdminStockPage> createState() => _AdminStockPageState();
}

class _AdminStockPageState extends State<AdminStockPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filters for Inventory
  String _invCategory = 'ALL';
  final TextEditingController _invSearchController = TextEditingController();

  // Search & Filters for Materials
  String _matCategory = 'ALL';
  final TextEditingController _matSearchController = TextEditingController();

  final List<String> _invCategories = const [
    'ALL',
    'RAW_GOLD',
    'DIAMONDS',
    'FINDINGS_CASTS',
    'READY_ALLOY',
  ];

  final List<String> _matCategories = const [
    'ALL',
    'METAL',
    'DIAMOND',
    'GEMSTONE',
    'FINDING',
    'MAKING_CHARGE',
  ];

  String _formatInvCategoryLabel(String cat) => switch (cat) {
    'RAW_GOLD' => 'Raw Gold (Fine)',
    'DIAMONDS' => 'Diamonds & Solitaires',
    'FINDINGS_CASTS' => 'Findings & Castings',
    'READY_ALLOY' => 'Ready Gold Alloys',
    _ => 'All Vault Items',
  };

  IconData _formatInvCategoryIcon(String cat) => switch (cat) {
    'RAW_GOLD' => Icons.grid_view_rounded,
    'DIAMONDS' => Icons.diamond_outlined,
    'FINDINGS_CASTS' => Icons.extension_outlined,
    'READY_ALLOY' => Icons.token_outlined,
    _ => Icons.all_inclusive,
  };

  String _formatMatCategoryLabel(String cat) => switch (cat) {
    'METAL' => 'Metals & Bullion',
    'DIAMOND' => 'Loose Diamonds',
    'GEMSTONE' => 'Precious Gemstones',
    'FINDING' => 'Findings & Parts',
    'MAKING_CHARGE' => 'Labor & Making Charges',
    _ => 'All Material Presets',
  };

  IconData _formatMatCategoryIcon(String cat) => switch (cat) {
    'METAL' => Icons.square_outlined,
    'DIAMOND' => Icons.diamond_outlined,
    'GEMSTONE' => Icons.auto_awesome_outlined,
    'FINDING' => Icons.handyman_outlined,
    'MAKING_CHARGE' => Icons.receipt_long_outlined,
    _ => Icons.category_outlined,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchInventory();
        _fetchMaterials();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invSearchController.dispose();
    _matSearchController.dispose();
    super.dispose();
  }

  void _fetchInventory() {
    context.read<InventoryBloc>().add(
      FetchInventoryEvent(
        category: _invCategory == 'ALL' ? null : _invCategory,
        search: _invSearchController.text.trim().isEmpty
            ? null
            : _invSearchController.text.trim(),
      ),
    );
  }

  void _fetchMaterials() {
    context.read<MaterialsBloc>().add(
      FetchMaterialsEvent(
        category: _matCategory == 'ALL' ? null : _matCategory,
        search: _matSearchController.text.trim().isEmpty
            ? null
            : _matSearchController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.emerald,
                ),
              );
            } else if (state is InventoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
        ),
        BlocListener<MaterialsBloc, MaterialsState>(
          listener: (context, state) {
            if (state is MaterialsOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.emerald,
                ),
              );
            } else if (state is MaterialsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
        ),
      ],
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Tab Switcher
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CommonText.headlineLarge('Inventory & Raw Materials'),
                  const SizedBox(height: 2),
                  CommonText.bodySmall(
                    'Vault stock balances, bullion rates, and raw material presets',
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  _StockTabHeader(tabController: _tabController),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab Body View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVaultInventoryTab(context),
                  _buildMasterMaterialsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 1: VAULT INVENTORY (`/inventory`)
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildVaultInventoryTab(BuildContext context) {
    return CommonRefreshIndicator(
      onRefresh: () async {
        _fetchInventory();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          ApiInventoryResponse? inventoryRes;
          if (state is InventoryLoaded) {
            inventoryRes = state.response;
          }

          final rawSummary =
              inventoryRes?.summary ?? const ApiInventorySummary();
          final items = inventoryRes?.items ?? const <ApiInventoryItem>[];

          final double totalVaultGold = rawSummary.totalVaultGold > 0
              ? rawSummary.totalVaultGold
              : items.fold(0.0, (sum, i) => sum + i.totalStock);

          final double totalReservedWip = rawSummary.totalReservedWip > 0
              ? rawSummary.totalReservedWip
              : items.fold(0.0, (sum, i) => sum + i.reservedWip);

          final double totalFreeBalance = rawSummary.totalFreeBalance > 0
              ? rawSummary.totalFreeBalance
              : items.fold(
                  0.0,
                  (sum, i) =>
                      sum +
                      (i.freeBalance > 0
                          ? i.freeBalance
                          : (i.totalStock - i.reservedWip)),
                );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              // Summary Banner Card
              CommonCard(
                backgroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
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
                              Icons.security,
                              color: Color(0xFFFFD18A),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Safe Vault Bullion & Stock Summary',
                              style: TextStyle(
                                color: Color(0xFFFFD18A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white70,
                            size: 20,
                          ),
                          onPressed: _fetchInventory,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _vaultStat(
                            'Total Vault Gold',
                            '${totalVaultGold.toStringAsFixed(1)} g',
                          ),
                        ),
                        Expanded(
                          child: _vaultStat(
                            'Reserved WIP',
                            '${totalReservedWip.toStringAsFixed(1)} g',
                            color: const Color(0xFFFFA88D),
                          ),
                        ),
                        Expanded(
                          child: _vaultStat(
                            'Free Balance',
                            '${totalFreeBalance.toStringAsFixed(1)} g',
                            color: const Color(0xFFA9DDD0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search Text Field & Add Stock Button
              Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      controller: _invSearchController,
                      hintText:
                          'Search vault stock by name, location, purity...',
                      prefixIcon: Icons.search,
                      onSubmitted: (_) => _fetchInventory(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openAddInventorySheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text(
                      'Add Stock',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Filter Chips (Below Search)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _invCategories.map((cat) {
                    final isSelected = _invCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _invCategory = cat);
                          _fetchInventory();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.emerald
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald
                                  : AppColors.outlineLight,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.emerald.withOpacity(
                                        0.25,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _formatInvCategoryIcon(cat),
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.emeraldDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatInvCategoryLabel(cat),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Loading / Empty / Content List
              if (state is InventoryLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CommonProgressIndicator()),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: AnimatedEmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No Vault Stock Found',
                    subtitle:
                        'No gold bullion, alloy casts, or raw vault stock items match your search.',
                    accentColor: AppColors.emerald,
                    actionLabel: 'Add Vault Stock',
                    onAction: () => _openAddInventorySheet(context),
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InventoryItemCard(
                      item: item,
                      onEdit: () => _openUpdateInventorySheet(context, item),
                      onDelete: () => _openDeleteInventoryDialog(context, item),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 2: MASTER RAW MATERIALS (`/materials`)
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildMasterMaterialsTab(BuildContext context) {
    return CommonRefreshIndicator(
      onRefresh: () async {
        _fetchMaterials();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: BlocBuilder<MaterialsBloc, MaterialsState>(
        builder: (context, state) {
          List<ApiMaterial> materials = const [];
          if (state is MaterialsLoaded) {
            materials = state.materials;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              // Search Text Field & New Preset Button
              Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      controller: _matSearchController,
                      hintText: 'Search raw materials by code, name, spec...',
                      prefixIcon: Icons.search,
                      onSubmitted: (_) => _fetchMaterials(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openAddMaterialSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'New Preset',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Filter Chips (Below Search)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _matCategories.map((cat) {
                    final isSelected = _matCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _matCategory = cat);
                          _fetchMaterials();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.goldDark
                                : AppColors.paper,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.goldDark
                                  : AppColors.outlineLight,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.goldDark.withOpacity(
                                        0.25,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _formatMatCategoryIcon(cat),
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.goldDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatMatCategoryLabel(cat),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Loading / Empty / Content List
              if (state is MaterialsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CommonProgressIndicator()),
                )
              else if (materials.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: AnimatedEmptyStateWidget(
                    icon: Icons.diamond_outlined,
                    title: 'No Material Presets Found',
                    subtitle:
                        'No raw materials, gemstones, or alloy specs configured for production.',
                    accentColor: AppColors.goldDark,
                    actionLabel: 'Create New Preset',
                    onAction: () => _openAddMaterialSheet(context),
                  ),
                )
              else
                ...materials.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MaterialItemCard(
                      item: item,
                      onUpdateRate: () =>
                          _openUpdateMaterialRateSheet(context, item),
                      onDelete: () => _openDeleteMaterialDialog(context, item),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _vaultStat(
    String label,
    String val, {
    Color color = AppColors.pureWhite,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // MODALS & DIALOGS FOR INVENTORY
  // ═════════════════════════════════════════════════════════════════════

  void _openAddInventorySheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final purityCtrl = TextEditingController();
    final totalStockCtrl = TextEditingController();
    final reservedCtrl = TextEditingController();
    final freeBalanceCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'g');
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedCat = 'RAW_GOLD';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  const CommonText.headlineMedium(
                    'Add Vault Stock Item',
                  ),
                  const SizedBox(height: 16),
                  CommonTextField(
                    controller: nameCtrl,
                    label: 'Item Name',
                    hintText: 'e.g. 24K Casting Grain Bar #B2',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    items: const [
                      DropdownMenuItem(
                        value: 'RAW_GOLD',
                        child: Text('RAW_GOLD'),
                      ),
                      DropdownMenuItem(
                        value: 'DIAMONDS',
                        child: Text('DIAMONDS'),
                      ),
                      DropdownMenuItem(
                        value: 'FINDINGS_CASTS',
                        child: Text('FINDINGS_CASTS'),
                      ),
                      DropdownMenuItem(
                        value: 'READY_ALLOY',
                        child: Text('READY_ALLOY'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCat = val);
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          controller: purityCtrl,
                          label: 'Purity / Grade',
                          hintText: '999.9 or VVS',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonTextField(
                          controller: unitCtrl,
                          label: 'Unit',
                          hintText: 'g or ct',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          controller: totalStockCtrl,
                          label: 'Total Stock',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CommonTextField(
                          controller: reservedCtrl,
                          label: 'Reserved WIP',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CommonTextField(
                          controller: freeBalanceCtrl,
                          label: 'Free Balance',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: locationCtrl,
                    label: 'Vault Location',
                    hintText: 'Main Atelier Vault • Safe #1',
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: notesCtrl,
                    label: 'Notes / Serial No.',
                    hintText: 'Certified bullion batch #102',
                  ),
                  const SizedBox(height: 20),
                  CommonButton.primary(
                    label: 'Create Vault Stock',
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final totalStock =
                          double.tryParse(totalStockCtrl.text.trim()) ?? 0.0;
                      final reservedWip =
                          double.tryParse(reservedCtrl.text.trim()) ?? 0.0;
                      final freeBal =
                          double.tryParse(freeBalanceCtrl.text.trim()) ?? 0.0;

                      if (name.isEmpty) return;

                      Navigator.pop(sheetCtx);
                      context.read<InventoryBloc>().add(
                        AddInventoryItemEvent(
                          name: name,
                          category: selectedCat,
                          purity: purityCtrl.text.trim(),
                          totalStock: totalStock,
                          reservedWip: reservedWip,
                          freeBalance: freeBal,
                          unit: unitCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          notes: notesCtrl.text.trim(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openUpdateInventorySheet(BuildContext context, ApiInventoryItem item) {
    final stockCtrl = TextEditingController(text: item.totalStock.toString());
    final reservedCtrl = TextEditingController(
      text: item.reservedWip.toString(),
    );
    final freeCtrl = TextEditingController(text: item.freeBalance.toString());
    final locationCtrl = TextEditingController(text: item.location);
    final notesCtrl = TextEditingController(text: item.notes ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
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
              CommonText.headlineMedium('Adjust Stock: ${item.name}'),
              const SizedBox(height: 4),
              Text(
                'Purity: ${item.purity} • Category: ${item.category}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      controller: stockCtrl,
                      label: 'Total Stock',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CommonTextField(
                      controller: reservedCtrl,
                      label: 'Reserved WIP',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CommonTextField(
                      controller: freeCtrl,
                      label: 'Free Balance',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CommonTextField(
                controller: locationCtrl,
                label: 'Location',
                hintText: 'Vault Safe #1',
              ),
              const SizedBox(height: 12),
              CommonTextField(
                controller: notesCtrl,
                label: 'Notes / Audit Reason',
                hintText: 'Physical bullion count audit',
              ),
              const SizedBox(height: 20),
              CommonButton.primary(
                label: 'Save Adjusted Vault Stock',
                onPressed: () {
                  final totalStock = double.tryParse(stockCtrl.text.trim());
                  final reservedWip = double.tryParse(reservedCtrl.text.trim());
                  final freeBal = double.tryParse(freeCtrl.text.trim());

                  Navigator.pop(sheetCtx);
                  context.read<InventoryBloc>().add(
                    UpdateInventoryItemEvent(
                      id: item.id,
                      totalStock: totalStock,
                      reservedWip: reservedWip,
                      freeBalance: freeBal,
                      location: locationCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDeleteInventoryDialog(BuildContext context, ApiInventoryItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text(
          'Are you sure you want to remove "${item.name}" (${item.id}) from the safe vault?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<InventoryBloc>().add(
                DeleteInventoryItemEvent(id: item.id),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // MODALS & DIALOGS FOR MASTER RAW MATERIALS
  // ═════════════════════════════════════════════════════════════════════

  void _openAddMaterialSheet(BuildContext context) {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'g');
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCat = 'METAL';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  const CommonText.headlineMedium('Create Master Raw Material'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CommonTextField(
                          controller: codeCtrl,
                          label: 'Code',
                          hintText: 'GOLD_24K',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonTextField(
                          controller: unitCtrl,
                          label: 'Unit',
                          hintText: 'g or ct',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: nameCtrl,
                    label: 'Material Name',
                    hintText: '24K Fine Gold (99.9%)',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    items: const [
                      DropdownMenuItem(value: 'METAL', child: Text('METAL')),
                      DropdownMenuItem(
                        value: 'DIAMOND',
                        child: Text('DIAMOND'),
                      ),
                      DropdownMenuItem(
                        value: 'GEMSTONE',
                        child: Text('GEMSTONE'),
                      ),
                      DropdownMenuItem(
                        value: 'FINDING',
                        child: Text('FINDING'),
                      ),
                      DropdownMenuItem(
                        value: 'MAKING_CHARGE',
                        child: Text('MAKING_CHARGE'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedCat = val);
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: specCtrl,
                    label: 'Specification',
                    hintText: '999.9 Purity or VVS1 / F Color',
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: priceCtrl,
                    label: 'Preset Price / Unit (₹)',
                    keyboardType: TextInputType.number,
                    hintText: '7450.0',
                  ),
                  const SizedBox(height: 12),
                  CommonTextField(
                    controller: descCtrl,
                    label: 'Description',
                    hintText: 'Standard bullion casting grain',
                  ),
                  const SizedBox(height: 20),
                  CommonButton.primary(
                    label: 'Create Material Preset',
                    onPressed: () {
                      final code = codeCtrl.text.trim();
                      final name = nameCtrl.text.trim();
                      final price =
                          double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                      if (code.isEmpty || name.isEmpty) return;

                      Navigator.pop(sheetCtx);
                      context.read<MaterialsBloc>().add(
                        CreateMaterialEvent(
                          code: code,
                          name: name,
                          category: selectedCat,
                          specification: specCtrl.text.trim(),
                          unit: unitCtrl.text.trim(),
                          presetPricePerUnit: price,
                          description: descCtrl.text.trim(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openUpdateMaterialRateSheet(BuildContext context, ApiMaterial item) {
    final rateCtrl = TextEditingController(
      text: item.presetPricePerUnit.toString(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
            CommonText.headlineMedium('Update Daily Rate: ${item.name}'),
            const SizedBox(height: 4),
            Text(
              'Code: ${item.code} • Unit: per ${item.unit}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            CommonTextField(
              controller: rateCtrl,
              label: 'Preset Price per ${item.unit} (₹)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            CommonButton.primary(
              label: 'Update Daily Rate',
              onPressed: () {
                final rate = double.tryParse(rateCtrl.text.trim());
                if (rate == null) return;

                Navigator.pop(sheetCtx);
                context.read<MaterialsBloc>().add(
                  UpdateMaterialRateEvent(
                    id: item.id,
                    presetPricePerUnit: rate,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDeleteMaterialDialog(BuildContext context, ApiMaterial item) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Raw Material'),
        content: Text(
          'Are you sure you want to delete material preset "${item.name}" (${item.code})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<MaterialsBloc>().add(
                DeleteMaterialEvent(id: item.id),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// VAULT INVENTORY ITEM CARD
// ═════════════════════════════════════════════════════════════════════
class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ApiInventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.emerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.purity} · ${item.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit / Reconcile',
                icon: const Icon(
                  Icons.edit_note,
                  color: AppColors.emerald,
                  size: 22,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete Item',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCol(
                  'Total Stock',
                  '${item.totalStock} ${item.unit}',
                ),
              ),
              Expanded(
                child: _metricCol(
                  'Reserved WIP',
                  '${item.reservedWip} ${item.unit}',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _metricCol(
                  'Free Balance',
                  '${item.freeBalance} ${item.unit}',
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                'Notes: ${item.notes}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCol(String label, String val, {Color color = AppColors.ink}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// MASTER RAW MATERIAL ITEM CARD
// ═════════════════════════════════════════════════════════════════════
class _MaterialItemCard extends StatelessWidget {
  const _MaterialItemCard({
    required this.item,
    required this.onUpdateRate,
    required this.onDelete,
  });

  final ApiMaterial item;
  final VoidCallback onUpdateRate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Text(
                            item.code,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Spec: ${item.specification} · Category: ${item.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Update Daily Rate',
                icon: const Icon(
                  Icons.price_change_outlined,
                  color: AppColors.emerald,
                  size: 22,
                ),
                onPressed: onUpdateRate,
              ),
              IconButton(
                tooltip: 'Delete Material',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${item.presetPricePerUnit.toStringAsFixed(2)} / ${item.unit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.emerald,
                    ),
                  ),
                  const Text(
                    'Preset Daily Rate',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
              if (item.description.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockTabHeader extends StatelessWidget {
  const _StockTabHeader({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final selectedIndex = tabController.index;
        final invState = context.watch<InventoryBloc>().state;
        final invCount = invState is InventoryLoaded
            ? invState.response.items.length
            : 0;
        final matState = context.watch<MaterialsBloc>().state;
        final matCount = matState is MaterialsLoaded
            ? matState.materials.length
            : 0;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineLight),
          ),
          child: Row(
            children: [
              // TAB 1: Vault Stock Inventory
              Expanded(
                child: GestureDetector(
                  onTap: () => tabController.animateTo(0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == 0
                          ? AppColors.paper
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: selectedIndex == 0
                          ? Border.all(
                              color: AppColors.emerald.withOpacity(0.3),
                            )
                          : null,
                      boxShadow: selectedIndex == 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: selectedIndex == 0
                              ? AppColors.emeraldDark
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Vault Inventory',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selectedIndex == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selectedIndex == 0
                                  ? AppColors.emeraldDark
                                  : AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selectedIndex == 0
                                ? AppColors.emeraldLight
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$invCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: selectedIndex == 0
                                  ? AppColors.emeraldDark
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // TAB 2: Master Raw Materials
              Expanded(
                child: GestureDetector(
                  onTap: () => tabController.animateTo(1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selectedIndex == 1
                          ? AppColors.paper
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: selectedIndex == 1
                          ? Border.all(
                              color: AppColors.goldDark.withOpacity(0.3),
                            )
                          : null,
                      boxShadow: selectedIndex == 1
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          size: 16,
                          color: selectedIndex == 1
                              ? AppColors.goldDark
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Master Materials',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selectedIndex == 1
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: selectedIndex == 1
                                  ? AppColors.goldDark
                                  : AppColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selectedIndex == 1
                                ? AppColors.goldLight
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$matCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: selectedIndex == 1
                                  ? AppColors.goldDark
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
