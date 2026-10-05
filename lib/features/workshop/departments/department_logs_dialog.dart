import 'package:flutter/material.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/network/api_error_handler.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import '../widgets/searchable_craftsman_picker.dart';
import '../widgets/searchable_order_part_picker.dart';

/// Department Logs Submission Dialog for Workshop Floor Operations
/// Enforces STRICT ZERO-CURRENCY POLICY: Physical weights (g) & Pieces (pcs) only.
class DepartmentLogsDialog extends StatefulWidget {
  const DepartmentLogsDialog({
    super.key,
    this.initialDepartmentIndex = 0,
    this.prefilledOrderPartId,
  });

  final int initialDepartmentIndex;
  final String? prefilledOrderPartId;

  static Future<void> show(
    BuildContext context, {
    int initialDepartmentIndex = 0,
    String? prefilledOrderPartId,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DepartmentLogsDialog(
        initialDepartmentIndex: initialDepartmentIndex,
        prefilledOrderPartId: prefilledOrderPartId,
      ),
    );
  }

  @override
  State<DepartmentLogsDialog> createState() => _DepartmentLogsDialogState();
}

class _DepartmentLogsDialogState extends State<DepartmentLogsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KaratFlowApiRepository _repo = KaratFlowApiRepository();

  bool _isLoadingInitialData = true;
  List<ApiEmployee> _craftsmen = [];
  List<ApiMasterAttribute> _stoneShapes = [];
  List<ApiMasterAttribute> _stoneColors = [];

  // ── 1. Casting State ──────────────────────────────────────────────────────
  String _castingMetal = 'Gold';
  final _castingPrevBalanceCtrl = TextEditingController(text: '0.0');
  final _castingFreshIssueCtrl = TextEditingController(text: '0.0');
  final _castingFinishedWtCtrl = TextEditingController(text: '0.0');
  final _castingRunnerScrapCtrl = TextEditingController(text: '0.0');
  final _castingNotesCtrl = TextEditingController();
  double _castingClosingBalance = 0.0;
  bool _isFetchingCastingBalance = false;
  bool _isSubmittingCasting = false;

  // ── 2. Filing State ───────────────────────────────────────────────────────
  String? _filingCraftsmanId;
  final _filingOrderPartCtrl = TextEditingController();
  final _filingIssueWtCtrl = TextEditingController(text: '0.0');
  final _filingFineReceivedCtrl = TextEditingController(text: '0.0');
  final _filingRunnerReturnCtrl = TextEditingController(text: '0.0');
  final _filingNotesCtrl = TextEditingController();
  double _filingWastageDiff = 0.0;
  bool _isSubmittingFiling = false;

  // ── 3. Polishing State ────────────────────────────────────────────────────
  String? _polishingCraftsmanId;
  final _polishingOrderPartCtrl = TextEditingController();
  final _polishingDirectCtrl = TextEditingController(text: '0');
  final _polishingIndirectCtrl = TextEditingController(text: '0');
  final _polishingFilingCtrl = TextEditingController(text: '0');
  final _polishingBeltCtrl = TextEditingController(text: '0');
  final _polishingNotesCtrl = TextEditingController();
  int _polishingTotalPcs = 0;
  bool _isSubmittingPolishing = false;

  // ── 4. Hand Setting State ─────────────────────────────────────────────────
  String? _settingCraftsmanId;
  final _settingOrderPartCtrl = TextEditingController();
  String _settingStoneType = 'Diamond';
  String? _settingShape;
  String? _settingColor;
  final _settingSizeCtrl = TextEditingController(text: '1.5mm');
  final _settingUsedStonesCtrl = TextEditingController(text: '0');
  final _settingBrokenStonesCtrl = TextEditingController(text: '0');
  bool _settingReplacementRequested = false;
  final _settingNotesCtrl = TextEditingController();
  bool _isSubmittingSetting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialDepartmentIndex.clamp(0, 3),
    );

    if (widget.prefilledOrderPartId != null) {
      _filingOrderPartCtrl.text = widget.prefilledOrderPartId!;
      _polishingOrderPartCtrl.text = widget.prefilledOrderPartId!;
      _settingOrderPartCtrl.text = widget.prefilledOrderPartId!;
    }

    _setupListeners();
    _loadMasterData();
    _fetchCastingBalance(_castingMetal);
  }

  void _setupListeners() {
    void updateCasting() {
      final prev = double.tryParse(_castingPrevBalanceCtrl.text.trim()) ?? 0.0;
      final fresh = double.tryParse(_castingFreshIssueCtrl.text.trim()) ?? 0.0;
      final fin = double.tryParse(_castingFinishedWtCtrl.text.trim()) ?? 0.0;
      final scrap = double.tryParse(_castingRunnerScrapCtrl.text.trim()) ?? 0.0;
      setState(() {
        _castingClosingBalance = (prev + fresh) - (fin + scrap);
      });
    }

    _castingPrevBalanceCtrl.addListener(updateCasting);
    _castingFreshIssueCtrl.addListener(updateCasting);
    _castingFinishedWtCtrl.addListener(updateCasting);
    _castingRunnerScrapCtrl.addListener(updateCasting);

    void updateFiling() {
      final issue = double.tryParse(_filingIssueWtCtrl.text.trim()) ?? 0.0;
      final fine = double.tryParse(_filingFineReceivedCtrl.text.trim()) ?? 0.0;
      final runner = double.tryParse(_filingRunnerReturnCtrl.text.trim()) ?? 0.0;
      setState(() {
        _filingWastageDiff = issue - (fine + runner);
      });
    }

    _filingIssueWtCtrl.addListener(updateFiling);
    _filingFineReceivedCtrl.addListener(updateFiling);
    _filingRunnerReturnCtrl.addListener(updateFiling);

    void updatePolishing() {
      final d = int.tryParse(_polishingDirectCtrl.text.trim()) ?? 0;
      final i = int.tryParse(_polishingIndirectCtrl.text.trim()) ?? 0;
      final f = int.tryParse(_polishingFilingCtrl.text.trim()) ?? 0;
      final b = int.tryParse(_polishingBeltCtrl.text.trim()) ?? 0;
      setState(() {
        _polishingTotalPcs = d + i + f + b;
      });
    }

    _polishingDirectCtrl.addListener(updatePolishing);
    _polishingIndirectCtrl.addListener(updatePolishing);
    _polishingFilingCtrl.addListener(updatePolishing);
    _polishingBeltCtrl.addListener(updatePolishing);
  }

  Future<void> _loadMasterData() async {
    setState(() => _isLoadingInitialData = true);
    try {
      final results = await Future.wait([
        _repo.listEmployees(),
        _repo.getMasterShapes(),
        _repo.getMasterColors(),
      ]);

      final allEmployees = results[0] as List<ApiEmployee>;
      final shapes = results[1] as List<ApiMasterAttribute>;
      final colors = results[2] as List<ApiMasterAttribute>;

      // Filter craftsmen (karigars)
      final craftsmen = allEmployees.where((e) {
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
          _craftsmen = craftsmen.isNotEmpty ? craftsmen : allEmployees;
          if (_craftsmen.isNotEmpty) {
            _filingCraftsmanId = _craftsmen.first.id;
            _polishingCraftsmanId = _craftsmen.first.id;
            _settingCraftsmanId = _craftsmen.first.id;
          }
          _stoneShapes = shapes;
          if (_stoneShapes.isNotEmpty) {
            _settingShape = _stoneShapes.first.name;
          }
          _stoneColors = colors;
          if (_stoneColors.isNotEmpty) {
            _settingColor = _stoneColors.first.name;
          }
          _isLoadingInitialData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingInitialData = false);
      }
    }
  }

  Future<void> _fetchCastingBalance(String metal) async {
    setState(() => _isFetchingCastingBalance = true);
    try {
      final res = await _repo.getCastingLastBalance(metal);
      if (mounted) {
        _castingPrevBalanceCtrl.text =
            res.lastClosingBalance.toStringAsFixed(3);
      }
    } catch (_) {
      // Keep existing balance if backend query encounters issues
    } finally {
      if (mounted) {
        setState(() => _isFetchingCastingBalance = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _castingPrevBalanceCtrl.dispose();
    _castingFreshIssueCtrl.dispose();
    _castingFinishedWtCtrl.dispose();
    _castingRunnerScrapCtrl.dispose();
    _castingNotesCtrl.dispose();

    _filingOrderPartCtrl.dispose();
    _filingIssueWtCtrl.dispose();
    _filingFineReceivedCtrl.dispose();
    _filingRunnerReturnCtrl.dispose();
    _filingNotesCtrl.dispose();

    _polishingOrderPartCtrl.dispose();
    _polishingDirectCtrl.dispose();
    _polishingIndirectCtrl.dispose();
    _polishingFilingCtrl.dispose();
    _polishingBeltCtrl.dispose();
    _polishingNotesCtrl.dispose();

    _settingOrderPartCtrl.dispose();
    _settingSizeCtrl.dispose();
    _settingUsedStonesCtrl.dispose();
    _settingBrokenStonesCtrl.dispose();
    _settingNotesCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _submitCasting() async {
    final prev = double.tryParse(_castingPrevBalanceCtrl.text.trim()) ?? 0.0;
    final fresh = double.tryParse(_castingFreshIssueCtrl.text.trim()) ?? 0.0;
    final fin = double.tryParse(_castingFinishedWtCtrl.text.trim()) ?? 0.0;
    final scrap = double.tryParse(_castingRunnerScrapCtrl.text.trim()) ?? 0.0;

    setState(() => _isSubmittingCasting = true);
    try {
      final res = await _repo.submitCastingLog(
        CastingSubmitPayload(
          metalType: _castingMetal,
          previousBalance: prev,
          freshIssueWeight: fresh,
          finishedWeight: fin,
          runnerScrapWeight: scrap,
          closingBalance: _castingClosingBalance,
          notes: _castingNotesCtrl.text.trim(),
        ),
      );
      if (mounted) {
        CommonSnackbar.success(
          context,
          title: 'Casting Log Submitted',
          message:
              'Closing Balance: ${res.closingBalance.toStringAsFixed(3)}g logged for ${res.metalType}.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Casting Submission Failed',
          message: ApiErrorHandler.parseMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingCasting = false);
    }
  }

  Future<void> _submitFiling() async {
    if (_filingCraftsmanId == null || _filingCraftsmanId!.isEmpty) {
      CommonSnackbar.warning(
        context,
        title: 'Karigar Required',
        message: 'Please select a craftsman (karigar) for this filing log.',
      );
      return;
    }

    final issue = double.tryParse(_filingIssueWtCtrl.text.trim()) ?? 0.0;
    final fine = double.tryParse(_filingFineReceivedCtrl.text.trim()) ?? 0.0;
    final runner = double.tryParse(_filingRunnerReturnCtrl.text.trim()) ?? 0.0;

    setState(() => _isSubmittingFiling = true);
    try {
      final res = await _repo.submitFilingLog(
        FilingSubmitPayload(
          craftsmanId: _filingCraftsmanId!,
          orderPartId: _filingOrderPartCtrl.text.trim().isNotEmpty
              ? _filingOrderPartCtrl.text.trim()
              : null,
          issueWeight: issue,
          fineReceivedWeight: fine,
          runnerReturnWeight: runner,
          wastageDifference: _filingWastageDiff,
          notes: _filingNotesCtrl.text.trim(),
        ),
      );
      if (mounted) {
        CommonSnackbar.success(
          context,
          title: 'Filing Log Submitted',
          message:
              'Wastage difference: ${res.wastageDifference.toStringAsFixed(3)}g recorded.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Filing Submission Failed',
          message: ApiErrorHandler.parseMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingFiling = false);
    }
  }

  Future<void> _submitPolishing() async {
    if (_polishingCraftsmanId == null || _polishingCraftsmanId!.isEmpty) {
      CommonSnackbar.warning(
        context,
        title: 'Karigar Required',
        message: 'Please select a craftsman (karigar) for polishing log.',
      );
      return;
    }

    final d = int.tryParse(_polishingDirectCtrl.text.trim()) ?? 0;
    final i = int.tryParse(_polishingIndirectCtrl.text.trim()) ?? 0;
    final f = int.tryParse(_polishingFilingCtrl.text.trim()) ?? 0;
    final b = int.tryParse(_polishingBeltCtrl.text.trim()) ?? 0;

    setState(() => _isSubmittingPolishing = true);
    try {
      final res = await _repo.submitPolishingLog(
        PolishingSubmitPayload(
          craftsmanId: _polishingCraftsmanId!,
          orderPartId: _polishingOrderPartCtrl.text.trim().isNotEmpty
              ? _polishingOrderPartCtrl.text.trim()
              : null,
          directPcs: d,
          indirectPcs: i,
          filingPcs: f,
          beltPcs: b,
          totalPcs: _polishingTotalPcs,
          notes: _polishingNotesCtrl.text.trim(),
        ),
      );
      if (mounted) {
        CommonSnackbar.success(
          context,
          title: 'Polishing Log Submitted',
          message: 'Total: ${res.totalPcs} pieces logged successfully.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Polishing Submission Failed',
          message: ApiErrorHandler.parseMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingPolishing = false);
    }
  }

  Future<void> _submitHandSetting() async {
    if (_settingCraftsmanId == null || _settingCraftsmanId!.isEmpty) {
      CommonSnackbar.warning(
        context,
        title: 'Karigar Required',
        message: 'Please select a craftsman (karigar) for hand setting log.',
      );
      return;
    }

    final used = int.tryParse(_settingUsedStonesCtrl.text.trim()) ?? 0;
    final broken = int.tryParse(_settingBrokenStonesCtrl.text.trim()) ?? 0;

    setState(() => _isSubmittingSetting = true);
    try {
      final res = await _repo.submitHandSettingLog(
        HandSettingSubmitPayload(
          craftsmanId: _settingCraftsmanId!,
          orderPartId: _settingOrderPartCtrl.text.trim().isNotEmpty
              ? _settingOrderPartCtrl.text.trim()
              : null,
          stoneType: _settingStoneType,
          shape: _settingShape ?? 'Round',
          color: _settingColor ?? 'White',
          size: _settingSizeCtrl.text.trim(),
          usedStonesCount: used,
          brokenStonesCount: broken,
          replacementRequested: _settingReplacementRequested,
          notes: _settingNotesCtrl.text.trim(),
        ),
      );
      if (mounted) {
        CommonSnackbar.success(
          context,
          title: 'Hand Setting Log Submitted',
          message:
              'Used: ${res.usedStonesCount} pcs, Broken: ${res.brokenStonesCount} pcs recorded.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CommonSnackbar.error(
          context,
          title: 'Hand Setting Submission Failed',
          message: ApiErrorHandler.parseMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingSetting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.outlineLight)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.goldDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.precision_manufacturing_rounded,
                      color: AppColors.goldDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workshop Department Logs',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Physical Weights (g) & Pieces (pcs) • Zero Currency',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
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

            // Tab Bar
            Container(
              color: AppColors.paper,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.emerald,
                indicatorWeight: 2.5,
                labelColor: AppColors.emerald,
                unselectedLabelColor: AppColors.muted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.local_fire_department_rounded, size: 16), text: 'Casting'),
                  Tab(icon: Icon(Icons.handyman_rounded, size: 16), text: 'Filing'),
                  Tab(icon: Icon(Icons.auto_awesome_rounded, size: 16), text: 'Polishing'),
                  Tab(icon: Icon(Icons.diamond_outlined, size: 16), text: 'Setting'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: _isLoadingInitialData
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.emerald,
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCastingView(),
                        _buildFilingView(),
                        _buildPolishingView(),
                        _buildHandSettingView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Casting View ───────────────────────────────────────────────────────
  Widget _buildCastingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  label: 'Metal Type',
                  value: _castingMetal,
                  items: const ['Gold', 'Silver', 'Platinum'],
                  itemLabel: (v) => v,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _castingMetal = val);
                      _fetchCastingBalance(val);
                    }
                  },
                ),
              ),
              if (_isFetchingCastingBalance) ...[
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Inputs
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  controller: _castingPrevBalanceCtrl,
                  label: 'Previous Balance (g)',
                  hint: '0.000',
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNumberInput(
                  controller: _castingFreshIssueCtrl,
                  label: 'Fresh Metal Issue (g)',
                  hint: '0.000',
                  icon: Icons.add_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  controller: _castingFinishedWtCtrl,
                  label: 'Finished Casted (g)',
                  hint: '0.000',
                  icon: Icons.done_all_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNumberInput(
                  controller: _castingRunnerScrapCtrl,
                  label: 'Runner Scrap (g)',
                  hint: '0.000',
                  icon: Icons.recycling_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Closing Balance Badge (Formula Display)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _castingClosingBalance >= 0
                    ? AppColors.emerald.withValues(alpha: 0.35)
                    : Colors.red.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Closing Balance (g)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '(Prev + Fresh) - (Finished + Scrap)',
                      style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                  ],
                ),
                Text(
                  '${_castingClosingBalance.toStringAsFixed(3)} g',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _castingClosingBalance >= 0
                        ? AppColors.emerald
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildTextInput(
            controller: _castingNotesCtrl,
            label: 'Notes / Flask Ref (Optional)',
            hint: 'e.g. Flask #4 Burnout cycle normal',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: CommonButton.primary(
              label: 'Submit Casting Log',
              isLoading: _isSubmittingCasting,
              onPressed: _submitCasting,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Filing View ────────────────────────────────────────────────────────
  Widget _buildFilingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCraftsmanSelectorField(
            label: 'Craftsman (Karigar)',
            selectedId: _filingCraftsmanId,
            onChanged: (val) => setState(() => _filingCraftsmanId = val),
          ),
          const SizedBox(height: 8),
          _buildOrderPartInputField(
            controller: _filingOrderPartCtrl,
            label: 'Order Part ID / Pouch Ref (Optional)',
            hint: 'e.g. ORD-1029-P1 or tap search',
          ),
          const SizedBox(height: 10),

          // Inputs
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  controller: _filingIssueWtCtrl,
                  label: 'Issue Weight (g) [Raw]',
                  hint: '0.000',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNumberInput(
                  controller: _filingFineReceivedCtrl,
                  label: 'Fine Received (g) [Clean]',
                  hint: '0.000',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildNumberInput(
            controller: _filingRunnerReturnCtrl,
            label: 'Runner Return (g) [Scrap Returned]',
            hint: '0.000',
            icon: Icons.keyboard_return_rounded,
          ),
          const SizedBox(height: 12),

          // Wastage Difference Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _filingWastageDiff >= 0
                    ? AppColors.goldDark.withValues(alpha: 0.35)
                    : Colors.red.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wastage Difference (g)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Issue - (Fine + Runner Return)',
                      style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                  ],
                ),
                Text(
                  '${_filingWastageDiff.toStringAsFixed(3)} g',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _filingWastageDiff >= 0
                        ? AppColors.goldDark
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildTextInput(
            controller: _filingNotesCtrl,
            label: 'Notes (Optional)',
            hint: 'e.g. Prong smoothing and sprue cut',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: CommonButton.primary(
              label: 'Submit Filing Log',
              isLoading: _isSubmittingFiling,
              onPressed: _submitFiling,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Polishing View ─────────────────────────────────────────────────────
  Widget _buildPolishingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCraftsmanSelectorField(
            label: 'Craftsman (Karigar)',
            selectedId: _polishingCraftsmanId,
            onChanged: (val) => setState(() => _polishingCraftsmanId = val),
          ),
          const SizedBox(height: 8),
          _buildOrderPartInputField(
            controller: _polishingOrderPartCtrl,
            label: 'Order Part ID / Pouch Ref (Optional)',
            hint: 'e.g. ORD-1029-P1 or tap search',
          ),
          const SizedBox(height: 10),

          const Text(
            'Pieces Categories (Unit: Pcs)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  controller: _polishingDirectCtrl,
                  label: 'Direct Pcs',
                  hint: '0',
                  isInteger: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNumberInput(
                  controller: _polishingIndirectCtrl,
                  label: 'Indirect Pcs',
                  hint: '0',
                  isInteger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  controller: _polishingFilingCtrl,
                  label: 'Filing Pcs',
                  hint: '0',
                  isInteger: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNumberInput(
                  controller: _polishingBeltCtrl,
                  label: 'Belt Pcs',
                  hint: '0',
                  isInteger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Pieces Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Polished Pieces',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '$_polishingTotalPcs pcs',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildTextInput(
            controller: _polishingNotesCtrl,
            label: 'Notes (Optional)',
            hint: 'e.g. High luster final buff completed',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: CommonButton.primary(
              label: 'Submit Polishing Log',
              isLoading: _isSubmittingPolishing,
              onPressed: _submitPolishing,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Hand Setting View ──────────────────────────────────────────────────
  Widget _buildHandSettingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCraftsmanSelectorField(
            label: 'Craftsman (Karigar)',
            selectedId: _settingCraftsmanId,
            onChanged: (val) => setState(() => _settingCraftsmanId = val),
          ),
          const SizedBox(height: 8),
          _buildOrderPartInputField(
            controller: _settingOrderPartCtrl,
            label: 'Order Part ID / Pouch Ref (Optional)',
            hint: 'e.g. ORD-1029-P1 or tap search',
          ),
          const SizedBox(height: 10),

          // Stone Type & Size
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  label: 'Stone Type',
                  value: _settingStoneType,
                  items: const ['Diamond', 'Moissanite', 'CZ', 'Ruby', 'Sapphire', 'Emerald'],
                  itemLabel: (v) => v,
                  onChanged: (val) {
                    if (val != null) setState(() => _settingStoneType = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextInput(
                  controller: _settingSizeCtrl,
                  label: 'Stone Size',
                  hint: 'e.g. 1.5mm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dynamic Shape & Color
          Row(
            children: [
              Expanded(
                child: _buildDropdownField<String>(
                  label: 'Shape',
                  value: _settingShape,
                  items: _stoneShapes.isNotEmpty
                      ? _stoneShapes.map((s) => s.name).toList()
                      : const ['Round', 'Princess', 'Marquise', 'Oval', 'Pear', 'Baguette'],
                  itemLabel: (v) => v,
                  onChanged: (val) => setState(() => _settingShape = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdownField<String>(
                  label: 'Color',
                  value: _settingColor,
                  items: _stoneColors.isNotEmpty
                      ? _stoneColors.map((c) => c.name).toList()
                      : const ['White', 'Yellow', 'Pink', 'Blue', 'Green'],
                  itemLabel: (v) => v,
                  onChanged: (val) => setState(() => _settingColor = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Used & Broken Counts
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  controller: _settingUsedStonesCtrl,
                  label: 'Used Stones (pcs)',
                  hint: '0',
                  isInteger: true,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNumberInput(
                  controller: _settingBrokenStonesCtrl,
                  label: 'Broken (pcs)',
                  hint: '0',
                  isInteger: true,
                  icon: Icons.broken_image_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Replacement Requested Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replacement Requested',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Request Stockist dispatch to replace broken pieces',
                      style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch.adaptive(
                    value: _settingReplacementRequested,
                    activeTrackColor: AppColors.emerald,
                    onChanged: (val) =>
                        setState(() => _settingReplacementRequested = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildTextInput(
            controller: _settingNotesCtrl,
            label: 'Notes (Optional)',
            hint: 'e.g. Micro-pave setting with 4 prongs',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: CommonButton.primary(
              label: 'Submit Hand Setting Log',
              isLoading: _isSubmittingSetting,
              onPressed: _submitHandSetting,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Form Widgets ───────────────────────────────────────────────────

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.subtle),
            prefixIcon: icon != null
                ? Icon(icon, size: 15, color: AppColors.muted)
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.emerald, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.subtle),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.emerald, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
              isExpanded: true,
              dropdownColor: AppColors.paper,
              items: items
                  .map(
                    (it) => DropdownMenuItem<T>(
                      value: it,
                      child: Text(
                        itemLabel(it),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCraftsmanSelectorField({
    required String label,
    required String? selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedCraftsman =
        _craftsmen.where((c) => c.id == selectedId).firstOrNull;
    final name = selectedCraftsman?.name ?? 'Tap to select karigar...';
    final role = selectedCraftsman?.role ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await SearchableCraftsmanPickerSheet.show(
              context,
              initialCraftsmen: _craftsmen,
              selectedCraftsmanId: selectedId,
            );
            if (picked != null) {
              onChanged(picked.id);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineLight),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: selectedCraftsman != null
                      ? AppColors.emerald
                      : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedCraftsman != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedCraftsman != null
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (role.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.search_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderPartInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final picked = await SearchableOrderPartPickerSheet.show(
              context,
              currentOrderPartId: controller.text.trim(),
            );
            if (picked != null && picked.isNotEmpty) {
              setState(() => controller.text = picked);
            }
          },
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.subtle),
            prefixIcon: const Icon(
              Icons.receipt_long_rounded,
              size: 15,
              color: AppColors.goldDark,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  IconButton(
                    iconSize: 15,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    tooltip: 'Clear',
                    onPressed: () => setState(() => controller.clear()),
                  ),
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.search_rounded, color: AppColors.emerald),
                  tooltip: 'Search Orders & Parts',
                  onPressed: () async {
                    final picked = await SearchableOrderPartPickerSheet.show(
                      context,
                      currentOrderPartId: controller.text.trim(),
                    );
                    if (picked != null && picked.isNotEmpty) {
                      setState(() => controller.text = picked);
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
            ),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.emerald, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
