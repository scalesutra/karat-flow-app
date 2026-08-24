import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:get/get.dart';

import 'core/localization/localization.dart';
import 'core/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'data/demo_store.dart';
import 'domain/models.dart';
import 'features/admin/bloc/admin_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/cad_designer/bloc/cad_bloc.dart';
import 'features/front_office/bloc/orders_bloc.dart';
import 'features/workshop/bloc/workshop_bloc.dart';
import 'routes/app_pages.dart';

class JewelleryOpsApp extends StatefulWidget {
  const JewelleryOpsApp({super.key, this.initialRole = AppRole.admin});

  final AppRole initialRole;

  @override
  State<JewelleryOpsApp> createState() => _JewelleryOpsAppState();
}

class _JewelleryOpsAppState extends State<JewelleryOpsApp> {
  late final DemoStore _store;

  @override
  void initState() {
    super.initState();
    // Keep one shared store across the shell, API sync and detail routes.
    // A second DemoStore instance leaves API-backed worker lists empty.
    _store = DemoStore.instance;
    Get.put(ConnectivityController(), permanent: true);
    Get.put(_store, permanent: true);
    final roleController = Get.put(AppRoleController(), permanent: true);
    roleController.setRole(widget.initialRole);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc()..add(const AuthCheckRequested()),
        ),
        BlocProvider<OrdersBloc>(create: (_) => OrdersBloc(store: _store)),
        BlocProvider<WorkshopBloc>(create: (_) => WorkshopBloc()),
        BlocProvider<CadBloc>(create: (_) => CadBloc(store: _store)),
        BlocProvider<AdminBloc>(create: (_) => AdminBloc(store: _store)),
      ],
      child: GetMaterialApp(
        title: 'KaratFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        defaultTransition: Transition.cupertino,
      ),
    );
  }
}
