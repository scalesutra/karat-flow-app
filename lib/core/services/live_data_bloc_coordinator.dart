import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models.dart';
import '../../features/admin/bloc/admin_bloc.dart';
import '../../features/cad_designer/bloc/cad_bloc.dart';
import '../../features/directives/bloc/directives_bloc.dart';
import '../../features/front_office/bloc/orders_bloc.dart';
import '../../features/inventory/bloc/inventory_bloc.dart';
import '../../features/materials/bloc/materials_bloc.dart';
import '../../features/raw_designer/bloc/sketch_bloc.dart';
import '../../features/workshop/bloc/workshop_bloc.dart';
import '../../features/workshop_artisan/bloc/artisan_bloc.dart';

abstract final class LiveDataBlocCoordinator {
  static void refreshForRole(BuildContext context, AppRole role) {
    switch (role) {
      case AppRole.admin:
        context.read<AdminBloc>().add(const FetchAdminDashboardEvent());
        context.read<OrdersBloc>().add(const FetchOrdersEvent());
        context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
        context.read<CadBloc>().add(const FetchCadTasksEvent());
        context.read<MaterialsBloc>().add(const FetchMaterialsEvent());
        context.read<InventoryBloc>().add(const FetchInventoryEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.frontOffice:
        context.read<OrdersBloc>().add(const FetchFrontOfficeDataEvent());
      case AppRole.processManager:
        context.read<OrdersBloc>().add(const FetchOrdersEvent());
        context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.cadDesigner:
        context.read<CadBloc>().add(const FetchCadTasksEvent());
      case AppRole.rawDesigner:
        context.read<SketchBloc>().add(const FetchSketchesEvent());
      case AppRole.workshopArtisan:
        context.read<ArtisanBloc>().add(const FetchArtisanTasksEvent());
    }
  }
}
