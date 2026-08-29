import 'package:flutter/material.dart';
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
    on<FetchStockInventoryEvent>(_onFetchStockInventory);
    on<UpdateProductStockEvent>(_onUpdateProductStock);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;

  Future<void> _onFetchDashboard(
    FetchAdminDashboardEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      debugPrint(
        '🌐 [Admin BLoC] Fetching real live dashboard & stock data directly from backend API...',
      );
      final employees = await _api.listEmployees();
      final customers = await _api.listCustomers(limit: 100);
      final sketches = await _api.listSketches(limit: 100);
      final stages = await _api.listStages();
      final threeDDesigns = await _api.listThreeDDesigns(limit: 100);
      final orders = await _api.listOrders(limit: 100);

      debugPrint(
        '📦 [Admin BLoC API RES] Received ${employees.length} employees, ${customers.length} customers, ${sketches.length} sketches, ${orders.length} orders, ${threeDDesigns.length} 3D design stock items from API.',
      );

      final team = employees.map(ApiDomainMapper.employee).toList();
      final clients = customers.map(ApiDomainMapper.customer).toList();
      final designs = sketches.map(ApiDomainMapper.sketch).toList();
      final cadTasks = threeDDesigns.map(ApiDomainMapper.cadTask).toList();
      final stockItems = threeDDesigns.map(ApiDomainMapper.stockItem).toList();
      final customerOrders = orders.map(ApiDomainMapper.order).toList();

      _store
        ..setTeam(team)
        ..setClients(clients)
        ..setDesigns(designs)
        ..setStages(stages)
        ..setCadTasks(cadTasks)
        ..setStock(stockItems)
        ..setOrders(customerOrders);

      emit(
        AdminLoaded(
          team: team,
          clients: clients,
          designs: designs,
          directives: const [],
        ),
      );
    } catch (error) {
      debugPrint(
        '❌ [Admin BLoC API ERR] Failed to fetch live dashboard from API: $error',
      );
      emit(AdminError('Failed to fetch dashboard data from API: $error'));
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
        category: 'sketches',
        bytes: event.bytes,
      );
      await _api.uploadSketch(
        designNumber: event.designNumber,
        title: event.title,
        sketchUrl: upload.fileKey,
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
        category: 'sketches',
        bytes: event.bytes,
      );
      await _api.reuploadSketch(
        id: event.sketchId,
        title: event.title,
        sketchUrl: upload.fileKey,
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
    } catch (error) {
      emit(AdminError('Failed to approve sketch: $error'));
    }
  }

  Future<void> _onReviewSketchDirective(
    ReviewSketchDirectiveEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      String? audioUrl;
      String? imageUrl;
      final audioBytes = event.audioBytes;
      final audioFileName = event.audioFileName;
      if (audioBytes != null &&
          audioBytes.isNotEmpty &&
          audioFileName != null &&
          audioFileName.isNotEmpty) {
        final upload = await _api.uploadFile(
          fileName: audioFileName,
          fileType: 'audio/mp4',
          category: 'audio-instructions',
          bytes: audioBytes,
        );
        audioUrl = upload.fileUrl;
      }

      final imageBytes = event.imageBytes;
      final imageFileName = event.imageFileName;
      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          imageFileName != null &&
          imageFileName.isNotEmpty) {
        final upload = await _api.uploadFile(
          fileName: imageFileName,
          fileType: _imageContentType(imageFileName),
          category: 'directive-images',
          bytes: imageBytes,
        );
        imageUrl = upload.fileUrl;
      }

      final cleanInstructions = event.instructions.trim().isNotEmpty
          ? event.instructions.trim()
          : audioUrl != null && imageUrl != null
          ? 'Voice and Image Directive Attached'
          : audioUrl != null
          ? 'Voice Directive Note Attached'
          : imageUrl != null
          ? 'Image Directive Attached'
          : 'Directive Note';

      await _api.reviewSketch(
        id: event.sketchId,
        status: 'CHANGES_REQUESTED',
        adminInstructions: cleanInstructions,
        feedbackAudioUrl: audioUrl,
        feedbackImageUrl: imageUrl,
      );

      emit(const AdminActionSuccess('Sketch changes requested successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to send directive: $error'));
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

  Future<void> _onUnsupportedDirective(
    SendDirectiveEvent event,
    Emitter<AdminState> emit,
  ) async {
    String? audioUrl;
    String? imageUrl;
    final bytes = event.audioBytes;
    final fileName = event.audioFileName;
    if (bytes != null && bytes.isNotEmpty && fileName != null) {
      try {
        final upload = await _api.uploadFile(
          fileName: fileName,
          fileType: 'audio/mp4',
          category: 'audio-instructions',
          bytes: bytes,
        );
        audioUrl = upload.fileUrl;
      } catch (error) {
        emit(AdminError('Failed to upload voice directive: $error'));
        return;
      }
    }

    final imageBytes = event.imageBytes;
    final imageFileName = event.imageFileName;
    if (imageBytes != null && imageBytes.isNotEmpty && imageFileName != null) {
      try {
        final upload = await _api.uploadFile(
          fileName: imageFileName,
          fileType: _imageContentType(imageFileName),
          category: 'directive-images',
          bytes: imageBytes,
        );
        imageUrl = upload.fileUrl;
      } catch (error) {
        emit(AdminError('Failed to upload directive image: $error'));
        return;
      }
    }

    try {
      final directive = await _api.dispatchDirective(
        title: 'Directive to ${event.recipient}',
        targetType: _directiveTargetType(event.recipient),
        instruction: event.directive,
        audioUrl: audioUrl,
        imageUrl: imageUrl,
      );
      _store.upsertApiDirective(directive);
      emit(
        AdminActionSuccess(
          'Directive sent to ${event.recipient} successfully.',
        ),
      );
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to send directive: $error'));
    }
  }

  Future<void> _onFetchStockInventory(
    FetchStockInventoryEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      debugPrint(
        '🌐 [Admin BLoC] Fetching stock inventory items directly from API /three-d-designs...',
      );
      final threeDDesigns = await _api.listThreeDDesigns(limit: 100);
      final stockItems = threeDDesigns.map(ApiDomainMapper.stockItem).toList();
      debugPrint(
        '📦 [Admin BLoC Stock API RES] ${stockItems.length} real stock items fetched directly from API.',
      );
      _store.setStock(stockItems);
    } catch (error) {
      debugPrint(
        '❌ [Admin BLoC Stock API ERR] Failed to fetch stock inventory: $error',
      );
    }
  }

  Future<void> _onUpdateProductStock(
    UpdateProductStockEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      final updatedDesign = await _api.updateThreeDProductStock(
        designId: event.designId,
        stock: event.stock,
        stockStatus: event.stockStatus,
        price: event.price,
        title: event.title,
        category: event.category,
        goldQuantity: event.goldQuantity,
        totalWeight: event.totalWeight,
        description: event.description,
        imageUrl: event.imageUrl,
      );
      final updatedStockItem = ApiDomainMapper.stockItem(updatedDesign);
      final stockItems = [..._store.stock];
      final stockIndex = stockItems.indexWhere(
        (item) => item.id == updatedStockItem.id,
      );
      if (stockIndex >= 0) {
        stockItems[stockIndex] = updatedStockItem;
      } else {
        stockItems.insert(0, updatedStockItem);
      }
      _store.setStock(stockItems);

      emit(
        AdminActionSuccess(
          'Stock updated to ${updatedStockItem.totalAvailable.toStringAsFixed(0)} '
          '${updatedStockItem.unit}.',
        ),
      );
      add(const FetchStockInventoryEvent());
    } catch (error) {
      emit(AdminError('Failed to update product stock: $error'));
    }
  }

  String _imageContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/png';
  }

  String _directiveTargetType(String recipient) {
    final normalized = recipient.toLowerCase();
    if (normalized.contains('cad') || normalized.contains('3d')) {
      return 'THREE_D_DESIGNER';
    }
    if (normalized.contains('sketch') || normalized.contains('raw')) {
      return 'SKETCHER';
    }
    if (normalized.contains('artisan') || normalized.contains('goldsmith')) {
      return 'ALL_ARTISANS';
    }
    return 'ALL_ARTISANS';
  }
}
