import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

  String get _currentYearMonth => DateFormat('yyyy-MM').format(_selectedDate);

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
      debugPrint(
        '🔍 [LEDGER PAGE] Requesting ledger: craftsmanId=$_selectedCraftsmanId, month=$_currentYearMonth',
      );
      final ledger = await _repo.getCraftsmanMonthlyLedger(
        craftsmanId: _selectedCraftsmanId!,
        yearMonth: _currentYearMonth,
      );
      debugPrint(
        '📊 [LEDGER PAGE DATA]: Craftsman: "${ledger.craftsmanName}" | Handled: ${ledger.totalGramsHandled}g | Wastage: ${ledger.totalWastageGrams}g (${ledger.wastagePercentage}%) | Pcs: ${ledger.totalPiecesDone} | Stones Set: ${ledger.totalStonesSet} (Broken: ${ledger.totalStonesBroken}) | Depts: ${ledger.departmentSummaries.length} | Job Sheets: ${ledger.jobSheets.length}',
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
      debugPrint('❌ [LEDGER PAGE ERROR]: $e');
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
    final maxYear = now.year; // Dynamically expands as years advance (e.g. 2026, 2031...)

    int tempYear = _selectedDate.year.clamp(minYear, maxYear);
    int tempMonth = _selectedDate.month;

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
                              maxYear - minYear + 1,
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
                  // Months Grid using intl DateFormat
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
                      final monthDate = DateTime(tempYear, m);
                      final monthLabel = DateFormat.MMM().format(monthDate);
                      final isFuture = (tempYear == now.year && m > now.month) || (tempYear > now.year);
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
                                    ? AppColors.canvas.withValues(alpha: 0.4)
                                    : AppColors.canvas),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.emerald
                                  : (isFuture
                                      ? AppColors.outlineLight.withValues(alpha: 0.4)
                                      : AppColors.outlineLight),
                            ),
                          ),
                          child: Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isFuture
                                      ? AppColors.muted.withValues(alpha: 0.35)
                                      : AppColors.ink),
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

            // Worker Dropdown (For Admin / Production Manager)
            if (!isCraftsman) ...[
              _buildWorkerSelector(),
              const SizedBox(height: 16),
            ],

            if (_isLoadingLedger && _ledger == null)
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
            : 'Worker Monthly Ledger',
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
    final displayMonth = DateFormat.yMMMM().format(_selectedDate);

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

  // ── Worker Selector ───────────────────────────────────────────────────────
  Widget _buildWorkerSelector() {
    final currentCraftsman =
        _craftsmen.where((c) => c.id == _selectedCraftsmanId).firstOrNull;
    final displayName = currentCraftsman?.name ??
        (_selectedCraftsmanName.isNotEmpty
            ? _selectedCraftsmanName
            : 'Select Worker...');
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
              'Worker:',
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
    final isSurplus = ledger.totalWastageGrams <= 0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Metal Issued',
                value: '${ledger.totalGramsHandled.toStringAsFixed(3)} g',
                icon: Icons.scale_rounded,
                color: AppColors.goldDark,
                subtitle: 'Raw Issue Weight',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Fine Received',
                value: '${ledger.totalFineReceived.toStringAsFixed(3)} g',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.emerald,
                subtitle: 'Clean Metal Received',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Runner Scrap',
                value: '${ledger.totalRunnerScrap.toStringAsFixed(3)} g',
                icon: Icons.recycling_rounded,
                color: AppColors.goldDark,
                subtitle: 'Scrap Returned',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'Wastage Diff',
                value: '${ledger.totalWastageGrams.toStringAsFixed(3)} g',
                icon: Icons.difference_rounded,
                color: isSurplus ? AppColors.emerald : Colors.red,
                subtitle: isSurplus ? 'Metal Recovery / Gain' : '${ledger.wastagePercentage.toStringAsFixed(2)}% Metal Loss',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Polished Output',
                value: '${ledger.totalPiecesDone} pcs',
                icon: Icons.auto_awesome_rounded,
                color: AppColors.emerald,
                subtitle: 'Piece-Rate Total',
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
              fontSize: 13.5,
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
              final isFiling = dept.department.toLowerCase().contains('filing');
              final isPolishing = dept.department.toLowerCase().contains('polish');
              final isSetting = dept.department.toLowerCase().contains('setting') ||
                  dept.department.toLowerCase().contains('stone');

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isFiling
                                  ? Icons.handyman_rounded
                                  : (isPolishing
                                      ? Icons.auto_awesome_rounded
                                      : Icons.diamond_outlined),
                              size: 14,
                              color: isFiling
                                  ? AppColors.goldDark
                                  : (isPolishing
                                      ? AppColors.emerald
                                      : const Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dept.department,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.outlineLight),
                          ),
                          child: Text(
                            '${dept.totalJobs} logs',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isFiling) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Issue Wt',
                              value: '${dept.gramsHandled.toStringAsFixed(3)}g',
                              color: AppColors.goldDark,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Fine Recd',
                              value: '${dept.fineReceived.toStringAsFixed(3)}g',
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Runner Return',
                              value: '${dept.runnerReturn.toStringAsFixed(3)}g',
                              color: AppColors.ink,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Wastage Diff',
                              value: '${dept.wastageGrams.toStringAsFixed(3)}g',
                              color: dept.wastageGrams <= 0 ? AppColors.emerald : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ] else if (isPolishing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Total Polished',
                              value: '${dept.pieces} pcs',
                              color: AppColors.emerald,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Direct / Indirect',
                              value: '${dept.directPcs} / ${dept.indirectPcs} pcs',
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Filing Pcs',
                              value: '${dept.filingPcs} pcs',
                              color: AppColors.muted,
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Belt Pcs',
                              value: '${dept.beltPcs} pcs',
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ] else if (isSetting) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Stones Set',
                              value: '${dept.stonesHandled} pcs',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          Expanded(
                            child: _buildMiniStat(
                              label: 'Broken Stones',
                              value: '${dept.stonesBroken} pcs',
                              color: dept.stonesBroken > 0 ? Colors.red : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
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
              separatorBuilder: (_, _) => const Divider(height: 12, color: AppColors.outlineLight),
              itemBuilder: (ctx, i) {
                final job = ledger.jobSheets[i];
                final isFiling = job.department.toLowerCase().contains('filing');
                final isPolishing = job.department.toLowerCase().contains('polish');
                final isSetting = job.department.toLowerCase().contains('setting') ||
                    job.department.toLowerCase().contains('stone');

                Color deptColor = AppColors.emerald;
                IconData deptIcon = Icons.precision_manufacturing_rounded;
                if (isFiling) {
                  deptColor = AppColors.goldDark;
                  deptIcon = Icons.handyman_rounded;
                } else if (isPolishing) {
                  deptColor = AppColors.emerald;
                  deptIcon = Icons.auto_awesome_rounded;
                } else if (isSetting) {
                  deptColor = const Color(0xFF3B82F6);
                  deptIcon = Icons.diamond_outlined;
                }

                // Format timestamp
                String formattedDate = job.date;
                if (job.date.isNotEmpty) {
                  try {
                    final dt = DateTime.parse(job.date).toLocal();
                    formattedDate =
                        DateFormat('dd MMM yyyy, hh:mm a').format(dt);
                  } catch (_) {}
                }

                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.canvas.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: deptColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(deptIcon, size: 11, color: deptColor),
                                const SizedBox(width: 4),
                                Text(
                                  job.department,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    color: deptColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (job.jobCode.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.outlineLight),
                              ),
                              child: Text(
                                'Tag: ${job.jobCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Spacer(),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Department Specific Register Data
                      if (isFiling) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Issue',
                                value: '${job.issueWeight.toStringAsFixed(3)}g',
                                color: AppColors.goldDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Fine Recd',
                                value: '${job.fineWeight.toStringAsFixed(3)}g',
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Runner',
                                value: '${job.runnerReturnWeight.toStringAsFixed(3)}g',
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Diff',
                                value: '${job.wastageWeight.toStringAsFixed(3)}g',
                                color: job.wastageWeight <= 0 ? AppColors.emerald : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ] else if (isPolishing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Total Output',
                                value: '${job.pieces} pcs',
                                color: AppColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Direct / Indirect',
                                value: '${job.directPcs} / ${job.indirectPcs} pcs',
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Filing / Belt',
                                value: '${job.filingPcs} / ${job.beltPcs} pcs',
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ] else if (isSetting) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Stone Ref',
                                value: '${job.stoneType} ${job.stoneSize}'.trim().isNotEmpty
                                    ? '${job.stoneType} ${job.stoneSize}'.trim()
                                    : 'Stones',
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Stones Set',
                                value: '${job.stonesSet} pcs',
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _buildMiniStat(
                                label: 'Broken',
                                value: '${job.stonesBroken} pcs',
                                color: job.stonesBroken > 0 ? Colors.red : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (job.notes.isNotEmpty || job.recordedByName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (job.notes.isNotEmpty)
                              Expanded(
                                child: Text(
                                  'Note: ${job.notes}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.muted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (job.recordedByName.isNotEmpty)
                              Text(
                                'By: ${job.recordedByName}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ],
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
              'Select a Worker and Month to view the physical ledger.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
