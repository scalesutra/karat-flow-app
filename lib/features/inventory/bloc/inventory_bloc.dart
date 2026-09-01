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
    on<GetInventoryByIdEvent>(_onGetInventoryById);
    on<AddInventoryItemEvent>(_onAddItem);
    on<UpdateInventoryItemEvent>(_onUpdateItem);
    on<DeleteInventoryItemEvent>(_onDeleteItem);
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

  Future<void> _onGetInventoryById(
    GetInventoryByIdEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    try {
      final item = await _repository.getInventoryById(event.id);
      emit(InventoryDetailLoaded(item: item));
    } catch (error) {
      emit(InventoryError('Failed to fetch inventory item details: $error'));
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
        notes: event.notes,
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

  Future<void> _onUpdateItem(
    UpdateInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.updateInventoryItem(
        event.id,
        totalStock: event.totalStock,
        reservedWip: event.reservedWip,
        freeBalance: event.freeBalance,
        location: event.location,
        notes: event.notes,
      );
      emit(
        const InventoryOperationSuccess(
          'Vault inventory item updated successfully.',
        ),
      );
      add(const FetchInventoryEvent());
    } catch (error) {
      emit(InventoryError('Failed to update vault item: $error'));
    }
  }

  Future<void> _onDeleteItem(
    DeleteInventoryItemEvent event,
    Emitter<InventoryState> emit,
  ) async {
    try {
      await _repository.deleteInventoryItem(event.id);
      emit(
        const InventoryOperationSuccess(
          'Vault inventory item deleted successfully.',
        ),
      );
      add(const FetchInventoryEvent());
    } catch (error) {
      emit(InventoryError('Failed to delete vault item: $error'));
    }
  }
}
