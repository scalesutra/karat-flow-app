import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/features/stockist/services/stockist_bom_mapper.dart';

Map<String, dynamic> queueRow({Object? quantity, Object? splitQuantity}) => {
  'orderPartId': 'part',
  'quantity': quantity,
  if (splitQuantity != null) 'splitQuantity': splitQuantity,
  'cadSpecs': {
    'gemWeightTw': 3.2,
    'gemBreakdown': [
      for (final count in [6, 25, 42, 4, 2]) {'shape': 'Stone', 'count': count},
    ],
  },
};

void main() {
  test(
    'existing nested order-part quantity calculates totals without new queue fields',
    () {
      final row = queueRow()..['orderPart'] = {'id': 'part', 'quantity': 10};
      final req = StockistBomMapper.requisition(
        ApiPendingIssuance.fromJson(row),
      );
      expect(req.quantity, 10);
      expect(req.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count), 790);
    },
  );

  test(
    'assignment ID selects the correct existing split instead of full order',
    () {
      final row = queueRow()
        ..['partAssignmentId'] = 'batch-b'
        ..['orderPart'] = {
          'quantity': 10,
          'assignments': [
            {'id': 'batch-a', 'splitQuantity': 1, 'status': 'ASSIGNED'},
            {'id': 'batch-b', 'splitQuantity': 9, 'status': 'ASSIGNED'},
          ],
        };
      final req = StockistBomMapper.requisition(
        ApiPendingIssuance.fromJson(row),
      );
      expect(req.quantity, 9);
      expect(req.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count), 711);
      row['partAssignmentId'] = 'unknown';
      expect(ApiPendingIssuance.fromJson(row).quantity, isNull);
    },
  );

  test('existing assignment split instructions resolve batch quantity', () {
    final row = queueRow()
      ..['partAssignmentId'] = 'batch'
      ..['orderPart'] = {
        'quantity': 10,
        'assignments': [
          {'id': 'batch', 'instructions': '[splitQty: 3] Assigned to Worker'},
        ],
      };
    expect(ApiPendingIssuance.fromJson(row).quantity, 3);
  });

  test('10 jewellery pieces require 790 stones and 32 carats', () {
    final req = StockistBomMapper.requisition(
      ApiPendingIssuance.fromJson(queueRow(quantity: 10)),
    );
    expect(req.quantity, 10);
    expect(req.stoneSpecs.map((s) => s.count), [60, 250, 420, 40, 20]);
    expect(req.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count), 790);
    expect(req.gemWeightTw, closeTo(32, 0.00001));
  });

  test('split batch uses assigned quantity, not parent quantity', () {
    for (final quantity in [1, 9]) {
      final req = StockistBomMapper.requisition(
        ApiPendingIssuance.fromJson(
          queueRow(quantity: 10, splitQuantity: quantity),
        ),
      );
      expect(req.quantity, quantity);
      expect(
        req.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count),
        79 * quantity,
      );
      expect(req.gemWeightTw, closeTo(3.2 * quantity, 0.00001));
    }
  });

  test('missing or invalid quantities never assume one piece', () {
    for (final quantity in [null, 0, -1, 1.5, 'bad']) {
      final api = ApiPendingIssuance.fromJson(queueRow(quantity: quantity));
      expect(api.quantity, isNull);
      final req = StockistBomMapper.requisition(api);
      expect(req.quantity, 0);
      expect(req.stoneSpecs, isEmpty);
      expect(req.gemWeightTw, 0);
    }
    expect(ApiPendingIssuance.fromJson(queueRow(quantity: '10')).quantity, 10);
    expect(
      ApiPendingIssuance.fromJson(
        queueRow(quantity: 10, splitQuantity: 0),
      ).quantity,
      isNull,
    );
  });

  test('issued quantities are not multiplied and metal is not a stone', () {
    final row = queueRow(quantity: 10)
      ..['isStockIssued'] = true
      ..['issuance'] = {
        'itemsIssued': [
          {'name': 'Gold', 'category': 'METAL', 'quantity': 3.21},
          {'name': 'Round', 'category': 'STONE', 'quantity': 250.0},
        ],
      };
    final req = StockistBomMapper.requisition(ApiPendingIssuance.fromJson(row));
    expect(req.stoneSpecs.length, 1);
    expect(req.stoneSpecs.single.count, 250);
    expect(req.stoneSpecs.single.name, 'Round');
  });

  test('dispatch and completed stages are marked as isDispatchedOrCompleted', () {
    for (final stage in ['Ready for Dispatch', 'dispatch', 'Completed', 'Delivered']) {
      final row = queueRow(quantity: 1)..['currentStage'] = stage;
      final req = StockistBomMapper.requisition(ApiPendingIssuance.fromJson(row));
      expect(req.isDispatchedOrCompleted, isTrue);
    }
    final normalRow = queueRow(quantity: 1)..['currentStage'] = 'Stone Setting';
    expect(
      StockistBomMapper.requisition(ApiPendingIssuance.fromJson(normalRow))
          .isDispatchedOrCompleted,
      isFalse,
    );
  });

  test('50 jewellery pieces with CAD specs calculates 3950 total stones matching web slip', () {
    final row = {
      'orderPartId': 'part',
      'quantity': 50,
      'cadSpecs': {
        'gemBreakdown': [
          {'shape': 'Marquise', 'dimensions': '4.00X2.00', 'color': 'White', 'count': 6},
          {'shape': 'Round', 'dimensions': '1.20X1.20', 'color': 'White', 'count': 25},
          {'shape': 'Round', 'dimensions': '1.40X1.40', 'color': 'White', 'count': 42},
          {'shape': 'Pear', 'dimensions': '4.00X8.00', 'color': 'White', 'count': 4},
          {'shape': 'Pear', 'dimensions': '0.00X4.00', 'color': 'White', 'count': 2},
        ],
      },
    };
    final req = StockistBomMapper.requisition(ApiPendingIssuance.fromJson(row));
    expect(req.quantity, 50);
    expect(req.stoneSpecs.fold<int>(0, (sum, s) => sum + s.count), 3950);
    expect(req.stoneSpecs[0].count, 300);
    expect(req.stoneSpecs[0].size, '4.00X2.00');
    expect(req.stoneSpecs[0].shape, 'Marquise');
    expect(req.stoneSpecs[1].count, 1250);
    expect(req.stoneSpecs[2].count, 2100);
    expect(req.stoneSpecs[3].count, 200);
    expect(req.stoneSpecs[4].count, 100);
  });
}
