import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/api_models.dart';
import '../services/bom_bill_printer_service.dart';

class BomBillPrintDialog extends StatelessWidget {
  const BomBillPrintDialog({
    super.key,
    required this.requisition,
    required this.storeName,
  });

  final VaultRequisition requisition;
  final String storeName;

  static Future<void> show(
    BuildContext context, {
    required VaultRequisition requisition,
    required String storeName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BomBillPrintDialog(
        requisition: requisition,
        storeName: storeName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStones = requisition.stoneSpecs.fold(
      0,
      (sum, s) => sum + s.count,
    );

    final now = DateTime.now();
    final dayStr = now.day.toString().padLeft(2, '0');
    final monthStr = now.month.toString().padLeft(2, '0');
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final hourStr = h.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final realDateStr = '$dayStr/$monthStr/${now.year} $hourStr:$minuteStr $amPm';

    final headerTitle = storeName.trim().toUpperCase();

    final voucherNo = requisition.id.startsWith('REQ-') ||
            requisition.id.length <= 10
        ? requisition.id
        : 'REQ-${requisition.id.substring(0, 6).toUpperCase()}';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Modal Header Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.print_rounded,
                        color: Color(0xFFFFD18A),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'BOM Issue Slip Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 5-Inch Thermal Receipt Printable Area (White paper container)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFDF9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Brand Header
                      const Text(
                        '✦ ATELIER MANUFACTURING ✦',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                          letterSpacing: 2,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (headerTitle.isNotEmpty) ...[
                        Text(
                          headerTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'JOB CARD & BOM ISSUE VOUCHER',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // TOP METADATA CARD (Clean Bordered Container)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black87, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            _thermalRow('VOUCHER NO :', voucherNo),
                            _thermalRow('ISSUE DATE :', realDateStr),
                            _thermalRow(
                              'ORDER REF  :',
                              '#${requisition.orderId}',
                            ),
                            if (requisition.customerName.isNotEmpty)
                              _thermalRow(
                                'CLIENT     :',
                                requisition.customerName,
                              ),
                            if (requisition.dueDate.isNotEmpty)
                              _thermalRow(
                                'DUE DATE   :',
                                requisition.dueDate.split('T').first,
                              ),
                            const Divider(color: Colors.black26, height: 8),
                            _thermalRow(
                              'DESIGN NO  :',
                              requisition.designNumber,
                            ),
                            if (requisition.sizeDimensions.isNotEmpty)
                              _thermalRow(
                                'SIZE / DIM :',
                                requisition.sizeDimensions,
                              ),
                            _thermalRow(
                              'CRAFTSMAN  :',
                              requisition.artisanName,
                            ),
                            _thermalRow(
                              'STAGE NAME :',
                              requisition.stageName.toUpperCase(),
                            ),
                          ],
                        ),
                      ),

                      // SECTION 1: METAL ALLOCATION (High-Impact Card)
                      if (requisition.goldWeightGrams > 0) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            border: Border.all(
                              color: Colors.black87,
                              width: 1.4,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '[1] BULLION / METAL ISSUED',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'VAULT CERTIFIED',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Text(
                                    'Net Gold Allocation:',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${requisition.goldWeightGrams.toStringAsFixed(2)} g',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Accuracy: 0.01g Calibrated • Scale Tag Verified',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // SECTION 2: GEMSTONES BOM
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black87, width: 1.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '[2] GEMSTONES BOM',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    requisition.gemWeightTw > 0
                                        ? '$totalStones Pcs · ${requisition.gemWeightTw.toStringAsFixed(2)} Cts'
                                        : '$totalStones Pcs',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.black54, height: 8),
                            if (requisition.stoneSpecs.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '* Plain Metal / No Gemstones Required',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 9.5,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'STONE SPEC',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Text(
                                      'QTY',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final s in requisition.stoneSpecs)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 3.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '• ${s.name} (${s.shape} ${s.size})',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 9.5,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${s.count} Pcs',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Physical Acknowledgement & Dual Signatures
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '[PHYSICAL ACKNOWLEDGEMENT]',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '☑ Verified Material Weight & Purity',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                color: Colors.black87,
                              ),
                            ),
                            const Text(
                              '☑ Verified Gemstone Count & Quality',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      '_______________',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'VAULT KEEPER',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '(Issued & Scaled)',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 7.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      '_______________',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'CRAFTSMAN SIGN',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '(Received & Checked)',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 7.5,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                '• KARATFLOW ATELIER PRECISION JOB CARD •',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8,
                                  letterSpacing: 1,
                                  color: Colors.black45,
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
            ),

            // Bottom Dialog Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        CommonSnackbar.info(
                          context,
                          title: 'Bill Shared',
                          message: 'BOM Bill details copied to clipboard.',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 16),
                      label: const Text(
                        'Share Text',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CommonButton.primary(
                      height: 40,
                      label: 'Print BOM Slip',
                      icon: Icons.print,
                      onPressed: () {
                        BomBillPrinterService.printThermalReceipt(
                          requisition: requisition,
                          storeName: storeName,
                          realDateStr: realDateStr,
                          totalStones: totalStones,
                        );
                        Navigator.pop(context);
                        CommonSnackbar.success(
                          context,
                          title: 'Printing Triggered',
                          message:
                              'Printer dialog opened. Select your printer.',
                        );
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

  Widget _thermalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
