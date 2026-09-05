import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/localization.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../front_office/bloc/orders_bloc.dart';
import '../workshop/bloc/workshop_bloc.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.store, this.onBrowseDesigns});

  final DemoStore store;
  final VoidCallback? onBrowseDesigns;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  ClientInfo? _selectedClient;
  final _clientController = TextEditingController();
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 2));
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.emerald,
              onPrimary: AppColors.pureWhite,
              surface: AppColors.paper,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.store.clients.isNotEmpty) {
      _selectedClient = widget.store.clients.first;
      _clientController.text =
          '${_selectedClient!.firmName} · ${_selectedClient!.city}';
    }
  }

  @override
  void dispose() {
    _clientController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (!_isSubmitting) return;
        if (state is OrderOperationSuccess) {
          setState(() => _isSubmitting = false);
          context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
          CommonSnackbar.success(
            context,
            title: 'Order Committed',
            message: state.message,
          );
        } else if (state is OrdersError) {
          setState(() => _isSubmitting = false);
          CommonSnackbar.error(
            context,
            title: 'Order Placement Failed',
            message: '${state.message} Cart was kept unchanged.',
          );
        }
      },
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final cartItems = widget.store.cart;

          if (cartItems.isEmpty) {
            return SafeArea(
              top: false,
              child: CommonEmptyState(
                icon: Icons.shopping_bag_outlined,
                title: AppStrings.cartEmpty.trClean,
                description:
                    'Browse our wholesale jewellery designs and select pieces for commitment.',
                actionLabel: 'Browse Catalogue',
                onAction: widget.onBrowseDesigns,
              ),
            );
          }

          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText.headlineLarge(AppStrings.orderCart.trClean),
                        const SizedBox(height: 2),
                        CommonText.bodySmall(
                          '${widget.store.cartItemsCount} designs selected',
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        widget.store.clearCart();
                        CommonSnackbar.info(
                          context,
                          title: 'Cart Cleared',
                          message: 'All items removed from cart.',
                        );
                      },
                      icon: const Icon(
                        Icons.delete_sweep,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'Clear',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Client Search & Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionHeader(
                      title: '1. Client Firm',
                      icon: Icons.storefront,
                    ),
                    if (_selectedClient != null)
                      Text(
                        'Assigned: ${_selectedClient!.firmName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                CommonTextField(
                  controller: _clientController,
                  hintText: 'Type client name, firm or phone number...',
                  prefixIcon: Icons.storefront_outlined,
                  suffixIcon: _clientController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _clientController.clear();
                              _selectedClient = null;
                            });
                          },
                        )
                      : null,
                  onChanged: (val) {
                    setState(() {
                      final query = val.trim().toLowerCase();
                      final matched = widget.store.clients.where((c) {
                        return c.firmName.toLowerCase().contains(query) ||
                            c.city.toLowerCase().contains(query) ||
                            c.contactPerson.toLowerCase().contains(query) ||
                            c.phone.contains(query);
                      }).firstOrNull;

                      if (matched != null &&
                          query == matched.firmName.toLowerCase()) {
                        _selectedClient = matched;
                      } else {
                        _selectedClient = ClientInfo(
                          id: matched?.id ??
                              'CUSTOM-${DateTime.now().millisecondsSinceEpoch}',
                          firmName: val.trim().isNotEmpty
                              ? val.trim()
                              : 'Custom Client',
                          city: matched?.city ?? '',
                          contactPerson: matched?.contactPerson ?? '',
                          phone: matched?.phone ?? '',
                          creditLimitLakhs: 0,
                          outstandingBalance: 0,
                          activeOrdersCount: 0,
                        );
                      }
                    });
                  },
                ),
                Builder(
                  builder: (context) {
                    final q = _clientController.text.trim().toLowerCase();
                    if (q.isEmpty) return const SizedBox.shrink();
                    final suggestions = widget.store.clients.where((c) {
                      return c.firmName.toLowerCase().contains(q) ||
                          c.city.toLowerCase().contains(q);
                    }).toList();
                    if (suggestions.isEmpty ||
                        (suggestions.length == 1 &&
                            suggestions.first.firmName.toLowerCase() == q)) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                        border: Border.all(color: AppColors.outlineLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: suggestions.take(3).map((c) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedClient = c;
                                _clientController.text =
                                    '${c.firmName} · ${c.city}';
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.business,
                                    size: 14,
                                    color: AppColors.emerald,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.firmName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${c.city})',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 2. Selected Items
                const _SectionHeader(
                  title: '2. Jewellery Items',
                  icon: Icons.diamond_outlined,
                ),
                const SizedBox(height: 8),
                for (final item in cartItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CartItemCard(
                      item: item,
                      onIncrease: () => widget.store.addToCart(item.design),
                      onDecrease: () => widget.store.updateCartQuantity(
                        item.design.id,
                        item.quantity - 1,
                      ),
                      onRemove: () =>
                          widget.store.removeFromCart(item.design.id),
                    ),
                  ),

                const SizedBox(height: 20),

                // 3. Due Date / Dispatch Deadline
                const _SectionHeader(
                  title: '3. Due Date / Dispatch Deadline',
                  icon: Icons.event_available,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDueDate(context),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: AppColors.emerald,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery / Due Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(_selectedDueDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSmall,
                            ),
                          ),
                          child: const Text(
                            'Select Date',
                            style: TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CommonTextField(
                  controller: _notesController,
                  hintText:
                      'Special instructions for workshop (e.g. Rhodium polish, BIS hallmark)...',
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // 4. Weight & Financial Summary
                CommonCard(
                  backgroundColor: AppColors.ink,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CommonText.bodyMedium(
                            'Total Items Count',
                            color: Colors.white70,
                          ),
                          CommonText.bodyLarge(
                            '${widget.store.cartItemsCount} pcs',
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CommonText.bodyMedium(
                            'Est. Total Value',
                            color: Colors.white70,
                          ),
                          Text(
                            '₹${widget.store.cartTotalEstimatedPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                CommonButton.primary(
                  isLoading: _isSubmitting,
                  icon: Icons.check_circle_outline,
                  label: 'Commit & Place Order',
                  onPressed: _placeOrder,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _placeOrder() async {
    final client = _selectedClient;
    if (client == null) {
      CommonSnackbar.error(
        context,
        title: 'Client Required',
        message: 'Please select a client for this order.',
      );
      return;
    }
    final cartItems = widget.store.cart;
    if (cartItems.isEmpty) return;
    if (cartItems.any((item) => !item.design.hasBackendPrice)) {
      CommonSnackbar.error(
        context,
        title: 'Price Required',
        message:
            'Every selected design must have a valid backend price before the order can be placed.',
      );
      return;
    }
    if (cartItems.any((item) => item.design.code.trim().isEmpty)) {
      CommonSnackbar.error(
        context,
        title: 'Invalid Design',
        message: 'Every cart item must have a backend design number.',
      );
      return;
    }
    final notes = _notesController.text.trim();
    final parts = cartItems
        .map(
          (item) => <String, dynamic>{
            'designNumber': item.design.code,
            'quantity': item.quantity,
            'grossWeight': double.parse(
              item.totalGrossWeight.toStringAsFixed(3),
            ),
            'notes': [
              item.selectedPurity,
              if (notes.isNotEmpty) notes,
            ].join(' · '),
          },
        )
        .toList(growable: false);
    setState(() => _isSubmitting = true);
    context.read<OrdersBloc>().add(
      CreateAndCheckoutOrderEvent(
        customerId: client.id,
        dueDate: _selectedDueDate.toUtc().toIso8601String(),
        specialInstructions: notes,
        parts: parts,
        clearCart: true,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.emerald),
        const SizedBox(width: 8),
        CommonText.titleMedium(title),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.design.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              item.design.category.icon,
              color: item.design.accentColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.design.purity,
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.design.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                CommonText.bodySmall(
                  '₹${item.totalEstimatedPrice.toStringAsFixed(0)}',
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 20,
                  color: AppColors.muted,
                ),
                onPressed: onDecrease,
              ),
              CommonText.labelLarge(
                '${item.quantity}',
                fontWeight: FontWeight.w800,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: AppColors.emerald,
                ),
                onPressed: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
