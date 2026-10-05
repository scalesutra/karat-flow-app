import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models.dart';
import '../../features/admin/bloc/admin_bloc.dart';
import '../../features/cad_designer/bloc/cad_bloc.dart';
import '../../features/directives/bloc/directives_bloc.dart';
import '../../features/front_office/bloc/orders_bloc.dart';
import '../../features/inventory/bloc/inventory_bloc.dart';
import '../../features/raw_designer/bloc/sketch_bloc.dart';
import '../../features/workshop/bloc/workshop_bloc.dart';
import '../../features/workshop_artisan/bloc/artisan_bloc.dart';

abstract final class LiveDataBlocCoordinator {
  static void refreshForRole(
    BuildContext context,
    AppRole role, {
    int tabIndex = 0,
  }) {
    switch (role) {
      case AppRole.admin:
        context.read<AdminBloc>().add(
          const FetchAdminDashboardEvent(overviewOnly: true),
        );
        // AdminBloc owns the order list displayed by the admin dashboard.
        // A second writer would replace it with a different set of orders.
        context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
        context.read<CadBloc>().add(const FetchCadTasksEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.frontOffice:
        if (tabIndex == 1) {
          context.read<OrdersBloc>().add(const FetchDesignsCatalogEvent());
        } else if (tabIndex == 3) {
          context.read<OrdersBloc>().add(const FetchCustomersEvent());
        } else {
          // Preload full Front Office dataset (Orders + Designs + Clients)
          context.read<OrdersBloc>().add(const FetchFrontOfficeDataEvent());
        }
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.processManager:
        context.read<OrdersBloc>().add(const FetchOrdersEvent());
        context.read<WorkshopBloc>().add(const FetchWorkshopLotsEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.cadDesigner:
        context.read<CadBloc>().add(const FetchCadTasksEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.rawDesigner:
        context.read<SketchBloc>().add(const FetchSketchesEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.workshopArtisan:
      case AppRole.worker:
        context.read<ArtisanBloc>().add(const FetchArtisanTasksEvent());
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
      case AppRole.stockist:
        // Stockist lazy loading: Tab 0 is Requisitions queue, Tab 1 is Vault Stock
        if (tabIndex == 1) {
          context.read<InventoryBloc>().add(const FetchInventoryEvent());
        } else {
          context.read<InventoryBloc>().add(
            const FetchPendingIssuancesQueueEvent(),
          );
        }
        context.read<DirectivesBloc>().add(const FetchDirectivesEvent());
    }
  }
}

