import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/network/api_error_handler.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/data/repositories/karatflow_api_repository.dart';
import '../widgets/searchable_craftsman_picker.dart';
import '../widgets/searchable_attribute_picker_sheet.dart';

/// Department Logs Submission Screen for Workshop Floor Operations
/// Enforces STRICT ZERO-CURRENCY POLICY: Physical weights (g) & Pieces (pcs) only.
class DepartmentLogsPage extends StatefulWidget {
  const DepartmentLogsPage({
    super.key,
    this.initialDepartmentIndex = 0,
    this.prefilledOrderPartId,
    this.prefilledJobCode,
  });

  final int initialDepartmentIndex;
  final String? prefilledOrderPartId;
  final String? prefilledJobCode;

  static Future<void> show(
    BuildContext context, {
    int initialDepartmentIndex = 0,
    String? prefilledOrderPartId,
    String? prefilledJobCode,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => DepartmentLogsPage(
          initialDepartmentIndex: initialDepartmentIndex,
          prefilledOrderPartId: prefilledOrderPartId,
          prefilledJobCode: prefilledJobCode,
        ),
      ),
    );
  }

  static Route<void> route({
    int initialDepartmentIndex = 0,
    String? prefilledOrderPartId,
    String? prefilledJobCode,
  }) {
    return MaterialPageRoute<void>(
      builder: (ctx) => DepartmentLogsPage(
        initialDepartmentIndex: initialDepartmentIndex,
        prefilledOrderPartId: prefilledOrderPartId,
        prefilledJobCode: prefilledJobCode,
      ),
    );
  }

  @override
  State<DepartmentLogsPage> createState() => _DepartmentLogsPageState();
}

/// Backwards compatibility alias
typedef DepartmentLogsDialog = DepartmentLogsPage;

