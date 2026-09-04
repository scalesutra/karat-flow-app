import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../core/widgets/common_snackbar.dart';
import '../../../../core/widgets/common_text_field.dart';
import '../../../../core/widgets/common_progress_indicator.dart';
import '../../../../core/widgets/presigned_sketch_image.dart';
import '../../../../core/widgets/animated_empty_state_widget.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../data/demo_store.dart';
import '../bloc/admin_bloc.dart';
import 'sketch_directive_dialog.dart';

/// Modal bottom sheet for Admin Review of 2D Client Sketches
class AdminReviewSketchesSheet extends StatefulWidget {
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

  @override
  State<AdminReviewSketchesSheet> createState() =>
      _AdminReviewSketchesSheetState();
}

class _AdminReviewSketchesSheetState extends State<AdminReviewSketchesSheet> {
  String _selectedFilter = 'PENDING';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
  }

  void _openNewSketchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RegisterNewSketchSheet(store: widget.store),
    );
  }

  Widget _filterChip(String label, String filterKey) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.ink,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.emerald,
      backgroundColor: AppColors.canvas,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterKey;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, adminState) {
        return AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final allDesigns = widget.store.designs;
            final pendingDesigns = allDesigns
                .where(
                  (d) =>
                      !d.isPopular &&
                      !d.name.contains('(Sketch Approved)') &&
                      !d.name.contains('(Admin Approved)'),
                )
                .toList();
            final approvedDesigns = allDesigns
                .where(
                  (d) =>
                      d.isPopular ||
                      d.name.contains('(Sketch Approved)') ||
                      d.name.contains('(Admin Approved)'),
                )
                .toList();

            final designs = switch (_selectedFilter) {
              'APPROVED' => approvedDesigns,
              'ALL' => allDesigns,
              _ => pendingDesigns,
            };

            final isLoading = adminState is AdminLoading && allDesigns.isEmpty;

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
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          'Pending Review (${pendingDesigns.length})',
                          'PENDING',
                        ),
                        const SizedBox(width: 8),
                        _filterChip(
                          'Approved (${approvedDesigns.length})',
                          'APPROVED',
                        ),
                        const SizedBox(width: 8),
                        _filterChip('All (${allDesigns.length})', 'ALL'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CommonProgressIndicator.admin(
                              label: 'Syncing live API sketches...',
                            ),
                          )
                        : CommonRefreshIndicator(
                            theme: IndicatorTheme.universal,
                            onRefresh: () async => context
                                .read<AdminBloc>()
                                .add(const FetchAdminDashboardEvent()),
                            child: designs.isEmpty
                                ? ListView(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 70,
                                          bottom: 40,
                                        ),
                                        child: AnimatedEmptyStateWidget(
                                          icon: _selectedFilter == 'PENDING'
                                              ? Icons.draw_outlined
                                              : (_selectedFilter == 'APPROVED'
                                                    ? Icons.verified_outlined
                                                    : Icons.palette_outlined),
                                          title: _selectedFilter == 'PENDING'
                                              ? 'No Pending Sketches'
                                              : (_selectedFilter == 'APPROVED'
                                                    ? 'No Approved Sketches'
                                                    : 'No Sketches Available'),
                                          subtitle: _selectedFilter == 'PENDING'
                                              ? 'All client 2D design sketches have been reviewed and processed!'
                                              : (_selectedFilter == 'APPROVED'
                                                    ? 'No approved design sketches found in history.'
                                                    : 'No design sketches registered for review right now.'),
                                          accentColor: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    itemCount: designs.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (ctx, index) {
                                      final design = designs[index];
                                      final isApproved = design.isPopular ||
                                          design.name.contains(
                                            '(Sketch Approved)',
                                          ) ||
                                          design.name.contains(
                                            '(Admin Approved)',
                                          );

                                      return CommonCard(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    design.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14,
                                                      color: AppColors.ink,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isApproved
                                                        ? AppColors.emeraldLight
                                                        : AppColors.goldLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (isApproved)
                                                        const Icon(
                                                          Icons.check_circle,
                                                          size: 11,
                                                          color: AppColors
                                                              .emeraldDark,
                                                        )
                                                      else
                                                        const Icon(
                                                          Icons
                                                              .pending_outlined,
                                                          size: 11,
                                                          color: AppColors
                                                              .goldDark,
                                                        ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isApproved
                                                            ? 'APPROVED'
                                                            : 'PENDING REVIEW',
                                                        style: TextStyle(
                                                          color: isApproved
                                                              ? AppColors
                                                                    .emeraldDark
                                                              : AppColors
                                                                    .goldDark,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800,
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
                                            _buildSketchImageThumbnail(
                                              context,
                                              design,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                if (!isApproved) ...[
                                                  Expanded(
                                                    child: CommonButton.primary(
                                                      height: 34,
                                                      backgroundColor:
                                                          AppColors.emerald,
                                                      icon: Icons.check,
                                                      label: 'Approve Sketch',
                                                      onPressed: () {
                                                        context
                                                            .read<AdminBloc>()
                                                            .add(
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
      },
    );
  }

  Widget _buildSketchImageThumbnail(
    BuildContext context,
    JewelleryDesign design,
  ) {
    final hasImage = design.imageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => _showFullSketchImage(context, design),
      child: Container(
        height: 140,
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineLight),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasImage)
              PresignedSketchImage(
                imageUrl: design.imageUrl,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: () => _buildSketchPlaceholder(design),
              )
            else
              _buildSketchPlaceholder(design),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Tap to View Full Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSketchPlaceholder(JewelleryDesign design) {
    return Container(
      color: AppColors.canvas,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.brush_outlined,
              size: 36,
              color: AppColors.goldDark.withOpacity(0.7),
            ),
            const SizedBox(height: 6),
            Text(
              '2D Pencil Sketch · ${design.code}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullSketchImage(BuildContext context, JewelleryDesign design) {
    final hasImage = design.imageUrl.trim().isNotEmpty;
    final isApproved =
        design.isPopular || design.name.contains('(Sketch Approved)');

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            design.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Design Code: ${design.code} · Purity: ${design.purity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineLight),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasImage
                        ? PresignedSketchImage(
                            imageUrl: design.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: () => _buildSketchPlaceholder(design),
                          )
                        : _buildSketchPlaceholder(design),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    if (!isApproved) ...[
                      Expanded(
                        child: CommonButton.primary(
                          backgroundColor: AppColors.emerald,
                          icon: Icons.check,
                          label: 'Approve Sketch',
                          onPressed: () {
                            context.read<AdminBloc>().add(
                              ApproveSketchDesignEvent(design.id),
                            );
                            Navigator.pop(dialogCtx);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: CommonButton.outlined(
                        icon: Icons.send,
                        label: 'Send Directive',
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          SketchDirectiveDialog.show(context, design);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

    Uint8List? bytes = file?.bytes;
    if (bytes == null && file?.path != null) {
      final f = File(file!.path!);
      if (f.existsSync()) {
        bytes = f.readAsBytesSync();
      }
    }

    if (file == null || bytes == null || bytes.isEmpty) {
      CommonSnackbar.error(
        context,
        title: 'Sketch File Required',
        message: 'Select a valid PNG, JPG, or WEBP sketch file.',
      );
      return;
    }
    final newDesign = JewelleryDesign(
      id: 'sk-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: code,
      category: _selectedCategory,
      purity: _selectedPurity,
      imageUrl: file.path ?? '',
      description: 'New 2D Pencil Sketch',
      isPopular: false,
    );
    widget.store.addDesign(newDesign);

    context.read<AdminBloc>().add(
      UploadSketchEvent(
        designNumber: code,
        title: name,
        fileName: file.name,
        bytes: bytes,
      ),
    );
    Navigator.pop(context);
  }

  PlatformFile? _stlFile;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _showAttachmentPicker({
    required String title,
    required bool isStl,
  }) async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    isStl
                        ? 'Select 3D render, CAD screenshot, or photo from gallery'
                        : 'Select sketch photo from gallery',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isStl) {
                      _pickStlFromImage(ImageSource.gallery);
                    } else {
                      _pickSketchFromImage(ImageSource.gallery);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.goldDark,
                    ),
                  ),
                  title: const Text(
                    'Take Photo with Camera',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Capture sketch or wax model directly with camera',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isStl) {
                      _pickStlFromImage(ImageSource.camera);
                    } else {
                      _pickSketchFromImage(ImageSource.camera);
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  title: Text(
                    isStl
                        ? 'Browse 3D Files (.stl, .obj, .step)'
                        : 'Browse Files / Documents',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    isStl
                        ? 'Select 3D mesh file (.stl, .3ds, .obj, .step, .stp)'
                        : 'Select PNG, JPG, or WEBP document',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (isStl) {
                      _pickStlFile();
                    } else {
                      _pickSketchFile();
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickSketchFromImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _sketchFile = PlatformFile(
          name: file.name,
          size: bytes.length,
          bytes: bytes,
          path: file.path,
        );
      });
    } catch (e) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Selection Failed',
        message: 'Could not attach image: $e',
      );
    }
  }

  Future<void> _pickStlFromImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _stlFile = PlatformFile(
          name: file.name,
          size: bytes.length,
          bytes: bytes,
          path: file.path,
        );
      });
    } catch (e) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Selection Failed',
        message: 'Could not attach image: $e',
      );
    }
  }

  Future<void> _pickSketchFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() => _sketchFile = result.files.first);
  }

  Future<void> _pickStlFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['stl', '3ds', 'obj', 'step', 'stp', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() => _stlFile = result.files.first);
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
                  Row(
                    children: [
                      Expanded(
                        child: CommonButton.outlined(
                          label: _sketchFile?.name ?? 'Sketch Image *',
                          icon: Icons.photo_library_outlined,
                          onPressed: () => _showAttachmentPicker(
                            title: 'Select Sketch Image',
                            isStl: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CommonButton.outlined(
                          label: _stlFile?.name ?? 'STL 3D File (Optional)',
                          icon: Icons.view_in_ar_outlined,
                          onPressed: () => _showAttachmentPicker(
                            title: 'Select 3D Model or Render Asset',
                            isStl: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CommonButton.primary(
                    label: 'Upload Design & Assets',
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
