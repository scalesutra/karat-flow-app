import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../../data/mappers/api_domain_mapper.dart';
import '../../domain/models.dart';
import 'bloc/orders_bloc.dart';

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
    if (widget.store.designs.isEmpty) {
      setState(() => _isLoading = true);
    }
    context.read<OrdersBloc>().add(const FetchDesignsCatalogEvent());
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
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
        final filteredDesigns = widget.store
            .designsForCategory(_category)
            .where((d) {
              if (_searchQuery.isEmpty) return true;
              final q = _searchQuery.toLowerCase();
              return d.name.toLowerCase().contains(q) ||
                  d.code.toLowerCase().contains(q) ||
                  d.description.toLowerCase().contains(q);
            })
            .toList();

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
                                AppStrings.navDesigns.trClean,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldLight,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag,
                                  size: 16,
                                  color: AppColors.emerald,
                                ),
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
                      hintText:
                          'Search by code (e.g. NK-842) or design name...',
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
                child: (_isLoading && widget.store.designs.isEmpty)
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
                        showIndicator: false,
                        onRefresh: _fetchLiveCatalogue,
                        child: filteredDesigns.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: CommonEmptyState(
                                  icon: Icons.search_off,
                                  title: 'No designs found',
                                  description:
                                      'Try adjusting your category or search terms.',
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  28,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 0.62,
                                    ),
                                itemCount: filteredDesigns.length,
                                itemBuilder: (context, index) {
                                  final design = filteredDesigns[index];
                                  final cartItem = widget.store.cart
                                      .where(
                                        (item) => item.design.id == design.id,
                                      )
                                      .firstOrNull;

                                  return _DesignCard(
                                    design: design,
                                    cartQuantity: cartItem?.quantity ?? 0,
                                    onAddToCart: () {
                                      if (!design.hasBackendPrice) {
                                        CommonSnackbar.error(
                                          context,
                                          title: 'Price Unavailable',
                                          message:
                                              'This design has no backend price and cannot be added yet.',
                                        );
                                        return;
                                      }
                                      widget.store.addToCart(design);
                                    },
                                    onIncrease: () {
                                      if (!design.hasBackendPrice) return;
                                      widget.store.addToCart(design);
                                    },
                                    onDecrease: () =>
                                        widget.store.updateCartQuantity(
                                          design.id,
                                          (cartItem?.quantity ?? 1) - 1,
                                        ),
                                    onTap: () => _showDesignDetailsSheet(
                                      context,
                                      design,
                                    ),
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
      builder: (ctx) => _DesignDetailModal(design: design, store: widget.store),
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
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: design.accentColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CadImageToggle(
                  croppedUrl: design.imageUrl,
                  rawCadSheetUrl: design.rawCadSheetUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusLarge),
                  ),
                  fallbackWidget: Center(
                    child: Icon(
                      design.category.icon,
                      size: 48,
                      color: design.accentColor,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                    ),
                    child: Text(
                      design.purity.split(' ').first,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                        _formatDesignCode(design.code),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (design.sizeDimensions != null &&
                                design.sizeDimensions!.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: Text(
                                  design.sizeDimensions!.trim(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
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
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            design.hasBackendPrice
                                ? '₹${_formatPrice(design.estimatedPrice)}'
                                : 'Price unavailable',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                            ),
                          ),
                          if (design.priceBreakdown != null &&
                              (design.priceBreakdown!.gstPercent > 0 ||
                                  design.priceBreakdown!.gstAmount > 0)) ...[
                            const SizedBox(width: 4),
                            Text(
                              '+${design.priceBreakdown!.gstPercent > 0 ? '${design.priceBreakdown!.gstPercent.toInt()}% ' : ''}GST',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
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
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMedium,
                            ),
                            border: Border.all(color: AppColors.emerald),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: onDecrease,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: AppColors.emerald,
                                  ),
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
                                  child: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: AppColors.emerald,
                                  ),
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

class _DesignDetailModal extends StatefulWidget {
  const _DesignDetailModal({required this.design, required this.store});

  final JewelleryDesign design;
  final DemoStore store;

  @override
  State<_DesignDetailModal> createState() => _DesignDetailModalState();
}

class _DesignDetailModalState extends State<_DesignDetailModal> {
  late JewelleryDesign _design;
  int _selectedImageIndex = 0;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _design = widget.design;
    _fetchFullDetailsIfNeeded();
  }

  Future<void> _fetchFullDetailsIfNeeded() async {
    if (_design.priceBreakdown != null && _design.galleryImages.isNotEmpty)
      return;
    setState(() => _isLoadingDetails = true);
    try {
      final repo = KaratFlowApiRepository();
      final fullApiDesign = await repo.getCatalogItemDetails(_design.id);
      if (mounted) {
        setState(() {
          _design = ApiDomainMapper.threeDDesign(fullApiDesign);
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  List<String> get _allImages {
    final list = <String>[];
    if (_design.heroImageUrl.isNotEmpty) list.add(_design.heroImageUrl);
    for (final img in _design.galleryImages) {
      if (img.url.isNotEmpty && !list.contains(img.url)) list.add(img.url);
    }
    if (_design.imageUrl.isNotEmpty && !list.contains(_design.imageUrl)) {
      list.add(_design.imageUrl);
    }
    return list;
  }

  String get _currentImageUrl {
    final images = _allImages;
    if (images.isEmpty) return _design.imageUrl;
    if (_selectedImageIndex >= 0 && _selectedImageIndex < images.length) {
      return images[_selectedImageIndex];
    }
    return images.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 14),

            // Header: Purity Badge & SKU
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _design.purity.isNotEmpty ? _design.purity : '22K Gold',
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatDesignCode(_design.code),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CommonText.titleLarge(_design.name),
            const SizedBox(height: 12),

            // Main Featured Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _design.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CadImageToggle(
                  croppedUrl: _currentImageUrl,
                  rawCadSheetUrl: _design.rawCadSheetUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(16),
                  fallbackWidget: Center(
                    child: Icon(
                      _design.category.icon,
                      size: 64,
                      color: _design.accentColor,
                    ),
                  ),
                ),
              ),
            ),

            // Gallery Thumbnails Strip (Priority 1 Gallery Images)
            if (_allImages.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _allImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final isSelected = i == _selectedImageIndex;
                    final imgUrl = _allImages[i];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImageIndex = i),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.emerald
                                : AppColors.outlineLight,
                            width: isSelected ? 2.5 : 1,
                          ),
                          color: AppColors.canvas,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CadImageToggle(
                            croppedUrl: imgUrl,
                            rawCadSheetUrl: '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 14),
            CommonText.bodyMedium(_design.description, color: AppColors.muted),



            const SizedBox(height: 16),

            CommonCard(
              backgroundColor: AppColors.canvas,
              child: Column(
                children: [
                  _specRow(
                    'Metal & Purity',
                    _design.purity.isNotEmpty
                        ? _design.purity
                        : 'Not Specified',
                    isBold: true,
                  ),
                  if (_design.sizeDimensions != null &&
                      _design.sizeDimensions!.trim().isNotEmpty) ...[
                    const Divider(height: 14),
                    _specRow(
                      'Size / Dimensions',
                      _design.sizeDimensions!.trim(),
                    ),
                  ],
                  const Divider(height: 14),
                  _specRow(
                    'Gem Summary',
                    _design.gemQuantity > 0 || _design.diamondCarats > 0
                        ? '${_design.gemQuantity > 0 ? "${_design.gemQuantity} Gems · " : ""}${_design.diamondCarats} ct TW'
                        : 'None',
                  ),
                  const Divider(height: 14),
                  _specRow(
                    'Backend Price',
                    _design.hasBackendPrice
                        ? '₹${_design.estimatedPrice.toStringAsFixed(0)}'
                        : 'Not provided',
                    isBold: true,
                  ),
                ],
              ),
            ),

            // ── Detailed Price Breakdown with Live GST ────────────────
            if (_isLoadingDetails) ...[
              const SizedBox(height: 14),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ] else if (_design.priceBreakdown != null &&
                (_design.priceBreakdown!.finalPrice > 0 ||
                    _design.priceBreakdown!.totalGoldCost > 0 ||
                    _design.priceBreakdown!.totalGemCost > 0)) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: AppColors.emeraldDark,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Live Price Calculation Breakdown',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _specRow(
                      'Gold Cost (${_design.priceBreakdown!.netGoldWeight}g @ ₹${_design.priceBreakdown!.goldRatePerGram.toStringAsFixed(0)}/g)',
                      '₹${_design.priceBreakdown!.totalGoldCost.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _specRow(
                      'Gem Cost (${_design.priceBreakdown!.gemQuantity} Gems)',
                      '₹${_design.priceBreakdown!.totalGemCost.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _specRow(
                      'Subtotal',
                      '₹${_design.priceBreakdown!.subtotal.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 6),
                    _specRow(
                      'GST (${_design.priceBreakdown!.gstPercent}%)',
                      '₹${_design.priceBreakdown!.gstAmount.toStringAsFixed(0)}',
                    ),
                    const Divider(height: 12),
                    _specRow(
                      'Final Price',
                      '₹${_design.priceBreakdown!.finalPrice.toStringAsFixed(0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],

            // ── Detailed Gem Breakdown Table ─────────────────────────────
            if (_design.gemBreakdown.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineLight),
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
                              Icons.diamond_outlined,
                              size: 16,
                              color: AppColors.ink,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Gem Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Total ${_design.gemQuantity} Gems',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._design.gemBreakdown.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${g.count}x ${g.shape} (${g.dimensions})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${g.weightTw.toStringAsFixed(2)} ct TW',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emeraldDark,
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
            const SizedBox(height: 20),
            CommonButton.primary(
              label: _design.hasBackendPrice
                  ? 'Add to Order Cart'
                  : 'Backend Price Required',
              icon: Icons.shopping_bag_outlined,
              onPressed: _design.hasBackendPrice
                  ? () {
                      widget.store.addToCart(_design);
                      Navigator.pop(context);
                      CommonSnackbar.success(
                        context,
                        title: 'Added to Cart',
                        message: '${_design.name} has been added.',
                        duration: const Duration(seconds: 2),
                      );
                    }
                  : null,
            ),
          ],
        ),
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

String _formatDesignCode(String code) {
  if (code.isEmpty) return 'SKU: #----';
  if (code.length > 12 && code.contains('-')) {
    return 'SKU: #${code.substring(0, 8).toUpperCase()}';
  }
  if (code.toUpperCase().startsWith('SKU:')) return code;
  return code.startsWith('#') ? 'SKU: $code' : 'SKU: #$code';
}
