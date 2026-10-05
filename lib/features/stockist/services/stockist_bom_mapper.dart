import '../../../data/models/api_models.dart';

/// Converts per-jewellery-piece CAD requirements into requisition totals once.
abstract final class StockistBomMapper {
  static VaultRequisition requisition(ApiPendingIssuance p) {
    final int quantity = p.quantity ?? 0;
    final issuedItems = p.isStockIssued ? p.issuance?.itemsIssued : null;
    final hasIssuedItems = issuedItems != null && issuedItems.isNotEmpty;

    final int issuedStonesCount = hasIssuedItems
        ? issuedItems!
              .where(
                (item) =>
                    (item['category'] as String? ?? '').toUpperCase() ==
                    'STONE',
              )
              .fold<int>(
                0,
                (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
              )
        : 0;

    final int cadPerPieceCount = p.cadSpecs.gemBreakdown.fold<int>(
      0,
      (sum, b) => sum + b.count,
    );

    // If cadSpecs has the breakdown, and issuedItems only has 1-piece count or is empty,
    // use cadSpecs multiplied by the batch quantity (matching Web Requisition Slip).
    final bool useCadBreakdown =
        p.cadSpecs.gemBreakdown.isNotEmpty &&
        (!hasIssuedItems ||
            (quantity > 1 && issuedStonesCount <= cadPerPieceCount));

    final specs = useCadBreakdown
        ? p.cadSpecs.gemBreakdown
              .map(
                (b) => StoneSpec(
                  name: b.shape.isNotEmpty ? b.shape : 'Diamond',
                  count: b.count * quantity,
                  size: b.dimensions,
                  shape: b.shape.isNotEmpty ? b.shape : 'Diamond',
                  color: b.color.isNotEmpty ? b.color : 'White',
                  clarity: 'BOM Grade',
                ),
              )
              .where((s) => s.count > 0)
              .toList()
        : (hasIssuedItems
              ? issuedItems!
                    .where(
                      (item) =>
                          (item['category'] as String? ?? '').toUpperCase() ==
                          'STONE',
                    )
                    .map(
                      (item) => StoneSpec(
                        name: item['name'] as String? ?? '',
                        count: (item['quantity'] as num?)?.toInt() ?? 0,
                        size: item['code'] as String? ?? '',
                        shape: item['shape'] as String? ?? '',
                        color: item['color'] as String? ?? '',
                        clarity: '',
                      ),
                    )
                    .toList()
              : const <StoneSpec>[]);
    final issueNumber = p.issuance?.issueNumber ?? '';
    return VaultRequisition(
      id: issueNumber.isNotEmpty ? issueNumber : p.orderPartId,
      orderPartId: p.orderPartId,
      designNumber: p.designNumber,
      orderId: p.orderNumber.isNotEmpty ? p.orderNumber : p.orderId,
      customerName: p.customerName,
      dueDate: p.dueDate,
      artisanName: p.assignedCraftsman?.name ?? '',
      stageName: p.currentStage,
      orderPartStatus: p.orderPartStatus,
      quantity: quantity,
      goldWeightGrams: p.cadSpecs.goldQuantity,
      gemWeightTw: p.cadSpecs.gemWeightTw * quantity,
      sizeDimensions: p.cadSpecs.sizeDimensions,
      stones: specs
          .map((s) => '${s.count}x ${s.shape} ${s.size} (${s.color})')
          .toList(),
      stoneSpecs: specs,
      status: p.isStockIssued ? 'ISSUED' : 'PENDING_ISSUE',
      timestamp: issueNumber.isNotEmpty ? issueNumber : p.dueDate,
    );
  }
}
