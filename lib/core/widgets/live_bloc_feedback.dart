import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/admin/bloc/admin_bloc.dart';
import '../../features/cad_designer/bloc/cad_bloc.dart';
import '../../features/front_office/bloc/orders_bloc.dart';
import '../../features/workshop/bloc/workshop_bloc.dart';
import 'common_snackbar.dart';

class LiveBlocFeedback extends StatelessWidget {
  const LiveBlocFeedback({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
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
      ],
      child: child,
    );
  }
}
