import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/api_models.dart';

/// Centralized API Repository implementing all 11 Sections of KaratFlow Backend Specification
class KaratFlowApiRepository {
  KaratFlowApiRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

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
    String role = 'OTHER_EMPLOYEE',
    int page = 1,
    int limit = 100,
  }) async {
    final response = await _api.get(
      ApiEndpoints.employees,
      queryParameters: {'role': role, 'page': page, 'limit': limit},
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((e) => ApiEmployee.fromJson(e as Map<String, dynamic>))
        .toList();
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
  }) async {
    final response = await _api.post(
      ApiEndpoints.employees,
      data: {'name': name, 'email': email, 'phone': phone, 'role': role},
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
  }) async {
    final response = await _api.patch(
      ApiEndpoints.reviewSketch(id),
      data: {
        'status': status,
        if (adminInstructions.isNotEmpty)
          'adminInstructions': adminInstructions,
        if (feedbackAudioUrl != null) 'feedbackAudioUrl': feedbackAudioUrl,
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
    required String status, // 'APPROVED'
    String adminInstructions = '',
  }) async {
    final response = await _api.patch(
      ApiEndpoints.reviewThreeD(id),
      data: {
        'status': status,
        if (adminInstructions.isNotEmpty)
          'adminInstructions': adminInstructions,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiThreeDDesign.fromJson(data);
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

  // ── SECTION 8: Production Floor (/production) ─────────────────────
  Future<List<dynamic>> listPendingProductionFloor() async {
    final response = await _api.get(ApiEndpoints.productionPending);
    return response.data['data'] as List? ?? [];
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

  Future<void> transitionPartNextStage({
    required String partId,
    String notes = '',
  }) async {
    await _api.post(
      ApiEndpoints.productionTransition(partId),
      data: {'notes': notes},
    );
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

  // ── SECTION 9: Worker Tasks (/worker-tasks) ───────────────────────
  Future<List<ApiWorkerTask>> listWorkerTasks() async {
    final response = await _api.get(ApiEndpoints.workerTasks);
    final list = response.data['data'] as List? ?? [];
    return list
        .map((w) => ApiWorkerTask.fromJson(w as Map<String, dynamic>))
        .toList();
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
      data: {'reason': reason},
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

  // ── SECTION 11: Health (/health) ──────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final response = await _api.get(ApiEndpoints.health);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
