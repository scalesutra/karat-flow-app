import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('governance voice directives survive a store restart', () async {
    SharedPreferences.setMockInitialValues({});
    final original = DemoStore.empty();

    await original.addAdminDirective(
      'CAD Designer',
      'Reduce thickness [ 🎙️ Voice Note: https://files.example/note.m4a ]',
    );

    final restored = DemoStore.empty();
    await restored.initialize();

    expect(restored.adminDirectives, hasLength(1));
    expect(restored.adminDirectives.single['recipient'], 'CAD Designer');
    expect(
      restored.adminDirectives.single['content'],
      contains('https://files.example/note.m4a'),
    );
    expect(restored.instructions.single.hasVoice, isTrue);
  });
}
