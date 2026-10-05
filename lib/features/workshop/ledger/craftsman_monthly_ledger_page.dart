import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/network/api_error_handler.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_app_bar.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_card.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_progress_indicator.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import 'package:jewellery_ops_mobile/features/auth/bloc/auth_bloc.dart';
import '../widgets/searchable_craftsman_picker.dart';

/// Craftsman Monthly Weight & Piece Ledger Page
/// Strictly adheres to ZERO-CURRENCY POLICY: Physical Grams (g) & Pieces (pcs) only.
class CraftsmanMonthlyLedgerPage extends StatefulWidget {
  const CraftsmanMonthlyLedgerPage({
    super.key,
    this.initialCraftsmanId,
    this.initialCraftsmanName,
    this.isEmbeddedView = false,
  });

  final String? initialCraftsmanId;
  final String? initialCraftsmanName;
  final bool isEmbeddedView;

  static Route<void> route({
    String? craftsmanId,
    String? craftsmanName,
  }) {
    return MaterialPageRoute(
      builder: (_) => CraftsmanMonthlyLedgerPage(
        initialCraftsmanId: craftsmanId,
        initialCraftsmanName: craftsmanName,
      ),
    );
  }

  @override
  State<CraftsmanMonthlyLedgerPage> createState() =>
      _CraftsmanMonthlyLedgerPageState();
}

