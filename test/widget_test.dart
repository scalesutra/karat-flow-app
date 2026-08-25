import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/core/widgets/common_empty_state.dart';

void main() {
  for (final size in <Size>[
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1280, 800),
  ]) {
    testWidgets('common empty state is responsive at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: CommonEmptyState(
                title: 'No live records',
                description: 'The API returned no records.',
              ),
            ),
          ),
        ),
      );

      expect(find.text('No live records'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
