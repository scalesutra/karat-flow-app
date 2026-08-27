import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';
import 'package:jewellery_ops_mobile/features/status/status_detail_page.dart';
import '../data/demo_store.dart';
import '../domain/models.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/login_page.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
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
    if (context.read<AuthBloc>().state is! AuthAuthenticated) {
      return const LoginPage();
    }
    final store = Get.find<DemoStore>();
    final roleController = Get.isRegistered<AppRoleController>()
        ? Get.find<AppRoleController>()
        : Get.put(AppRoleController(), permanent: true);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! AuthAuthenticated) return const LoginPage();

        final targetRole = AppRole.fromRoleString(state.role);
        if (roleController.currentRole.value != targetRole) {
          roleController.setRole(targetRole);
        }
        return Obx(
          () => AppShell(
            role: roleController.currentRole.value,
            store: store,
            onRoleChanged: roleController.setRole,
          ),
        );
      },
    );
  }
}

class _StatusDetailRoute extends StatelessWidget {
  const _StatusDetailRoute();

  @override
  Widget build(BuildContext context) {
    if (context.read<AuthBloc>().state is! AuthAuthenticated) {
      return const LoginPage();
    }
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

class _StageOverviewRoute extends StatefulWidget {
  const _StageOverviewRoute();

  @override
  State<_StageOverviewRoute> createState() => _StageOverviewRouteState();
}

class _StageOverviewRouteState extends State<_StageOverviewRoute> {
  @override
  Widget build(BuildContext context) {
    if (context.read<AuthBloc>().state is! AuthAuthenticated) {
      return const LoginPage();
    }
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final rawArgs = routeArgs ?? Get.arguments;

    Map<String, dynamic>? orderData;
    if (rawArgs is Map<String, dynamic>) {
      orderData = rawArgs;
    } else if (rawArgs is Map) {
      orderData = Map<String, dynamic>.from(rawArgs);
    }

    if (orderData != null) {
      return StageOverviewScreen(orderData: orderData);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: Color(0xFF8C7A6B),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order details session reset on web refresh.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C241D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please return to the control center to select an order.',
                style: TextStyle(fontSize: 14, color: Color(0xFF7A6E65)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(Routes.shell),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A2B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text(
                  'Back to Control Center',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
