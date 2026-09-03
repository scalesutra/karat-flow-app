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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── Optional Controllers ──────────────────────────────────────────
  final _specialtyController = TextEditingController();
  final _skillsController = TextEditingController();

  String _selectedRole = 'CRAFTSMAN';
  List<ApiStage> _skillCategories = const [];
  String? _selectedStageId;
  bool _isSubmitting = false;
  TeamMember? _pendingMember;

  static const List<Map<String, String>> _availableRoles = [
    {
      'value': 'CRAFTSMAN',
      'label': 'Craftsman / Artisan',
      'desc': 'Workshop artisan on production floor',
    },
    {
      'value': 'MANAGER',
      'label': 'Workshop Manager',
      'desc': 'Oversees stage lots and assignments',
    },
    {
      'value': 'DESIGNER',
      'label': '3D CAD Designer',
      'desc': 'CAD modeler for 3D designs',
    },
    {
      'value': 'SKETCHER',
      'label': '2D Concept Sketcher',
      'desc': 'Raw pencil jewelry artist',
    },
    {
      'value': 'FRONTLINER',
      'label': 'Front Office / Sales',
      'desc': 'Customer orders and intake',
    },
    {
      'value': 'ADMIN',
      'label': 'System Administrator',
      'desc': 'Full system governance',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSkillCategories();
  }

  Future<void> _loadSkillCategories() async {
    final stages = widget.store.stages.where((stage) => stage.isActive).toList()
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
    if (!mounted) return;
    setState(() {
      _skillCategories = stages;
      _selectedStageId = stages.isEmpty ? null : stages.first.id;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _specialtyController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final specialty = _specialtyController.text.trim();
    final skillsRaw = _skillsController.text.trim();

    final skillsList = skillsRaw.isNotEmpty
        ? skillsRaw
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];

    final newMember = TeamMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      craft: specialty.isNotEmpty ? specialty : _selectedRole,
      shift: _selectedRole,
      activeLotsCount: 0,
      status: EmployeeStatus.available,
      todayEfficiencyPercent: 100,
      currentAssignment: 'Ready for allocation',
      email: email,
      phone: phone,
      role: _selectedRole,
      skills: skillsList,
      specialty: specialty,
    );

    setState(() {
      _pendingMember = newMember;
      _isSubmitting = true;
    });

    context.read<AdminBloc>().add(
      AddArtisanEvent(
        newMember,
        email: email,
        phone: phone,
        role: _selectedRole,
        password: password.isNotEmpty ? password : null,
        skills: skillsList,
        specialty: specialty,
        stageId: _selectedStageId ?? '',
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSubmit = !_isSubmitting;

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
                            'Workshop Artisan & Artisan Registration',
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
                        hintText: 'e.g. Kailash Prajapati',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) {
                          final str = val?.trim() ?? '';
                          if (str.isEmpty) return 'Employee name is required';
                          if (str.length < 2)
                            return 'Name must be at least 2 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email (Mandatory)
                      CommonTextField(
                        controller: _emailController,
                        label: 'Email Address *',
                        hintText: 'e.g. artisan@rkjewellers.com',
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

                      // Phone Number (Mandatory)
                      CommonTextField(
                        controller: _phoneController,
                        label: 'Phone Number *',
                        hintText: '+91 98290 11006',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) return 'Phone number is required';
                          if (phone.length < 5)
                            return 'Enter a valid phone number (min 5 digits)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Login Password (Mandatory)
                      CommonTextField(
                        controller: _passwordController,
                        label: 'Login Password *',
                        hintText: 'Initial password (min 6 characters)',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (val) {
                          final pwd = val?.trim() ?? '';
                          if (pwd.isEmpty)
                            return 'Initial password is required';
                          if (pwd.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Employee Role Dropdown (Mandatory)
                      _buildRoleSelector(),
                      const SizedBox(height: 24),

                      // ── 2. CRAFT & SPECIALTY SECTION ───────────
                      const CommonText.titleMedium('Craft Specialty & Skills'),
                      const SizedBox(height: 12),

                      // Primary Specialty (Optional)
                      CommonTextField(
                        controller: _specialtyController,
                        label: 'Primary Specialty / Craft (Optional)',
                        hintText: 'e.g. Stone Setting, Waxing',
                        prefixIcon: Icons.workspace_premium_outlined,
                      ),
                      const SizedBox(height: 12),

                      // Craft Skills (Optional, comma-separated)
                      CommonTextField(
                        controller: _skillsController,
                        label: 'Skills (Optional, comma-separated)',
                        hintText:
                            'e.g. Stone Setting, Micro Prong Setting, Waxing',
                        prefixIcon: Icons.military_tech_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Keycloak Registration Info Card
                      CommonCard(
                        backgroundColor: AppColors.canvas,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.security_outlined,
                              size: 20,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Employee profile will be stored in PostgreSQL & automatically registered in Keycloak Identity Provider for app login.',
                                style: TextStyle(
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
                  label: '+ Register Employee',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: _isSubmitting,
                  onPressed: !_isSubmitting ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee Role *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.ink,
              ),
              items: _availableRoles.map((role) {
                return DropdownMenuItem<String>(
                  value: role['value'],
                  child: Row(
                    children: [
                      Icon(
                        _getRoleIcon(role['value']!),
                        size: 18,
                        color: AppColors.goldDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          role['label']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null) {
                  setState(() {
                    _selectedRole = newRole;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    return switch (role.toUpperCase()) {
      'ADMIN' => Icons.admin_panel_settings_outlined,
      'MANAGER' => Icons.manage_accounts_outlined,
      'DESIGNER' => Icons.view_in_ar_outlined,
      'SKETCHER' => Icons.draw_outlined,
      'FRONTLINER' => Icons.storefront_outlined,
      _ => Icons.precision_manufacturing_outlined,
    };
  }
}
