import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/admin/bloc/admin_bloc.dart';
import '../../features/cad_designer/bloc/cad_bloc.dart';
import '../../features/directives/bloc/directives_bloc.dart';
import '../../features/front_office/bloc/orders_bloc.dart';
import '../../features/inventory/bloc/inventory_bloc.dart';
import '../../features/materials/bloc/materials_bloc.dart';
import '../../features/raw_designer/bloc/sketch_bloc.dart';
import '../../features/workshop/bloc/workshop_bloc.dart';
import '../../features/workshop_artisan/bloc/artisan_bloc.dart';
import 'common_snackbar.dart';

class LiveBlocFeedback extends StatelessWidget {
  const LiveBlocFeedback({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MaterialsBloc, MaterialsState>(
          listener: (context, state) {
            if (state case MaterialsOperationSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Materials Updated',
                message: message,
              );
            } else if (state case MaterialsError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Materials API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state case InventoryOperationSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Inventory Updated',
                message: message,
              );
            } else if (state case InventoryError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Inventory API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<DirectivesBloc, DirectivesState>(
          listener: (context, state) {
            if (state case DirectivesOperationSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Directive Sent',
                message: message,
              );
            } else if (state case DirectivesError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Directive API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<OrdersBloc, OrdersState>(
          listener: (context, state) {
            if (state case OrderOperationSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Order Updated',
                message: message,
              );
            } else if (state case OrdersError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Order API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<WorkshopBloc, WorkshopState>(
          listener: (context, state) {
            if (state case WorkshopStageUpdated(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Workshop Updated',
                message: message,
              );
            } else if (state case WorkshopError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Workshop API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<CadBloc, CadState>(
          listener: (context, state) {
            if (state case CadOperationSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'CAD Updated',
                message: message,
              );
            } else if (state case CadError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'CAD API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<AdminBloc, AdminState>(
          listener: (context, state) {
            if (state case AdminActionSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Admin Updated',
                message: message,
              );
            } else if (state case AdminError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Admin API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<SketchBloc, SketchState>(
          listener: (context, state) {
            if (state case SketchActionSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Sketch Updated',
                message: message,
              );
            } else if (state case SketchError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Sketch API Error',
                message: message,
              );
            }
          },
        ),
        BlocListener<ArtisanBloc, ArtisanState>(
          listener: (context, state) {
            if (state case ArtisanActionSuccess(:final message)) {
              CommonSnackbar.success(
                context,
                title: 'Workshop Task Updated',
                message: message,
              );
            } else if (state case ArtisanError(:final message)) {
              CommonSnackbar.error(
                context,
                title: 'Worker Task API Error',
                message: message,
              );
            }
          },
        ),
      ],
      child: child,
    );
  }
}
