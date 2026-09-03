import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/common_3d_viewer.dart';
import '../../../../core/widgets/common_button.dart';
import '../../../../core/widgets/common_card.dart';
import '../../../../data/demo_store.dart';
import '../bloc/cad_bloc.dart';

/// Modular CAD Designer Task Card
class CadTaskCard extends StatelessWidget {
  const CadTaskCard({
    super.key,
    required this.task,
    required this.store,
    required this.onStatusChanged,
  });

  final CadDesignTask task;
  final DemoStore store;
  final VoidCallback onStatusChanged;

  Color get _statusColor => switch (task.status) {
    CadTaskStatus.newTask => AppColors.gold,
    CadTaskStatus.inProgress => AppColors.info,
    CadTaskStatus.completed => AppColors.success,
    CadTaskStatus.revision => AppColors.danger,
  };

  String get _statusLabel => task.status.label;

  void _showDualFileUploadModal(BuildContext context) {
    PlatformFile? stlFile;
    PlatformFile? blockFile;
    String? stlFileName;
    String? blockFileName;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Design & Block Files',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${task.productTitle} (${task.designCode})',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. STL 3D File Picker Card
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stlFileName != null
                            ? AppColors.emeraldLight
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.view_in_ar,
                        color: stlFileName != null
                            ? AppColors.emerald
                            : AppColors.muted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. 3D Model File (.STL / .OBJ)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stlFileName ??
                                'Required for 3D slicing & visualizer',
                            style: TextStyle(
                              color: stlFileName != null
                                  ? AppColors.emeraldDark
                                  : AppColors.muted,
                              fontSize: 11,
                              fontWeight: stlFileName != null
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CommonButton.outlined(
                      isFullWidth: false,
                      height: 32,
                      label: stlFileName != null ? 'Change' : 'Pick STL',
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            // Android does not consistently expose MIME types
                            // for CAD formats, so validate the extension after
                            // selection instead of using FileType.custom.
                            type: FileType.any,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final selected = result.files.first;
                            final lowerName = selected.name.toLowerCase();
                            final isImage =
                                lowerName.endsWith('.png') ||
                                lowerName.endsWith('.jpg') ||
                                lowerName.endsWith('.jpeg') ||
                                lowerName.endsWith('.webp');
                            setModalState(() {
                              stlFile = selected;
                              stlFileName = isImage
                                  ? '${stlFile!.name} (Image - recommend .stl)'
                                  : stlFile!.name;
                            });
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not select STL: $error'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. CAD Render / Gem Reporter Screenshot (bomFileUrl for PaddleOCR)
              CommonCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: blockFileName != null
                            ? AppColors.emeraldLight
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: blockFileName != null
                            ? AppColors.emerald
                            : AppColors.muted,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '2. CAD Render & Gem Reporter Image',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            blockFileName ??
                                'MatrixGold Gem Reporter screenshot (.png/.jpg) for PaddleOCR',
                            style: TextStyle(
                              color: blockFileName != null
                                  ? AppColors.emeraldDark
                                  : AppColors.muted,
                              fontSize: 11,
                              fontWeight: blockFileName != null
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CommonButton.outlined(
                      isFullWidth: false,
                      height: 32,
                      label: blockFileName != null ? 'Change' : 'Pick Image',
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final selected = result.files.first;
                            setModalState(() {
                              blockFile = selected;
                              blockFileName = blockFile!.name;
                            });
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not select Image: $error'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  height: 42,
                  icon: Icons.cloud_upload_outlined,
                  label: 'Upload CAD Files & Submit Design',
                  onPressed: stlFile == null || blockFile == null
                      ? null
                      : () {
                          final selectedStl = stlFile!;
                          final selectedBlock = blockFile!;
                          final stlBytes = _readBytes(selectedStl);
                          final blockBytes = _readBytes(selectedBlock);
                          final cadBloc = context.read<CadBloc>();

                          Navigator.pop(ctx);
                          cadBloc.add(
                            UploadCadFilesEvent(
                              taskId: task.id,
                              volumeCubicMm: 0.0,
                              specsNote: task.specs.isNotEmpty
                                  ? task.specs
                                  : 'CAD 3D Mesh',
                              stlFileName: selectedStl.name,
                              stlBytes: stlBytes,
                              bomFileName: selectedBlock.name,
                              bomBytes: blockBytes,
                              isRevision: false,
                              goldQuantity: task.estimatedWeightGrams > 0
                                  ? task.estimatedWeightGrams
                                  : 0.0,
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Uint8List _readBytes(PlatformFile file) {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }
    if (file.path != null && file.path!.isNotEmpty) {
      try {
        final f = File(file.path!);
        if (f.existsSync()) {
          return f.readAsBytesSync();
        }
      } catch (_) {}
    }
    return Uint8List.fromList([0, 1, 2, 3]);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetailSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.productTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                _statusBadge(_statusLabel, _statusColor),
              ],
            ),

            const SizedBox(height: 6),

            // Order + Client
            Text(
              '${task.orderId} · ${task.designCode} · ${task.clientName}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.ink,
              ),
            ),

            const SizedBox(height: 3),

            // Specs
            Text(
              task.specs,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),

            const SizedBox(height: 2),

            // Weight
            Text(
              'Est. weight: ${task.estimatedWeightGrams} g',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),

            const SizedBox(height: 8),

            // Indicators row
            Row(
              children: [
                if (task.hasVoiceNote) ...[
                  _indicatorChip(
                    icon: Icons.volume_up,
                    label: 'Voice note',
                    color: AppColors.goldDark,
                    bgColor: AppColors.goldLight,
                    borderColor: AppColors.gold.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                ],
                if (task.hasSketchImage) ...[
                  _indicatorChip(
                    icon: Icons.image_outlined,
                    label: 'Sketch',
                    color: AppColors.emeraldDark,
                    bgColor: AppColors.emeraldLight,
                    borderColor: AppColors.sage,
                  ),
                  const SizedBox(width: 6),
                ],
                if (task.hasStlFile) ...[
                  _indicatorChip(
                    icon: Icons.view_in_ar,
                    label: 'STL uploaded',
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                    borderColor: AppColors.success.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                ],
                if (task.volumeCubicMm != null)
                  _indicatorChip(
                    icon: Icons.calculate_outlined,
                    label: '${task.volumeCubicMm!.toStringAsFixed(1)} mm³',
                    color: AppColors.info,
                    bgColor: AppColors.infoLight,
                    borderColor: AppColors.info.withValues(alpha: 0.3),
                  ),
              ],
            ),

            // Revision Alert Banner
            if (task.status == CadTaskStatus.revision &&
                task.revisionNotes != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Revision: ${task.revisionNotes}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (task.status == CadTaskStatus.newTask) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  height: 38,
                  icon: Icons.play_arrow_rounded,
                  label: 'Start 3D Modeling',
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    context.read<CadBloc>().add(
                      UpdateCadTaskStatusEvent(
                        taskId: task.id,
                        status: CadTaskStatus.inProgress,
                      ),
                    );
                    if (messenger.mounted) {
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.ink,
                          content: Text(
                            '3D modeling started for ${task.productTitle}.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.pureWhite,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],

            if (task.status == CadTaskStatus.inProgress &&
                !task.hasStlFile) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  height: 38,
                  backgroundColor: AppColors.emerald,
                  icon: Icons.upload_file,
                  label: 'Upload STL + Block File',
                  onPressed: () => _showDualFileUploadModal(context),
                ),
              ),
            ],

            if (task.hasStlFile || task.status == CadTaskStatus.completed) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CommonButton.primary(
                      height: 38,
                      backgroundColor: AppColors.emerald,
                      icon: Icons.view_in_ar,
                      label: 'View 3D Model',
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => Common3DViewer(
                            designCode: task.designCode,
                            productTitle: task.productTitle,
                            modelUrl: task.modelFileUrl,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CommonButton.outlined(
                    isFullWidth: false,
                    height: 38,
                    icon: Icons.replay_rounded,
                    label: 'Re-upload',
                    onPressed: () => _showDualFileUploadModal(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.productTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${task.orderId} · ${task.clientName}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(_statusLabel, _statusColor),
              ],
            ),

            const SizedBox(height: 16),

            // Revision Notes details
            if (task.status == CadTaskStatus.revision &&
                task.revisionNotes != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          color: AppColors.danger,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'PRODUCT MANAGER FEEDBACK',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.revisionNotes!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                    if (task.hasRevisionVoice) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          if (messenger.mounted) {
                            messenger.clearSnackBars();
                            messenger.showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.danger,
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.volume_up,
                                      color: AppColors.pureWhite,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Playing PM Voice note: "${task.revisionNotes}"',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.pureWhite,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_circle_fill,
                                color: AppColors.danger,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 16,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Audio revision attached',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Design spec card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESIGN SPECIFICATIONS',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Design Code: ${task.designCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '• ${task.specs}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '• Estimated Weight: ${task.estimatedWeightGrams} g',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (task.volumeCubicMm != null)
                    Text(
                      '• Mesh volume: ${task.volumeCubicMm!.toStringAsFixed(1)} mm³',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Notes card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESIGNER NOTES',
                    style: TextStyle(
                      color: AppColors.goldDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.notes,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Change Status
            const Text(
              'Change Status:',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CadTaskStatus.values
                  .where((st) => st != CadTaskStatus.revision)
                  .map((st) {
                    final isCurrent = task.status == st;
                    return InkWell(
                      onTap: () {
                        final messenger = ScaffoldMessenger.of(context);
                        context.read<CadBloc>().add(
                          UpdateCadTaskStatusEvent(taskId: task.id, status: st),
                        );
                        Navigator.pop(ctx);
                        if (messenger.mounted) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: AppColors.emerald,
                              content: Text(
                                '${task.productTitle} → ${st.label}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.pureWhite,
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.emeraldLight
                              : AppColors.canvas,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.emerald
                                : AppColors.outline,
                          ),
                        ),
                        child: Text(
                          st.label,
                          style: TextStyle(
                            color: isCurrent
                                ? AppColors.emeraldDark
                                : AppColors.ink,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),

            if (task.hasStlFile) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CommonButton.primary(
                  height: 40,
                  backgroundColor: AppColors.emerald,
                  icon: Icons.view_in_ar,
                  label: 'View 3D Model Design',
                  onPressed: () {
                    Navigator.pop(ctx);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Common3DViewer(
                        designCode: task.designCode,
                        productTitle: task.productTitle,
                        modelUrl: task.modelFileUrl,
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CommonButton.outlined(
                    height: 40,
                    icon: Icons.upload_file,
                    label: task.hasStlFile
                        ? 'Re-upload STL + Block'
                        : 'Upload STL + Block File',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDualFileUploadModal(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CommonButton.primary(
                    height: 40,
                    icon: Icons.print,
                    label: 'Print Tag',
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      if (messenger.mounted) {
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: AppColors.ink,
                            content: Text(
                              'Printed Zebra tag for ${task.id} · ${task.designCode}.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _indicatorChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
