import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models.dart';
import '../../features/admin/bloc/admin_bloc.dart';
import '../../features/cad_designer/bloc/cad_bloc.dart';
import '../../features/front_office/bloc/orders_bloc.dart';
import '../../features/workshop/bloc/workshop_bloc.dart';

abstract final class LiveDataBlocCoordinator {
  static void refreshForRole(BuildContext context, AppRole role) {
    switch (role) {
      case AppRole.admin:
        context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
        context.read<OrdersBloc>().add(const FetchOrdersEvent());
        context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
        context.read<CadBloc>().add(const FetchCadTasksEvent());
      case AppRole.frontOffice:
        context.read<OrdersBloc>().add(const FetchFrontOfficeDataEvent());
      case AppRole.processManager:
        context.read<OrdersBloc>().add(const FetchOrdersEvent());
        context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
      case AppRole.cadDesigner:
        context.read<CadBloc>().add(const FetchCadTasksEvent());
    }
  }
}
