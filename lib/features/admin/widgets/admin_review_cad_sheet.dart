import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_3d_viewer.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_progress_indicator.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../core/widgets/common_text_field.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';

/// Modal bottom sheet for Admin Review of 3D CAD Models
class AdminReviewCadSheet extends StatelessWidget {
  const AdminReviewCadSheet({
    super.key,
    required this.store,
    required this.onSendDirective,
  });

  final DemoStore store;
  final void Function(String contextRef) onSendDirective;

  static void show(
    BuildContext context, {
    required DemoStore store,
    required void Function(String contextRef) onSendDirective,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: AdminReviewCadSheet(
          store: store,
          onSendDirective: onSendDirective,
        ),
      ),
    );
  }

  void _openDirectCadBriefModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NewCadBriefSheet(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pendingTasks = store.cadTasks;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review 3D CAD Models',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Inspect solitaire ring models and approve for printing',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: CommonRefreshIndicator(
                  theme: IndicatorTheme.cad,
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: pendingTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final task = pendingTasks[index];
                      final isApproved = task.status == CadTaskStatus.completed ||
                          task.specs.contains('(Approved)');

                      return CommonCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    task.productTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isApproved
                                        ? AppColors.emeraldLight
                                        : AppColors.goldLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isApproved)
                                        const Icon(Icons.check_circle, size: 11, color: AppColors.emeraldDark)
                                      else
                                        const Icon(Icons.view_in_ar, size: 11, color: AppColors.goldDark),
                                      const SizedBox(width: 4),
                                      Text(
                                        isApproved ? 'APPROVED' : 'PENDING 3D SIGN-OFF',
                                        style: TextStyle(
                                          color: isApproved
                                              ? AppColors.emeraldDark
                                              : AppColors.goldDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Code: ${task.designCode} · Client: ${task.clientName} · ${task.specs}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: CommonButton.outlined(
                                    height: 34,
                                    icon: Icons.view_in_ar,
                                    label: 'View 3D',
                                    onPressed: () {
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (viewCtx) => Common3DViewer(
                                          designCode: task.designCode,
                                          productTitle: task.productTitle,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isApproved) ...[
                                  Expanded(
                                    child: CommonButton.primary(
                                      height: 34,
                                      backgroundColor: AppColors.emerald,
                                      icon: Icons.check_circle_outline,
                                      label: 'Approve 3D',
                                      onPressed: () {
                                        store.approveCadTask(task.id);
                                        CommonSnackbar.success(
                                          context,
                                          title: 'CAD 3D Approved',
                                          message: 'Model for ${task.productTitle} approved for wax printing.',
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: CommonButton.outlined(
                                    height: 34,
                                    icon: Icons.edit_note,
                                    label: 'Directive',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onSendDirective(
                                        'CAD Modification: ${task.designCode}',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  onPressed: () => _openDirectCadBriefModal(context),
                  label: '+ Direct CAD Brief / New Task',
                  icon: Icons.add_box_outlined,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet to create a direct CAD Design Task
class _NewCadBriefSheet extends StatefulWidget {
  const _NewCadBriefSheet({required this.store});

  final DemoStore store;

  @override
  State<_NewCadBriefSheet> createState() => _NewCadBriefSheetState();
}

class _NewCadBriefSheetState extends State<_NewCadBriefSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _designCodeController = TextEditingController();
  final _clientController = TextEditingController(text: 'Direct Wholesale Client');
  final _weightController = TextEditingController(text: '35.0');
  final _specsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final count = widget.store.cadTasks.length + 1;
    _designCodeController.text = 'CAD-${count.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _designCodeController.dispose();
    _clientController.dispose();
    _weightController.dispose();
    _specsController.dispose();
    super.dispose();
  }

  void _saveCadBrief() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final code = _designCodeController.text.trim().toUpperCase();
    final client = _clientController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 25.0;
    final specs = _specsController.text.trim().isEmpty
        ? '22K Gold, standard prongs and wall thickness'
        : _specsController.text.trim();

    final newTask = CadDesignTask(
      id: 'CAD-${DateTime.now().millisecondsSinceEpoch}',
      orderId: 'DIR-CAD-${code.replaceAll('-', '')}',
      designCode: code,
      productTitle: title,
      clientName: client,
      specs: specs,
      notes: 'Direct design brief submitted from Admin Review Desk.',
      estimatedWeightGrams: weight,
      status: CadTaskStatus.newTask,
      hasVoiceNote: false,
      hasSketchImage: true,
      hasStlFile: true,
      assignedTo: 'Vikram · CAD',
      receivedAt: DateTime.now(),
    );

    widget.store.addCadTask(newTask);
    Navigator.pop(context);

    CommonSnackbar.success(
      context,
      title: 'CAD Brief Created',
      message: '$title ($code) assigned to CAD team queue.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.view_in_ar_outlined, color: AppColors.goldDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direct CAD Brief',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
                        ),
                        Text(
                          'Create a new 3D modeling task for CAD team',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outlineLight),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    CommonTextField(
                      controller: _titleController,
                      label: 'Product / Jewellery Title *',
                      hintText: 'e.g. Royal Antique Navratna Choker',
                      prefixIcon: Icons.diamond_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Title is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            controller: _designCodeController,
                            label: 'Design Code *',
                            hintText: 'e.g. NK-505',
                            prefixIcon: Icons.tag,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Code is required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CommonTextField(
                            controller: _weightController,
                            label: 'Target Weight (g) *',
                            hintText: 'e.g. 38.5',
                            prefixIcon: Icons.scale_outlined,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Weight is required';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CommonTextField(
                      controller: _clientController,
                      label: 'Client / Party Name',
                      hintText: 'e.g. Saanvi Jewels, Jaipur',
                      prefixIcon: Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 12),
                    CommonTextField(
                      controller: _specsController,
                      label: 'Modeling Specs & Tolerance Notes',
                      hintText: 'e.g. 22K Gold, 1.2mm minimum wall thickness, 2.5ct total diamond setting.',
                      prefixIcon: Icons.notes_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.paper,
                border: Border(top: BorderSide(color: AppColors.outlineLight)),
              ),
              child: CommonButton.primary(
                label: 'Dispatch CAD Brief',
                icon: Icons.send,
                onPressed: _saveCadBrief,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
