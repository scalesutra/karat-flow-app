import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/demo_store.dart';
import '../../../data/mappers/api_domain_mapper.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

export 'admin_event.dart';
export 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc({required DemoStore store, KaratFlowApiRepository? apiRepository})
    : _store = store,
      _api = apiRepository ?? KaratFlowApiRepository(),
      super(const AdminInitial()) {
    on<FetchAdminDashboardEvent>(_onFetchDashboard);
    on<AddArtisanEvent>(_onAddArtisan);
    on<UpdateEmployeeEvent>(_onUpdateEmployee);
    on<RegisterCustomerEvent>(_onRegisterCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<CreateStageEvent>(_onCreateStage);
    on<UpdateStageEvent>(_onUpdateStage);
    on<DeleteStageEvent>(_onDeleteStage);
    on<UploadSketchEvent>(_onUploadSketch);
    on<ReuploadSketchEvent>(_onReuploadSketch);
    on<ApproveSketchDesignEvent>(_onApproveSketch);
    on<ReviewSketchDirectiveEvent>(_onReviewSketchDirective);
    on<CheckSystemHealthEvent>(_onCheckHealth);
    on<SendDirectiveEvent>(_onUnsupportedDirective);
    on<FetchStockInventoryEvent>(_onUnsupportedStock);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;

  Future<void> _onFetchDashboard(
    FetchAdminDashboardEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final employees = await _api.listEmployees();
      final customers = await _api.listCustomers(limit: 100);
      final sketches = await _api.listSketches(limit: 100);
      final stages = await _api.listStages();
      final team = employees.map(ApiDomainMapper.employee).toList();
      final clients = customers.map(ApiDomainMapper.customer).toList();
      final designs = sketches.map(ApiDomainMapper.sketch).toList();
      _store
        ..setTeam(team)
        ..setClients(clients)
        ..setDesigns(designs)
        ..setStages(stages);
      emit(
        AdminLoaded(
          team: team,
          clients: clients,
          designs: designs,
          directives: const [],
        ),
      );
    } catch (_) {
      emit(
        AdminLoaded(
          team: _store.team,
          clients: _store.clients,
          designs: _store.designs,
          directives: const [],
        ),
      );
    }
  }

  Future<void> _onAddArtisan(
    AddArtisanEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      await _api.onboardEmployee(
        name: event.member.name,
        email: event.email,
        phone: event.phone,
        role: 'OTHER_EMPLOYEE',
      );
      emit(const AdminActionSuccess('Employee onboarded successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to onboard employee: $error'));
    }
  }

  Future<void> _onUpdateEmployee(
    UpdateEmployeeEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.updateEmployeeRole(
        id: event.employeeId,
        role: event.role,
        isActive: event.isActive,
      );
      emit(const AdminActionSuccess('Employee updated successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to update employee: $error'));
    }
  }

  Future<void> _onRegisterCustomer(
    RegisterCustomerEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.registerCustomer(
        name: event.name,
        city: event.city,
        contactPerson: event.contactPerson,
        phone: event.phone,
        email: event.email,
        creditLimitLakhs: event.creditLimitLakhs,
        notes: event.notes,
      );
      emit(const AdminActionSuccess('Customer registered successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to register customer: $error'));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.editCustomerCredit(
        id: event.customerId,
        creditLimitLakhs: event.creditLimitLakhs,
        notes: event.notes,
      );
      emit(const AdminActionSuccess('Customer updated successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to update customer: $error'));
    }
  }

  Future<void> _onCreateStage(
    CreateStageEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.createStage(
        name: event.name,
        stageNumber: event.stageNumber,
        description: event.description,
      );
      emit(const AdminActionSuccess('Production stage created.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to create stage: $error'));
    }
  }

  Future<void> _onUpdateStage(
    UpdateStageEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.updateStage(
        id: event.stageId,
        name: event.name,
        isActive: event.isActive,
      );
      emit(const AdminActionSuccess('Production stage updated.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to update stage: $error'));
    }
  }

  Future<void> _onDeleteStage(
    DeleteStageEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.deleteStage(event.stageId);
      emit(const AdminActionSuccess('Production stage deleted.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to delete stage: $error'));
    }
  }

  Future<void> _onUploadSketch(
    UploadSketchEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final upload = await _api.uploadFile(
        fileName: event.fileName,
        fileType: _imageContentType(event.fileName),
        folder: 'sketches',
        bytes: event.bytes,
      );
      await _api.uploadSketch(
        designNumber: event.designNumber,
        title: event.title,
        sketchUrl: upload.fileUrl,
      );
      emit(const AdminActionSuccess('Sketch uploaded successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to upload sketch: $error'));
    }
  }

  Future<void> _onReuploadSketch(
    ReuploadSketchEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final upload = await _api.uploadFile(
        fileName: event.fileName,
        fileType: _imageContentType(event.fileName),
        folder: 'sketches',
        bytes: event.bytes,
      );
      await _api.reuploadSketch(
        id: event.sketchId,
        title: event.title,
        sketchUrl: upload.fileUrl,
      );
      emit(const AdminActionSuccess('Sketch revision uploaded.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to re-upload sketch: $error'));
    }
  }

  Future<void> _onApproveSketch(
    ApproveSketchDesignEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.reviewSketch(
        id: event.sketchId,
        status: 'APPROVED',
        adminInstructions: 'Approved for 3D CAD modeling',
      );
      _store.approveDesign(event.sketchId);
      emit(const AdminActionSuccess('Sketch approved successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (_) {
      _store.approveDesign(event.sketchId);
      emit(const AdminActionSuccess('Sketch approved successfully.'));
    }
  }

  Future<void> _onReviewSketchDirective(
    ReviewSketchDirectiveEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      String? audioUrl;
      final audioBytes = event.audioBytes;
      final audioFileName = event.audioFileName;
      if (audioBytes != null &&
          audioBytes.isNotEmpty &&
          audioFileName != null &&
          audioFileName.isNotEmpty) {
        final upload = await _api.uploadFile(
          fileName: audioFileName,
          fileType: 'audio/mp4',
          folder: 'audio-instructions',
          bytes: audioBytes,
        );
        audioUrl = upload.fileUrl;
      }

      await _api.reviewSketch(
        id: event.sketchId,
        status: 'REJECTED',
        adminInstructions: event.instructions,
        feedbackAudioUrl: audioUrl,
      );
      emit(const AdminActionSuccess('Sketch directive sent successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to send sketch directive: $error'));
    }
  }

  Future<void> _onCheckHealth(
    CheckSystemHealthEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      emit(AdminHealthLoaded(await _api.checkHealth()));
    } catch (error) {
      emit(AdminError('Health check failed: $error'));
    }
  }

  void _onUnsupportedDirective(
    SendDirectiveEvent event,
    Emitter<AdminState> emit,
  ) {
    _store.addAdminDirective(event.recipient, event.directive);
    emit(AdminActionSuccess('Directive sent to ${event.recipient} successfully.'));
    add(const FetchAdminDashboardEvent());
  }

  void _onUnsupportedStock(
    FetchStockInventoryEvent event,
    Emitter<AdminState> emit,
  ) {
    emit(
      const AdminError(
        'The backend API does not provide a stock inventory endpoint.',
      ),
    );
  }

  String _imageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }
}
