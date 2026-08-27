import 'dart:typed_data';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/api_models.dart';

/// Centralized API Repository implementing all 11 Sections of KaratFlow Backend Specification
class KaratFlowApiRepository {
  KaratFlowApiRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Map<String, dynamic> _dataMap(dynamic responseData) {
    if (responseData is! Map || responseData['data'] is! Map) {
      throw const FormatException('API response data must be an object.');
    }
    return Map<String, dynamic>.from(responseData['data'] as Map);
  }

  List<dynamic> _dataList(dynamic responseData) {
    if (responseData is! Map || responseData['data'] is! List) {
      throw const FormatException('API response data must be a list.');
    }
    return List<dynamic>.from(responseData['data'] as List);
  }

  // ── SECTION 1: Auth & Token Management (/auth) ────────────────────
  Future<AuthResponseData> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResponseData.fromJson(data);
  }

  Future<AuthResponseData> refreshToken(String refreshToken) async {
    final response = await _api.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return AuthResponseData.fromJson(data);
  }

  Future<ApiUser> getProfile() async {
    final response = await _api.get(ApiEndpoints.authMe);
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiUser.fromJson(data);
  }

  // ── SECTION 2: Employee & User Management (/employees) ───────────
  Future<List<ApiEmployee>> listEmployees({
    String? role,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'limit': limit};
      if (role != null && role.isNotEmpty) {
        query['role'] = role;
      }
      final response = await _api.get(
        ApiEndpoints.employees,
        queryParameters: query,
      );
      final list = response.data['data'] as List? ?? [];
      return list
          .map((e) => ApiEmployee.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Return empty list if current role lacks permission to query /employees
      return [];
    }
  }

  Future<ApiEmployee> getEmployeeDetails(String id) async {
    final response = await _api.get(ApiEndpoints.employeeDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiEmployee.fromJson(data);
  }

  Future<ApiEmployee> onboardEmployee({
    required String name,
    required String email,
    required String phone,
    String role = 'OTHER_EMPLOYEE',
    String specialty = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.employees,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        if (specialty.isNotEmpty) 'specialty': specialty,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiEmployee.fromJson(data);
  }

  Future<ApiEmployee> updateEmployeeRole({
    required String id,
    required String role,
    bool isActive = true,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.updateEmployee(id),
      data: {'role': role, 'isActive': isActive},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiEmployee.fromJson(data);
  }

  // ── SECTION 3: Customers & Clients (/customers) ───────────────────
  Future<List<ApiCustomer>> listCustomers({
    String search = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'limit': limit};
      if (search.isNotEmpty) query['search'] = search;

      final response = await _api.get(
        ApiEndpoints.customers,
        queryParameters: query,
      );
      final list = response.data['data'] as List? ?? [];
      return list
          .map((c) => ApiCustomer.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Return empty list if current role lacks permission to query /customers
      return [];
    }
  }

  Future<ApiCustomer> getCustomerDetails(String id) async {
    final response = await _api.get(ApiEndpoints.customerDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiCustomer.fromJson(data);
  }

  Future<ApiCustomer> registerCustomer({
    required String name,
    required String city,
    required String contactPerson,
    required String phone,
    String email = '',
    double creditLimitLakhs = 50.0,
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.customers,
      data: {
        'name': name,
        'city': city,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': email,
        'creditLimitLakhs': creditLimitLakhs,
        'notes': notes,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiCustomer.fromJson(data);
  }

  Future<ApiCustomer> editCustomerCredit({
    required String id,
    required double creditLimitLakhs,
    String notes = '',
  }) async {
    final response = await _api.patch(
      ApiEndpoints.updateCustomer(id),
      data: {
        'creditLimitLakhs': creditLimitLakhs,
        if (notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiCustomer.fromJson(data);
  }

  // ── SECTION 4: Dynamic Production Stages (/stages) ───────────────
  Future<List<ApiStage>> listStages() async {
    final response = await _api.get(ApiEndpoints.stages);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((s) => ApiStage.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<ApiStage> createStage({
    required String name,
    required int stageNumber,
    String description = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.stages,
      data: {
        'name': name,
        'stageNumber': stageNumber,
        'description': description,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiStage.fromJson(data);
  }

  Future<ApiStage> updateStage({
    required String id,
    required String name,
    bool isActive = true,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.stageDetails(id),
      data: {'name': name, 'isActive': isActive},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiStage.fromJson(data);
  }

  Future<void> deleteStage(String id) async {
    await _api.delete(ApiEndpoints.stageDetails(id));
  }

  // ── SECTION 5: Raw Pencil Sketches (/sketches) ────────────────────
  Future<List<ApiSketch>> listSketches({
    String status = '',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      ApiEndpoints.sketches,
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((s) => ApiSketch.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<ApiSketch> getSketchDetails(String id) async {
    final response = await _api.get(ApiEndpoints.sketchDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiSketch.fromJson(data);
  }

  Future<ApiSketch> uploadSketch({
    required String designNumber,
    required String title,
    required String sketchUrl,
  }) async {
    final response = await _api.post(
      ApiEndpoints.uploadSketch,
      data: {
        'designNumber': designNumber,
        'title': title,
        'sketchUrl': sketchUrl,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiSketch.fromJson(data);
  }

  Future<ApiSketch> reuploadSketch({
    required String id,
    required String title,
    required String sketchUrl,
  }) async {
    final response = await _api.put(
      ApiEndpoints.reuploadSketch(id),
      data: {'title': title, 'sketchUrl': sketchUrl},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiSketch.fromJson(data);
  }

  Future<ApiSketch> reviewSketch({
    required String id,
    required String status, // 'APPROVED' or 'REJECTED'
    String adminInstructions = '',
    String? feedbackAudioUrl,
    String? feedbackImageUrl,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.reviewSketch(id),
      data: {
        'status': status,
        if (adminInstructions.isNotEmpty)
          'adminInstructions': adminInstructions,
        'feedbackAudioUrl': ?feedbackAudioUrl,
        'feedbackImageUrl': ?feedbackImageUrl,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiSketch.fromJson(data);
  }

  // ── SECTION 6: 3D CAD / CAM Designs (/three-d-designs) ───────────
  Future<List<ApiThreeDDesign>> listThreeDDesigns({
    String status = '',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      ApiEndpoints.threeDDesigns,
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((t) => ApiThreeDDesign.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<ApiThreeDDesign> getThreeDDesignDetails(String id) async {
    final response = await _api.get(ApiEndpoints.threeDDesignDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiThreeDDesign.fromJson(data);
  }

  Future<ApiThreeDDesign> uploadThreeDDesign({
    required String sketchId,
    required String xtlFileUrl,
    required String bomFileUrl,
    required int gemQuantity,
    required double goldQuantity,
    required double totalWeight,
    required double volumeMm3,
    required String sizeDimensions,
  }) async {
    final response = await _api.post(
      ApiEndpoints.uploadThreeD,
      data: {
        'sketchId': sketchId,
        'xtlFileUrl': xtlFileUrl,
        'bomFileUrl': bomFileUrl,
        'gemQuantity': gemQuantity,
        'goldQuantity': goldQuantity,
        'totalWeight': totalWeight,
        'volumeMm3': volumeMm3,
        'sizeDimensions': sizeDimensions,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiThreeDDesign.fromJson(data);
  }

  Future<ApiThreeDDesign> reviewThreeDDesign({
    required String id,
    required String status, // 'APPROVED' | 'REJECTED'
    String adminInstructions = '',
    String? feedbackAudioUrl,
    String? feedbackImageUrl,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (adminInstructions.isNotEmpty) {
      body['adminInstructions'] = adminInstructions;
    }
    if (feedbackAudioUrl != null && feedbackAudioUrl.isNotEmpty) {
      body['feedbackAudioUrl'] = feedbackAudioUrl;
    }
    if (feedbackImageUrl != null && feedbackImageUrl.isNotEmpty) {
      body['feedbackImageUrl'] = feedbackImageUrl;
    }

    final response = await _api.patch(
      ApiEndpoints.reviewThreeD(id),
      data: body,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiThreeDDesign.fromJson(data);
  }

  /// PATCH /three-d-designs/{designId}/product - Update product catalog record & stock details
  Future<ApiThreeDDesign> updateThreeDProductStock({
    required String designId,
    int? stock,
    String? stockStatus,
    double? price,
    String? title,
    String? category,
    double? goldQuantity,
    double? totalWeight,
    String? description,
    String? imageUrl,
  }) async {
    final payload = <String, dynamic>{
      'stock': ?stock,
      if (stockStatus?.isNotEmpty == true) 'stockStatus': stockStatus,
      'price': ?price,
      if (title?.isNotEmpty == true) 'title': title,
      if (category?.isNotEmpty == true) 'category': category,
      'goldQuantity': ?goldQuantity,
      'totalWeight': ?totalWeight,
      if (description?.isNotEmpty == true) 'description': description,
      if (imageUrl?.isNotEmpty == true) 'imageUrl': imageUrl,
    };

    final response = await _api.patch(
      ApiEndpoints.updateThreeDProduct(designId),
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiThreeDDesign.fromJson(data);
  }

  Future<ApiThreeDDesign> reuploadThreeDDesign({
    required String id,
    required String xtlFileUrl,
    required String bomFileUrl,
    required double totalWeight,
  }) async {
    final response = await _api.put(
      ApiEndpoints.reuploadThreeD(id),
      data: {
        'xtlFileUrl': xtlFileUrl,
        'bomFileUrl': bomFileUrl,
        'totalWeight': totalWeight,
      },
    );
    return ApiThreeDDesign.fromJson(_dataMap(response.data));
  }

  // ── SECTION 7: Orders (/orders) ───────────────────────────────────
  Future<List<ApiOrder>> listOrders({
    String status = '',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      ApiEndpoints.orders,
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((o) => ApiOrder.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<ApiOrder> getOrderDetails(String id) async {
    final response = await _api.get(ApiEndpoints.orderDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiOrder.fromJson(data);
  }

  Future<ApiOrderTracking> trackOrder(String orderNumber) async {
    final response = await _api.get(ApiEndpoints.orderTrack(orderNumber));
    return ApiOrderTracking.fromJson(_dataMap(response.data));
  }

  Future<ApiOrder> createMultiDesignOrder({
    required String customerId,
    required String dueDate,
    String specialInstructions = '',
    required List<Map<String, dynamic>> parts,
  }) async {
    final response = await _api.post(
      ApiEndpoints.orders,
      data: {
        'customerId': customerId,
        'dueDate': dueDate,
        'specialInstructions': specialInstructions,
        'parts': parts,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiOrder.fromJson(data);
  }

  Future<void> checkoutOrder(String orderId) async {
    await _api.post(ApiEndpoints.checkoutOrder(orderId));
  }

  Future<List<ApiOrderPart>> addOrderParts({
    required String orderId,
    required List<Map<String, dynamic>> parts,
  }) async {
    final response = await _api.post(
      ApiEndpoints.addOrderParts(orderId),
      data: {'parts': parts},
    );
    return _dataList(response.data)
        .map((part) => ApiOrderPart.fromJson(part as Map<String, dynamic>))
        .toList(growable: false);
  }

  // ── SECTION 8: Production Floor (/production) ─────────────────────
  Future<List<dynamic>> listPendingProductionFloor() async {
    try {
      final response = await _api.get(ApiEndpoints.productionPending);
      return response.data['data'] as List? ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> assignPartToArtisan({
    required List<String> partIds,
    required String stageId,
    required String assignedEmployeeId,
    String instructions = '',
  }) async {
    await _api.post(
      ApiEndpoints.productionAssign,
      data: {
        'partIds': partIds,
        'stageId': stageId,
        'assignedEmployeeId': assignedEmployeeId,
        'instructions': instructions,
      },
    );
  }

  Future<Map<String, dynamic>?> transitionPartNextStage({
    required String partId,
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.productionTransition(partId),
      data: {'notes': notes},
    );
    return response.data['data'] as Map<String, dynamic>?;
  }

  Future<void> rollbackPartStage({
    required String partId,
    required String targetStageId,
    required String reason,
  }) async {
    await _api.post(
      ApiEndpoints.productionRollback(partId),
      data: {'targetStageId': targetStageId, 'reason': reason},
    );
  }

  Future<void> blockOrderPart({
    required String partId,
    required String reason,
  }) async {
    await _api.post(
      ApiEndpoints.productionBlock(partId),
      data: {'reason': reason},
    );
  }

  Future<void> unblockOrderPart({required String partId, String? notes}) async {
    await _api.post(
      ApiEndpoints.productionUnblock(partId),
      data: {if (notes?.isNotEmpty == true) 'notes': notes},
    );
  }

  // ── SECTION 9: Worker Tasks (/worker-tasks) ───────────────────────
  Future<List<ApiWorkerTask>> listWorkerTasks() async {
    try {
      final response = await _api.get(ApiEndpoints.workerTasks);
      final list = response.data['data'] as List? ?? [];
      return list
          .map((w) => ApiWorkerTask.fromJson(w as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> startWorkerTask(String id) async {
    await _api.post(ApiEndpoints.startWorkerTask(id));
  }

  Future<void> completeWorkerTask(String id) async {
    await _api.post(ApiEndpoints.completeWorkerTask(id));
  }

  Future<void> reportWorkerTaskFailure(String id, String reason) async {
    await _api.post(
      ApiEndpoints.reportWorkerTaskFailure(id),
      data: {'failureReason': reason, 'reason': reason},
    );
  }

  // ── SECTION 10: AWS S3 Cloud Storage (/storage) ──────────────────
  Future<ApiPresignedUrl> getPresignedUploadUrl({
    required String fileName,
    required String fileType,
    required String folder,
  }) async {
    final response = await _api.post(
      ApiEndpoints.storageUploadUrl,
      data: {'fileName': fileName, 'fileType': fileType, 'folder': folder},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiPresignedUrl.fromJson(data);
  }

  Future<ApiPresignedUrl> uploadFile({
    required String fileName,
    required String fileType,
    required String folder,
    required Uint8List bytes,
  }) async {
    final signedUrl = await getPresignedUploadUrl(
      fileName: fileName,
      fileType: fileType,
      folder: folder,
    );
    if (signedUrl.uploadUrl.isEmpty || signedUrl.fileUrl.isEmpty) {
      throw const FormatException(
        'Storage API returned an invalid upload URL.',
      );
    }
    await _api.putAbsoluteBytes(
      signedUrl.uploadUrl,
      bytes: bytes,
      contentType: fileType,
    );
    return signedUrl;
  }

  Future<ApiPresignedDownloadUrl> getPresignedDownloadUrl(
    String fileKey,
  ) async {
    final response = await _api.get(
      ApiEndpoints.storageDownloadUrl,
      queryParameters: {'fileKey': fileKey},
    );
    return ApiPresignedDownloadUrl.fromJson(_dataMap(response.data));
  }

  Future<Uint8List> downloadStoredFile(String storedUrl) async {
    final uri = Uri.tryParse(storedUrl.trim());
    if (uri == null || !uri.hasScheme) {
      throw const FormatException('The stored file URL is invalid.');
    }

    String targetUrl = storedUrl;
    final fileKey = _storageFileKey(uri);
    if (fileKey != null) {
      final signed = await getPresignedDownloadUrl(fileKey);
      if (signed.downloadUrl.isEmpty) {
        throw const FormatException('Storage API returned no download URL.');
      }
      targetUrl = signed.downloadUrl;
    }

    return _api.getAbsoluteBytes(targetUrl);
  }

  String? _storageFileKey(Uri uri) {
    final isSigned = uri.queryParameters.keys.any(
      (key) => key.toLowerCase() == 'x-amz-signature',
    );
    if (isSigned) return null;

    final proxyKey =
        uri.queryParameters['fileKey'] ?? uri.queryParameters['key'];
    if (proxyKey != null && proxyKey.trim().isNotEmpty) {
      return proxyKey.trim();
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('amazonaws.com') && !host.contains('s3')) return null;
    final key = uri.pathSegments.join('/').trim();
    return key.isEmpty ? null : key;
  }

  // ── SECTION 11: Master Raw Materials & Preset Pricing Matrix ────
  Future<List<ApiMaterial>> listMaterials({
    String? category,
    String? search,
  }) async {
    final response = await _api.get(
      ApiEndpoints.materials,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final list = _dataList(response.data);
    return list
        .map((e) => ApiMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiMaterial> updateMaterialRate(
    String id,
    double presetPricePerUnit,
  ) async {
    final response = await _api.patch(
      ApiEndpoints.updateMaterialRate(id),
      data: {'presetPricePerUnit': presetPricePerUnit},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiMaterial.fromJson(data);
  }

  Future<ApiMaterial> createMaterial({
    required String code,
    required String name,
    required String category,
    required String specification,
    required String unit,
    required double presetPricePerUnit,
    String description = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.materials,
      data: {
        'code': code,
        'name': name,
        'category': category,
        'specification': specification,
        'unit': unit,
        'presetPricePerUnit': presetPricePerUnit,
        'description': description,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiMaterial.fromJson(data);
  }

  // ── SECTION 12: Vault & Safe Inventory Stock ──────────────────────
  Future<ApiInventoryResponse> getInventory({
    String? category,
    String? search,
  }) async {
    final response = await _api.get(
      ApiEndpoints.inventory,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiInventoryResponse.fromJson(data);
  }

  Future<ApiInventoryItem> addInventoryItem({
    required String name,
    required String category,
    required String purity,
    required double totalStock,
    double reservedWip = 0.0,
    required double freeBalance,
    required String unit,
    required String location,
  }) async {
    final response = await _api.post(
      ApiEndpoints.inventory,
      data: {
        'name': name,
        'category': category,
        'purity': purity,
        'totalStock': totalStock,
        'reservedWip': reservedWip,
        'freeBalance': freeBalance,
        'unit': unit,
        'location': location,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiInventoryItem.fromJson(data);
  }

  // ── SECTION 13: Floor Directives & Voice Notes ────────────────────
  Future<List<ApiDirective>> listDirectives({
    String? status,
    String? search,
  }) async {
    final response = await _api.get(
      ApiEndpoints.directives,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final list = _dataList(response.data);
    return list
        .map((e) => ApiDirective.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiDirective> dispatchDirective({
    required String title,
    required String targetType,
    required String instruction,
    String? audioUrl,
    String? imageUrl,
  }) async {
    final response = await _api.post(
      ApiEndpoints.directives,
      data: {
        'title': title,
        'targetType': targetType,
        'instruction': instruction,
        if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiDirective.fromJson(data);
  }

  Future<ApiDirective> acknowledgeDirective(String id) async {
    final response = await _api.patch(
      ApiEndpoints.acknowledgeDirective(id),
      data: <String, dynamic>{},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiDirective.fromJson(data);
  }

  // ── SECTION 14: Health (/health) ──────────────────────────────────
  Future<ApiHealthStatus> checkHealth() async {
    final response = await _api.get(ApiEndpoints.health);
    return ApiHealthStatus.fromJson(_dataMap(response.data));
  }
}
