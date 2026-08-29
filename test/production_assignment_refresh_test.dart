import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/mappers/api_domain_mapper.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';

void main() {
  tearDown(() => DemoStore.instance.setLots(const []));

  test('maps documented order part assignments after a refresh', () {
    final lot = ApiDomainMapper.pendingPart({
      'id': 'part-uuid-1',
      '_orderId': 'order-uuid-1',
      '_orderNumber': 'ORD-20260829-0001',
      'designNumber': 'LOT-BRC-091',
      'quantity': 1,
      'grossWeight': 45.2,
      'status': 'ASSIGNED',
      'currentStage': {'id': 'stage-uuid-1', 'name': 'Wax Tree Casting'},
      'assignments': [
        {
          'id': 'assignment-latest',
          'assignedEmployeeId': 'artisan-user-uuid',
          'status': 'ASSIGNED',
          'assignedEmployee': {
            'id': 'artisan-user-uuid',
            'name': 'Ramesh Soni',
          },
          'stage': {'id': 'stage-uuid-1', 'name': 'Wax Tree Casting'},
        },
        {
          'id': 'assignment-older',
          'status': 'ASSIGNED',
          'assignedEmployee': {'name': 'Older Artisan'},
          'stage': {'id': 'stage-uuid-1', 'name': 'Wax Tree Casting'},
        },
      ],
    });

    expect(lot.id, 'part-uuid-1');
    expect(lot.orderId, 'order-uuid-1');
    expect(lot.assignedEmployee, 'Ramesh Soni');
    expect(lot.pieces, 1);
  });

  test('maps documented employee active assignment count', () {
    final employee = ApiEmployee.fromJson({
      'id': 'artisan-user-uuid',
      'name': 'Ramesh Soni',
      'email': 'ramesh@karratflow.com',
      'phone': '+919829012345',
      'role': 'CRAFTSMAN',
      'activeAssignmentsCount': 3,
    });

    expect(employee.workerAssignmentsCount, 3);
    expect(ApiDomainMapper.employee(employee).activeLotsCount, 3);
  });

  test('backend refresh replaces optimistic assignment state', () {
    const optimistic = WorkshopLot(
      id: 'part-uuid-1',
      orderId: 'order-uuid-1',
      designCode: 'LOT-BRC-091',
      productTitle: 'LOT-BRC-091',
      stage: WorkshopStage.cadAndWax,
      assignedEmployee: 'Optimistic Worker',
      assignedEmployeeRole: 'ASSIGNED',
      pieces: 1,
      issueWeightGrams: 45.2,
      targetWeightGrams: 45.2,
      tone: HealthTone.healthy,
      blockerReason: null,
      lastUpdatedTime: 'Just now',
    );
    final backendLot = optimistic.copyWith(assignedEmployee: 'Unassigned');

    DemoStore.instance.setLots([optimistic]);
    DemoStore.instance.setLots([backendLot]);

    expect(DemoStore.instance.lots.single.assignedEmployee, 'Unassigned');
  });
}
