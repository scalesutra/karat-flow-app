import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../core/widgets/common_text_field.dart';
import '../../../../data/demo_store.dart';
import '../../../../domain/models.dart';
import '../bloc/admin_bloc.dart';
import 'sketch_directive_dialog.dart';

/// Modal bottom sheet for Admin Review of 2D Client Sketches
class AdminReviewSketchesSheet extends StatelessWidget {
  const AdminReviewSketchesSheet({
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
        child: AdminReviewSketchesSheet(
          store: store,
          onSendDirective: onSendDirective,
        ),
      ),
    );
  }

  void _openNewSketchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RegisterNewSketchSheet(store: store),
    );
  }

  void _showDirectiveDialog(BuildContext context, JewelleryDesign design) {
    final controller = TextEditingController(
      text:
          'Please adjust prong height and check shank thickness for ${design.name} (${design.code}).',
    );
    String targetRole = 'CAD Designer';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.paper,
          title: Row(
            children: [
              const Icon(
                Icons.send_rounded,
                color: AppColors.goldDark,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Directive for ${design.code}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Recipient Role:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: targetRole,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'CAD Designer',
                    child: Text('CAD Designer'),
                  ),
                  DropdownMenuItem(
                    value: 'Goldsmith (Artisans)',
                    child: Text('Goldsmith (Artisans)'),
                  ),
                  DropdownMenuItem(
                    value: 'Process Manager',
                    child: Text('Process Manager'),
                  ),
                  DropdownMenuItem(value: 'QC Team', child: Text('QC Team')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => targetRole = val);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Correction Message / Directive:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Enter correction notes for the artisan/designer...',
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Dispatch Directive'),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  context.read<AdminBloc>().add(
                    SendDirectiveEvent(recipient: targetRole, directive: text),
                  );
                  Navigator.pop(dialogCtx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final designs = store.designs;

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
                          'Review Client Sketches',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Approve client 2D sketches or send correction directives',
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
                child: designs.isEmpty
                    ? const Center(
                        child: Text(
                          'No design sketches available.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: designs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final design = designs[index];
                          final isApproved = design.name.contains(
                            '(Sketch Approved)',
                          );

                          return CommonCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        design.name,
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
                                            const Icon(
                                              Icons.check_circle,
                                              size: 11,
                                              color: AppColors.emeraldDark,
                                            )
                                          else
                                            const Icon(
                                              Icons.pending_outlined,
                                              size: 11,
                                              color: AppColors.goldDark,
                                            ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isApproved
                                                ? 'APPROVED'
                                                : 'PENDING REVIEW',
                                            style: TextStyle(
                                              color: isApproved
                                                  ? AppColors.emeraldDark
                                                  : AppColors.goldDark,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Code: ${design.code} · Purity: ${design.purity} · Est. Weight: ${design.grossWeightGrams} g · ₹${(design.estimatedPrice / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (!isApproved) ...[
                                      Expanded(
                                        child: CommonButton.primary(
                                          height: 34,
                                          backgroundColor: AppColors.emerald,
                                          icon: Icons.check,
                                          label: 'Approve Sketch',
                                          onPressed: () {
                                            context.read<AdminBloc>().add(
                                              ApproveSketchDesignEvent(
                                                design.id,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: CommonButton.outlined(
                                        height: 34,
                                        icon: Icons.send,
                                        label: 'Send Directive',
                                        onPressed: () =>
                                            SketchDirectiveDialog.show(
                                              context,
                                              design,
                                            ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  onPressed: () => _openNewSketchModal(context),
                  label: '+ Register New Design Sketch',
                  icon: Icons.add_photo_alternate_outlined,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet form to register a new 2D jewellery sketch design
class _RegisterNewSketchSheet extends StatefulWidget {
  const _RegisterNewSketchSheet({required this.store});

  final DemoStore store;

  @override
  State<_RegisterNewSketchSheet> createState() =>
      _RegisterNewSketchSheetState();
}

class _RegisterNewSketchSheetState extends State<_RegisterNewSketchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final JewelleryCategory _selectedCategory = JewelleryCategory.necklaces;
  String _selectedPurity = '22KT';

  final List<String> _purityOptions = const ['22KT', '18KT', '14KT', '24KT'];
  PlatformFile? _sketchFile;

  @override
  void initState() {
    super.initState();
    final count = widget.store.designs.length + 1;
    _codeController.text = 'DSG-${count.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveSketch() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    final file = _sketchFile;
    if (file?.bytes == null) {
      CommonSnackbar.error(
        context,
        title: 'Sketch File Required',
        message: 'Select a PNG, JPG, or WEBP sketch file.',
      );
      return;
    }
    context.read<AdminBloc>().add(
      UploadSketchEvent(
        designNumber: code,
        title: name,
        fileName: file!.name,
        bytes: file.bytes!,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickSketch() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() => _sketchFile = result.files.first);
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
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.brush_outlined,
                      color: AppColors.emeraldDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register Design Sketch',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Create a new 2D client sketch entry for CAD approval',
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
            ),
            const Divider(height: 1, color: AppColors.outlineLight),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    CommonTextField(
                      controller: _nameController,
                      label: 'Design Name *',
                      hintText: 'e.g. Peacock Kundan Jadau Haar',
                      prefixIcon: Icons.auto_awesome,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Design name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            controller: _codeController,
                            label: 'Design Code *',
                            hintText: 'e.g. NK-991',
                            prefixIcon: Icons.tag,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Code is required';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Purity *',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPurity,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                ),
                                items: _purityOptions
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedPurity = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            controller: _weightController,
                            label: 'Est. Gross Weight (g) *',
                            hintText: 'e.g. 48.5',
                            prefixIcon: Icons.scale_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Weight is required';
                              if (double.tryParse(val.trim()) == null)
                                return 'Enter valid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CommonTextField(
                            controller: _priceController,
                            label: 'Est. Price (₹)',
                            hintText: 'e.g. 350000',
                            prefixIcon: Icons.currency_rupee_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CommonTextField(
                      controller: _descriptionController,
                      label: 'Sketch Notes / Specs (Optional)',
                      hintText:
                          'e.g. Client requested antique finish with South Sea pearl drops.',
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommonButton.outlined(
                    label: _sketchFile?.name ?? 'Select Sketch File',
                    icon: Icons.attach_file,
                    onPressed: _pickSketch,
                  ),
                  const SizedBox(height: 8),
                  CommonButton.primary(
                    label: 'Upload Design Sketch',
                    icon: Icons.cloud_upload_outlined,
                    onPressed: _saveSketch,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
