import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';

void main() {
  test('instruction keeps target context through its lifecycle', () {
    final store = DemoStore.seeded();
    addTearDown(store.dispose);
    final target = store.workItemsFor(StatusPivot.orders).first;

    final instruction = store.addInstruction(
      target: target,
      message: 'Confirm the replacement stones.',
      urgency: InstructionUrgency.urgent,
      hasPhoto: true,
    );

    expect(instruction.targetId, target.id);
    expect(instruction.targetLabel, 'Order ${target.id}');
    expect(instruction.status, InstructionStatus.sent);
    expect(store.instructions.first.id, instruction.id);

    store.setInstructionStatus(instruction.id, InstructionStatus.acknowledged);
    expect(store.instructions.first.status, InstructionStatus.acknowledged);

    store.setInstructionStatus(instruction.id, InstructionStatus.resolved);
    expect(store.instructions.first.status, InstructionStatus.resolved);
  });

  test('createDirectOrder creates order with designs, quantities and due date', () {
    final store = DemoStore.seeded();
    addTearDown(store.dispose);

    final client = store.clients.first;
    final design = store.designs.first;
    final initialOrderCount = store.orders.length;

    final order = store.createDirectOrder(
      client: client,
      items: [
        {'design': design, 'quantity': 3},
      ],
      dueDate: 'Due Tomorrow · 12:00 PM',
      notes: 'Urgent wholesale request',
    );

    expect(store.orders.length, initialOrderCount + 1);
    expect(order.clientFirmName, client.firmName);
    expect(order.itemsCount, 3);
    expect(order.promiseDate, 'Due Tomorrow · 12:00 PM');
    expect(order.itemsSummary, contains(design.name));
  });

  test('toggleOrderHold updates order blocked status correctly', () {
    final store = DemoStore.seeded();
    addTearDown(store.dispose);

    final firstOrderId = store.orders.first.id;
    expect(store.orders.first.isBlocked, false);

    store.toggleOrderHold(firstOrderId, isBlocked: true, reason: 'Missing stones');
    expect(store.orders.first.isBlocked, true);
    expect(store.orders.first.blockedReason, 'Missing stones');

    store.toggleOrderHold(firstOrderId, isBlocked: false);
    expect(store.orders.first.isBlocked, false);
    expect(store.orders.first.blockedReason, isNull);
  });
}
