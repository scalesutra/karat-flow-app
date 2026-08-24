import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/core/constants/app_colors.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_button.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_card.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_snackbar.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_text.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_text_field.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
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
  final _employeeIdController = TextEditingController();

  // ── Optional Controllers ──────────────────────────────────────────
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _skillController = TextEditingController();

  // ── Skill Categories with ID Prefixes ────────────────────────────
  static const List<Map<String, String>> _skillCategories = [
    {
      'name': 'Stone Setting',
      'prefix': 'SET',
      'icon': 'diamond',
      'desc': 'Prong, bezel & micro-pave setting',
    },
    {
      'name': 'Filing & Assembly',
      'prefix': 'FIL',
      'icon': 'hardware',
      'desc': 'Mounting, pre-polish shaping',
    },
    {
      'name': 'Polish & Rhodium',
      'prefix': 'POL',
      'icon': 'auto_awesome',
      'desc': 'Mirror finish, ultrasonic wash',
    },
    {
      'name': 'Tree Casting & Melting',
      'prefix': 'CST',
      'icon': 'local_fire_department',
      'desc': 'Vacuum induction casting',
    },
    {
      'name': 'CAD 3D Modeling',
      'prefix': 'CAD',
      'icon': 'view_in_ar',
      'desc': 'Rhino/Matrix 3D CAM design',
    },
    {
      'name': 'QC & Hallmarking',
      'prefix': 'QC',
      'icon': 'verified',
      'desc': 'XRF purity & weight tolerance',
    },
    {
      'name': 'Enameling & Meenakari',
      'prefix': 'MNK',
      'icon': 'brush',
      'desc': 'Kundan, jadau & traditional enamel',
    },
    {
      'name': 'Laser Soldering',
      'prefix': 'LSR',
      'icon': 'flash_on',
      'desc': 'Precision micro-pulse weld',
    },
  ];

  late String _selectedSkillCategory;

  @override
  void initState() {
    super.initState();
    _selectedSkillCategory = _skillCategories.first['name']!;
    _generateEmployeeId(_selectedSkillCategory);
  }

  void _generateEmployeeId(String categoryName) {
    final cat = _skillCategories.firstWhere(
      (c) => c['name'] == categoryName,
      orElse: () => _skillCategories.first,
    );
    final prefix = cat['prefix'] ?? 'ART';
    final count = widget.store.team.length + 1;
    _employeeIdController.text = '$prefix-${count.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final empId = _employeeIdController.text.trim();
    final skillDetail = _skillController.text.trim();

    final craftDisplay = skillDetail.isNotEmpty
        ? '$_selectedSkillCategory ($skillDetail)'
        : _selectedSkillCategory;

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

    context.read<AdminBloc>().add(
      AddArtisanEvent(newMember, phone: _phoneController.text.trim()),
    );

    if (widget.onArtisanAdded != null) {
      widget.onArtisanAdded!(newMember);
    } else {
      Navigator.pop(context, newMember);
    }
  }

  IconData _getIcon(String iconName) {
    return switch (iconName) {
      'diamond' => Icons.diamond_outlined,
      'hardware' => Icons.hardware_outlined,
      'auto_awesome' => Icons.auto_awesome,
      'local_fire_department' => Icons.local_fire_department_outlined,
      'view_in_ar' => Icons.view_in_ar_outlined,
      'verified' => Icons.verified_outlined,
      'brush' => Icons.brush_outlined,
      'flash_on' => Icons.flash_on_outlined,
      _ => Icons.person_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

                    // Skill Category Selector (Mandatory)
                    const Text(
                      'Skill Category *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSkillCategory,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.ink,
                          ),
                          items: _skillCategories.map((cat) {
                            final name = cat['name']!;
                            final prefix = cat['prefix']!;
                            final icon = _getIcon(cat['icon']!);
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: AppColors.goldDark,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.canvas,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    child: Text(
                                      prefix,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSkillCategory = val;
                                _generateEmployeeId(val);
                              });
                            }
                          },
                        ),
                      ),
                    ),
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                              'Selecting a skill category auto-updates the Employee ID prefix. Only Name and Skill Category are needed to add.',
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
                border: Border(top: BorderSide(color: AppColors.outlineLight)),
              ),
              child: CommonButton.primary(
                label: '+ Add Artisan',
                icon: Icons.check_circle_outline,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
