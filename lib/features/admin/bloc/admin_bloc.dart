import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_error_handler.dart';
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
    on<CreateEmployeeEvent>(_onCreateEmployee);
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
    on<AdminDirectCreateDesignEvent>(_onDirectCreateDesign);
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
      await _api.createEmployee(
        name: event.member.name,
        email: event.email,
        phone: event.phone,
        role: event.role,
        password: event.password,
        skills: event.skills,
        specialty: event.specialty,
      );
      emit(
        const AdminActionSuccess(
          'Employee onboarded & registered successfully.',
        ),
      );
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      final msg = error.toString().replaceAll('Exception: ', '');
      emit(AdminError('Failed to onboard employee: $msg'));
    }
  }

  Future<void> _onCreateEmployee(
    CreateEmployeeEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      await _api.createEmployee(
        name: event.name,
        email: event.email,
        phone: event.phone,
        role: event.role,
        password: event.password,
        skills: event.skills,
        specialty: event.specialty,
      );
      emit(const AdminActionSuccess('New employee registered successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      final msg = error.toString().replaceAll('Exception: ', '');
      emit(AdminError('Failed to create employee: $msg'));
    }
  }

  Future<void> _onUpdateEmployee(
    UpdateEmployeeEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.updateEmployee(
        id: event.employeeId,
        name: event.name,
        phone: event.phone,
        role: event.role,
        specialty: event.specialty,
        skills: event.skills,
        isActive: event.isActive,
      );
      emit(const AdminActionSuccess('Employee updated successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      final msg = error.toString().replaceAll('Exception: ', '');
      emit(AdminError('Failed to update employee: $msg'));
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
      final stages = await _api.listStages();
      _store.setStages(stages);
      emit(const AdminActionSuccess('Production stage created successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      final msg = ApiErrorHandler.parseMessage(
        error,
        fallback: 'Failed to create stage. Please try again.',
      );
      emit(AdminError(msg));
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
      final stages = await _api.listStages();
      _store.setStages(stages);
      emit(const AdminActionSuccess('Production stage updated successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      final msg = ApiErrorHandler.parseMessage(
        error,
        fallback: 'Failed to update stage. Please try again.',
      );
      emit(AdminError(msg));
    }
  }

  Future<void> _onDeleteStage(
    DeleteStageEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _api.deleteStage(event.stageId);
      final stages = await _api.listStages();
      _store.setStages(stages);
      emit(const AdminActionSuccess('Production stage deleted successfully.'));
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      final msg = ApiErrorHandler.parseMessage(
        error,
        fallback: 'Failed to delete stage. Please try again.',
      );
      emit(AdminError(msg));
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
      final sketch = await _api.uploadSketch(
        designNumber: event.designNumber,
        title: event.title,
        sketchUrl: upload.fileUrl.isNotEmpty ? upload.fileUrl : upload.fileKey,
      );
      try {
        await _api.reviewSketch(
          id: sketch.id,
          status: 'APPROVED',
          adminInstructions: 'Admin Upload - Pre-approved for production',
        );
        _store.approveDesign(sketch.id);
        _store.approveSketch(event.designNumber);
      } catch (_) {}
      emit(
        const AdminActionSuccess('Design uploaded & approved successfully.'),
      );
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
        sketchUrl: upload.fileUrl.isNotEmpty ? upload.fileUrl : upload.fileKey,
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

  Future<void> _onDirectCreateDesign(
    AdminDirectCreateDesignEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    try {
      // Step 1: Upload sketch image to S3 if provided
      String? uploadedImageUrl;
      if (event.sketchBytes != null) {
        final upload = await _api.uploadFile(
          fileName: event.sketchFileName ?? 'sketch.png',
          fileType: _imageContentType(event.sketchFileName ?? 'sketch.png'),
          category: 'sketches',
          bytes: event.sketchBytes!,
        );
        uploadedImageUrl = upload.fileUrl.isNotEmpty
            ? upload.fileUrl
            : upload.fileKey;
      }

      // Step 2: Upload STL/3D file to S3 if provided
      String? uploadedStlUrl;
      if (event.stlBytes != null) {
        final stlUpload = await _api.uploadFile(
          fileName: event.stlFileName ?? 'model.stl',
          fileType: 'application/octet-stream',
          category: 'cad-models',
          bytes: event.stlBytes!,
        );
        uploadedStlUrl = stlUpload.fileUrl.isNotEmpty
            ? stlUpload.fileUrl
            : stlUpload.fileKey;
      }

      // Step 3: Run PaddleOCR extraction on uploaded sketch image (same as CAD flow)
      double? ocrGoldQuantity;
      String? ocrDescription;
      if (uploadedImageUrl != null) {
        try {
          debugPrint(
            '🔍 [Admin BLoC] Running PaddleOCR on uploaded sketch: $uploadedImageUrl',
          );
          final ocrData = await _api.extractCadOcr(imageUrl: uploadedImageUrl);
          debugPrint(
            '✅ [Admin BLoC] PaddleOCR: design=${ocrData.designNumber}, '
            'weight=${ocrData.metalWeightGrams}g, '
            'gems=${ocrData.gemSummary.totalCount}, '
            'making=${ocrData.makingCode}, '
            'confidence=${ocrData.confidenceScore}',
          );
          // Use OCR data to fill any missing fields
          if (ocrData.metalWeightGrams > 0 && event.goldQuantity == null) {
            ocrGoldQuantity = ocrData.metalWeightGrams;
          }
          // Build rich description from OCR extracted specs
          final ocrParts = <String>[];
          if (ocrData.makingCode.isNotEmpty) {
            ocrParts.add('Making: ${ocrData.makingCode}');
          }
          if (ocrData.gemSummary.totalCount > 0) {
            ocrParts.add(
              'Gems: ${ocrData.gemSummary.totalCount} pcs / '
              '${ocrData.gemSummary.totalWeightTw.toStringAsFixed(2)} tw',
            );
          }
          if (ocrData.metalWeightGrams > 0) {
            ocrParts.add('Metal: ${ocrData.metalWeightGrams}g');
          }
          if (ocrParts.isNotEmpty) {
            ocrDescription = 'OCR Extracted: ${ocrParts.join(' · ')}';
          }
        } catch (ocrError) {
          debugPrint(
            '⚠️ [Admin BLoC] OCR extraction failed (non-blocking): $ocrError',
          );
          // OCR failure is non-blocking — design creation continues without it
        }
      }

      // Step 4: Call direct-create endpoint (with OCR-enriched data)
      final description = event.description?.isNotEmpty == true
          ? (ocrDescription != null
                ? '${event.description} · $ocrDescription'
                : event.description)
          : (ocrDescription ?? 'Master design concept sketch');

      final result = await _api.directCreateDesign(
        title: event.title,
        designNumber: event.designNumber,
        imageUrl: uploadedImageUrl,
        bomFileUrl: uploadedImageUrl,
        xtlFileUrl: uploadedStlUrl,
        category: event.category,
        goldQuantity: event.goldQuantity ?? ocrGoldQuantity,
        sizeDimensions: event.sizeDimensions,
        description: description,
      );

      // Step 5: Add to local store for instant UI update
      final design = ApiDomainMapper.threeDDesign(result);
      _store.addDesign(design);
      _store.approveDesign(result.id);
      if (result.sketch != null) {
        _store.approveSketch(result.sketch!.designNumber);
      }

      emit(
        const AdminActionSuccess(
          'Master design created & approved successfully.',
        ),
      );
      add(const FetchAdminDashboardEvent());
    } catch (error) {
      emit(AdminError('Failed to create master design: $error'));
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
