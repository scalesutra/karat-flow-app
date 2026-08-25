import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';

void main() {
  test('live presentation cache starts empty', () {
    final store = DemoStore.empty();
    addTearDown(store.dispose);

    expect(store.orders, isEmpty);
    expect(store.clients, isEmpty);
    expect(store.designs, isEmpty);
    expect(store.lots, isEmpty);
    expect(store.team, isEmpty);
    expect(store.cadTasks, isEmpty);
    expect(store.stages, isEmpty);
    expect(store.stock, isEmpty);
  });

  test('API setters replace rather than merge live data', () {
    final store = DemoStore.empty();
    addTearDown(store.dispose);
    final first = ClientInfo(
      id: 'customer-1',
      firmName: 'First',
      city: 'Jaipur',
      contactPerson: 'Owner',
      phone: '+910000000001',
      creditLimitLakhs: 10,
      outstandingBalance: 0,
      activeOrdersCount: 0,
    );
    final second = ClientInfo(
      id: 'customer-2',
      firmName: 'Second',
      city: 'Mumbai',
      contactPerson: 'Owner',
      phone: '+910000000002',
      creditLimitLakhs: 20,
      outstandingBalance: 0,
      activeOrdersCount: 0,
    );

    store.setClients([first]);
    store.setClients([second]);

    expect(store.clients, hasLength(1));
    expect(store.clients.single.id, 'customer-2');
  });

  test('cart remains temporary UI state only', () {
    final store = DemoStore.empty();
    addTearDown(store.dispose);
    const design = JewelleryDesign(
      id: 'design-1',
      name: 'Ring',
      code: 'RG-1',
      category: JewelleryCategory.rings,
      purity: '22KT',
      description: '',
    );

    store.addToCart(design, quantity: 2);
    expect(store.cartItemsCount, 2);
    store.clearCart();
    expect(store.cart, isEmpty);
  });
}
