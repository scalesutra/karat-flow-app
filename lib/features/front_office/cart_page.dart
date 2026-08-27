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
  String _promiseOption = 'Due Tomorrow Â· 6 PM';
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _promiseOptions = const [
    'Due Today Â· Urgent',
    'Due Tomorrow Â· 6 PM',
    'Due in 3 Days',
    'Due Next Monday',
    'Custom Date',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.store.clients.isNotEmpty) {
      _selectedClient = widget.store.clients.first;
    }
  }

  @override
  void dispose() {
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

                // 1. Client Selection Card
                const _SectionHeader(
                  title: '1. Select Client Firm',
                  icon: Icons.storefront,
                ),
                const SizedBox(height: 8),
                CommonCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onTap: () => _openClientPicker(context),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.emeraldLight,
                        radius: 20,
                        child: Icon(
                          Icons.business,
                          color: AppColors.emerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedClient?.firmName ?? 'Select Client',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedClient != null
                                  ? '${_selectedClient!.city} Â· ${_selectedClient!.contactPerson}'
                                  : 'Tap to assign this order to a client',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _promiseOptions.map((opt) {
                    final isSelected = _promiseOption == opt;
                    return InkWell(
                      onTap: () => setState(() => _promiseOption = opt),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.emeraldLight
                              : AppColors.paper,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.emerald
                                : AppColors.outline,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.emerald,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              opt,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.emeraldDark
                                    : AppColors.ink,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                            'Total Gross Weight',
                            color: Colors.white70,
                          ),
                          Text(
                            '${widget.store.cartTotalGrossWeight.toStringAsFixed(2)} g',
                            style: const TextStyle(
                              color: Color(0xFFFFD18A),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
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
                            'â‚¹${widget.store.cartTotalEstimatedPrice.toStringAsFixed(0)}',
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

  void _openClientPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
            const CommonText.headlineMedium('Select Client Firm'),
            const SizedBox(height: 12),
            for (final client in widget.store.clients)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.emeraldLight,
                  child: Icon(Icons.business, color: AppColors.emerald),
                ),
                title: Text(
                  client.firmName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${client.city} Â· ${client.contactPerson}'),
                trailing: _selectedClient?.id == client.id
                    ? const Icon(Icons.check, color: AppColors.emerald)
                    : null,
                onTap: () {
                  setState(() => _selectedClient = client);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
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
        dueDate: _apiDueDate().toUtc().toIso8601String(),
        specialInstructions: notes,
        parts: parts,
        clearCart: true,
      ),
    );
  }

  DateTime _apiDueDate() {
    final now = DateTime.now();
    if (_promiseOption.startsWith('Due Today')) {
      return DateTime(now.year, now.month, now.day, 23, 59);
    }
    if (_promiseOption.startsWith('Due Tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18);
    }
    if (_promiseOption == 'Due in 3 Days') {
      return now.add(const Duration(days: 3));
    }
    if (_promiseOption == 'Due Next Monday') {
      final days = (DateTime.monday - now.weekday + 7) % 7;
      return now.add(Duration(days: days == 0 ? 7 : days));
    }
    return now.add(const Duration(days: 7));
  }

  void _showOrderSuccessDialog(CustomerOrder order) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.emeraldLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.emerald,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Order ${order.id} Committed!',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Assigned to ${_selectedClient?.firmName}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Items Selected',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${order.itemsCount} Items (${order.itemsSummary})',
                            maxLines: 1,
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Gross Weight',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${order.totalGrossGrams.toStringAsFixed(2)} g',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Delivery Target',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.promiseDate,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.emeraldDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  label: 'Done & Back to Catalogue',
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onBrowseDesigns?.call();
                  },
                ),
              ),
            ],
          ),
        ),
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
                  '${item.totalGrossWeight.toStringAsFixed(1)}g GW Â· â‚¹${item.totalEstimatedPrice.toStringAsFixed(0)}',
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
