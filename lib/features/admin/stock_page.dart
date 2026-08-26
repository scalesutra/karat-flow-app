import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import 'bloc/admin_bloc.dart';

class AdminStockPage extends StatefulWidget {
  const AdminStockPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<AdminStockPage> createState() => _AdminStockPageState();
}

class _AdminStockPageState extends State<AdminStockPage> {
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Raw Gold',
    'Diamonds',
    'Findings & Casts',
    'Finished Goods',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final stockItems = widget.store.stock.where((item) {
          if (_selectedCategory == 'All') return true;
          return item.category.label.toLowerCase() ==
              _selectedCategory.toLowerCase();
        }).toList();

        final totalGold = widget.store.stock
            .where((s) => s.category == StockCategory.rawGold)
            .fold(0.0, (sum, s) => sum + s.totalAvailable);
        final reservedGold = widget.store.stock
            .where((s) => s.category == StockCategory.rawGold)
            .fold(0.0, (sum, s) => sum + s.reservedInLots);
        final freeGold = totalGold - reservedGold;

        return CommonRefreshIndicator(
          onRefresh: () async {
            context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CommonText.headlineLarge('Inventory & Vault Stock'),
                      const SizedBox(height: 1),
                      CommonText.bodySmall(
                        'Gold grain, certified diamonds, findings and vault custody',
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 10),

                      // Vault Balances Card
                      CommonCard(
                        backgroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFFFFD18A),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Main Gold Vault Balance (24K & 22K)',
                                  style: TextStyle(
                                    color: Color(0xFFFFD18A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _vaultStat(
                                    'Total in Vault',
                                    '${totalGold.toStringAsFixed(0)} g',
                                  ),
                                ),
                                Expanded(
                                  child: _vaultStat(
                                    'Reserved in Lots',
                                    '${reservedGold.toStringAsFixed(0)} g',
                                    color: const Color(0xFFFFA88D),
                                  ),
                                ),
                                Expanded(
                                  child: _vaultStat(
                                    'Free Available',
                                    '${freeGold.toStringAsFixed(0)} g',
                                    color: const Color(0xFFA9DDD0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                CommonFilterChips<String>(
                  options: _categories,
                  selected: _selectedCategory,
                  onSelected: (val) => setState(() => _selectedCategory = val),
                  labelBuilder: (val) => val,
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: stockItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = stockItems[index];
                      return _StockCard(
                        item: item,
                        onReconcile: () => _openReconcileDialog(context, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            fontSize: 16,
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

  void _openReconcileDialog(BuildContext context, StockItem item) {
    final stockController = TextEditingController(
      text: '${item.totalAvailable.toInt()}',
    );
    final priceController = TextEditingController();
    String selectedStatus = 'In Stock';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
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
                CommonText.headlineMedium('Update Stock Product: ${item.name}'),
                const SizedBox(height: 4),
                Text(
                  'Vault Location: ${item.vaultLocation} · Purity: ${item.purityOrGrade}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CommonTextField(
                        controller: stockController,
                        label: 'Stock Quantity',
                        hintText: 'e.g. 5',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonTextField(
                        controller: priceController,
                        label: 'Price (₹)',
                        hintText: 'e.g. 52000',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Stock Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                    DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                    DropdownMenuItem(value: 'Custom Made', child: Text('Custom Made')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedStatus = val);
                    }
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
                const SizedBox(height: 20),
                CommonButton.primary(
                  label: 'Update Stock Product (PATCH API)',
                  onPressed: () {
                    final stockVal = int.tryParse(stockController.text.trim());
                    final priceVal = double.tryParse(priceController.text.trim());
                    Navigator.pop(ctx);

                    context.read<AdminBloc>().add(
                          UpdateProductStockEvent(
                            designId: item.id,
                            stock: stockVal,
                            stockStatus: selectedStatus,
                            price: priceVal,
                            title: item.name,
                          ),
                        );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item, required this.onReconcile});

  final StockItem item;
  final VoidCallback onReconcile;

  @override
  Widget build(BuildContext context) {
    final hasDiscrepancy = item.discrepancyGrams != 0.0;

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
                  Icons.inventory_2,
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
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.purityOrGrade} · ${item.vaultLocation}',
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
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Audit / Reconcile',
                icon: const Icon(
                  Icons.edit_note,
                  color: AppColors.emerald,
                  size: 22,
                ),
                onPressed: onReconcile,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCol(
                  'Total Stock',
                  '${item.totalAvailable} ${item.unit}',
                ),
              ),
              Expanded(
                child: _metricCol(
                  'Reserved WIP',
                  '${item.reservedInLots} ${item.unit}',
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _metricCol(
                  'Free Balance',
                  '${item.netFreeQuantity.toStringAsFixed(1)} ${item.unit}',
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          if (hasDiscrepancy) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.danger, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Audit discrepancy: ${item.discrepancyGrams} ${item.unit}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
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
