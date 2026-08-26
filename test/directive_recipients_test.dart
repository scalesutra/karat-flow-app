import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/domain/directive_recipients.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import 'package:jewellery_ops_mobile/features/instructions/directive_audio.dart';

void main() {
  test('all teams directive matches every operational role', () {
    for (final role in AppRole.values.where((role) => role != AppRole.admin)) {
      expect(
        DirectiveRecipients.matchesRole(DirectiveRecipients.allTeams, role),
        isTrue,
      );
    }
  });

  test('role directives only match their intended login role', () {
    expect(
      DirectiveRecipients.matchesRole(
        'Product Manager',
        AppRole.processManager,
      ),
      isTrue,
    );
    expect(
      DirectiveRecipients.matchesRole('Raw Designer', AppRole.cadDesigner),
      isFalse,
    );
  });

  test('voice directive separates readable text and audio URL', () {
    final message = DirectiveMessage.parse(
      'Reduce thickness [ 🎙️ Voice Note: https://files.example/note.m4a ] '
      '[ 🖼️ Image: https://files.example/reference.jpg ]',
    );

    expect(message.text, 'Reduce thickness');
    expect(message.audioUrl, 'https://files.example/note.m4a');
    expect(message.hasAudio, isTrue);
    expect(message.imageUrl, 'https://files.example/reference.jpg');
    expect(message.hasImage, isTrue);
  });
}