class _DepartmentLogsPageState extends State<DepartmentLogsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final KaratFlowApiRepository _repo = KaratFlowApiRepository();

  bool _isLoadingInitialData = true;
  List<ApiEmployee> _craftsmen = [];
  List<ApiMasterAttribute> _stoneShapes = [];
  List<ApiMasterAttribute> _stoneColors = [];

  // ── 1. Casting State ──────────────────────────────────────────────────────
  final _castingJobCodeCtrl = TextEditingController();
  final _castingPrevBalanceCtrl = TextEditingController(text: '0.0');
  final _castingFreshIssueCtrl = TextEditingController(text: '0.0');
  final _castingFinishedWtCtrl = TextEditingController(text: '0.0');
  final _castingRunnerScrapCtrl = TextEditingController(text: '0.0');
  final _castingNotesCtrl = TextEditingController();
  double _castingClosingBalance = 0.0;
  bool _isFetchingCastingBalance = false;
  bool _isSubmittingCasting = false;

  // ── 2. Filing State (Floor Weight Loss Register) ───────────────────────────
  String? _filingCraftsmanId;
  final _filingJobCodeCtrl = TextEditingController();
  final _filingIssueWtCtrl = TextEditingController(text: '0.0');
  final _filingFineReceivedCtrl = TextEditingController(text: '0.0');
  final _filingRunnerReturnCtrl = TextEditingController(text: '0.0');
  final _filingNotesCtrl = TextEditingController();
  double _filingWastageDiff = 0.0;
  bool _isSubmittingFiling = false;

  // ── 3. Polishing State (Piece-Rate Register) ───────────────────────────────
  String? _polishingCraftsmanId;
  final _polishingJobCodeCtrl = TextEditingController();
  final _polishingDirectCtrl = TextEditingController(text: '0');
  final _polishingIndirectCtrl = TextEditingController(text: '0');
  final _polishingFilingCtrl = TextEditingController(text: '0');
  final _polishingBeltCtrl = TextEditingController(text: '0');
  final _polishingNotesCtrl = TextEditingController();
  int _polishingTotalPcs = 0;
  bool _isSubmittingPolishing = false;

  // ── 4. Hand Setting State (Open Stones & Breakage Register) ────────────────
  String? _settingCraftsmanId;
  final _settingJobCodeCtrl = TextEditingController();
  String? _settingShape;
  String? _settingColor;
  final _settingSizeCtrl = TextEditingController(text: '1.5mm');
  final _settingUsedStonesCtrl = TextEditingController(text: '0');
  final _settingBrokenStonesCtrl = TextEditingController(text: '0');
  bool _settingReplacementRequested = false;
  final _settingNotesCtrl = TextEditingController();
  bool _isSubmittingSetting = false;

  // Hand Setting Logs Register & Dynamic Attributes
  bool _showSettingHistory = false;
  List<HandSettingLogResponse> _settingLogs = [];
  bool _isLoadingSettingLogs = false;
  final _settingSearchCtrl = TextEditingController();
  String _settingSearchQuery = '';
  List<String> _stoneSizes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialDepartmentIndex.clamp(0, 3),
    );

    final initialTag = widget.prefilledJobCode ?? widget.prefilledOrderPartId;
    if (initialTag != null && initialTag.isNotEmpty) {
      _castingJobCodeCtrl.text = initialTag;
      _filingJobCodeCtrl.text = initialTag;
      _polishingJobCodeCtrl.text = initialTag;
      _settingJobCodeCtrl.text = initialTag;
    }

    _setupListeners();
    _loadMasterData();
    _fetchCastingBalance('Gold');
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
        _repo.getStoneStockMatrix().catchError((_) => const StoneMatrixResponse()),
        _repo.getHandSettingLogs().catchError((_) => <HandSettingLogResponse>[]),
      ]);

      final allEmployees = results[0] as List<ApiEmployee>;
      final shapes = results[1] as List<ApiMasterAttribute>;
      final colors = results[2] as List<ApiMasterAttribute>;
      final matrix = results[3] as StoneMatrixResponse;
      final logs = results[4] as List<HandSettingLogResponse>;

      // Filter craftsmen (workers)
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
          _stoneSizes = matrix.sizes;
          if (_stoneSizes.isNotEmpty && _settingSizeCtrl.text.isEmpty) {
            _settingSizeCtrl.text = _stoneSizes.first;
          }
          _settingLogs = logs;
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
      debugPrint('⚖️ [DEPARTMENT LOGS UI] Fetching last casting balance for: $metal');
      final res = await _repo.getCastingLastBalance(metal);
      debugPrint(
        '⚖️ [DEPARTMENT LOGS UI SUCCESS] Casting balance: ${res.lastClosingBalance}g for ${res.metalType}',
      );
      if (mounted) {
        _castingPrevBalanceCtrl.text =
            res.lastClosingBalance.toStringAsFixed(3);
        if (_castingJobCodeCtrl.text.isEmpty && res.lastLotNumber.isNotEmpty) {
          _castingJobCodeCtrl.text = res.lastLotNumber;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [DEPARTMENT LOGS UI ERROR] Failed to fetch casting balance: $e');
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
    _castingJobCodeCtrl.dispose();
    _castingPrevBalanceCtrl.dispose();
    _castingFreshIssueCtrl.dispose();
    _castingFinishedWtCtrl.dispose();
    _castingRunnerScrapCtrl.dispose();
    _castingNotesCtrl.dispose();

    _filingJobCodeCtrl.dispose();
    _filingIssueWtCtrl.dispose();
    _filingFineReceivedCtrl.dispose();
    _filingRunnerReturnCtrl.dispose();
    _filingNotesCtrl.dispose();

    _polishingJobCodeCtrl.dispose();
    _polishingDirectCtrl.dispose();
    _polishingIndirectCtrl.dispose();
    _polishingFilingCtrl.dispose();
    _polishingBeltCtrl.dispose();
    _polishingNotesCtrl.dispose();

    _settingJobCodeCtrl.dispose();
    _settingSizeCtrl.dispose();
    _settingUsedStonesCtrl.dispose();
    _settingBrokenStonesCtrl.dispose();
    _settingNotesCtrl.dispose();
    _settingSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSettingLogs({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoadingSettingLogs = true);
    try {
      final logs = await _repo.getHandSettingLogs(
        craftsmanId: _settingCraftsmanId,
      );
      if (mounted) {
        setState(() {
          _settingLogs = logs;
          _isLoadingSettingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSettingLogs = false);
      }
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _submitCasting() async {
    final lotNumber = _castingJobCodeCtrl.text.trim();
    if (lotNumber.isEmpty) {
      CommonSnackbar.warning(
        context,
        title: 'Lot Number Required',
        message: 'Please enter lot number (e.g. LOT-20261006-2).',
      );
      return;
    }

    final prev = double.tryParse(_castingPrevBalanceCtrl.text.trim()) ?? 0.0;
    final fresh = double.tryParse(_castingFreshIssueCtrl.text.trim()) ?? 0.0;
    final fin = double.tryParse(_castingFinishedWtCtrl.text.trim()) ?? 0.0;
    final scrap = double.tryParse(_castingRunnerScrapCtrl.text.trim()) ?? 0.0;

    setState(() => _isSubmittingCasting = true);
    try {
      debugPrint(
        '🚀 [CASTING SUBMIT UI] Submitting Casting: lotNumber=$lotNumber, prev=$prev, fresh=$fresh, fin=$fin, scrap=$scrap',
      );
      final res = await _repo.submitCastingLog(
        CastingSubmitPayload(
          lotNumber: lotNumber,
          previousBalance: prev,
          freshMetalIssue: fresh,
          finishedCastingWeight: fin,
          runnerReturnScrap: scrap,
          notes: _castingNotesCtrl.text.trim(),
        ),
      );
      debugPrint(
        '✅ [CASTING SUBMIT UI SUCCESS] Response: id=${res.id}, closingBalance=${res.closingBalance}g',
      );
      if (mounted) {
        CommonSnackbar.success(
          context,
          title: 'Casting Log Recorded',
          message:
              'Lot: $lotNumber | Closing Balance: ${res.closingBalance.toStringAsFixed(3)}g saved.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ [CASTING SUBMIT UI ERROR]: $e');
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
        title: 'Worker Required',
        message: 'Please select a worker for this filing log.',
      );
      return;
    }

    final jobCode = _filingJobCodeCtrl.text.trim();
    final issue = double.tryParse(_filingIssueWtCtrl.text.trim()) ?? 0.0;
    final fine = double.tryParse(_filingFineReceivedCtrl.text.trim()) ?? 0.0;
    final runner = double.tryParse(_filingRunnerReturnCtrl.text.trim()) ?? 0.0;

    setState(() => _isSubmittingFiling = true);
    try {
      debugPrint(
        '🚀 [FILING SUBMIT UI] Submitting Filing: craftsman=$_filingCraftsmanId, jobCode=$jobCode, issue=$issue, fine=$fine, runner=$runner, wastageDiff=$_filingWastageDiff',
      );
      final res = await _repo.submitFilingLog(
        FilingSubmitPayload(
          craftsmanId: _filingCraftsmanId!,
          jobCode: jobCode.isNotEmpty ? jobCode : null,
          issueWeight: issue,
          fineReceivedWeight: fine,
          runnerReturnWeight: runner,
          wastageDifference: _filingWastageDiff,
          notes: _filingNotesCtrl.text.trim(),
        ),
      );
      debugPrint(
        '✅ [FILING SUBMIT UI SUCCESS] Response: id=${res.id}, wastageDifference=${res.wastageDifference}g, craftsman=${res.craftsmanName}',
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
      debugPrint('❌ [FILING SUBMIT UI ERROR]: $e');
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
        title: 'Worker Required',
        message: 'Please select a worker for polishing log.',
      );
      return;
    }

    final jobCode = _polishingJobCodeCtrl.text.trim();
    final d = int.tryParse(_polishingDirectCtrl.text.trim()) ?? 0;
    final i = int.tryParse(_polishingIndirectCtrl.text.trim()) ?? 0;
    final f = int.tryParse(_polishingFilingCtrl.text.trim()) ?? 0;
    final b = int.tryParse(_polishingBeltCtrl.text.trim()) ?? 0;

    setState(() => _isSubmittingPolishing = true);
    try {
      debugPrint(
        '🚀 [POLISHING SUBMIT UI] Submitting Polishing: craftsman=$_polishingCraftsmanId, jobCode=$jobCode, direct=$d, indirect=$i, filing=$f, belt=$b, total=$_polishingTotalPcs',
      );
      final res = await _repo.submitPolishingLog(
        PolishingSubmitPayload(
          craftsmanId: _polishingCraftsmanId!,
          jobCode: jobCode.isNotEmpty ? jobCode : null,
          directPcs: d,
          indirectPcs: i,
          filingPcs: f,
          beltPcs: b,
          totalPcs: _polishingTotalPcs,
          notes: _polishingNotesCtrl.text.trim(),
        ),
      );
      debugPrint(
        '✅ [POLISHING SUBMIT UI SUCCESS] Response: id=${res.id}, totalPcs=${res.totalPcs}, craftsman=${res.craftsmanName}',
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
      debugPrint('❌ [POLISHING SUBMIT UI ERROR]: $e');
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
        title: 'Worker Required',
        message: 'Please select a worker for hand setting log.',
      );
      return;
    }

    final jobCode = _settingJobCodeCtrl.text.trim();
    final used = int.tryParse(_settingUsedStonesCtrl.text.trim()) ?? 0;
    final broken = int.tryParse(_settingBrokenStonesCtrl.text.trim()) ?? 0;

    if (used <= 0 && broken <= 0) {
      CommonSnackbar.warning(
        context,
        title: 'Stone Count Required',
        message: 'Please enter used stones or broken stones count.',
      );
      return;
    }

    final shape = _settingShape ?? (_stoneShapes.isNotEmpty ? _stoneShapes.first.name : 'Round');
    final color = _settingColor ?? (_stoneColors.isNotEmpty ? _stoneColors.first.name : 'White');
    final size = _settingSizeCtrl.text.trim().isNotEmpty ? _settingSizeCtrl.text.trim() : '1.5mm';

    setState(() => _isSubmittingSetting = true);
    try {
      debugPrint(
        '🚀 [HAND SETTING SUBMIT UI] Submitting Hand Setting: craftsman=$_settingCraftsmanId, jobCode=$jobCode, shape=$shape, color=$color, size=$size, used=$used, broken=$broken',
      );
      final res = await _repo.submitHandSettingLog(
        HandSettingSubmitPayload(
          craftsmanId: _settingCraftsmanId!,
          jobCode: jobCode.isNotEmpty ? jobCode : null,
          stoneType: shape,
          shape: shape,
          color: color,
          size: size,
          usedStonesCount: used,
          brokenStonesCount: broken,
          replacementRequested: _settingReplacementRequested,
          notes: _settingNotesCtrl.text.trim(),
        ),
      );
      debugPrint(
        '✅ [HAND SETTING SUBMIT UI SUCCESS] Response: id=${res.id}, usedStones=${res.usedStonesCount}, brokenStones=${res.brokenStonesCount}',
      );
      final displayUsed = res.usedStonesCount > 0 ? res.usedStonesCount : used;
      final displayBroken = res.brokenStonesCount > 0 ? res.brokenStonesCount : broken;

      _fetchSettingLogs(showLoading: false);

      if (mounted) {
        CommonSnackbar.success(
          context,
          title: 'Hand Setting Log Submitted',
          message:
              'Used: $displayUsed pcs, Broken: $displayBroken pcs recorded successfully.',
        );
        setState(() {
          _showSettingHistory = true;
          _settingUsedStonesCtrl.text = '0';
          _settingBrokenStonesCtrl.text = '0';
          _settingNotesCtrl.clear();
        });
      }
    } catch (e) {
      debugPrint('❌ [HAND SETTING SUBMIT UI ERROR]: $e');
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Workshop Department Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Physical Weights (g) & Pieces (pcs) • Zero Currency',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.outlineLight)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.emerald,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.emerald,
              unselectedLabelColor: AppColors.muted,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.local_fire_department_rounded, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 3),
                  text: 'Casting',
                ),
                Tab(
                  icon: Icon(Icons.handyman_rounded, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 3),
                  text: 'Filing',
                ),
                Tab(
                  icon: Icon(Icons.auto_awesome_rounded, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 3),
                  text: 'Polishing',
                ),
                Tab(
                  icon: Icon(Icons.diamond_outlined, size: 18),
                  iconMargin: EdgeInsets.only(bottom: 3),
                  text: 'Setting',
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
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
    );
  }

  // ── 1. Casting View (Record Casting) ──────────────────────────────────────
  Widget _buildCastingView() {
    final prev = double.tryParse(_castingPrevBalanceCtrl.text.trim()) ?? 0.0;
    final fresh = double.tryParse(_castingFreshIssueCtrl.text.trim()) ?? 0.0;
    final fin = double.tryParse(_castingFinishedWtCtrl.text.trim()) ?? 0.0;
    final scrap = double.tryParse(_castingRunnerScrapCtrl.text.trim()) ?? 0.0;
    final totalIn = prev + fresh;
    final totalRecovered = fin + scrap;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Furnace Status Banner
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.goldDark.withValues(alpha: 0.12),
                  AppColors.paper,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.goldDark.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.goldDark.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.goldDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Casting Furnace Register',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: AppColors.emerald),
                                SizedBox(width: 4),
                                Text(
                                  'Live Synced',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Gold Material Control • Exact Weight Tracking (g)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card 1: Lot Information & Opening Balance
          _buildSectionCard(
            title: 'Lot Identification & Opening',
            icon: Icons.tag_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextInput(
                      controller: _castingJobCodeCtrl,
                      label: 'Lot Number',
                      hint: 'e.g. LOT-20261006-1',
                      icon: Icons.qr_code_2_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _castingPrevBalanceCtrl,
                      label: 'Prev Balance',
                      hint: '0.000',
                      icon: Icons.history_rounded,
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Card 2: Fresh Metal Issuance & Recovery
          _buildSectionCard(
            title: 'Metal Issuance & Recovery',
            icon: Icons.scale_rounded,
            children: [
              _buildNumberInput(
                controller: _castingFreshIssueCtrl,
                label: 'Fresh Metal Issued',
                hint: 'Enter fresh metal weight',
                icon: Icons.add_circle_outline_rounded,
                suffix: 'g',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      controller: _castingFinishedWtCtrl,
                      label: 'Finished Weight',
                      hint: 'Finished casting tree',
                      icon: Icons.done_all_rounded,
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _castingRunnerScrapCtrl,
                      label: 'Runner Scrap',
                      hint: 'Runner return scrap',
                      icon: Icons.recycling_rounded,
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Card 3: Material Audit Summary & Closing Balance (Hero Card)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL METAL IN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${totalIn.toStringAsFixed(3)}g',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 26, color: AppColors.outlineLight),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL RECOVERED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${totalRecovered.toStringAsFixed(3)}g',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.outlineLight),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18,
                            color: AppColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Closing Balance',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Rolling to next furnace cycle',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_castingClosingBalance.toStringAsFixed(3)}g',
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cancel & Save Log Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.outlineLight),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CommonButton.primary(
                  label: 'Save Casting Log',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSubmittingCasting,
                  onPressed: _submitCasting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── 2. Filing View ────────────────────────────────────────────────────────
  Widget _buildFilingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Worker & Job Assignment
          _buildSectionCard(
            title: 'Worker Assignment & Work Order',
            icon: Icons.person_pin_rounded,
            children: [
              _buildCraftsmanSelectorField(
                label: 'Assigned Craftsman',
                selectedId: _filingCraftsmanId,
                onChanged: (val) => setState(() => _filingCraftsmanId = val),
              ),
              const SizedBox(height: 12),
              _buildTextInput(
                controller: _filingJobCodeCtrl,
                label: 'Job / Design Tag (Optional)',
                hint: 'e.g. RKE-351 or LOT-4',
                icon: Icons.tag_rounded,
              ),
            ],
          ),

          // Card 2: Physical Weights Movement
          _buildSectionCard(
            title: 'Metal Movement (Floor Weights)',
            icon: Icons.scale_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      controller: _filingIssueWtCtrl,
                      label: 'Raw Issued Weight',
                      hint: '0.000',
                      icon: Icons.arrow_forward_rounded,
                      suffix: 'g',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _filingFineReceivedCtrl,
                      label: 'Fine Received Wt',
                      hint: '0.000',
                      icon: Icons.check_circle_outline_rounded,
                      suffix: 'g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNumberInput(
                controller: _filingRunnerReturnCtrl,
                label: 'Runner Return Scrap',
                hint: '0.000',
                icon: Icons.keyboard_return_rounded,
                suffix: 'g',
              ),
            ],
          ),

          // Card 3: Wastage Difference Hero Card
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _filingWastageDiff >= 0
                    ? AppColors.goldDark.withValues(alpha: 0.35)
                    : Colors.red.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_filingWastageDiff >= 0 ? AppColors.goldDark : Colors.red)
                      .withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: (_filingWastageDiff >= 0
                                ? AppColors.goldDark
                                : Colors.red)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        size: 18,
                        color: _filingWastageDiff >= 0
                            ? AppColors.goldDark
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wastage Difference',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Issue - (Fine + Runner Scrap)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_filingWastageDiff >= 0
                            ? AppColors.goldDark
                            : Colors.red)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_filingWastageDiff.toStringAsFixed(3)}g',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: _filingWastageDiff >= 0
                          ? AppColors.goldDark
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card 4: Notes
          _buildSectionCard(
            title: 'Floor Remarks & Notes',
            icon: Icons.notes_rounded,
            children: [
              _buildTextInput(
                controller: _filingNotesCtrl,
                label: 'Notes (Optional)',
                hint: 'e.g. Sprue grinded and prong filing completed',
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: CommonButton.primary(
              label: 'Submit Filing Log',
              icon: Icons.send_rounded,
              isLoading: _isSubmittingFiling,
              onPressed: _submitFiling,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── 3. Polishing View ─────────────────────────────────────────────────────
  Widget _buildPolishingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Polisher & Work Order
          _buildSectionCard(
            title: 'Worker Assignment & Work Order',
            icon: Icons.person_pin_rounded,
            children: [
              _buildCraftsmanSelectorField(
                label: 'Assigned Polisher',
                selectedId: _polishingCraftsmanId,
                onChanged: (val) => setState(() => _polishingCraftsmanId = val),
              ),
              const SizedBox(height: 12),
              _buildTextInput(
                controller: _polishingJobCodeCtrl,
                label: 'Job / Design Tag (Optional)',
                hint: 'e.g. RKE-351 or LOT-4',
                icon: Icons.tag_rounded,
              ),
            ],
          ),

          // Card 2: Pieces Finished Breakdown
          _buildSectionCard(
            title: 'Pieces Finished Breakdown (pcs)',
            icon: Icons.auto_awesome_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      controller: _polishingDirectCtrl,
                      label: 'Direct Pieces',
                      hint: '0',
                      isInteger: true,
                      suffix: 'pcs',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _polishingIndirectCtrl,
                      label: 'Indirect Pieces',
                      hint: '0',
                      isInteger: true,
                      suffix: 'pcs',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      controller: _polishingFilingCtrl,
                      label: 'Filing Pieces',
                      hint: '0',
                      isInteger: true,
                      suffix: 'pcs',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _polishingBeltCtrl,
                      label: 'Belt Pieces',
                      hint: '0',
                      isInteger: true,
                      suffix: 'pcs',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Card 3: Total Output Hero Card
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: AppColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Polished Pieces',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Sum of Direct + Indirect + Filing + Belt',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_polishingTotalPcs pcs',
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card 4: Floor Notes
          _buildSectionCard(
            title: 'Floor Remarks & Notes',
            icon: Icons.notes_rounded,
            children: [
              _buildTextInput(
                controller: _polishingNotesCtrl,
                label: 'Notes (Optional)',
                hint: 'e.g. High luster final buff completed',
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: CommonButton.primary(
              label: 'Submit Polishing Log',
              icon: Icons.send_rounded,
              isLoading: _isSubmittingPolishing,
              onPressed: _submitPolishing,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── 4. Hand Setting View ──────────────────────────────────────────────────
  Widget _buildHandSettingView() {
    return Column(
      children: [
        // Sub-segmented Tab Bar between Log Entry & Logs Register
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outlineLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showSettingHistory = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_showSettingHistory ? AppColors.emerald : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Log Entry',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: !_showSettingHistory ? AppColors.pureWhite : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => _showSettingHistory = true);
                    _fetchSettingLogs(showLoading: false);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _showSettingHistory ? AppColors.emerald : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Logs Register',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _showSettingHistory ? AppColors.pureWhite : AppColors.ink,
                          ),
                        ),
                        if (_settingLogs.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _showSettingHistory
                                  ? AppColors.pureWhite.withOpacity(0.25)
                                  : AppColors.canvas,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_settingLogs.length}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: _showSettingHistory ? AppColors.pureWhite : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: _showSettingHistory
              ? _buildHandSettingHistoryView()
              : _buildHandSettingFormView(),
        ),
      ],
    );
  }

  Widget _buildHandSettingFormView() {
    final used = int.tryParse(_settingUsedStonesCtrl.text.trim()) ?? 0;
    final broken = int.tryParse(_settingBrokenStonesCtrl.text.trim()) ?? 0;
    final totalStones = used + broken;
    final breakagePercent =
        totalStones > 0 ? ((broken / totalStones) * 100).toStringAsFixed(1) : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Setter Assignment & Work Order
          _buildSectionCard(
            title: 'Worker Assignment & Work Order',
            icon: Icons.person_pin_rounded,
            children: [
              _buildCraftsmanSelectorField(
                label: 'Assigned Setter',
                selectedId: _settingCraftsmanId,
                onChanged: (val) {
                  setState(() => _settingCraftsmanId = val);
                  if (_showSettingHistory) _fetchSettingLogs(showLoading: false);
                },
              ),
              const SizedBox(height: 12),
              _buildTextInput(
                controller: _settingJobCodeCtrl,
                label: 'Job / Design Tag (Optional)',
                hint: 'e.g. LOT-202610-01 or RKE-351',
                icon: Icons.tag_rounded,
              ),
            ],
          ),

          // Card 2: Stone Shape, Color & Dimensions
          _buildSectionCard(
            title: 'Stone Specifications',
            icon: Icons.diamond_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _stoneShapes.isNotEmpty
                        ? _buildShapeSelectorField()
                        : _buildEmptyAttributeWarning('Shape', 'Loading shapes...'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stoneColors.isNotEmpty
                        ? _buildColorSelectorField()
                        : _buildEmptyAttributeWarning('Color', 'Loading colors...'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextInput(
                controller: _settingSizeCtrl,
                label: 'Stone Size',
                hint: 'e.g. 1.5mm',
                icon: Icons.straighten_rounded,
              ),
              if (_stoneSizes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _stoneSizes.take(10).map((sz) {
                    final isSel = _settingSizeCtrl.text.trim() == sz;
                    return InkWell(
                      onTap: () => setState(() => _settingSizeCtrl.text = sz),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.emerald : AppColors.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel ? AppColors.emerald : AppColors.outlineLight,
                          ),
                        ),
                        child: Text(
                          sz,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? AppColors.pureWhite : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),

          // Card 3: Consumption & Breakage Audit
          _buildSectionCard(
            title: 'Stone Consumption & Breakage Audit',
            icon: Icons.pie_chart_outline_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNumberInput(
                      controller: _settingUsedStonesCtrl,
                      label: 'Used Stones',
                      hint: '0',
                      isInteger: true,
                      icon: Icons.check_circle_outline_rounded,
                      suffix: 'pcs',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberInput(
                      controller: _settingBrokenStonesCtrl,
                      label: 'Broken / Crashed',
                      hint: '0',
                      isInteger: true,
                      icon: Icons.broken_image_outlined,
                      suffix: 'pcs',
                    ),
                  ),
                ],
              ),
              if (totalStones > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: broken > 0
                        ? AppColors.danger.withValues(alpha: 0.08)
                        : AppColors.emerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: broken > 0
                          ? AppColors.danger.withValues(alpha: 0.25)
                          : AppColors.emerald.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        broken > 0
                            ? 'Breakage Loss Rate: $breakagePercent%'
                            : 'Zero Breakage Reported (100% Intact)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: broken > 0 ? AppColors.danger : AppColors.emerald,
                        ),
                      ),
                      Text(
                        '$totalStones total stones',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Card 4: Replacement Request & Remarks
          _buildSectionCard(
            title: 'Dispatch & Remarks',
            icon: Icons.local_shipping_outlined,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Request Stockist dispatch to replace broken pieces',
                          style: TextStyle(fontSize: 10, color: AppColors.muted),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _settingReplacementRequested,
                      activeTrackColor: AppColors.emerald,
                      onChanged: (val) =>
                          setState(() => _settingReplacementRequested = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildTextInput(
                controller: _settingNotesCtrl,
                label: 'Notes / Reason (Optional)',
                hint: 'e.g. Setting completed for ring order',
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: CommonButton.primary(
              label: 'Submit Hand Setting Log',
              icon: Icons.send_rounded,
              isLoading: _isSubmittingSetting,
              onPressed: _submitHandSetting,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHandSettingHistoryView() {
    final query = _settingSearchQuery.trim().toLowerCase();
    final filteredLogs = _settingLogs.where((log) {
      if (query.isEmpty) return true;
      final worker = log.displayWorkerName.toLowerCase();
      final phone = log.craftsmanPhone.toLowerCase();
      final job = (log.jobCode ?? '').toLowerCase();
      final shape = log.shape.toLowerCase();
      final color = log.color.toLowerCase();
      final size = log.size.toLowerCase();
      final stoneType = log.stoneType.toLowerCase();
      final notes = log.notes.toLowerCase();
      final recBy = log.recordedByName.toLowerCase();
      return worker.contains(query) ||
          phone.contains(query) ||
          job.contains(query) ||
          shape.contains(query) ||
          color.contains(query) ||
          size.contains(query) ||
          stoneType.contains(query) ||
          notes.contains(query) ||
          recBy.contains(query);
    }).toList();

    return Column(
      children: [
        // Live Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _settingSearchCtrl,
            onChanged: (val) => setState(() => _settingSearchQuery = val),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: 'Search by worker, job tag, stone, color...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.subtle),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              suffixIcon: _settingSearchQuery.isNotEmpty
                  ? IconButton(
                      iconSize: 16,
                      icon: const Icon(Icons.clear_rounded, color: AppColors.muted),
                      onPressed: () {
                        _settingSearchCtrl.clear();
                        setState(() => _settingSearchQuery = '');
                      },
                    )
                  : null,
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
        ),

        // Status row with count & refresh button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredLogs.length} of ${_settingLogs.length} logs',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              InkWell(
                onTap: () => _fetchSettingLogs(showLoading: true),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, size: 13, color: AppColors.emerald),
                      const SizedBox(width: 4),
                      Text(
                        _isLoadingSettingLogs ? 'Refreshing...' : 'Refresh',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of logs
        Expanded(
          child: _isLoadingSettingLogs
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald),
                  ),
                )
              : filteredLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _settingSearchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.diamond_outlined,
                            size: 36,
                            color: AppColors.muted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _settingSearchQuery.isNotEmpty
                                ? 'No logs match "$_settingSearchQuery"'
                                : 'No hand setting logs recorded yet',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: filteredLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _buildHandSettingLogCard(log);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHandSettingLogCard(HandSettingLogResponse log) {
    String formattedTime = log.createdAt;
    try {
      final parsed = DateTime.tryParse(log.createdAt);
      if (parsed != null) {
        formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Job Code & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.outlineLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag_rounded, size: 12, color: AppColors.emerald),
                    const SizedBox(width: 3),
                    Text(
                      (log.jobCode != null && log.jobCode!.isNotEmpty)
                          ? log.jobCode!
                          : 'General Floor',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (formattedTime.isNotEmpty)
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Worker & Manager
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  log.displayWorkerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (log.craftsmanPhone.isNotEmpty)
                Text(
                  log.craftsmanPhone,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
            ],
          ),

          if (log.recordedByName.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 12, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  'Recorded by ${log.recordedByName}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Stones Spec & Breakdown
          Row(
            children: [
              // Used Stones Pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.emerald.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.usedStonesCount} pcs Used',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald,
                        ),
                      ),
                      Text(
                        '${log.size.isNotEmpty ? log.size : "-"} · ${log.color.isNotEmpty ? log.color : ""} · ${log.shape.isNotEmpty ? log.shape : log.stoneType}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              if (log.brokenStonesCount > 0) ...[
                const SizedBox(width: 8),
                // Broken Stones Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${log.brokenStonesCount} pcs Broken',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                        Text(
                          log.notes.isNotEmpty ? log.notes : 'Setting Breakage',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (log.replacementRequested) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber),
                  SizedBox(width: 4),
                  Text(
                    'Replacement Requested from Stockist',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (log.notes.isNotEmpty && log.brokenStonesCount == 0) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${log.notes}',
              style: const TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShapeSelectorField() {
    final selectedShape =
        _stoneShapes.where((s) => s.name == _settingShape).firstOrNull;
    final displayName = selectedShape?.name ?? (_settingShape ?? 'Select Shape');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stone Shape',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final picked = await SearchableAttributePickerSheet.show(
              context,
              type: AttributePickerType.shape,
              attributes: _stoneShapes,
              selectedName: _settingShape,
            );
            if (picked != null) {
              setState(() => _settingShape = picked.name);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.diamond_rounded,
                    size: 15,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedShape != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedShape != null
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelectorField() {
    final selectedColor =
        _stoneColors.where((c) => c.name == _settingColor).firstOrNull;
    final displayName = selectedColor?.name ?? (_settingColor ?? 'Select Color');

    Color swatchColor = AppColors.muted;
    if (selectedColor != null && selectedColor.hexCode.isNotEmpty) {
      try {
        final hex = selectedColor.hexCode.replaceAll('#', '').trim();
        if (hex.length == 6) {
          swatchColor = Color(int.parse('FF$hex', radix: 16));
        }
      } catch (_) {}
    } else if (selectedColor != null) {
      final n = selectedColor.name.toLowerCase();
      if (n.contains('white')) {
        swatchColor = const Color(0xFFF8F9FA);
      } else if (n.contains('pink')) {
        swatchColor = const Color(0xFFF48FB1);
      } else if (n.contains('green')) {
        swatchColor = const Color(0xFF4CAF50);
      } else if (n.contains('yellow') || n.contains('gold')) {
        swatchColor = const Color(0xFFFFD54F);
      } else if (n.contains('blue')) {
        swatchColor = const Color(0xFF42A5F5);
      } else if (n.contains('red')) {
        swatchColor = const Color(0xFFE53935);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stone Color',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final picked = await SearchableAttributePickerSheet.show(
              context,
              type: AttributePickerType.color,
              attributes: _stoneColors,
              selectedName: _settingColor,
            );
            if (picked != null) {
              setState(() => _settingColor = picked.name);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: swatchColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.outline, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedColor != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedColor != null
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAttributeWarning(String label, String message) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineLight),
          ),
          child: Text(
            message,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  // ── Helper Form Widgets ───────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.emerald),
                const SizedBox(width: 8),
              ],
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.muted,
                ),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? suffix,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          onTap: () {
            if (controller.text == '0' || controller.text == '0.0') {
              controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              );
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.subtle),
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: AppColors.muted)
                : null,
            prefixIconConstraints: icon != null
                ? const BoxConstraints(minWidth: 36, minHeight: 36)
                : null,
            suffixIcon: suffix != null
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.center,
                    width: 38,
                    child: Text(
                      suffix,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 36),
            filled: true,
            fillColor: AppColors.canvas,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
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
    IconData? icon,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.subtle),
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: AppColors.muted)
                : null,
            prefixIconConstraints: icon != null
                ? const BoxConstraints(minWidth: 36, minHeight: 36)
                : null,
            suffixIcon: suffix != null
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.center,
                    width: 38,
                    child: Text(
                      suffix,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 36),
            filled: true,
            fillColor: AppColors.canvas,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
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
    final name = selectedCraftsman?.name ?? 'Tap to select worker...';
    final role = selectedCraftsman?.role ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 5),
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selectedCraftsman != null
                        ? AppColors.emerald.withValues(alpha: 0.12)
                        : AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: selectedCraftsman != null
                        ? AppColors.emerald
                        : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
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
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.outlineLight),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
