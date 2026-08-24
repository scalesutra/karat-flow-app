import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../../domain/models.dart';

class DesignsPage extends StatefulWidget {
  const DesignsPage({super.key, required this.store});

  final DemoStore store;

  @override
  State<DesignsPage> createState() => _DesignsPageState();
}

class _DesignsPageState extends State<DesignsPage> {
  JewelleryCategory _category = JewelleryCategory.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveCatalogue();
  }

  Future<void> _fetchLiveCatalogue() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      debugPrint('🎨 [DesignsPage] Fetching catalogue from GET /sketches & GET /three-d-designs...');
      final apiRepo = KaratFlowApiRepository();
      final sketches = await apiRepo.listSketches();
      final threeD = await apiRepo.listThreeDDesigns();

      debugPrint('✅ [DesignsPage] Received ${sketches.length} sketches & ${threeD.length} 3D designs from server.');

      final List<JewelleryDesign> catalogue = [];

      for (final sk in sketches) {
        catalogue.add(
          JewelleryDesign(
            id: sk.id,
            name: sk.title.isNotEmpty ? sk.title : 'Design #${sk.designNumber}',
            code: sk.designNumber.isNotEmpty ? sk.designNumber : sk.id,
            category: JewelleryCategory.all,
            purity: '22KT',
            grossWeightGrams: 25.0,
            imageUrl: sk.sketchUrl,
            description: sk.adminInstructions ?? '2D Pencil Sketch Model',
            isPopular: true,
          ),
        );
      }

      for (final td in threeD) {
        catalogue.add(
          JewelleryDesign(
            id: td.id,
            name: '3D CAD (${td.sketchId})',
            code: 'CAD-${td.id}',
            category: JewelleryCategory.rings,
            purity: '22KT',
            grossWeightGrams: td.totalWeight > 0 ? td.totalWeight : 18.5,
            imageUrl: td.xtlFileUrl ?? '',
            description: '3D CAD Model (Vol: ${td.volumeMm3}mm³)',
            isPopular: true,
          ),
        );
      }

      widget.store.setDesigns(catalogue);
    } catch (e) {
      debugPrint('❌ [DesignsPage] Error fetching catalogue from API: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final filteredDesigns =
            widget.store.designsForCategory(_category).where((d) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return d.name.toLowerCase().contains(q) ||
              d.code.toLowerCase().contains(q) ||
              d.description.toLowerCase().contains(q);
        }).toList();

        return SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText.headlineLarge(
                                '${AppStrings.navDesigns.trClean} Catalogue',
                              ),
                              const SizedBox(height: 1),
                              CommonText.bodySmall(
                                '${widget.store.designs.length} curated wholesale designs',
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                        if (widget.store.cartItemsCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLight,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shopping_bag, size: 16, color: AppColors.emerald),
                                const SizedBox(width: 6),
                                CommonText.labelSmall(
                                  '${widget.store.cartItemsCount} in cart',
                                  color: AppColors.emerald,
                                  fontWeight: FontWeight.w700,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CommonSearchBar(
                      controller: _searchController,
                      hintText: 'Search by code (e.g. NK-842) or design name...',
                      onChanged: (val) => setState(() => _searchQuery = val),
                      onClear: () => setState(() => _searchQuery = ''),
                    ),
                  ],
                ),
              ),
              CommonFilterChips<JewelleryCategory>(
                options: JewelleryCategory.values,
                selected: _category,
                onSelected: (cat) => setState(() => _category = cat),
                labelBuilder: (cat) => cat.label,
                iconBuilder: (cat) => cat.icon,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CommonProgressIndicator(
                            theme: IndicatorTheme.cad,
                            size: 54,
                            label: 'Loading design catalogue from server...',
                          ),
                        ),
                      )
                    : CommonRefreshIndicator(
                        theme: IndicatorTheme.cad,
                        onRefresh: _fetchLiveCatalogue,
                        child: filteredDesigns.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: CommonEmptyState(
                            icon: Icons.search_off,
                            title: 'No designs found',
                            description: 'Try adjusting your category or search terms.',
                            actionLabel: 'Show All Designs',
                            onAction: () {
                              setState(() {
                                _category = JewelleryCategory.all;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: filteredDesigns.length,
                          itemBuilder: (context, index) {
                            final design = filteredDesigns[index];
                            final cartItem = widget.store.cart
                                .where((item) => item.design.id == design.id)
                                .firstOrNull;

                            return _DesignCard(
                              design: design,
                              cartQuantity: cartItem?.quantity ?? 0,
                              onAddToCart: () => widget.store.addToCart(design),
                              onIncrease: () => widget.store.addToCart(design),
                              onDecrease: () => widget.store.updateCartQuantity(
                                design.id,
                                (cartItem?.quantity ?? 1) - 1,
                              ),
                              onTap: () => _showDesignDetailsSheet(context, design),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDesignDetailsSheet(BuildContext context, JewelleryDesign design) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DesignDetailModal(
        design: design,
        store: widget.store,
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.design,
    required this.cartQuantity,
    required this.onAddToCart,
    required this.onIncrease,
    required this.onDecrease,
    required this.onTap,
  });

  final JewelleryDesign design;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Showcase Container
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: design.accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    design.category.icon,
                    size: 48,
                    color: design.accentColor,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      design.purity,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (design.isPopular)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: const Text(
                        'TRENDING',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText.labelSmall(
                        design.code,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        design.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.scale, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          CommonText.bodySmall(
                            '${design.grossWeightGrams.toStringAsFixed(1)}g GW',
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                          if (design.diamondCarats > 0) ...[
                            const SizedBox(width: 6),
                            CommonText.bodySmall(
                              '${design.diamondCarats}ct',
                              fontSize: 11,
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${_formatPrice(design.estimatedPrice)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (cartQuantity == 0)
                        CommonButton.primary(
                          height: 34,
                          label: 'Add to Cart',
                          icon: Icons.shopping_bag_outlined,
                          onPressed: onAddToCart,
                        )
                      else
                        Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            border: Border.all(color: AppColors.emerald),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: onDecrease,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.remove, size: 16, color: AppColors.emerald),
                                ),
                              ),
                              CommonText.labelMedium(
                                '$cartQuantity',
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w800,
                              ),
                              InkWell(
                                onTap: onIncrease,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.add, size: 16, color: AppColors.emerald),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} L';
    }
    return amount.toStringAsFixed(0);
  }
}

class _DesignDetailModal extends StatelessWidget {
  const _DesignDetailModal({required this.design, required this.store});

  final JewelleryDesign design;
  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: design.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(design.category.icon, size: 36, color: design.accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            design.purity,
                            style: const TextStyle(color: AppColors.pureWhite, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CommonText.labelMedium(design.code, color: AppColors.muted),
                      ],
                    ),
                    const SizedBox(height: 4),
                    CommonText.titleLarge(design.name),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CommonText.bodyMedium(design.description, color: AppColors.muted),
          const SizedBox(height: 18),
          CommonCard(
            backgroundColor: AppColors.canvas,
            child: Column(
              children: [
                _specRow('Gross Weight', '${design.grossWeightGrams} g'),
                const Divider(height: 14),
                _specRow('Net Gold Weight', '${design.netGoldWeightGrams} g'),
                const Divider(height: 14),
                _specRow('Diamond Carat Weight', design.diamondCarats > 0 ? '${design.diamondCarats} cts' : 'None'),
                const Divider(height: 14),
                _specRow('Making Charges', '₹${design.makingChargesPerGram}/g'),
                const Divider(height: 14),
                _specRow('Est. Total (Approx)', '₹${design.estimatedPrice.toStringAsFixed(0)}', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CommonButton.primary(
            label: 'Add to Order Cart',
            icon: Icons.shopping_bag_outlined,
            onPressed: () {
              store.addToCart(design);
              Navigator.pop(context);
              CommonSnackbar.success(
                context,
                title: 'Added to Cart',
                message: '${design.name} has been added.',
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonText.bodySmall(label, color: AppColors.muted),
        Text(
          value,
          style: TextStyle(
            color: isBold ? AppColors.emerald : AppColors.ink,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: isBold ? 14 : 13,
          ),
        ),
      ],
    );
  }
}
