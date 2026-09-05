import 'package:flutter/foundation.dart';
import '../../../domain/models.dart';
import '../../stockist/services/bom_bill_printer_stub.dart'
    if (dart.library.html) '../../stockist/services/bom_bill_printer_web.dart'
    as printer_impl;

class CadTagPrinterService {
  static void printJewelryTag({
    required CadDesignTask task,
    String storeName = 'RK JEWELLERS',
  }) {
    if (!kIsWeb) return;

    try {
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
          : task.id.substring(0, task.id.length > 8 ? 8 : task.id.length);

      final title = task.productTitle.trim().isNotEmpty &&
              task.productTitle.trim().toLowerCase() != code.toLowerCase()
          ? task.productTitle.trim()
          : '3D CAD Model';

      final goldVal = task.goldQuantity > 0
          ? task.goldQuantity
          : task.estimatedWeightGrams;
      final goldStr =
          goldVal > 0 ? '${goldVal.toStringAsFixed(2)} g' : 'Pending';

      final gemCount = task.gemQuantity;
      final gemTw = task.gemWeightTw;
      final gemStr = gemCount > 0
          ? '$gemCount Pcs' + (gemTw > 0 ? ' (${gemTw.toStringAsFixed(2)} Tw)' : '')
          : 'Plain Metal';

      final isWorkflowNote = task.sizeDimensions.toLowerCase().contains('sketch') ||
          task.sizeDimensions.toLowerCase().contains('wax') ||
          task.sizeDimensions.toLowerCase().contains('pending') ||
          task.sizeDimensions.toLowerCase().contains('modeling');
      final sizeStr = !isWorkflowNote && task.sizeDimensions.trim().isNotEmpty
          ? task.sizeDimensions.trim()
          : '';

      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <title>Zebra Tag - $code</title>
  <style>
    @page {
      size: 60mm auto;
      margin: 1.5mm;
    }
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      font-size: 10px;
      width: 56mm;
      margin: 0 auto;
      color: #000;
      background: #fff;
      padding: 4px;
      line-height: 1.3;
    }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
    .tag-box {
      border: 1.5px solid #000;
      border-radius: 4px;
      padding: 6px;
      background: #fff;
    }
    .flex {
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      margin-bottom: 2px;
    }
    .flex span:last-child {
      max-width: 65%;
      text-align: right;
      word-break: break-word;
    }
    .badge {
      display: inline-block;
      background: #000;
      color: #fff;
      font-size: 8px;
      font-weight: 800;
      letter-spacing: 0.5px;
      padding: 1px 4px;
      border-radius: 2px;
    }
    .barcode-svg {
      display: block;
      margin: 4px auto 1px auto;
      max-width: 100%;
    }
  </style>
</head>
<body>
  <div class="tag-box">
    <!-- HEADER -->
    <div class="center" style="border-bottom: 1px solid #000; padding-bottom: 3px; margin-bottom: 4px;">
      <div style="font-size: 8px; letter-spacing: 1.5px; font-weight: 800;">✦ ATELIER WAX & CAD ✦</div>
      <div class="bold" style="font-size: 13px; letter-spacing: 0.5px;">$storeName</div>
      <div class="badge" style="margin-top: 1px;">ZEBRA PRODUCTION TAG</div>
    </div>

    <!-- CODE & TITLE -->
    <div class="center" style="margin: 4px 0 2px 0;">
      <div class="mono bold" style="font-size: 17px; letter-spacing: 1px;">$code</div>
      <div class="bold" style="font-size: 11px; color: #222; margin-top: 1px;">$title</div>
    </div>

    <!-- BARCODE SIMULATION -->
    <div class="center mono" style="margin: 4px 0 3px 0;">
      <svg class="barcode-svg" width="160" height="28" viewBox="0 0 160 28" xmlns="http://www.w3.org/2000/svg">
        <rect x="0" y="0" width="160" height="28" fill="#fff" />
        <rect x="6" y="2" width="2" height="24" fill="#000" />
        <rect x="10" y="2" width="4" height="24" fill="#000" />
        <rect x="16" y="2" width="1.5" height="24" fill="#000" />
        <rect x="20" y="2" width="3" height="24" fill="#000" />
        <rect x="25" y="2" width="1" height="24" fill="#000" />
        <rect x="28" y="2" width="4" height="24" fill="#000" />
        <rect x="34" y="2" width="2" height="24" fill="#000" />
        <rect x="38" y="2" width="1.5" height="24" fill="#000" />
        <rect x="42" y="2" width="3.5" height="24" fill="#000" />
        <rect x="48" y="2" width="1.5" height="24" fill="#000" />
        <rect x="52" y="2" width="4" height="24" fill="#000" />
        <rect x="58" y="2" width="2" height="24" fill="#000" />
        <rect x="62" y="2" width="1" height="24" fill="#000" />
        <rect x="65" y="2" width="3" height="24" fill="#000" />
        <rect x="70" y="2" width="2" height="24" fill="#000" />
        <rect x="74" y="2" width="4" height="24" fill="#000" />
        <rect x="80" y="2" width="1.5" height="24" fill="#000" />
        <rect x="84" y="2" width="3" height="24" fill="#000" />
        <rect x="89" y="2" width="1" height="24" fill="#000" />
        <rect x="92" y="2" width="4" height="24" fill="#000" />
        <rect x="98" y="2" width="2" height="24" fill="#000" />
        <rect x="102" y="2" width="1.5" height="24" fill="#000" />
        <rect x="106" y="2" width="3" height="24" fill="#000" />
        <rect x="111" y="2" width="2" height="24" fill="#000" />
        <rect x="115" y="2" width="4" height="24" fill="#000" />
        <rect x="121" y="2" width="1.5" height="24" fill="#000" />
        <rect x="125" y="2" width="3" height="24" fill="#000" />
        <rect x="130" y="2" width="1" height="24" fill="#000" />
        <rect x="133" y="2" width="4" height="24" fill="#000" />
        <rect x="139" y="2" width="2" height="24" fill="#000" />
        <rect x="143" y="2" width="1.5" height="24" fill="#000" />
        <rect x="147" y="2" width="3" height="24" fill="#000" />
        <rect x="152" y="2" width="2" height="24" fill="#000" />
      </svg>
      <div style="font-size: 9px; letter-spacing: 2px;">*$code*</div>
    </div>

    <!-- SPECS TABLE -->
    <div style="border-top: 1px dashed #000; border-bottom: 1px dashed #000; padding: 4px 0; margin: 3px 0; font-size: 9.5px;">
      <div class="flex"><span>EST. GOLD :</span><span class="bold">$goldStr</span></div>
      <div class="flex"><span>GEMSTONES :</span><span class="bold">$gemStr</span></div>
      ${sizeStr.isNotEmpty ? '<div class="flex"><span>SIZE / DIM :</span><span class="bold">$sizeStr</span></div>' : ''}
      <div class="flex"><span>DISPATCH  :</span><span class="bold">WAX PRINT & CASTING</span></div>
      <div class="flex"><span>PRINT DATE:</span><span style="font-size: 8.5px;">$dateStr</span></div>
    </div>

    <!-- FOOTER -->
    <div class="center" style="font-size: 7.5px; color: #444; margin-top: 3px;">
      SCAN FOR WORKSHOP DISPATCH
    </div>
  </div>

  <script>
    window.addEventListener('load', function() {
      setTimeout(function() {
        window.focus();
        window.print();
      }, 200);
    });
  </script>
</body>
</html>
''';

      printer_impl.printHtmlDocument(htmlContent);
    } catch (_) {}
  }
}
