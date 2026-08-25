import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_card.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_progress_indicator.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_text.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_text_field.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import '../bloc/admin_bloc.dart';

class AddArtisanSheet extends StatefulWidget {
  const AddArtisanSheet({super.key, required this.store, this.onArtisanAdded});

  final DemoStore store;
  final ValueChanged<TeamMember>? onArtisanAdded;

  static Future<TeamMember?> show(BuildContext context, DemoStore store) {
    return showModalBottomSheet<TeamMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddArtisanSheet(
        store: store,
        onArtisanAdded: (member) => Navigator.pop(ctx, member),
      ),
    );
  }

  @override
  State<AddArtisanSheet> createState() => _AddArtisanSheetState();
}

class _AddArtisanSheetState extends State<AddArtisanSheet> {
  final _formKey = GlobalKey<FormState>();

  // ── Mandatory Controllers ─────────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();

  // ── Optional Controllers ──────────────────────────────────────────
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _skillController = TextEditingController();

  List<ApiStage> _skillCategories = const [];
  String? _selectedStageId;
  String? _stageError;
  bool _isLoadingStages = true;
  bool _isSubmitting = false;
  TeamMember? _pendingMember;

  ApiStage? get _selectedStage {
    for (final stage in _skillCategories) {
      if (stage.id == _selectedStageId) return stage;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadSkillCategories();
  }

  Future<void> _loadSkillCategories() async {
    setState(() {
      _isLoadingStages = true;
      _stageError = null;
    });
    final stages = widget.store.stages.where((stage) => stage.isActive).toList()
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
    if (!mounted) return;
    setState(() {
      _skillCategories = stages;
      _selectedStageId = stages.isEmpty ? null : stages.first.id;
      _stageError = stages.isEmpty
          ? 'No live production stages are available.'
          : null;
      _isLoadingStages = false;
    });
    if (stages.isNotEmpty) _generateEmployeeId(stages.first);
  }

  void _generateEmployeeId(ApiStage stage) {
    final sanitized = stage.name
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final prefix = sanitized.isEmpty
        ? 'ART'
        : sanitized.length <= 3
        ? sanitized
        : sanitized.substring(0, 3);
    final count = widget.store.team.length + 1;
    _employeeIdController.text = '$prefix-${count.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final stage = _selectedStage;
    if (stage == null || _isSubmitting) return;

    final name = _nameController.text.trim();
    final empId = _employeeIdController.text.trim();
    final skillDetail = _skillController.text.trim();

    final craftDisplay = skillDetail.isNotEmpty
        ? '${stage.name} ($skillDetail)'
        : stage.name;

    final newMember = TeamMember(
      id: empId,
      name: name,
      craft: craftDisplay,
      shift: 'Morning Shift',
      activeLotsCount: 0,
      status: EmployeeStatus.available,
      todayEfficiencyPercent: 100,
      currentAssignment: 'Ready for allocation',
    );

    setState(() {
      _pendingMember = newMember;
      _isSubmitting = true;
    });
    context.read<AdminBloc>().add(
      AddArtisanEvent(
        newMember,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        stageId: stage.id,
      ),
    );
  }

  void _handleAdminState(BuildContext context, AdminState state) {
    if (_pendingMember == null) return;
    if (state is AdminActionSuccess) {
      final member = _pendingMember!;
      _pendingMember = null;
      if (widget.onArtisanAdded != null) {
        widget.onArtisanAdded!(member);
      } else {
        Navigator.pop(context, member);
      }
    } else if (state is AdminError) {
      setState(() {
        _pendingMember = null;
        _isSubmitting = false;
      });
      CommonSnackbar.error(
        context,
        title: 'Unable to add artisan',
        message: state.message,
      );
    }
  }

  IconData _getStageIcon(String stageName) {
    final normalized = stageName.toLowerCase();
    if (normalized.contains('cad') || normalized.contains('wax')) {
      return Icons.view_in_ar_outlined;
    }
    if (normalized.contains('cast') || normalized.contains('melt')) {
      return Icons.local_fire_department_outlined;
    }
    if (normalized.contains('setting')) return Icons.diamond_outlined;
    if (normalized.contains('polish')) return Icons.auto_awesome;
    if (normalized.contains('quality') || normalized.contains('qc')) {
      return Icons.verified_outlined;
    }
    return Icons.precision_manufacturing_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSubmit =
        !_isLoadingStages &&
        _stageError == null &&
        _selectedStageId != null &&
        _skillCategories.isNotEmpty &&
        !_isSubmitting;

    return BlocListener<AdminBloc, AdminState>(
      listener: _handleAdminState,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            children: [
              // Handle Bar
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.goldDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Artisan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Workshop Goldsmith & Karigar Registration',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.muted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.outlineLight),

              // Form Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // ── 1. MANDATORY SECTION ─────────────────────────
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.goldDark,
                          ),
                          const SizedBox(width: 6),
                          const CommonText.titleMedium('Mandatory Information'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Full Name (Mandatory)
                      CommonTextField(
                        controller: _nameController,
                        label: 'Full Name *',
                        hintText: 'e.g. Ramesh Chandra Verma',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Artisan name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      CommonTextField(
                        controller: _emailController,
                        label: 'Email Address *',
                        hintText: 'artisan@company.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Email address is required';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _buildSkillCategoryField(),
                      const SizedBox(height: 14),

                      // Employee ID (Mandatory / Auto-generated from Category)
                      CommonTextField(
                        controller: _employeeIdController,
                        label: 'Employee ID * (Auto-Generated)',
                        hintText: 'e.g. SET-007',
                        prefixIcon: Icons.tag_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Employee ID is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── 2. OPTIONAL SECTION ──────────────────────────
                      const CommonText.titleMedium('Optional Details'),
                      const SizedBox(height: 12),

                      // Phone Number
                      CommonTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'e.g. 98290 12345',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Address (Optional)
                      CommonTextField(
                        controller: _addressController,
                        label: 'Address (Optional)',
                        hintText: 'e.g. Johari Bazaar, Jaipur',
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Skill / Specialization (Optional)
                      CommonTextField(
                        controller: _skillController,
                        label: 'Specialized Skill / Notes (Optional)',
                        hintText: 'e.g. Micro-prong setting, Solitaire bezel',
                        prefixIcon: Icons.military_tech_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Summary Card
                      CommonCard(
                        backgroundColor: AppColors.canvas,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Skill categories are loaded from the live production stages API. The selected stage is saved with the employee.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  border: Border(
                    top: BorderSide(color: AppColors.outlineLight),
                  ),
                ),
                child: CommonButton.primary(
                  label: '+ Add Artisan',
                  icon: Icons.check_circle_outline,
                  isLoading: _isSubmitting,
                  onPressed: canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skill Category *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        if (_isLoadingStages)
          const SizedBox(
            height: 72,
            child: Center(
              child: CommonProgressIndicator.medium(
                theme: IndicatorTheme.workshop,
              ),
            ),
          )
        else if (_stageError != null || _skillCategories.isEmpty)
          CommonCard(
            backgroundColor: AppColors.dangerLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stageError == null
                      ? 'No active skill categories returned by the stages API.'
                      : 'Could not load skill categories from the stages API.',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                CommonButton.outlined(
                  label: 'Retry',
                  isFullWidth: false,
                  height: 34,
                  onPressed: _loadSkillCategories,
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStageId,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.ink,
                ),
                items: _skillCategories.map((stage) {
                  return DropdownMenuItem<String>(
                    value: stage.id,
                    child: Row(
                      children: [
                        Icon(
                          _getStageIcon(stage.name),
                          size: 18,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stage.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '#${stage.stageNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (stageId) {
                  if (stageId == null) return;
                  final stage = _skillCategories.firstWhere(
                    (item) => item.id == stageId,
                  );
                  setState(() {
                    _selectedStageId = stageId;
                    _generateEmployeeId(stage);
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}
