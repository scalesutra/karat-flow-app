import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';

/// Result returned by SearchableOrderPartPickerSheet containing the database UUID and friendly label.
class PickedOrderPartResult {
  const PickedOrderPartResult({
    required this.partId,
    required this.displayLabel,
    this.orderNumber = '',
  });

  final String partId;
  final String displayLabel;
  final String orderNumber;
}

/// Searchable Bottom Sheet for selecting Order / Order Part / Pouch Ref.
/// Supports live search across Order #, customer firm name, design codes & part IDs,
/// as well as custom manual reference entry.
class SearchableOrderPartPickerSheet extends StatefulWidget {
  const SearchableOrderPartPickerSheet({
    super.key,
    this.currentOrderPartId,
    this.initialOrders = const [],
  });

  final String? currentOrderPartId;
  final List<CustomerOrder> initialOrders;

  static Future<PickedOrderPartResult?> show(
    BuildContext context, {
    String? currentOrderPartId,
    List<CustomerOrder> initialOrders = const [],
  }) {
    return showModalBottomSheet<PickedOrderPartResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchableOrderPartPickerSheet(
        currentOrderPartId: currentOrderPartId,
        initialOrders: initialOrders,
      ),
    );
  }

  @override
  State<SearchableOrderPartPickerSheet> createState() =>
      _SearchableOrderPartPickerSheetState();
}

class _SearchableOrderPartPickerSheetState
    extends State<SearchableOrderPartPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final KaratFlowApiRepository _repo = KaratFlowApiRepository();
  Timer? _debounceTimer;

  List<CustomerOrder> _orders = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.initialOrders);
    if (_orders.isEmpty) {
      _fetchInitialOrders();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.listOrdersPage(page: 1, limit: 30);
      if (mounted) {
        setState(() {
          _orders = res.orders.map(ApiDomainMapper.order).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value.trim());
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final res = await _repo.listOrdersPage(
          search: value.trim(),
          page: 1,
          limit: 30,
        );
        if (mounted) {
          setState(() {
            _orders = res.orders.map(ApiDomainMapper.order).toList();
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: AppColors.goldDark,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Select Order / Part Ref',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Order #, Customer, Design Code...',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtle,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _query.isNotEmpty
                    ? IconButton(
                        iconSize: 16,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: AppColors.muted,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outlineLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outlineLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.goldDark,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // Custom Input shortcut if user typed something
          if (_query.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: InkWell(
                onTap: () {
                  final trimmed = _query.trim();
                  if (KaratFlowApiRepository.isValidUuid(trimmed)) {
                    Navigator.of(context).pop(
                      PickedOrderPartResult(
                        partId: trimmed,
                        displayLabel: trimmed,
                      ),
                    );
                    return;
                  }
                  final matched = _orders.where((o) {
                    final ordNum = ApiDomainMapper.formatOrderNumber(o.id);
                    return ordNum.toLowerCase() == trimmed.toLowerCase() ||
                        o.id.toLowerCase() == trimmed.toLowerCase();
                  }).firstOrNull;
                  if (matched != null) {
                    final partId = matched.designs.isNotEmpty &&
                            matched.designs.first.partId.isNotEmpty
                        ? matched.designs.first.partId
                        : matched.apiId;
                    final ordNum = ApiDomainMapper.formatOrderNumber(matched.id);
                    Navigator.of(context).pop(
                      PickedOrderPartResult(
                        partId: partId,
                        displayLabel: '$ordNum • ${matched.clientFirmName}',
                        orderNumber: ordNum,
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an order from the list to get its valid ID.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.goldDark.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: AppColors.goldDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use custom ref: "$_query"',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.goldDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const Divider(height: 1, color: AppColors.outlineLight),

          // Orders / Parts List
          Expanded(
            child: _orders.isEmpty && !_isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: AppColors.muted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _query.isEmpty
                                ? 'No orders loaded'
                                : 'No order matching "$_query"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final orderNum = ApiDomainMapper.formatOrderNumber(order.id);
                      final clientName = order.clientFirmName.isNotEmpty
                          ? order.clientFirmName
                          : 'Order #$orderNum';

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order header row - CLICKABLE ON 1 TAP!
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () {
                                  final partId = order.designs.isNotEmpty &&
                                          order.designs.first.partId.isNotEmpty
                                      ? order.designs.first.partId
                                      : order.apiId;
                                  final displayLabel = order.designs.isNotEmpty &&
                                          order.designs.first.designNumber.isNotEmpty
                                      ? '$orderNum • ${order.designs.first.designNumber}'
                                      : '$orderNum • $clientName';
                                  Navigator.of(context).pop(
                                    PickedOrderPartResult(
                                      partId: partId,
                                      displayLabel: displayLabel,
                                      orderNumber: orderNum,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.canvas,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppColors.outlineLight,
                                                ),
                                              ),
                                              child: Text(
                                                orderNum,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                clientName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.goldDark
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Pick Order',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.goldDark,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Icon(
                                              Icons.check_rounded,
                                              size: 12,
                                              color: AppColors.goldDark,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // If order has designs/parts, show clickable part chips
                            if (order.designs.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: order.designs.map((design) {
                                    final partRef = design.partId.isNotEmpty
                                        ? design.partId
                                        : (design.designNumber.isNotEmpty
                                            ? '$orderNum-${design.designNumber}'
                                            : orderNum);

                                    final isCurrent =
                                        widget.currentOrderPartId == partRef;

                                    return InkWell(
                                      onTap: () {
                                        final partId = design.partId.isNotEmpty
                                            ? design.partId
                                            : order.apiId;
                                        final displayLabel =
                                            '$orderNum • ${design.designNumber.isNotEmpty ? design.designNumber : (design.designName.isNotEmpty ? design.designName : 'Part')}';
                                        Navigator.of(context).pop(
                                          PickedOrderPartResult(
                                            partId: partId,
                                            displayLabel: displayLabel,
                                            orderNumber: orderNum,
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? AppColors.emerald.withValues(alpha: 0.15)
                                              : AppColors.canvas,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isCurrent
                                                ? AppColors.emerald
                                                : AppColors.outlineLight,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.diamond_outlined,
                                              size: 11,
                                              color: isCurrent
                                                  ? AppColors.emerald
                                                  : AppColors.muted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              design.designNumber.isNotEmpty
                                                  ? design.designNumber
                                                  : partRef,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: isCurrent
                                                    ? AppColors.emerald
                                                    : AppColors.ink,
                                              ),
                                            ),
                                            if (design.currentStage.isNotEmpty) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '(${design.currentStage})',
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
