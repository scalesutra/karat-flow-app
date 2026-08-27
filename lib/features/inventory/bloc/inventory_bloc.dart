import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/karatflow_api_repository.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

export 'inventory_event.dart';
export 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({KaratFlowApiRepository? repository})
    : _repository = repository ?? KaratFlowApiRepository(),
      super(const InventoryInitial()) {
    on<FetchInventoryEvent>(_onFetchInventory);
    on<AddInventoryItemEvent>(_onAddItem);
  }

  final KaratFlowApiRepository _repository;

  Future<void> _onFetchInventory(
    FetchInventoryEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final res = await _repository.getInventory(
        category: event.category,
        search: event.search,
      );
      emit(InventoryLoaded(response: res));
    } catch (error) {
      emit(InventoryError('Failed to fetch vault inventory: $error'));
    }
  }

  Future<void> _onAddItem(
    AddInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.addInventoryItem(
        name: event.name,
        category: event.category,
        purity: event.purity,
        totalStock: event.totalStock,
        reservedWip: event.reservedWip,
        freeBalance: event.freeBalance,
        unit: event.unit,
        location: event.location,
      );
      emit(
        const InventoryOperationSuccess(
          'Vault inventory item added successfully.',
        ),
      );
      add(const FetchInventoryEvent());
    } catch (error) {
      emit(InventoryError('Failed to add vault item: $error'));
    }
  }
}
