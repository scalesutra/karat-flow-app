import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jewellery_ops_mobile/core/localization/localization.dart';
import 'package:jewellery_ops_mobile/core/theme/app_theme.dart';
import 'package:jewellery_ops_mobile/data/demo_store.dart';
import 'package:jewellery_ops_mobile/domain/models.dart';
import 'package:jewellery_ops_mobile/features/shell/app_shell.dart';

void main() {
  testWidgets('Admin status renders successfully with live store data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DemoStore.seeded();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light(),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: AppShell(
            role: AppRole.admin,
            store: store,
            onRoleChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.adminDashboard.trClean), findsWidgets);
    expect(find.text('JO-10482'), findsWidgets);
  });

  testWidgets('Process Manager tab renders without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DemoStore.seeded();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light(),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: AppShell(
            role: AppRole.processManager,
            store: store,
            onRoleChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.productManager.trClean), findsWidgets);
    expect(find.text('JO-10482'), findsWidgets);
  });

  testWidgets('Front Office tab renders without Custom/CAD filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = DemoStore.seeded();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light(),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: AppShell(
            role: AppRole.frontOffice,
            store: store,
            onRoleChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('JO-10482'), findsWidgets);
    expect(find.text('Custom / CAD'), findsNothing);
  });
}
