import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/network/api_error_handler.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_progress_indicator.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';

/// Live Physical Stone Stock Matrix (Size × Color 2D Grid)
/// Adheres strictly to ZERO-CURRENCY POLICY: Physical stone counts (pcs) only.
class StoneStockMatrixView extends StatefulWidget {
  const StoneStockMatrixView({super.key});

  @override
  State<StoneStockMatrixView> createState() => _StoneStockMatrixViewState();
}

class _StoneStockMatrixViewState extends State<StoneStockMatrixView> {
  final KaratFlowApiRepository _repo = KaratFlowApiRepository();

  bool _isLoading = true;
  StoneMatrixResponse? _matrix;
  String? _errorMessage;

  List<ApiMasterAttribute> _shapes = [];
  List<ApiMasterAttribute> _colors = [];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchMatrix();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatrix() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repo.getStoneStockMatrix(),
        _repo.getMasterShapes(),
        _repo.getMasterColors(),
      ]);

      if (mounted) {
        setState(() {
          _matrix = results[0] as StoneMatrixResponse;
          _shapes = results[1] as List<ApiMasterAttribute>;
          _colors = results[2] as List<ApiMasterAttribute>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiErrorHandler.parseMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  // ── Dialog: Stone Inward (Zero Currency) ──────────────────────────────────
  void _openStoneInwardDialog({String? prefillSize, String? prefillColor}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _StoneInwardDialog(
        repo: _repo,
        shapes: _shapes,
        colors: _colors,
        prefillSize: prefillSize,
        prefillColor: prefillColor,
        onSuccess: () {
          _fetchMatrix();
        },
      ),
    );
  }

  // ── Dialog: Stone Outward / Deduct (Zero Currency) ─────────────────────────
  void _openStoneDeductDialog({String? prefillSize, String? prefillColor}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _StoneDeductDialog(
        repo: _repo,
        shapes: _shapes,
        colors: _colors,
        prefillSize: prefillSize,
        prefillColor: prefillColor,
        onSuccess: () {
          _fetchMatrix();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 36, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              CommonButton.primary(
                label: 'Retry Loading Matrix',
                onPressed: _fetchMatrix,
              ),
            ],
          ),
        ),
      );
    }

    final matrix = _matrix;
    if (matrix == null) {
      return const Center(child: Text('No stone matrix data available.'));
    }

    final availableSizes = matrix.sizes.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final availableColors = matrix.colors.isNotEmpty
        ? matrix.colors
        : (_colors.isNotEmpty
            ? _colors.map((c) => c.name).toList()
            : ['White', 'Yellow', 'Pink', 'Blue']);

    return CommonRefreshIndicator(
      onRefresh: _fetchMatrix,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Controls Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openStoneInwardDialog(),
                    icon: const Icon(Icons.add_box_rounded, size: 18),
                    label: const Text(
                      'Stone Inward (Pcs)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openStoneDeductDialog(),
                    icon: const Icon(Icons.indeterminate_check_box_rounded, size: 18),
                    label: const Text(
                      'Stone Outward',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Filter
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Filter by stone size (e.g. 1.5mm, 2.0mm)...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.paper,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: 16),

            // Matrix Grid Header Note
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.grid_on_rounded, size: 18, color: AppColors.goldDark),
                    SizedBox(width: 8),
                    Text(
                      'Live Stone Stock Matrix',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: const Text(
                    'Unit: Pieces (Zero Currency)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (availableSizes.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.diamond_outlined, size: 36, color: AppColors.muted),
                    const SizedBox(height: 8),
                    const Text(
                      'No stones found in matrix.',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use "Stone Inward" to record incoming physical stones without rupees.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              // 2D Scrollable Matrix Table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      AppColors.canvas,
                    ),
                    columns: [
                      const DataColumn(
                        label: Text(
                          'Size ↓ / Color →',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...availableColors.map((c) {
                        return DataColumn(
                          label: Text(
                            c,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ],
                    rows: availableSizes.map((size) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              size,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          ...availableColors.map((color) {
                            final qty = matrix.getQuantity(size, color);
                            return DataCell(
                              InkWell(
                                onTap: () => _showCellActions(size, color, qty),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: qty > 0
                                        ? AppColors.emerald.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: qty > 0
                                          ? AppColors.emerald.withValues(alpha: 0.4)
                                          : AppColors.outline,
                                    ),
                                  ),
                                  child: Text(
                                    '$qty pcs',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: qty > 0
                                          ? AppColors.emerald
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCellActions(String size, String color, int currentQty) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              Text(
                'Stone: $size • $color',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Current Stock: $currentQty physical pieces',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.emerald),
                title: const Text('Inward More Stones (Receive Bulk)'),
                subtitle: const Text('Zero Currency • No Rupees'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openStoneInwardDialog(prefillSize: size, prefillColor: color);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: const Text('Outward / Deduct Stones'),
                subtitle: const Text('Broken, Lost or Defective Stones'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openStoneDeductDialog(prefillSize: size, prefillColor: color);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stone Inward Dialog (Zero Currency) ─────────────────────────────────────
class _StoneInwardDialog extends StatefulWidget {
  const _StoneInwardDialog({
    required this.repo,
    required this.shapes,
    required this.colors,
    this.prefillSize,
    this.prefillColor,
    required this.onSuccess,
  });

  final KaratFlowApiRepository repo;
  final List<ApiMasterAttribute> shapes;
  final List<ApiMasterAttribute> colors;
  final String? prefillSize;
  final String? prefillColor;
  final VoidCallback onSuccess;

  @override
  State<_StoneInwardDialog> createState() => _StoneInwardDialogState();
}

class _StoneInwardDialogState extends State<_StoneInwardDialog> {
  String _stoneType = 'Diamond';
  late String _shape;
  late String _color;
  final _sizeCtrl = TextEditingController(text: '1.5mm');
  final _qtyCtrl = TextEditingController(text: '100');
  final _lotCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _shape = widget.shapes.isNotEmpty ? widget.shapes.first.name : 'Round';
    _color = widget.prefillColor ??
        (widget.colors.isNotEmpty ? widget.colors.first.name : 'White');
    if (widget.prefillSize != null) {
      _sizeCtrl.text = widget.prefillSize!;
    }
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    _qtyCtrl.dispose();
    _lotCtrl.dispose();
    _supplierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      CommonSnackbar.warning(
        context,
        title: 'Invalid Quantity',
        message: 'Please enter physical piece count greater than 0.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.repo.purchasePhysicalStones(
        StoneInwardPayload(
          stoneType: _stoneType,
          shape: _shape,
          color: _color,
          size: _sizeCtrl.text.trim(),
          quantity: qty,
          lotNumber: _lotCtrl.text.trim().isNotEmpty ? _lotCtrl.text.trim() : null,
          supplierRef: _supplierCtrl.text.trim().isNotEmpty
              ? _supplierCtrl.text.trim()
              : null,
          notes: _notesCtrl.text.trim(),
        ),
      );

      if (mounted) {
        if (success) {
          CommonSnackbar.success(
            context,
            title: 'Stones Inward Recorded',
            message: '$qty physical pieces added to vault inventory.',
          );
          widget.onSuccess();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Stone Inward Failed',
          message: ApiErrorHandler.parseMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_box_rounded, color: AppColors.emerald, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Physical Stone Inward',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Zero Currency • Physical Pieces Only',
                          style: TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.outline, height: 24),

              DropdownButtonFormField<String>(
                initialValue: _stoneType,
                decoration: const InputDecoration(labelText: 'Stone Type'),
                items: const ['Diamond', 'Moissanite', 'CZ', 'Ruby', 'Sapphire']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _stoneType = v!),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _shape,
                      decoration: const InputDecoration(labelText: 'Shape'),
                      items: (widget.shapes.isNotEmpty
                              ? widget.shapes.map((s) => s.name).toList()
                              : const ['Round', 'Princess', 'Oval', 'Pear'])
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _shape = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _color,
                      decoration: const InputDecoration(labelText: 'Color'),
                      items: (widget.colors.isNotEmpty
                              ? widget.colors.map((c) => c.name).toList()
                              : const ['White', 'Yellow', 'Pink', 'Blue'])
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _color = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sizeCtrl,
                      decoration: const InputDecoration(labelText: 'Size (e.g. 1.5mm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity (Pieces)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _lotCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lot / Packet # (Optional)',
                  hintText: 'e.g. PKT-2026-90',
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes / Remarks (Optional)',
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  CommonButton.primary(
                    label: 'Record Inward',
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stone Deduct Dialog (Zero Currency) ─────────────────────────────────────
class _StoneDeductDialog extends StatefulWidget {
  const _StoneDeductDialog({
    required this.repo,
    required this.shapes,
    required this.colors,
    this.prefillSize,
    this.prefillColor,
    required this.onSuccess,
  });

  final KaratFlowApiRepository repo;
  final List<ApiMasterAttribute> shapes;
  final List<ApiMasterAttribute> colors;
  final String? prefillSize;
  final String? prefillColor;
  final VoidCallback onSuccess;

  @override
  State<_StoneDeductDialog> createState() => _StoneDeductDialogState();
}

class _StoneDeductDialogState extends State<_StoneDeductDialog> {
  static const String _stoneType = 'Diamond';
  late String _shape;
  late String _color;
  final _sizeCtrl = TextEditingController(text: '1.5mm');
  final _qtyCtrl = TextEditingController(text: '10');
  String _reason = 'Broken during bench setting';
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _shape = widget.shapes.isNotEmpty ? widget.shapes.first.name : 'Round';
    _color = widget.prefillColor ??
        (widget.colors.isNotEmpty ? widget.colors.first.name : 'White');
    if (widget.prefillSize != null) {
      _sizeCtrl.text = widget.prefillSize!;
    }
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      CommonSnackbar.warning(
        context,
        title: 'Invalid Quantity',
        message: 'Please enter deduction count greater than 0.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.repo.deductPhysicalStones(
        StoneDeductPayload(
          stoneType: _stoneType,
          shape: _shape,
          color: _color,
          size: _sizeCtrl.text.trim(),
          quantity: qty,
          reason: _reason,
          notes: _notesCtrl.text.trim(),
        ),
      );

      if (mounted) {
        if (success) {
          CommonSnackbar.success(
            context,
            title: 'Stone Deduction Recorded',
            message: '$qty physical pieces deducted from stock.',
          );
          widget.onSuccess();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Stone Deduction Failed',
          message: ApiErrorHandler.parseMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stone Outward / Deduction',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Physical Stone Adjustment (Zero Currency)',
                          style: TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.outline, height: 24),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sizeCtrl,
                      decoration: const InputDecoration(labelText: 'Size'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Deduct Quantity (Pcs)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(labelText: 'Deduction Reason'),
                items: const [
                  'Broken during bench setting',
                  'Chipped stone defect',
                  'Vault loss / count discrepancy',
                  'Sample testing extraction',
                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _reason = v!),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  CommonButton.primary(
                    label: 'Confirm Deduction',
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
