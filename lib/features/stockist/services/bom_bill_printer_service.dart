import 'package:flutter/foundation.dart';

import '../../../data/models/api_models.dart';
import 'bom_bill_printer_stub.dart'
    if (dart.library.html) 'bom_bill_printer_web.dart' as printer_impl;

class BomBillPrinterService {
  static void printThermalReceipt({
    required VaultRequisition requisition,
    required String storeName,
    required String realDateStr,
    required int totalStones,
  }) {
    if (!kIsWeb) return;

    try {
      final voucherNo = requisition.id.startsWith('REQ-') ||
              requisition.id.length <= 10
          ? requisition.id
          : 'REQ-${requisition.id.substring(0, 6).toUpperCase()}';

      final titleHeader = storeName.trim().toUpperCase();

      final hasMetal = requisition.goldWeightGrams > 0;
      final tcwVal = requisition.gemWeightTw;
      final tcwStr = tcwVal > 0 ? '${tcwVal.toStringAsFixed(2)} Cts' : '';

      final stonesRows = requisition.stoneSpecs.isEmpty
          ? '<tr><td colspan="3" style="padding:6px 4px;color:#555;font-style:italic;text-align:center;">Plain Metal / No Gemstones Required</td></tr>'
          : requisition.stoneSpecs
              .map(
                (s) =>
                    '<tr style="border-bottom:1px dashed #ccc;">'
                    '<td style="padding:4px 2px;font-weight:600;">${s.name}</td>'
                    '<td style="padding:4px 2px;color:#333;font-size:10.5px;">${s.shape} ${s.size}</td>'
                    '<td style="padding:4px 2px;text-align:right;font-weight:bold;">${s.count} Pcs</td>'
                    '</tr>',
              )
              .join('');

      final metalSectionHtml = hasMetal
          ? '''
            <div style="border:1.5px solid #000;border-radius:4px;margin:8px 0;padding:6px 8px;background:#fafafa;">
              <div style="display:flex;justify-content:space-between;align-items:center;">
                <span style="font-size:10px;font-weight:900;letter-spacing:0.5px;">[1] BULLION / METAL ISSUED</span>
                <span style="font-size:9px;background:#000;color:#fff;padding:1px 4px;border-radius:2px;font-weight:bold;">VAULT CERTIFIED</span>
              </div>
              <div style="display:flex;justify-content:space-between;align-items:baseline;margin-top:6px;">
                <span style="font-size:11px;color:#333;">Net Gold Allocation:</span>
                <span style="font-size:18px;font-weight:900;letter-spacing:-0.5px;">${requisition.goldWeightGrams.toStringAsFixed(2)} <span style="font-size:12px;font-weight:bold;">g</span></span>
              </div>
              <div style="font-size:9px;color:#666;margin-top:2px;">Accuracy: 0.01g Calibrated • Scale Tag Verified</div>
            </div>
          '''
          : '';

      final customerRow = requisition.customerName.isNotEmpty
          ? '<div class="flex"><span>CLIENT:</span><span class="bold">${requisition.customerName}</span></div>'
          : '';

      final dueDateRow = requisition.dueDate.isNotEmpty
          ? '<div class="flex"><span>DUE DATE:</span><span class="bold" style="background:#000;color:#fff;padding:0 4px;border-radius:2px;">${requisition.dueDate.split('T').first}</span></div>'
          : '';

      final sizeDimRow = requisition.sizeDimensions.isNotEmpty
          ? '<div class="flex"><span>SIZE / DIM:</span><span class="bold">${requisition.sizeDimensions}</span></div>'
          : '';

      final gemHeaderBadge = tcwStr.isNotEmpty
          ? '$totalStones Pcs · $tcwStr'
          : '$totalStones Pcs';

      final htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>Job Slip - $voucherNo</title>
          <style>
            @page { size: 80mm auto; margin: 2mm; }
            * { box-sizing: border-box; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
              font-size: 11px;
              width: 74mm;
              margin: 0 auto;
              color: #111;
              background: #fff;
              padding: 4px;
              line-height: 1.35;
            }
            .center { text-align: center; }
            .bold { font-weight: bold; }
            .mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace; }
            .badge {
              display: inline-block;
              background: #000;
              color: #fff;
              font-size: 9.5px;
              font-weight: 800;
              letter-spacing: 0.8px;
              padding: 2px 6px;
              border-radius: 2px;
              text-transform: uppercase;
            }
            .divider { border-top: 1px dashed #888; margin: 6px 0; }
            .double-divider { border-top: 2px solid #000; margin: 8px 0; }
            .flex { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 2.5px; }
            .info-grid {
              border: 1px solid #222;
              border-radius: 4px;
              padding: 6px;
              margin: 6px 0;
              background: #fff;
            }
            table { width: 100%; border-collapse: collapse; font-size: 10.5px; }
          </style>
        </head>
        <body>
          <!-- BRAND HEADER -->
          <div class="center" style="margin-bottom:4px;">
            <div style="font-size:8.5px;letter-spacing:2px;color:#555;font-weight:bold;">✦ ATELIER MANUFACTURING ✦</div>
            <div class="bold" style="font-size:15px;letter-spacing:0.5px;margin:2px 0;">$titleHeader</div>
            <div class="badge" style="margin-top:2px;">JOB CARD & BOM ISSUE VOUCHER</div>
          </div>

          <!-- TOP METADATA CARD -->
          <div class="info-grid mono" style="font-size:10px;">
            <div class="flex"><span>VOUCHER NO :</span><span class="bold" style="font-size:11.5px;">$voucherNo</span></div>
            <div class="flex"><span>ISSUE DATE :</span><span>$realDateStr</span></div>
            <div class="flex"><span>ORDER REF  :</span><span class="bold">#${requisition.orderId}</span></div>
            $customerRow
            $dueDateRow
            <div style="border-top:1px dashed #bbb;margin:4px 0;"></div>
            <div class="flex"><span>DESIGN NO  :</span><span class="bold" style="font-size:11.5px;">${requisition.designNumber}</span></div>
            $sizeDimRow
            <div class="flex"><span>CRAFTSMAN  :</span><span class="bold">${requisition.artisanName}</span></div>
            <div class="flex"><span>STAGE NAME :</span><span class="bold">${requisition.stageName.toUpperCase()}</span></div>
          </div>

          <!-- SECTION 1: METAL ALLOCATION -->
          $metalSectionHtml

          <!-- SECTION 2: GEMSTONES BOM -->
          <div style="border:1.5px solid #000;border-radius:4px;margin:8px 0;padding:6px 8px;">
            <div style="display:flex;justify-content:space-between;align-items:center;padding-bottom:4px;border-bottom:1px solid #000;">
              <span style="font-size:10px;font-weight:900;letter-spacing:0.5px;">[2] GEMSTONES BOM</span>
              <span style="font-size:9.5px;font-weight:bold;background:#000;color:#fff;padding:1px 5px;border-radius:2px;">$gemHeaderBadge</span>
            </div>
            <table style="margin-top:4px;">
              <thead>
                <tr style="border-bottom:1px solid #888;font-size:9px;text-align:left;color:#444;">
                  <th style="padding:2px 0;">STONE SPEC</th>
                  <th style="padding:2px 0;">SHAPE / DIM</th>
                  <th style="padding:2px 0;text-align:right;">QTY</th>
                </tr>
              </thead>
              <tbody>
                $stonesRows
              </tbody>
            </table>
          </div>

          <!-- PHYSICAL ACKNOWLEDGEMENT & DUAL SIGNATURES -->
          <div style="margin-top:8px;padding-top:4px;border-top:1px solid #000;">
            <div class="bold" style="font-size:9.5px;margin-bottom:3px;">[PHYSICAL ACKNOWLEDGEMENT]</div>
            <div style="font-size:9.5px;">☑ Verified Material Weight & Purity</div>
            <div style="font-size:9.5px;">☑ Verified Gemstone Count & Quality</div>
            <div style="display:flex;justify-content:space-between;margin-top:18px;font-size:9px;" class="mono">
              <div style="text-align:center;width:45%;">
                <div style="border-top:1px solid #000;padding-top:3px;"><b>VAULT KEEPER</b><br/>(Issued & Scaled)</div>
              </div>
              <div style="text-align:center;width:45%;">
                <div style="border-top:1px solid #000;padding-top:3px;"><b>CRAFTSMAN SIGN</b><br/>(Received & Checked)</div>
              </div>
            </div>
          </div>

          <div class="center" style="font-size:8px;color:#777;margin-top:10px;letter-spacing:1px;border-top:1px dashed #aaa;padding-top:4px;">
            • KARATFLOW ATELIER PRECISION JOB CARD •
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
