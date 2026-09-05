import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_text.dart';
import '../../../../core/widgets/common_text_field.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';
import '../bloc/orders_bloc.dart';

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
  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 2));
  final _notesController = TextEditingController();
  final _clientSearchController = TextEditingController();
  final _designSearchController = TextEditingController();
  bool _isClientDropdownOpen = false;

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
      _clientSearchController.text =
          '${_selectedClient!.firmName} · ${_selectedClient!.city}';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _clientSearchController.dispose();
    _designSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final designs = widget.store.designs;
    final clients = widget.store.clients;

    final clientQuery = _clientSearchController.text.trim().toLowerCase();
    final filteredClients = clients.where((c) {
      if (clientQuery.isEmpty) return true;
      return c.firmName.toLowerCase().contains(clientQuery) ||
          c.city.toLowerCase().contains(clientQuery) ||
          c.contactPerson.toLowerCase().contains(clientQuery) ||
          c.phone.contains(clientQuery);
    }).toList();

    final designQuery = _designSearchController.text.trim().toLowerCase();
    final searchedDesigns = designQuery.isEmpty
        ? <JewelleryDesign>[]
        : designs.where((d) {
            return d.name.toLowerCase().contains(designQuery) ||
                d.code.toLowerCase().contains(designQuery) ||
                d.purity.toLowerCase().contains(designQuery);
          }).toList();

    final selectedDesignsList = designs.where((d) {
      return (_selectedQuantities[d.code] ?? 0) > 0;
    }).toList();

    int totalPcs = 0;
    for (final entry in _selectedQuantities.entries) {
      if (entry.value > 0) {
        totalPcs += entry.value;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$totalPcs pcs',
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
                // 1. SELECT CLIENT (Searchable & Editable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '1. Select Client',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    if (_selectedClient != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Selected: ${_selectedClient!.firmName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                CommonTextField(
                  controller: _clientSearchController,
                  hintText: 'Type to filter or enter client name...',
                  prefixIcon: Icons.storefront_outlined,
                  onTap: () {
                    setState(() {
                      _isClientDropdownOpen = true;
                    });
                  },
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_clientSearchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _clientSearchController.clear();
                              _selectedClient = null;
                              _isClientDropdownOpen = true;
                            });
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          _isClientDropdownOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.ink,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isClientDropdownOpen = !_isClientDropdownOpen;
                          });
                        },
                      ),
                    ],
                  ),
                  onChanged: (val) {
                    setState(() {
                      _isClientDropdownOpen = true;
                      final query = val.trim().toLowerCase();
                      final matched = clients.where((c) {
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
                          id:
                              matched?.id ??
                              'CUSTOM-${DateTime.now().millisecondsSinceEpoch}',
                          firmName: val.trim().isNotEmpty
                              ? val.trim()
                              : (clients.isNotEmpty
                                    ? clients.first.firmName
                                    : 'Guest Client'),
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
                if (_isClientDropdownOpen) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                      border: Border.all(color: AppColors.outline),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSmall,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: filteredClients.isEmpty
                            ? [
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    'Use custom client: "${_clientSearchController.text.trim()}"',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _isClientDropdownOpen = false;
                                    });
                                  },
                                ),
                              ]
                            : filteredClients.map((c) {
                                final isSelected =
                                    _selectedClient?.id == c.id ||
                                    _selectedClient?.firmName == c.firmName;
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  leading: const Icon(
                                    Icons.storefront_outlined,
                                    size: 16,
                                    color: AppColors.emerald,
                                  ),
                                  title: Text(
                                    '${c.firmName} · ${c.city}',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                      color: isSelected
                                          ? AppColors.emerald
                                          : AppColors.ink,
                                    ),
                                  ),
                                  subtitle: c.contactPerson.isNotEmpty
                                      ? Text(
                                          '${c.contactPerson} (${c.phone})',
                                          style: const TextStyle(fontSize: 11),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.emerald,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedClient = c;
                                      _clientSearchController.text =
                                          '${c.firmName} · ${c.city}';
                                      _isClientDropdownOpen = false;
                                    });
                                  },
                                );
                              }).toList(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // 2. SEARCH & SELECT DESIGNS (Clean Search & Checkbox)
                const Text(
                  '2. Search & Select Designs',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                CommonTextField(
                  controller: _designSearchController,
                  hintText: 'Search designs by name or code...',
                  prefixIcon: Icons.search,
                  suffixIcon: _designSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              _designSearchController.clear();
                            });
                          },
                        )
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                if (designQuery.isNotEmpty) ...[
                  if (searchedDesigns.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: Text(
                        'No designs match "${_designSearchController.text.trim()}"',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ...searchedDesigns.map((design) => _buildDesignItem(design)),
                ] else if (selectedDesignsList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 4),
                    child: Text(
                      'Selected Designs (${selectedDesignsList.length}):',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ),
                  ...selectedDesignsList.map((design) => _buildDesignItem(design)),
                ],

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
                      color: AppColors.canvas,
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

                const SizedBox(height: 14),

                // 4. NOTES
                CommonTextField(
                  controller: _notesController,
                  label: 'Special Instructions / Artisan Note (Optional)',
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
                ? 'Confirm Order ($totalPcs pcs)'
                : 'Select at least 1 design',
            onPressed: totalPcs > 0 && _selectedClient != null
                ? () {
                    final List<Map<String, dynamic>> apiParts = [];
                    for (final entry in _selectedQuantities.entries) {
                      if (entry.value > 0) {
                        final d = designs.firstWhere(
                          (item) => item.code == entry.key,
                        );
                        apiParts.add({
                          'designNumber': d.code,
                          'quantity': entry.value,
                          'grossWeight': d.grossWeightGrams * entry.value,
                          'notes': _notesController.text.trim(),
                        });
                      }
                    }

                    context.read<OrdersBloc>().add(
                      CreateAndCheckoutOrderEvent(
                        customerId: _selectedClient!.id,
                        dueDate: _selectedDueDate.toUtc().toIso8601String(),
                        specialInstructions: _notesController.text.trim(),
                        parts: apiParts,
                      ),
                    );
                    Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDesignItem(JewelleryDesign design) {
    final qty = _selectedQuantities[design.code] ?? 0;
    final isSelected = qty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.paper : AppColors.canvas,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: isSelected ? AppColors.emerald : AppColors.outlineLight,
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
                    color: isSelected ? AppColors.ink : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${design.code} · ${design.purity}',
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
                        _selectedQuantities[design.code] = qty - 1;
                      } else {
                        _selectedQuantities.remove(design.code);
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    child: const Icon(
                      Icons.add,
                      size: 14,
                      color: AppColors.emerald,
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
