import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/karatflow_api_repository.dart';
import 'materials_event.dart';
import 'materials_state.dart';

export 'materials_event.dart';
export 'materials_state.dart';

class MaterialsBloc extends Bloc<MaterialsEvent, MaterialsState> {
  MaterialsBloc({KaratFlowApiRepository? repository})
    : _repository = repository ?? KaratFlowApiRepository(),
      super(const MaterialsInitial()) {
    on<FetchMaterialsEvent>(_onFetchMaterials);
    on<UpdateMaterialRateEvent>(_onUpdateRate);
    on<CreateMaterialEvent>(_onCreateMaterial);
  }

  final KaratFlowApiRepository _repository;

  Future<void> _onFetchMaterials(
    FetchMaterialsEvent event,
    Emitter<MaterialsState> emit,
  ) async {
    emit(const MaterialsLoading());
    try {
      final materials = await _repository.listMaterials(
        category: event.category,
        search: event.search,
      );
      emit(MaterialsLoaded(materials: materials));
    } catch (error) {
      emit(MaterialsError('Failed to fetch materials: $error'));
    }
  }

  Future<void> _onUpdateRate(
    UpdateMaterialRateEvent event,
    Emitter<MaterialsState> emit,
  ) async {
    try {
      await _repository.updateMaterialRate(event.id, event.presetPricePerUnit);
      emit(
        const MaterialsOperationSuccess('Preset rate updated successfully.'),
      );
      add(const FetchMaterialsEvent());
    } catch (error) {
      emit(MaterialsError('Failed to update rate: $error'));
    }
  }

  Future<void> _onCreateMaterial(
    CreateMaterialEvent event,
    Emitter<MaterialsState> emit,
  ) async {
    try {
      await _repository.createMaterial(
        code: event.code,
        name: event.name,
        category: event.category,
        specification: event.specification,
        unit: event.unit,
        presetPricePerUnit: event.presetPricePerUnit,
        description: event.description,
      );
      emit(
        const MaterialsOperationSuccess('Raw material created successfully.'),
      );
      add(const FetchMaterialsEvent());
    } catch (error) {
      emit(MaterialsError('Failed to create material: $error'));
    }
  }
}
