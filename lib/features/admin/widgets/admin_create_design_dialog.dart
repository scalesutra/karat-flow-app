import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/demo_store.dart';
import '../bloc/admin_bloc.dart';

class AdminCreateDesignDialog extends StatefulWidget {
  const AdminCreateDesignDialog({super.key, required this.store});

  final DemoStore store;

  static Future<void> show(BuildContext context, DemoStore store) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminCreateDesignDialog(store: store),
    );
  }

  @override
  State<AdminCreateDesignDialog> createState() =>
      _AdminCreateDesignDialogState();
}

class _AdminCreateDesignDialogState extends State<AdminCreateDesignDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _designCodeController;
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  final ImagePicker _imagePicker = ImagePicker();

  String? _sketchFileName;
  Uint8List? _sketchBytes;

  String? _stlFileName;
  Uint8List? _stlBytes;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _designCodeController = TextEditingController();
    _titleController = TextEditingController();
    _categoryController = TextEditingController();
    _weightController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _designCodeController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _pickSketchImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1920,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _sketchFileName = file.name;
        _sketchBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Image Selection Failed',
        message: 'Could not attach selected sketch image: $e',
      );
    }
  }

  Future<void> _pickSketchFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null || !mounted) return;
      setState(() {
        _sketchFileName = file!.name;
        _sketchBytes = file.bytes;
      });
    } catch (e) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'File Error',
        message: 'Could not select sketch file: $e',
      );
    }
  }

  Future<void> _pickStlImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _stlFileName = file.name;
        _stlBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'Image Selection Failed',
        message: 'Could not select 3D model render image: $e',
      );
    }
  }

  Future<void> _pickStlFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'stl',
          '3ds',
          'obj',
          'step',
          'stp',
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null || !mounted) return;
      setState(() {
        _stlFileName = file.name;
        _stlBytes = file.bytes;
      });
    } catch (e) {
      if (!mounted) return;
      CommonSnackbar.error(
        context,
        title: 'STL File Error',
        message: 'Could not select STL 3D file: $e',
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sketchBytes == null) {
      CommonSnackbar.error(
        context,
        title: 'Sketch Image Required',
        message:
            'Please upload a concept sketch image or screenshot for the new design.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final code = _designCodeController.text.trim().toUpperCase();
    final title = _titleController.text.trim();
    final categoryText = _categoryController.text.trim();
    final grossWt = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();

    // Dispatch to BLoC: uploads files to S3 + calls direct-create endpoint
    context.read<AdminBloc>().add(
      AdminDirectCreateDesignEvent(
        designNumber: code,
        title: title.isNotEmpty ? title : 'Design $code',
        category: categoryText.isNotEmpty ? categoryText : null,
        goldQuantity: grossWt > 0 ? grossWt : null,
        description: notes.isNotEmpty
            ? notes
            : (_stlFileName != null
                  ? 'Master design with 3D model file ($_stlFileName)'
                  : 'Master design concept sketch'),
        sketchFileName: _sketchFileName,
        sketchBytes: _sketchBytes,
        stlFileName: _stlFileName,
        stlBytes: _stlBytes,
      ),
    );

    if (mounted) {
      CommonSnackbar.success(
        context,
        title: 'Master Design Published',
        message: _stlFileName != null
            ? 'Design $code added to Catalogue with Sketch & 3D Asset ($_stlFileName)!'
            : 'Design $code added to Catalogue with Concept Sketch!',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- LUXURY BANNER HEADER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.emeraldDark,
                          Color(0xFF0F5A44),
                          AppColors.emerald,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.goldLight,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Master Design',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Catalogue Registry & Production Assets',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SECTION 1: IDENTITY & SPECIFICATIONS ---
                        _buildSectionHeader(
                          icon: Icons.fingerprint_rounded,
                          title: '1. DESIGN IDENTITY & SPECIFICATIONS',
                        ),
                        const SizedBox(height: 12),

                        // Code + Weight Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: CommonTextField(
                                controller: _designCodeController,
                                label: 'Design Code *',
                                hintText: 'e.g. DSN-1082',
                                prefixIcon: Icons.tag_rounded,
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Code required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: CommonTextField(
                                controller: _weightController,
                                label: 'Gross Wt (g)',
                                hintText: 'e.g. 24.50',
                                prefixIcon: Icons.scale_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title Field
                        CommonTextField(
                          controller: _titleController,
                          label: 'Design Title / Name *',
                          hintText: 'e.g. Royal Kundan Peacock Choker',
                          prefixIcon: Icons.title_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Design title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Category Field
                        CommonTextField(
                          controller: _categoryController,
                          label: 'Jewellery Category *',
                          hintText:
                              'e.g. Choker, Rings, Polki, Bangles, Pendants...',
                          prefixIcon: Icons.category_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Category is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // --- SECTION 2: CONCEPT VISUAL / SKETCH (REQUIRED) ---
                        _buildSectionHeader(
                          icon: Icons.palette_outlined,
                          title: '2. CONCEPT VISUAL / SKETCH *',
                          badge: _sketchBytes != null ? 'ATTACHED' : null,
                          badgeColor: AppColors.emeraldLight,
                          badgeTextColor: AppColors.emeraldDark,
                        ),
                        const SizedBox(height: 10),

                        if (_sketchBytes != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.emerald.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(13),
                                      ),
                                      child: Image.memory(
                                        _sketchBytes!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color: Colors.black54,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          onTap: () => setState(() {
                                            _sketchFileName = null;
                                            _sketchBytes = null;
                                          }),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.emeraldLight,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _sketchFileName ?? 'Sketch Image',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Size: ${_formatBytes(_sketchBytes!.length)}',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _pickSketchImage(
                                          ImageSource.gallery,
                                        ),
                                        icon: const Icon(
                                          Icons.sync_rounded,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Replace',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.emerald.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.emerald,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Select 2D Concept Sketch or Render Image',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Required for visual catalogue reference & workshop lots',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 10.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionPill(
                                        icon: Icons.camera_alt_outlined,
                                        label: 'Camera',
                                        onTap: () => _pickSketchImage(
                                          ImageSource.camera,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildActionPill(
                                        icon: Icons.photo_library_outlined,
                                        label: 'Gallery',
                                        isPrimary: true,
                                        onTap: () => _pickSketchImage(
                                          ImageSource.gallery,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildActionPill(
                                        icon: Icons.attach_file_rounded,
                                        label: 'File',
                                        onTap: _pickSketchFile,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // --- SECTION 3: 3D CAD MODEL / STL ASSET ---
                        _buildSectionHeader(
                          icon: Icons.view_in_ar_rounded,
                          title: '3. 3D MODEL / STL ASSET',
                          badge: _stlFileName != null
                              ? 'STL LOADED'
                              : 'RECOMMENDED',
                          badgeColor: _stlFileName != null
                              ? AppColors.goldLight
                              : AppColors.canvas,
                          badgeTextColor: _stlFileName != null
                              ? AppColors.goldDark
                              : AppColors.muted,
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _stlFileName != null
                                ? AppColors.goldLight.withValues(alpha: 0.25)
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _stlFileName != null
                                  ? AppColors.gold
                                  : AppColors.outlineLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _stlFileName != null
                                      ? AppColors.goldLight
                                      : AppColors.paper,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _stlFileName != null
                                        ? AppColors.gold
                                        : AppColors.outlineLight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.view_in_ar_rounded,
                                  size: 22,
                                  color: _stlFileName != null
                                      ? AppColors.goldDark
                                      : AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _stlFileName ?? 'No 3D Model Attached',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: _stlFileName != null
                                            ? AppColors.ink
                                            : AppColors.muted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _stlFileName != null
                                          ? 'Size: ${_formatBytes(_stlBytes?.length ?? 0)} · 3D Mesh ready'
                                          : 'Attach .STL, .OBJ, .3DS or 3D render image',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _stlFileName != null
                                            ? AppColors.goldDark
                                            : AppColors.muted,
                                        fontWeight: _stlFileName != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_stlFileName != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() {
                                    _stlFileName = null;
                                    _stlBytes = null;
                                  }),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMiniActionButton(
                                      icon: Icons.photo_library_outlined,
                                      label: 'Gallery',
                                      onTap: () =>
                                          _pickStlImage(ImageSource.gallery),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildMiniActionButton(
                                      icon: Icons.upload_file_rounded,
                                      label: 'File',
                                      isPrimary: true,
                                      onTap: _pickStlFile,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // --- SECTION 4: MASTER NOTES & SPECS ---
                        _buildSectionHeader(
                          icon: Icons.notes_rounded,
                          title: '4. MASTER NOTES & INSTRUCTIONS',
                        ),
                        const SizedBox(height: 10),

                        CommonTextField(
                          controller: _notesController,
                          label: 'Production Notes / Instructions (Optional)',
                          hintText:
                              'e.g. Master model for wholesale production · 2.5ct Solitaire setting',
                          prefixIcon: Icons.edit_note_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        // --- FOOTER BUTTONS ---
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.outline,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                label: Text(
                                  _isSubmitting
                                      ? 'Publishing...'
                                      : 'Save & Publish Design',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  disabledBackgroundColor: AppColors.emerald
                                      .withValues(alpha: 0.6),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  shadowColor: AppColors.emerald.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.emeraldDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              color: AppColors.ink,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor ?? AppColors.canvas,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor ?? AppColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? AppColors.emerald : AppColors.paper,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrimary ? AppColors.emerald : AppColors.outlineLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isPrimary ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: isPrimary ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? AppColors.goldDark : AppColors.paper,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary ? AppColors.goldDark : AppColors.outlineLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isPrimary ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: isPrimary ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
