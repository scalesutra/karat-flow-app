import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_card.dart';
import '../../../core/widgets/common_text.dart';
import '../../../core/widgets/common_text_field.dart';
import '../../../data/demo_store.dart';
import '../bloc/admin_bloc.dart';

class AddStageSheet extends StatefulWidget {
  const AddStageSheet({
    super.key,
    required this.store,
    this.defaultSequence,
  });

  final DemoStore store;
  final int? defaultSequence;

  static Future<void> show(
    BuildContext context, {
    required DemoStore store,
    int? defaultSequence,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddStageSheet(
        store: store,
        defaultSequence: defaultSequence,
      ),
    );
  }

  @override
  State<AddStageSheet> createState() => _AddStageSheetState();
}

class _AddStageSheetState extends State<AddStageSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _seqController;
  late final TextEditingController _descController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final nextSeq = widget.defaultSequence ?? (widget.store.stages.length + 1);
    _nameController = TextEditingController();
    _seqController = TextEditingController(text: '$nextSeq');
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seqController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final seq = int.tryParse(_seqController.text.trim()) ?? 1;
    final desc = _descController.text.trim();

    setState(() => _isSubmitting = true);

    context.read<AdminBloc>().add(
      CreateStageEvent(
        name: name,
        stageNumber: seq,
        description: desc,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText.headlineSmall('Create Production Stage'),
                        const SizedBox(height: 2),
                        CommonText.bodySmall(
                          'Add a sequential stage to the workshop manufacturing flow',
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Sequence preview banner
              CommonCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sequential Workflow Rule',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current active stages: ${widget.store.stages.length}. New stages are auto-ordered by sequence.',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stage Name
              CommonTextField(
                controller: _nameController,
                labelText: 'Stage Name *',
                hintText: 'e.g. Laser Engraving & Hallmarking',
                prefixIcon: Icons.label_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Stage name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Stage name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Stage Sequence Number
              CommonTextField(
                controller: _seqController,
                labelText: 'Sequence Step Number *',
                hintText: 'e.g. 5',
                prefixIcon: Icons.format_list_numbered_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Sequence step number is required';
                  }
                  final num = int.tryParse(val.trim());
                  if (num == null || num < 1) {
                    return 'Sequence number must be a positive integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description
              CommonTextField(
                controller: _descController,
                labelText: 'Technical Guidelines / Description (Optional)',
                hintText: 'e.g. Personalized custom laser hallmark & serialization guidelines',
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  isLoading: _isSubmitting,
                  label: 'Create Stage',
                  icon: Icons.add_task_rounded,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
