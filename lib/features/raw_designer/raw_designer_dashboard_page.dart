import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/api_models.dart';
import 'bloc/sketch_bloc.dart';

class RawDesignerDashboardPage extends StatefulWidget {
  const RawDesignerDashboardPage({super.key});

  @override
  State<RawDesignerDashboardPage> createState() =>
      _RawDesignerDashboardPageState();
}

class _RawDesignerDashboardPageState extends State<RawDesignerDashboardPage> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    context.read<SketchBloc>().add(const FetchSketchesEvent());
  }

  void _filter(String value) {
    setState(() => _status = value);
    context.read<SketchBloc>().add(FetchSketchesEvent(status: value));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SketchBloc, SketchState>(
      builder: (context, state) {
        final sketches = state is SketchLoaded
            ? state.sketches
            : const <ApiSketch>[];
        final loading = state is SketchLoading || state is SketchInitial;
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
                          'Create, revise and track pencil sketches from the live design workflow.',
                      icon: Icons.draw_outlined,
                      action: CommonButton.primary(
                        isFullWidth: false,
                        label: 'Upload Sketch',
                        icon: Icons.upload_file_outlined,
                        onPressed: () => _showUploadDialog(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ResponsiveMetricGrid(
                      metrics: [
                        DashboardMetric(
                          value: '${sketches.length}',
                          label: 'Visible sketches',
                          icon: Icons.collections_outlined,
                          color: AppColors.emerald,
                        ),
                        DashboardMetric(
                          value: '${_count(sketches, 'PENDING')}',
                          label: 'Awaiting review',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                        ),
                        DashboardMetric(
                          value: '${_count(sketches, 'REJECTED')}',
                          label: 'Needs revision',
                          icon: Icons.replay_rounded,
                          color: AppColors.danger,
                        ),
                        DashboardMetric(
                          value: '${_count(sketches, 'APPROVED')}',
                          label: 'Approved',
                          icon: Icons.verified_outlined,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CommonFilterChips<String>(
                      padding: EdgeInsets.zero,
                      options: const ['', 'PENDING', 'REJECTED', 'APPROVED'],
                      selected: _status,
                      onSelected: _filter,
                      labelBuilder: (value) =>
                          value.isEmpty ? 'All' : _statusLabel(value),
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
                    else if (sketches.isEmpty)
                      CommonEmptyState(
                        icon: Icons.draw_outlined,
                        title: 'No sketches found',
                        description:
                            'The live API returned no sketches for this filter.',
                        actionLabel: 'Upload Sketch',
                        onAction: () => _showUploadDialog(context),
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
                              (constraints.maxWidth - (12 * (columns - 1))) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: sketches
                                .map(
                                  (sketch) => SizedBox(
                                    width: cardWidth,
                                    child: _SketchCard(
                                      sketch: sketch,
                                      onReupload: () =>
                                          _reupload(context, sketch),
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

  void _showUploadDialog(BuildContext context) {
    final designController = TextEditingController();
    final titleController = TextEditingController();
    String? fileName;
    Uint8List? bytes;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          title: const Text('Upload New Sketch'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommonTextField(
                  controller: designController,
                  label: 'Design Number *',
                  hintText: 'Enter the assigned design number',
                ),
                const SizedBox(height: 12),
                CommonTextField(
                  controller: titleController,
                  label: 'Sketch Title *',
                  hintText: 'Enter a clear sketch title',
                ),
                const SizedBox(height: 12),
                CommonButton.outlined(
                  label: fileName ?? 'Select Image *',
                  icon: Icons.image_outlined,
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      withData: true,
                    );
                    final file = result?.files.single;
                    if (file?.bytes == null) return;
                    setDialogState(() {
                      fileName = file!.name;
                      bytes = file.bytes;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final designNumber = designController.text.trim();
                final title = titleController.text.trim();
                if (designNumber.isEmpty ||
                    title.isEmpty ||
                    fileName == null ||
                    bytes == null) {
                  CommonSnackbar.error(
                    context,
                    title: 'Required information',
                    message: 'Design number, title and image are required.',
                  );
                  return;
                }
                context.read<SketchBloc>().add(
                  UploadRawSketchEvent(
                    designNumber: designNumber,
                    title: title,
                    fileName: fileName!,
                    bytes: bytes!,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      designController.dispose();
      titleController.dispose();
    });
  }

  static String _statusLabel(String status) => switch (status.toUpperCase()) {
    'PENDING' => 'Pending',
    'REJECTED' => 'Needs Revision',
    'APPROVED' => 'Approved',
    _ => status,
  };
}

class _SketchCard extends StatelessWidget {
  const _SketchCard({required this.sketch, required this.onReupload});

  final ApiSketch sketch;
  final VoidCallback onReupload;

  @override
  Widget build(BuildContext context) {
    final status = sketch.status.toUpperCase();
    final color = switch (status) {
      'APPROVED' => AppColors.success,
      'REJECTED' => AppColors.danger,
      _ => AppColors.warning,
    };
    return CommonCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: sketch.sketchUrl.isEmpty
                ? const Center(child: Icon(Icons.image_not_supported_outlined))
                : ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusLarge),
                    ),
                    child: Image.network(
                      sketch.sketchUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sketch.designNumber,
                        style: const TextStyle(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _RawDesignerDashboardPageState._statusLabel(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  sketch.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Version ${sketch.version}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                if (sketch.adminInstructions?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  Text(
                    sketch.adminInstructions!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                if (status == 'REJECTED') ...[
                  const SizedBox(height: 12),
                  CommonButton.tonal(
                    height: 40,
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
    );
  }
}
