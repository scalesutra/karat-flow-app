import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../core/widgets/common_text.dart';
import '../../../../core/widgets/common_text_field.dart';
import '../../../../data/demo_store.dart';
import '../../../../data/repositories/karatflow_api_repository.dart';
import '../../../../domain/models.dart';

/// New Order creation modal with Client, Designs, Quantity, and Due Date
class NewOrderSheet extends StatefulWidget {
  const NewOrderSheet({super.key, required this.store});

  final DemoStore store;

  static Future<void> show(BuildContext context, DemoStore store) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => NewOrderSheet(store: store),
    );
  }

  @override
  State<NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends State<NewOrderSheet> {
  ClientInfo? _selectedClient;
  final Map<String, int> _selectedQuantities = {};
  String _dueDate = 'Due Today · 6:00 PM';
  final _notesController = TextEditingController();

  final List<String> _dueDatePresets = const [
    'Due Today · 6:00 PM',
    'Due Tomorrow · 12:00 PM',
    'Due in 3 Days',
    'Due Friday',
    'Due next Monday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.store.clients.isNotEmpty) {
      _selectedClient = widget.store.clients.first;
    }
    if (widget.store.designs.isNotEmpty) {
      _selectedQuantities[widget.store.designs.first.code] = 1;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final designs = widget.store.designs;
    final clients = widget.store.clients;

    int totalPcs = 0;
    double totalWeight = 0.0;
    for (final entry in _selectedQuantities.entries) {
      if (entry.value > 0) {
        final d = designs.firstWhere(
          (item) => item.code == entry.key,
          orElse: () => designs.first,
        );
        totalPcs += entry.value;
        totalWeight += d.grossWeightGrams * entry.value;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CommonText.headlineMedium('Create New Order'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$totalPcs pcs · ${totalWeight.toStringAsFixed(1)}g',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                // 1. SELECT CLIENT
                const Text(
                  '1. Select Client',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ClientInfo>(
                      value: _selectedClient,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.ink),
                      items: clients.map((c) {
                        return DropdownMenuItem<ClientInfo>(
                          value: c,
                          child: Row(
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  size: 16, color: AppColors.emerald),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${c.firmName} · ${c.city}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (c) {
                        if (c != null) setState(() => _selectedClient = c);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. SELECT DESIGNS & QUANTITIES
                const Text(
                  '2. Select Designs & Quantity for Each Design',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                ...designs.map((design) {
                  final qty = _selectedQuantities[design.code] ?? 0;
                  final isSelected = qty > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.paper : AppColors.canvas,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.emerald
                            : AppColors.outlineLight,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.emerald,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedQuantities[design.code] = 1;
                              } else {
                                _selectedQuantities.remove(design.code);
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                design.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isSelected
                                      ? AppColors.ink
                                      : AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${design.code} · ${design.purity} · ${design.grossWeightGrams}g/pc',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (qty > 1) {
                                      _selectedQuantities[design.code] =
                                          qty - 1;
                                    } else {
                                      _selectedQuantities
                                          .remove(design.code);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.outlineLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.remove, size: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedQuantities[design.code] = qty + 1;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.add,
                                      size: 14, color: AppColors.emerald),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // 3. SELECT DUE DATE
                const Text(
                  '3. Due Date / Dispatch Deadline',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _dueDatePresets.map((preset) {
                    final isSel = _dueDate == preset;
                    return InkWell(
                      onTap: () => setState(() => _dueDate = preset),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.ink : AppColors.canvas,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                          border: Border.all(
                            color:
                                isSel ? AppColors.ink : AppColors.outline,
                          ),
                        ),
                        child: Text(
                          preset,
                          style: TextStyle(
                            color: isSel
                                ? AppColors.pureWhite
                                : AppColors.ink,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 4. NOTES
                CommonTextField(
                  controller: _notesController,
                  label:
                      'Special Instructions / Karigar Note (Optional)',
                  hintText:
                      'e.g. Urgent bridal delivery, 22K antique polish...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // CONFIRM BUTTON
          CommonButton.primary(
            label: totalPcs > 0
                ? 'Confirm Order ($totalPcs pcs · ${totalWeight.toStringAsFixed(1)}g)'
                : 'Select at least 1 design',
            onPressed: totalPcs > 0 && _selectedClient != null
                ? () async {
                    final List<Map<String, dynamic>> orderItems = [];
                    final List<Map<String, dynamic>> apiParts = [];
                    for (final entry in _selectedQuantities.entries) {
                      if (entry.value > 0) {
                        final d = designs.firstWhere(
                            (item) => item.code == entry.key);
                        orderItems.add({
                          'design': d,
                          'quantity': entry.value,
                        });
                        apiParts.add({
                          'designNumber': d.code,
                          'quantity': entry.value,
                          'grossWeight': d.grossWeightGrams * entry.value,
                          'notes': _notesController.text.trim(),
                        });
                      }
                    }

                    try {
                      debugPrint(
                          '📦 [NewOrderSheet] Calling POST /orders via createMultiDesignOrder API for ${_selectedClient!.firmName}...');
                      final apiRepo = KaratFlowApiRepository();
                      await apiRepo.createMultiDesignOrder(
                        customerId: _selectedClient!.id,
                        dueDate: _dueDate,
                        specialInstructions: _notesController.text.trim(),
                        parts: apiParts,
                      );
                      debugPrint(
                          '✅ [NewOrderSheet] Order created on live API successfully!');

                      final newOrder = widget.store.createDirectOrder(
                        client: _selectedClient!,
                        items: orderItems,
                        dueDate: _dueDate,
                        notes: _notesController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        CommonSnackbar.success(
                          context,
                          title: 'Order Created',
                          message:
                              'Order ${newOrder.id} placed for ${_selectedClient!.firmName} on server.',
                        );
                      }
                    } catch (e) {
                      debugPrint(
                          '❌ [NewOrderSheet] Failed to call POST /orders API: $e');
                      if (context.mounted) {
                        CommonSnackbar.error(
                          context,
                          title: 'Order Placement Failed',
                          message: 'Server error: ${e.toString()}',
                        );
                      }
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