class _CraftsmanMonthlyLedgerPageState
    extends State<CraftsmanMonthlyLedgerPage> {
  final KaratFlowApiRepository _repo = KaratFlowApiRepository();

  late DateTime _selectedDate;
  String? _selectedCraftsmanId;
  String _selectedCraftsmanName = '';

  bool _isLoadingEmployees = false;
  bool _isLoadingLedger = false;
  List<ApiEmployee> _craftsmen = [];
  CraftsmanMonthlyLedger? _ledger;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initCraftsmanAndData();
  }

  String get _currentYearMonth {
    final y = _selectedDate.year.toString();
    final m = _selectedDate.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  Future<void> _initCraftsmanAndData() async {
    final authState = context.read<AuthBloc>().state;
    final userRole = authState is AuthAuthenticated
        ? AppRole.fromRoleString(authState.role)
        : AppRole.admin;

    final isCraftsman = userRole == AppRole.workshopArtisan ||
        userRole == AppRole.worker;

    if (widget.initialCraftsmanId != null) {
      _selectedCraftsmanId = widget.initialCraftsmanId;
      _selectedCraftsmanName = widget.initialCraftsmanName ?? 'Craftsman';
    } else if (isCraftsman) {
      try {
        final profile = await _repo.getProfile();
        _selectedCraftsmanId = profile.id;
        _selectedCraftsmanName = profile.name;
      } catch (_) {
        if (authState is AuthAuthenticated) {
          _selectedCraftsmanName = authState.userName;
        }
      }
    }

    if (!isCraftsman) {
      await _loadCraftsmenList();
    }

    if (_selectedCraftsmanId != null && _selectedCraftsmanId!.isNotEmpty) {
      await _fetchLedger();
    }
  }

  Future<void> _loadCraftsmenList() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final allEmployees = await _repo.listEmployees();
      final karigars = allEmployees.where((e) {
        final r = e.role.toUpperCase();
        return r.contains('CRAFTSMAN') ||
            r.contains('ARTISAN') ||
            r.contains('WORKER') ||
            r.contains('GOLDSMITH') ||
            r.contains('SETTER') ||
            r.contains('POLISHER');
      }).toList();

      if (mounted) {
        setState(() {
          _craftsmen = karigars.isNotEmpty ? karigars : allEmployees;
          if (_selectedCraftsmanId == null && _craftsmen.isNotEmpty) {
            _selectedCraftsmanId = _craftsmen.first.id;
            _selectedCraftsmanName = _craftsmen.first.name;
          }
          _isLoadingEmployees = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
      }
    }
  }

  Future<void> _fetchLedger() async {
    if (_selectedCraftsmanId == null || _selectedCraftsmanId!.isEmpty) return;

    setState(() {
      _isLoadingLedger = true;
      _errorMessage = null;
    });

    try {
      final ledger = await _repo.getCraftsmanMonthlyLedger(
        craftsmanId: _selectedCraftsmanId!,
        yearMonth: _currentYearMonth,
      );
      if (mounted) {
        setState(() {
          _ledger = ledger;
          if (ledger.craftsmanName.isNotEmpty) {
            _selectedCraftsmanName = ledger.craftsmanName;
          }
          _isLoadingLedger = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiErrorHandler.parseMessage(e);
          _isLoadingLedger = false;
        });
      }
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    if (_selectedDate.year < now.year) return true;
    if (_selectedDate.year == now.year && _selectedDate.month < now.month) return true;
    return false;
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
    _fetchLedger();
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
    _fetchLedger();
  }

  Future<void> _showMonthYearPicker() async {
    final now = DateTime.now();
    final minYear = 2023;
    final maxYear = now.year < 2024 ? 2026 : now.year;

    int tempYear = _selectedDate.year;
    int tempMonth = _selectedDate.month;

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Ledger Month',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.today_rounded, size: 14, color: AppColors.emerald),
                        label: const Text(
                          'Current Month',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          setState(() {
                            _selectedDate = DateTime(now.year, now.month);
                          });
                          _fetchLedger();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Year Selector Row
                  Row(
                    children: [
                      const Text(
                        'Year:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              (maxYear - minYear + 1).clamp(1, 10),
                              (idx) {
                                final yr = minYear + idx;
                                final isSel = yr == tempYear;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(
                                      '$yr',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                        color: isSel ? Colors.white : AppColors.ink,
                                      ),
                                    ),
                                    selected: isSel,
                                    selectedColor: AppColors.emerald,
                                    backgroundColor: AppColors.canvas,
                                    showCheckmark: false,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setModalState(() {
                                          tempYear = yr;
                                          if (tempYear == now.year && tempMonth > now.month) {
                                            tempMonth = now.month;
                                          }
                                        });
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, idx) {
                      final m = idx + 1;
                      final isFuture = (tempYear == now.year && m > now.month) || tempYear > now.year;
                      final isSelected = m == tempMonth && tempYear == _selectedDate.year;

                      return InkWell(
                        onTap: isFuture
                            ? null
                            : () {
                                Navigator.of(sheetCtx).pop();
                                setState(() {
                                  _selectedDate = DateTime(tempYear, m);
                                });
                                _fetchLedger();
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.emerald
                                : (isFuture
                                    ? AppColors.canvas.withValues(alpha: 0.5)
                                    : AppColors.canvas),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald
                                  : AppColors.outlineLight,
                            ),
                          ),
                          child: Text(
                            monthNames[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isFuture ? AppColors.muted.withValues(alpha: 0.4) : AppColors.ink),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userRole = authState is AuthAuthenticated
        ? AppRole.fromRoleString(authState.role)
        : AppRole.admin;
    final isCraftsman = userRole == AppRole.workshopArtisan ||
        userRole == AppRole.worker;

    final content = CommonRefreshIndicator(
      theme: IndicatorTheme.workshop,
      showIndicator: false,
      onRefresh: _fetchLedger,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Picker Bar
            _buildMonthSelectorBar(),
            const SizedBox(height: 12),

            // Karigar Dropdown (For Admin / Production Manager)
            if (!isCraftsman) ...[
              _buildKarigarSelector(),
              const SizedBox(height: 16),
            ],

            if (_isLoadingLedger)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.emerald,
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorCard()
            else if (_ledger != null) ...[
              // Zero-Currency KPI Header
              _buildKpiMetricsGrid(_ledger!),
              const SizedBox(height: 16),

              // Department Breakdown Card
              _buildDepartmentBreakdownCard(_ledger!),
              const SizedBox(height: 16),

              // Job Sheets History Table
              _buildJobSheetsSection(_ledger!),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
    );

    if (widget.isEmbeddedView) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: CommonAppBar(
        title: _selectedCraftsmanName.isNotEmpty
            ? '$_selectedCraftsmanName • Monthly Ledger'
            : 'Karigar Monthly Ledger',
        subtitle: 'Zero Currency • Weights (g) & Pieces (pcs) Only',
        leading: widget.isEmbeddedView
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: content,
    );
  }

  // ── Month Selector ────────────────────────────────────────────────────────
  Widget _buildMonthSelectorBar() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final displayMonth =
        '${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink),
            onPressed: _previousMonth,
            tooltip: 'Previous Month',
          ),
          InkWell(
            onTap: _showMonthYearPicker,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    displayMonth,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _canGoNext
                  ? AppColors.ink
                  : AppColors.muted.withValues(alpha: 0.3),
            ),
            onPressed: _canGoNext ? _nextMonth : null,
            tooltip: _canGoNext ? 'Next Month' : 'Future months not available',
          ),
        ],
      ),
    );
  }

  // ── Karigar Selector ──────────────────────────────────────────────────────
  Widget _buildKarigarSelector() {
    final currentCraftsman =
        _craftsmen.where((c) => c.id == _selectedCraftsmanId).firstOrNull;
    final displayName = currentCraftsman?.name ??
        (_selectedCraftsmanName.isNotEmpty
            ? _selectedCraftsmanName
            : 'Select Craftsman...');
    final displayRole = currentCraftsman?.role;

    return InkWell(
      onTap: () async {
        final picked = await SearchableCraftsmanPickerSheet.show(
          context,
          initialCraftsmen: _craftsmen,
          selectedCraftsmanId: _selectedCraftsmanId,
        );
        if (picked != null && mounted) {
          setState(() {
            _selectedCraftsmanId = picked.id;
            _selectedCraftsmanName = picked.name;
          });
          _fetchLedger();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineLight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.person_search_rounded,
              size: 16,
              color: AppColors.emerald,
            ),
            const SizedBox(width: 8),
            const Text(
              'Karigar:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: currentCraftsman != null || _selectedCraftsmanName.isNotEmpty
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayRole != null && displayRole.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayRole,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isLoadingEmployees) ...[
              const SizedBox(width: 6),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ] else ...[
              const Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: AppColors.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── KPI Metrics Grid ──────────────────────────────────────────────────────
  Widget _buildKpiMetricsGrid(CraftsmanMonthlyLedger ledger) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Handled',
                value: '${ledger.totalGramsHandled.toStringAsFixed(2)} g',
                icon: Icons.scale_rounded,
                color: AppColors.goldDark,
                subtitle: 'Metal Issued & Worked',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Wastage',
                value: '${ledger.totalWastageGrams.toStringAsFixed(3)} g',
                icon: Icons.delete_sweep_rounded,
                color: ledger.wastagePercentage > 3.0 ? Colors.red : AppColors.gold,
                subtitle: '${ledger.wastagePercentage.toStringAsFixed(2)}% of metal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Pieces Done',
                value: '${ledger.totalPiecesDone} pcs',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.emerald,
                subtitle: 'Polished & Bench Output',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Stones Set',
                value: '${ledger.totalStonesSet} pcs',
                icon: Icons.diamond_outlined,
                color: const Color(0xFF3B82F6),
                subtitle: 'Broken: ${ledger.totalStonesBroken} pcs',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Department Breakdown Card ─────────────────────────────────────────────
  Widget _buildDepartmentBreakdownCard(CraftsmanMonthlyLedger ledger) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 15, color: AppColors.emerald),
              SizedBox(width: 6),
              Text(
                'Departmental Performance',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (ledger.departmentSummaries.isEmpty)
            const Text(
              'No department breakdowns logged for this period.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            )
          else
            ...ledger.departmentSummaries.map((dept) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dept.department,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (dept.gramsHandled > 0)
                          Text(
                            '${dept.gramsHandled.toStringAsFixed(2)}g (Loss: ${dept.wastageGrams.toStringAsFixed(2)}g)',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldDark,
                            ),
                          ),
                        if (dept.pieces > 0)
                          Text(
                            '${dept.pieces} pcs output',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald,
                            ),
                          ),
                        if (dept.stonesHandled > 0)
                          Text(
                            '${dept.stonesHandled} stones set',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Job Sheets Section ────────────────────────────────────────────────────
  Widget _buildJobSheetsSection(CraftsmanMonthlyLedger ledger) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.list_alt_rounded, size: 15, color: AppColors.goldDark),
                  SizedBox(width: 6),
                  Text(
                    'Monthly Floor Logs & Job Sheets',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${ledger.jobSheets.length} entries',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (ledger.jobSheets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No log entries found for this month.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ledger.jobSheets.length,
              separatorBuilder: (_, _) => const Divider(height: 10, color: AppColors.outlineLight),
              itemBuilder: (ctx, i) {
                final job = ledger.jobSheets[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          job.department.isNotEmpty ? job.department[0] : 'J',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.department.isNotEmpty ? job.department : 'Workshop Task',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            if (job.orderNumber.isNotEmpty || job.partName.isNotEmpty)
                              Text(
                                '${job.orderNumber} • ${job.partName}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            if (job.notes.isNotEmpty)
                              Text(
                                job.notes,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (job.issueWeight > 0)
                            Text(
                              '${job.issueWeight.toStringAsFixed(2)}g',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldDark,
                              ),
                            ),
                          if (job.wastageWeight > 0)
                            Text(
                              'Loss: ${job.wastageWeight.toStringAsFixed(2)}g',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          if (job.pieces > 0)
                            Text(
                              '${job.pieces} pcs',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          if (job.stonesSet > 0)
                            Text(
                              '${job.stonesSet} stones',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Failed to load ledger',
            style: const TextStyle(fontSize: 13, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchLedger,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.muted),
            SizedBox(height: 10),
            Text(
              'Select a Karigar and Month to view the physical ledger.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
