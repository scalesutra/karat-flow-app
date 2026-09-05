import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/common_button.dart';
import '../../../domain/models.dart';
import '../services/cad_tag_printer_service.dart';

class CadTagPrintDialog extends StatelessWidget {
  const CadTagPrintDialog({
    super.key,
    required this.task,
    this.storeName = 'RK JEWELLERS',
  });

  final CadDesignTask task;
  final String storeName;

  static Future<void> show(
    BuildContext context, {
    required CadDesignTask task,
    String storeName = 'RK JEWELLERS',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CadTagPrintDialog(task: task, storeName: storeName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = (now.hour % 12 == 0 ? 12 : now.hour % 12)
        .toString()
        .padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final dateStr = '$day/$month/$year $hour:$min $ampm';

    final code = task.designCode.trim().isNotEmpty
        ? task.designCode.trim()
        : (task.id.length > 8 ? task.id.substring(0, 8) : task.id);

    final title = task.productTitle.trim().isNotEmpty &&
            task.productTitle.trim().toLowerCase() != code.toLowerCase()
        ? task.productTitle.trim()
        : '3D CAD Model';

    final goldVal = task.goldQuantity > 0
        ? task.goldQuantity
        : task.estimatedWeightGrams;
    final goldStr =
        goldVal > 0 ? '${goldVal.toStringAsFixed(2)} g' : 'Pending Wt';

    final gemCount = task.gemQuantity;
    final gemTw = task.gemWeightTw;
    final gemStr = gemCount > 0
        ? '$gemCount Pcs' + (gemTw > 0 ? ' (${gemTw.toStringAsFixed(2)} Tw)' : '')
        : 'Plain Metal';

    final isWorkflowNote = task.sizeDimensions.toLowerCase().contains('sketch') ||
        task.sizeDimensions.toLowerCase().contains('wax') ||
        task.sizeDimensions.toLowerCase().contains('pending') ||
        task.sizeDimensions.toLowerCase().contains('modeling');
    final cleanSize = !isWorkflowNote && task.sizeDimensions.trim().isNotEmpty
        ? task.sizeDimensions.trim()
        : '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: AppColors.emerald,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zebra Production Tag',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thermal barcode sticker for Wax/Casting tray',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.outlineLight),

            // Tag Visual Preview
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      const Text(
                        '✦ ATELIER WAX & CAD ✦',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storeName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'ZEBRA PRODUCTION TAG',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(color: Colors.black, height: 1, thickness: 1),
                      const SizedBox(height: 8),

                      // Design Code (Big)
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Barcode Simulation
                      _buildBarcodeWidget(code),
                      const SizedBox(height: 3),
                      Text(
                        '*$code*',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(color: Colors.black54, height: 1, thickness: 1),
                      const SizedBox(height: 8),

                      // Spec Grid (Overflow-safe)
                      _specRow('EST. GOLD :', goldStr),
                      const SizedBox(height: 3),
                      _specRow('GEMSTONES :', gemStr),
                      if (cleanSize.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _specRow('SIZE / DIM :', cleanSize),
                      ],
                      const SizedBox(height: 3),
                      _specRow('DISPATCH  :', 'WAX PRINT & CASTING'),
                      const SizedBox(height: 3),
                      _specRow('PRINT DATE:', dateStr, isMuted: true),

                      const SizedBox(height: 10),
                      const Divider(color: Colors.black, height: 1, thickness: 1),
                      const SizedBox(height: 6),

                      const Text(
                        'SCAN FOR WORKSHOP DISPATCH',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.outlineLight),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: CommonButton.outlined(
                      height: 42,
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CommonButton.primary(
                      height: 42,
                      icon: Icons.print_rounded,
                      label: 'Print Zebra Tag',
                      onPressed: () {
                        Navigator.pop(context);
                        CadTagPrinterService.printJewelryTag(
                          task: task,
                          storeName: storeName,
                        );

                        final messenger = ScaffoldMessenger.of(context);
                        if (messenger.mounted) {
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: AppColors.emeraldDark,
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Printing Zebra tag for $code ($title)...',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specRow(String label, String value, {bool isMuted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isMuted ? Colors.black54 : Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isMuted ? FontWeight.w500 : FontWeight.w800,
              color: Colors.black,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeWidget(String text) {
    // Generate clean bar sequence
    final bars = <double>[
      2, 4, 1.5, 3, 1, 4, 2, 1.5, 3.5, 1.5, 4, 2, 1, 3, 2, 4, 1.5, 3, 1, 4, 2, 1.5, 3, 2, 4, 1.5, 3, 1, 4, 2, 1.5, 3, 2
    ];

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: bars
            .map(
              (w) => Container(
                width: w,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: Colors.black,
              ),
            )
            .toList(),
      ),
    );
  }
}
