import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';

void main() {
  test('governance directives are populated from API data', () {
    final store = DemoStore.empty();
    store.setApiDirectives(const [
      ApiDirective(
        id: 'directive-id',
        directiveCode: 'DIR-1',
        title: 'CAD review',
        targetType: 'THREE_D_DESIGNER',
        instruction: 'Reduce thickness',
        audioUrl: 'audio-key',
        imageUrl: 'image-key',
      ),
    ]);

    expect(store.adminDirectives, hasLength(1));
    expect(store.adminDirectives.single['recipient'], 'CAD Designer');
    expect(store.adminDirectives.single['content'], 'Reduce thickness');
    expect(store.adminDirectives.single['audioUrl'], 'audio-key');
    expect(store.adminDirectives.single['imageUrl'], 'image-key');
    expect(store.instructions.single.hasVoice, isTrue);
    expect(store.instructions.single.hasPhoto, isTrue);
  });
}
