import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/demo_store.dart';
import '../domain/models.dart';
import '../features/auth/login_page.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import '../features/status/admin_status_page.dart';
import '../features/workshop/stage_overview_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static const initial = Routes.splash;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.initial,
      page: () => const _AppShellRoute(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.shell,
      page: () => const _AppShellRoute(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.statusDetail,
      page: () => const _StatusDetailRoute(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: Routes.stageOverview,
      page: () => const _StageOverviewRoute(),
      transition: Transition.cupertino,
    ),
  ];
}

class _AppShellRoute extends StatelessWidget {
  const _AppShellRoute();

  @override
  Widget build(BuildContext context) {
    final store = Get.find<DemoStore>();
    final roleController = Get.put(AppRoleController());

    return Obx(
      () => AppShell(
        role: roleController.currentRole.value,
        store: store,
        onRoleChanged: roleController.setRole,
      ),
    );
  }
}

class _StatusDetailRoute extends StatelessWidget {
  const _StatusDetailRoute();

  @override
  Widget build(BuildContext context) {
    final store = Get.find<DemoStore>();
    final item = Get.arguments as WorkItem?;
    if (item == null) {
      return const Scaffold(
        body: Center(child: Text('Work item details not found.')),
      );
    }
    return StatusDetailPage(item: item, store: store);
  }
}

class AppRoleController extends GetxController {
  final currentRole = AppRole.admin.obs;

  void setRole(AppRole role) {
    currentRole.value = role;
  }
}

class _StageOverviewRoute extends StatelessWidget {
  const _StageOverviewRoute();

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final rawArgs = routeArgs ?? Get.arguments;

    Map<String, dynamic> orderData;
    if (rawArgs is Map<String, dynamic>) {
      orderData = rawArgs;
    } else if (rawArgs is Map) {
      orderData = Map<String, dynamic>.from(rawArgs);
    } else {
      return const Scaffold(
        body: Center(child: Text('Live order data was not provided.')),
      );
    }

    return StageOverviewScreen(orderData: orderData);
  }
}
