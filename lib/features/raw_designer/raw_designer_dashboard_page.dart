import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/api_models.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../instructions/directive_audio.dart';
import 'bloc/sketch_bloc.dart';

class RawDesignerDashboardPage extends StatefulWidget {
  const RawDesignerDashboardPage({super.key});

  @override
  State<RawDesignerDashboardPage> createState() =>
      _RawDesignerDashboardPageState();
}

class _RawDesignerDashboardPageState extends State<RawDesignerDashboardPage> {
  String _status = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SketchBloc>().add(const FetchSketchesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String value) {
    setState(() => _status = value);
    context.read<SketchBloc>().add(FetchSketchesEvent(status: value));
  }

  List<ApiSketch> _applySearch(List<ApiSketch> sketches) {
    if (_searchQuery.trim().isEmpty) return sketches;
    final query = _searchQuery.toLowerCase().trim();
    return sketches.where((s) {
      final matchesDesign = s.designNumber.toLowerCase().contains(query);
      final matchesTitle = s.title.toLowerCase().contains(query);
      return matchesDesign || matchesTitle;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchBloc, SketchState>(
      builder: (context, state) {
        final allSketches = state is SketchLoaded
            ? state.sketches
            : const <ApiSketch>[];
        final filteredSketches = _applySearch(allSketches);
        final loading = state is SketchLoading || state is SketchInitial;

        final pendingCount = _count(allSketches, 'PENDING');
        final revisionCount = _count(allSketches, 'CHANGES_REQUESTED');
        final approvedCount = _count(allSketches, 'APPROVED');

        return RefreshIndicator(
          color: AppColors.emerald,
          onRefresh: () async => context.read<SketchBloc>().add(
            FetchSketchesEvent(status: _status),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RoleDashboardHeader(
                      eyebrow: 'Raw Design Studio',
                      title: 'Sketch Dashboard',
                      description:
                          'Create, revise, and manage live pencil sketches for the production pipeline.',
                      icon: Icons.draw_outlined,
                      action: CommonButton.primary(
                        isFullWidth: false,
                        label: 'Upload Sketch',
                        icon: Icons.upload_file_rounded,
                        onPressed: () => _showUploadDialog(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ResponsiveMetricGrid(
                      metrics: [
                        DashboardMetric(
                          value: '${allSketches.length}',
                          label: 'Total Sketches',
                          icon: Icons.collections_outlined,
                          color: AppColors.emerald,
                        ),
                        DashboardMetric(
                          value: '$pendingCount',
                          label: 'Awaiting Review',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                        ),
                        DashboardMetric(
                          value: '$revisionCount',
                          label: 'Needs Revision',
                          icon: Icons.assignment_late_outlined,
                          color: AppColors.danger,
                        ),
                        DashboardMetric(
                          value: '$approvedCount',
                          label: 'Approved',
                          icon: Icons.verified_rounded,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search & Filter Controls Bar
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            controller: _searchController,
                            hintText: 'Search by design code or title...',
                            prefixIcon: Icons.search_rounded,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CommonFilterChips<String>(
                      padding: EdgeInsets.zero,
                      options: const [
                        '',
                        'PENDING',
                        'CHANGES_REQUESTED',
                        'APPROVED',
                      ],
                      selected: _status,
                      onSelected: _filter,
                      labelBuilder: (value) => switch (value.toUpperCase()) {
                        'PENDING' => 'Pending ($pendingCount)',
                        'CHANGES_REQUESTED' =>
                          'Needs Revision ($revisionCount)',
                        'APPROVED' => 'Approved ($approvedCount)',
                        _ => 'All (${allSketches.length})',
                      },
                    ),
                    const SizedBox(height: 16),

                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CommonProgressIndicator(
                          label: 'Loading live sketches...',
                        ),
                      )
                    else if (state is SketchError)
                      CommonEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Sketches unavailable',
                        description: state.message,
                        actionLabel: 'Retry',
                        onAction: () => _filter(_status),
                      )
                    else if (filteredSketches.isEmpty)
                      CommonEmptyState(
                        icon: Icons.draw_outlined,
                        title: _searchQuery.isNotEmpty
                            ? 'No matching sketches found'
                            : 'No sketches in this category',
                        description: _searchQuery.isNotEmpty
                            ? 'Try searching with a different design code or title.'
                            : 'There are currently no sketches matching this status filter.',
                        actionLabel: _searchQuery.isNotEmpty
                            ? 'Clear Search'
                            : 'Upload Sketch',
                        onAction: () {
                          if (_searchQuery.isNotEmpty) {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          } else {
                            _showUploadDialog(context);
                          }
                        },
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 960
                              ? 3
                              : constraints.maxWidth >= 620
                              ? 2
                              : 1;
                          final cardWidth =
                              (constraints.maxWidth - (16 * (columns - 1))) /
                              columns;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: filteredSketches
                                .map(
                                  (sketch) => SizedBox(
                                    width: cardWidth,
                                    child: _SketchCard(
                                      sketch: sketch,
                                      onReupload: () =>
                                          _reupload(context, sketch),
                                      onPreviewImage: () =>
                                          _showImagePreviewDialog(
                                            context,
                                            sketch,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static int _count(List<ApiSketch> values, String status) =>
      values.where((value) => value.status.toUpperCase() == status).length;

  Future<void> _reupload(BuildContext context, ApiSketch sketch) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (!context.mounted || file?.bytes == null) return;
    context.read<SketchBloc>().add(
      ReuploadRawSketchEvent(
        sketchId: sketch.id,
        title: sketch.title,
        fileName: file!.name,
        bytes: file.bytes!,
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, ApiSketch sketch) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _SketchImagePreviewDialog(sketch: sketch),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => const _UploadSketchDialog(),
    );
  }

  static String statusLabel(String status) => switch (status.toUpperCase()) {
    'PENDING' => 'Pending Review',
    'CHANGES_REQUESTED' => 'Needs Revision',
    'REJECTED' => 'Rejected',
    'APPROVED' => 'Approved',
    _ => status,
  };
}

class _SketchImagePreviewDialog extends StatelessWidget {
  const _SketchImagePreviewDialog({required this.sketch});

  final ApiSketch sketch;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.8).clamp(400.0, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 800,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 60, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          sketch.designNumber,
                          style: const TextStyle(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sketch.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Image Display Area
                Expanded(
                  child: Container(
                    color: AppColors.canvas,
                    width: double.infinity,
                    height: double.infinity,
                    child: sketch.sketchUrl.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: AppColors.muted,
                            ),
                          )
                        : InteractiveViewer(
                            clipBehavior: Clip.hardEdge,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: _PresignedSketchImage(
                                imageUrl: sketch.sketchUrl,
                                fit: BoxFit.contain,
                                loadingLabel: 'Loading full sketch image...',
                              ),
                            ),
                          ),
                  ),
                ),
                // Footer info
                if ((sketch.adminInstructions?.trim().isNotEmpty ?? false) ||
                    (sketch.feedbackAudioUrl?.trim().isNotEmpty ?? false) ||
                    (sketch.feedbackImageUrl?.trim().isNotEmpty ?? false))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sketch.status == 'CHANGES_REQUESTED'
                          ? AppColors.dangerLight
                          : AppColors.goldLight.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              sketch.status == 'CHANGES_REQUESTED'
                                  ? Icons.assignment_late_outlined
                                  : Icons.record_voice_over_outlined,
                              color: sketch.status == 'CHANGES_REQUESTED'
                                  ? AppColors.danger
                                  : AppColors.goldDark,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sketch.status == 'CHANGES_REQUESTED'
                                  ? 'Admin Revision Notes'
                                  : 'Admin Instructions',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: sketch.status == 'CHANGES_REQUESTED'
                                    ? AppColors.danger
                                    : AppColors.goldDark,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (sketch.adminInstructions?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            sketch.adminInstructions!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                        if (sketch.feedbackAudioUrl?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          DirectiveVoiceButton(
                            audioUrl: sketch.feedbackAudioUrl!.trim(),
                          ),
                        ],
                        if (sketch.feedbackImageUrl?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 10),
                          DirectiveImageAttachment(
                            imageUrl: sketch.feedbackImageUrl!.trim(),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: AppColors.paper,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.ink),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSketchDialog extends StatefulWidget {
  const _UploadSketchDialog();

  @override
  State<_UploadSketchDialog> createState() => _UploadSketchDialogState();
}

class _UploadSketchDialogState extends State<_UploadSketchDialog> {
  late final TextEditingController _designController;
  late final TextEditingController _titleController;
  String? _fileName;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _designController = TextEditingController();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _designController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.draw_rounded,
              color: AppColors.emerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload New Sketch',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Submit pencil sketch for admin review',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              CommonTextField(
                controller: _designController,
                label: 'Design Code / Number *',
                hintText: 'e.g. DSG-1042',
                prefixIcon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: 14),
              CommonTextField(
                controller: _titleController,
                label: 'Sketch Title *',
                hintText: 'e.g. Diamond Solitaire Ring - Pencil Draft',
                prefixIcon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),

              // Image Upload Selector / Preview Box
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    withData: true,
                  );
                  final file = result?.files.single;
                  if (file?.bytes == null) return;
                  setState(() {
                    _fileName = file!.name;
                    _bytes = file.bytes;
                  });
                },
                child: Container(
                  height: _bytes != null ? 160 : 120,
                  decoration: BoxDecoration(
                    color: _bytes != null
                        ? AppColors.canvas
                        : AppColors.emeraldLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _bytes != null
                          ? AppColors.emerald
                          : AppColors.outline,
                      width: _bytes != null ? 2 : 1.5,
                    ),
                  ),
                  child: _bytes != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _bytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.pureWhite,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    _fileName ?? 'Image Selected',
                                    style: const TextStyle(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap to change image',
                                  style: TextStyle(
                                    color: AppColors.sage,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppColors.emerald,
                              size: 36,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Select Sketch Image *',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Supports PNG, JPG, WEBP',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CommonButton.primary(
          isFullWidth: false,
          height: 40,
          label: 'Upload Sketch',
          icon: Icons.check_rounded,
          onPressed: () {
            final designNumber = _designController.text.trim();
            final title = _titleController.text.trim();
            if (designNumber.isEmpty ||
                title.isEmpty ||
                _fileName == null ||
                _bytes == null) {
              CommonSnackbar.error(
                context,
                title: 'Required Fields Missing',
                message: 'Design number, title and image are required.',
              );
              return;
            }
            context.read<SketchBloc>().add(
              UploadRawSketchEvent(
                designNumber: designNumber,
                title: title,
                fileName: _fileName!,
                bytes: _bytes!,
              ),
            );
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

String statusLabel(String status) => switch (status.toUpperCase()) {
  'PENDING' => 'Pending Review',
  'CHANGES_REQUESTED' => 'Needs Revision',
  'REJECTED' => 'Rejected',
  'APPROVED' => 'Approved',
  _ => status,
};

class _SketchCard extends StatelessWidget {
  const _SketchCard({
    required this.sketch,
    required this.onReupload,
    required this.onPreviewImage,
  });

  final ApiSketch sketch;
  final VoidCallback onReupload;
  final VoidCallback onPreviewImage;

  @override
  Widget build(BuildContext context) {
    final status = sketch.status.toUpperCase();
    final (statusColor, statusBg, statusIcon) = switch (status) {
      'APPROVED' => (
        AppColors.success,
        AppColors.successLight,
        Icons.check_circle_rounded,
      ),
      'CHANGES_REQUESTED' || 'REJECTED' => (
        AppColors.danger,
        AppColors.dangerLight,
        Icons.assignment_late_outlined,
      ),
      _ => (
        AppColors.warning,
        AppColors.warningLight,
        Icons.hourglass_top_rounded,
      ),
    };

    final hasAdminInstructions =
        sketch.adminInstructions?.trim().isNotEmpty ?? false;
    final hasFeedbackAudio =
        sketch.feedbackAudioUrl?.trim().isNotEmpty ?? false;
    final hasFeedbackImage =
        sketch.feedbackImageUrl?.trim().isNotEmpty ?? false;

    return CommonCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onPreviewImage,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Box Container
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: sketch.sketchUrl.isEmpty
                      ? Container(
                          color: AppColors.canvas,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.muted,
                              size: 32,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusLarge),
                          ),
                          child: _PresignedSketchImage(
                            imageUrl: sketch.sketchUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),

                // Floating Status Pill (Top Right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _RawDesignerDashboardPageState.statusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Version Tag (Bottom Left)
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'v${sketch.version}',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          sketch.designNumber,
                          style: const TextStyle(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.zoom_in_rounded,
                        size: 16,
                        color: AppColors.subtle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sketch.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),

                  // Admin Feedback / Revision Container
                  if (hasAdminInstructions ||
                      hasFeedbackAudio ||
                      hasFeedbackImage) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: status == 'CHANGES_REQUESTED'
                            ? AppColors.dangerLight
                            : AppColors.goldLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status == 'CHANGES_REQUESTED'
                              ? AppColors.danger.withValues(alpha: 0.3)
                              : AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                status == 'CHANGES_REQUESTED'
                                    ? Icons.report_problem_outlined
                                    : Icons.record_voice_over_outlined,
                                color: status == 'CHANGES_REQUESTED'
                                    ? AppColors.danger
                                    : AppColors.goldDark,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status == 'CHANGES_REQUESTED'
                                    ? 'ADMIN REVISION NOTES'
                                    : 'ADMIN INSTRUCTIONS',
                                style: TextStyle(
                                  color: status == 'CHANGES_REQUESTED'
                                      ? AppColors.danger
                                      : AppColors.goldDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          if (hasAdminInstructions) ...[
                            const SizedBox(height: 4),
                            Text(
                              sketch.adminInstructions!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                          if (hasFeedbackAudio) ...[
                            const SizedBox(height: 8),
                            DirectiveVoiceButton(
                              audioUrl: sketch.feedbackAudioUrl!.trim(),
                            ),
                          ],
                          if (hasFeedbackImage) ...[
                            const SizedBox(height: 8),
                            DirectiveImageAttachment(
                              imageUrl: sketch.feedbackImageUrl!.trim(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Action for Needs Revision
                  if (status == 'CHANGES_REQUESTED') ...[
                    const SizedBox(height: 12),
                    CommonButton.tonal(
                      height: 38,
                      label: 'Upload Revision',
                      icon: Icons.replay_rounded,
                      onPressed: onReupload,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresignedSketchImage extends StatefulWidget {
  const _PresignedSketchImage({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.loadingLabel,
  });

  final String imageUrl;
  final BoxFit fit;
  final String? loadingLabel;

  @override
  State<_PresignedSketchImage> createState() => _PresignedSketchImageState();
}

class _PresignedSketchImageState extends State<_PresignedSketchImage> {
  static final Map<String, String> _urlCache = {};
  String? _resolvedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void didUpdateWidget(_PresignedSketchImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    if (_urlCache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _resolvedUrl = _urlCache[url];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      String resolvedUrl;
      if (url.contains('X-Amz-Algorithm')) {
        resolvedUrl = url;
      } else if (!uri.hasScheme && url.startsWith('/api/')) {
        resolvedUrl = Uri.parse(ApiEndpoints.baseUrl).resolve(url).toString();
      } else if (!uri.hasScheme || url.contains('amazonaws.com')) {
        final fileKey = uri.hasScheme
            ? uri.path.replaceFirst(RegExp(r'^/+'), '')
            : url.replaceFirst(RegExp(r'^/+'), '');
        final api = KaratFlowApiRepository();
        final signed = await api.getPresignedDownloadUrl(fileKey);
        if (signed.downloadUrl.isEmpty) {
          throw const FormatException('Storage API returned no download URL.');
        }
        resolvedUrl = signed.downloadUrl;
      } else {
        resolvedUrl = url;
      }
      _urlCache[url] = resolvedUrl;
      if (mounted) {
        setState(() {
          _resolvedUrl = resolvedUrl;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedUrl = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CommonProgressIndicator(
          label: widget.loadingLabel ?? 'Loading...',
        ),
      );
    }

    if (_hasError) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.danger,
          size: 32,
        ),
      );
    }

    final targetUrl = _resolvedUrl ?? widget.imageUrl;

    return Image.network(
      targetUrl,
      fit: widget.fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: AppColors.emerald,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.danger,
            size: 32,
          ),
        );
      },
    );
  }
}
