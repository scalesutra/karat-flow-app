import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/api_models.dart';

/// Centralized API Repository implementing all 11 Sections of KaratFlow Backend Specification
class KaratFlowApiRepository {
  KaratFlowApiRepository({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  ApiClient get apiClient => _api;

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
    String? search,
    String? role,
    bool? isActive,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (role != null && role.trim().isNotEmpty) {
        query['role'] = role.trim();
      }
      if (isActive != null) {
        query['isActive'] = isActive ? 'true' : 'false';
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

  Future<ApiEmployee> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String role,
    String? password,
    List<String>? skills,
    String? specialty,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role.trim(),
      if (password != null && password.trim().isNotEmpty)
        'password': password.trim(),
      if (skills != null && skills.isNotEmpty) 'skills': skills,
      if (specialty != null && specialty.trim().isNotEmpty)
        'specialty': specialty.trim(),
    };

    final response = await _api.post(ApiEndpoints.employees, data: payload);
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiEmployee.fromJson(data);
  }

  Future<ApiEmployee> onboardEmployee({
    required String name,
    required String email,
    required String phone,
    String role = 'CRAFTSMAN',
    String specialty = '',
    List<String>? skills,
    String? password,
  }) => createEmployee(
    name: name,
    email: email,
    phone: phone,
    role: role,
    password: password,
    skills: skills,
    specialty: specialty,
  );

  Future<ApiEmployee> updateEmployee({
    required String id,
    String? name,
    String? phone,
    String? role,
    String? specialty,
    List<String>? skills,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      if (specialty != null) 'specialty': specialty.trim(),
      'skills': ?skills,
      'isActive': ?isActive,
    };

    final response = await _api.patch(
      ApiEndpoints.updateEmployee(id),
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiEmployee.fromJson(data);
  }

  Future<ApiEmployee> updateEmployeeRole({
    required String id,
    required String role,
    bool isActive = true,
  }) => updateEmployee(id: id, role: role, isActive: isActive);

  Future<List<ApiEmployeeAssignment>> getEmployeeAssignments(
    String id, {
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null && status.trim().isNotEmpty) {
        query['status'] = status.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      final response = await _api.get(
        ApiEndpoints.employeeAssignments(id),
        queryParameters: query,
      );
      final list = response.data['data'] as List? ?? [];
      return list
          .map((e) => ApiEmployeeAssignment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
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
    String? description,
  }) async {
    final response = await _api.post(
      ApiEndpoints.stages,
      data: {
        'name': name.trim(),
        'stageNumber': stageNumber,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiStage.fromJson(data);
  }

  Future<ApiStage> updateStage({
    required String id,
    String? name,
    int? stageNumber,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (stageNumber != null) body['stageNumber'] = stageNumber;
    if (description != null) body['description'] = description.trim();
    if (isActive != null) body['isActive'] = isActive;
    final response = await _api.patch(
      ApiEndpoints.stageDetails(id),
      data: body,
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
    String search = '',
    String designerId = '',
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get(
      ApiEndpoints.sketches,
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
        if (designerId.isNotEmpty) 'designerId': designerId,
        'page': page,
        'limit': limit,
      },
    );
    final list = response.data['data'] as List? ?? [];
    return list
        .map((s) => ApiSketch.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApiSketch>> listAllSketches({
    String status = '',
    String search = '',
    String designerId = '',
    int maxTotal = 2000,
  }) async {
    final all = <ApiSketch>[];
    int page = 1;
    const pageSize = 100;
    while (all.length < maxTotal) {
      try {
        final chunk = await listSketches(
          status: status,
          search: search,
          designerId: designerId,
          page: page,
          limit: pageSize,
        );
        if (chunk.isEmpty) break;
        all.addAll(chunk);
        if (chunk.length < pageSize) break;
        page++;
      } catch (_) {
        break;
      }
    }
    return all;
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
    try {
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
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('404') ||
          errStr.contains('403') ||
          errStr.contains('permission')) {
        try {
          final fallbackResp = await _api.post(
            ApiEndpoints.sketches,
            data: {
              'designNumber': designNumber,
              'title': title,
              'sketchUrl': sketchUrl,
              'photoUrl': sketchUrl,
            },
          );
          final data = fallbackResp.data['data'] as Map<String, dynamic>;
          return ApiSketch.fromJson(data);
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
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
    required String status,
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
    try {
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
    } catch (_) {
      return [];
    }
  }

  Future<List<ApiThreeDDesign>> listAllThreeDDesigns({
    String status = '',
    int maxTotal = 2000,
  }) async {
    final all = <ApiThreeDDesign>[];
    int page = 1;
    const pageSize = 100;
    while (all.length < maxTotal) {
      try {
        final chunk = await listThreeDDesigns(
          status: status,
          page: page,
          limit: pageSize,
        );
        if (chunk.isEmpty) break;
        all.addAll(chunk);
        if (chunk.length < pageSize) break;
        page++;
      } catch (_) {
        break;
      }
    }
    return all;
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
    double otherMetalsQuantity = 0.0,
    double volumeMm3 = 0.0,
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
        'otherMetalsQuantity': otherMetalsQuantity,
        if (volumeMm3 > 0) 'volumeMm3': volumeMm3,
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

  /// POST /three-d-designs/direct-create - Admin single-step design creation
  /// Creates both sketch & 3D design as APPROVED in one call
  Future<ApiThreeDDesign> directCreateDesign({
    required String title,
    required String designNumber,
    String? imageUrl,
    String? bomFileUrl,
    String? xtlFileUrl,
    String? category,
    double? price,
    double? goldQuantity,
    String? sizeDimensions,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'designNumber': designNumber,
      if (imageUrl?.isNotEmpty == true) 'imageUrl': imageUrl,
      if (bomFileUrl?.isNotEmpty == true) 'bomFileUrl': bomFileUrl,
      if (xtlFileUrl?.isNotEmpty == true) 'xtlFileUrl': xtlFileUrl,
      if (category?.isNotEmpty == true) 'category': category,
      if (price != null && price > 0) 'price': price,
      if (goldQuantity != null && goldQuantity > 0)
        'goldQuantity': goldQuantity,
      if (sizeDimensions?.isNotEmpty == true) 'sizeDimensions': sizeDimensions,
      if (description?.isNotEmpty == true) 'description': description,
    };
    final response = await _api.post(
      ApiEndpoints.directCreateThreeD,
      data: payload,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiThreeDDesign.fromJson(data);
  }

  /// Alias for [directCreateDesign]
  Future<ApiThreeDDesign> createThreeDDesignDirect({
    required String title,
    required String designNumber,
    String? imageUrl,
    String? bomFileUrl,
    String? xtlFileUrl,
    String? category,
    double? price,
    double? goldQuantity,
    String? sizeDimensions,
    String? description,
  }) => directCreateDesign(
    title: title,
    designNumber: designNumber,
    imageUrl: imageUrl,
    bomFileUrl: bomFileUrl,
    xtlFileUrl: xtlFileUrl,
    category: category,
    price: price,
    goldQuantity: goldQuantity,
    sizeDimensions: sizeDimensions,
    description: description,
  );

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

  /// Returns raw order parts (including `assignments`) as plain Maps.
  /// Used by [WorkshopBloc] on startup to restore assigned worker state since
  /// [listPendingProductionFloor] only returns UNASSIGNED parts.
  Future<List<Map<String, dynamic>>> listOrderPartsRaw({
    int limit = 100,
  }) async {
    final response = await _api.get(
      ApiEndpoints.orders,
      queryParameters: {'page': 1, 'limit': limit},
    );
    final orders = response.data['data'] as List? ?? [];
    final parts = <Map<String, dynamic>>[];
    for (final o in orders) {
      final orderMap = Map<String, dynamic>.from(o as Map);
      final rawParts = orderMap['parts'] as List? ?? [];
      for (final p in rawParts) {
        final partMap = Map<String, dynamic>.from(p as Map);
        partMap['_orderId'] = orderMap['id'];
        partMap['_orderNumber'] = orderMap['orderNumber'];
        parts.add(partMap);
      }
    }
    return parts;
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

  Future<Map<String, dynamic>?> transitionPartNextStage({
    required String partId,
    int? quantity,
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.productionTransition(partId),
      data: {'notes': notes, 'quantity': ?quantity},
    );
    return response.data['data'] as Map<String, dynamic>?;
  }

  Future<void> rollbackPartStage({
    required String partId,
    required String targetStageId,
    required String reason,
    int? quantity,
  }) async {
    await _api.post(
      ApiEndpoints.productionRollback(partId),
      data: {
        'targetStageId': targetStageId,
        'reason': reason,
        'quantity': ?quantity,
      },
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
  Future<List<ApiWorkerTask>> listWorkerTasks({
    String status = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.workerTasks,
        queryParameters: {
          if (status.isNotEmpty) 'status': status,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'];
      List rawList = [];
      if (data is Map<String, dynamic>) {
        rawList = data['items'] as List? ?? [];
      } else if (data is List) {
        rawList = data;
      }
      final tasks = rawList
          .map((w) => ApiWorkerTask.fromJson(w as Map<String, dynamic>))
          .toList();

      return tasks;
    } catch (e) {
      return [];
    }
  }

  Future<ApiWorkerTask> startWorkerTask(String id) async {
    try {
      final response = await _api.post(ApiEndpoints.startWorkerTask(id));
      final dataMap = _dataMap(response.data);
      return ApiWorkerTask.fromJson(dataMap);
    } on DioException catch (e) {
      final resMsg = e.response?.data?['message'] as String?;
      if (resMsg != null && resMsg.isNotEmpty) {
        throw Exception(resMsg);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiWorkerTask> completeWorkerTask(String id) async {
    final response = await _api.post(ApiEndpoints.completeWorkerTask(id));
    final dataMap = _dataMap(response.data);
    return ApiWorkerTask.fromJson(dataMap);
  }

  Future<ApiWorkerTask> reportWorkerTaskFailure(
    String id,
    String reason,
  ) async {
    final response = await _api.post(
      ApiEndpoints.reportWorkerTaskFailure(id),
      data: {'failureReason': reason},
    );
    final dataMap = _dataMap(response.data);
    return ApiWorkerTask.fromJson(dataMap);
  }

  // ── SECTION 10: AWS S3 Cloud Storage (/storage) ──────────────────
  Future<ApiPresignedUrl> getPresignedUploadUrl({
    required String fileName,
    required String fileType,
    required String category,
  }) async {
    final response = await _api.post(
      ApiEndpoints.storagePresignedUrl,
      data: {'filename': fileName, 'fileType': fileType, 'folder': category},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiPresignedUrl.fromJson(data);
  }

  Future<ApiPresignedUrl> uploadFile({
    required String fileName,
    required String fileType,
    required String category,
    required Uint8List bytes,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.storageDirectUpload,
        queryParameters: {'folder': category, 'fileName': fileName},
        data: Stream.fromIterable([bytes]),
        options: Options(
          contentType: fileType,
          headers: {'Content-Type': fileType, 'Content-Length': bytes.length},
        ),
      );

      final respData = response.data;
      Map<String, dynamic>? dataMap;
      if (respData is Map<String, dynamic>) {
        if (respData['data'] is Map<String, dynamic>) {
          dataMap = respData['data'] as Map<String, dynamic>;
        } else {
          dataMap = respData;
        }
      }

      final rawFileUrl =
          dataMap?['fileUrl'] as String? ??
          dataMap?['url'] as String? ??
          dataMap?['publicUrl'] as String? ??
          '';
      var fileKey =
          dataMap?['fileKey'] as String? ?? dataMap?['key'] as String? ?? '';

      if (fileKey.isEmpty && rawFileUrl.isNotEmpty) {
        final parsedUri = Uri.tryParse(rawFileUrl);
        if (parsedUri != null) {
          final segs = parsedUri.pathSegments;
          if (segs.length > 1 &&
              (segs.first.toLowerCase() == 'karatflow' ||
                  segs.first.toLowerCase() == 'karratflow')) {
            fileKey = segs.skip(1).join('/');
          } else if (segs.isNotEmpty) {
            fileKey = segs.join('/');
          }
        }
      }

      if (fileKey.isEmpty) {
        fileKey = '$category/$fileName';
      }

      // Server view proxy URL as used by Admin Panel and working endpoints
      final serverViewUrl =
          '/api/v1/storage/view?key=${Uri.encodeQueryComponent(fileKey)}';

      if (rawFileUrl.isNotEmpty || serverViewUrl.isNotEmpty) {
        return ApiPresignedUrl(
          uploadUrl: rawFileUrl.isNotEmpty ? rawFileUrl : serverViewUrl,
          fileKey: fileKey,
          fileUrl: serverViewUrl,
          expiresInSeconds: 86400,
        );
      }
      throw FormatException(
        'Direct upload server response did not contain fileUrl: $respData',
      );
    } catch (e) {
      final signedUrl = await getPresignedUploadUrl(
        fileName: fileName,
        fileType: fileType,
        category: category,
      );
      if (signedUrl.uploadUrl.isEmpty) {
        throw FormatException(
          'Direct upload failed: $e, and presigned upload URL is empty.',
        );
      }
      await _api.putAbsoluteBytes(
        signedUrl.uploadUrl,
        bytes: bytes,
        contentType: fileType,
      );
      return signedUrl;
    }
  }

  // ── SECTION 10B: PaddleOCR Spec Extraction (/ocr) ───────────────
  Future<CadOcrExtractedData> extractCadOcr({
    required String imageUrl,
    bool asyncMode = false,
  }) async {
    final response = await _api.post(
      ApiEndpoints.ocrExtractCad,
      data: {'imageUrl': imageUrl, 'asyncMode': asyncMode},
    );
    final dataMap = _dataMap(response.data);
    final extractedMap =
        dataMap['extractedData'] as Map<String, dynamic>? ?? dataMap;
    return CadOcrExtractedData.fromJson(extractedMap);
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
    final reference = storedUrl.trim();
    if (reference.isEmpty) {
      throw const FormatException('The stored file reference is empty.');
    }

    // Reject browser-local blob: URLs immediately (cannot be fetched over HTTP)
    if (reference.toLowerCase().startsWith('blob:')) {
      throw const FormatException(
        'Blob memory URLs are client-side only and cannot be downloaded.',
      );
    }

    // 1. Check if it's a local file on device
    try {
      final localFile = File(reference);
      if (localFile.existsSync()) {
        final bytes = await localFile.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (_) {}

    final uri = Uri.tryParse(reference);
    if (uri == null) {
      throw const FormatException('The stored file reference is invalid.');
    }

    // 2. Relative storage key (e.g. 'sketches/filename.png')
    if (!uri.hasScheme && !reference.startsWith('/api/')) {
      final cleanRef = reference
          .replaceFirst(RegExp(r'^/+'), '')
          .replaceAll('\\', '/');
      try {
        final signed = await getPresignedDownloadUrl(cleanRef);
        if (signed.downloadUrl.isNotEmpty) {
          return await _api.getAbsoluteBytes(signed.downloadUrl);
        }
      } catch (_) {
        // Try with/without karratflow/ prefix
        if (cleanRef.startsWith('karratflow/')) {
          try {
            final signed = await getPresignedDownloadUrl(
              cleanRef.replaceFirst('karratflow/', ''),
            );
            if (signed.downloadUrl.isNotEmpty) {
              return await _api.getAbsoluteBytes(signed.downloadUrl);
            }
          } catch (_) {}
        } else {
          try {
            final signed = await getPresignedDownloadUrl(
              'karratflow/$cleanRef',
            );
            if (signed.downloadUrl.isNotEmpty) {
              return await _api.getAbsoluteBytes(signed.downloadUrl);
            }
          } catch (_) {}
        }

        // Try server view proxy endpoint directly
        try {
          return await _api.getBytes(
            '/storage/view?key=${Uri.encodeQueryComponent(cleanRef)}',
          );
        } catch (_) {}
        try {
          return await _api.getBytes(
            '/storage/view?key=${Uri.encodeQueryComponent('karratflow/$cleanRef')}',
          );
        } catch (_) {}

        final resolvedUrl = Uri.parse(
          ApiEndpoints.baseUrl,
        ).resolve(reference).toString();
        return await _api.getBytes(resolvedUrl);
      }
    }

    // 3. Absolute URL, Cloudflare R2, or AWS S3 URL
    String targetUrl = uri.hasScheme
        ? reference
        : Uri.parse(ApiEndpoints.baseUrl).resolve(reference).toString();

    // If already a server view endpoint, download directly via _api
    if (reference.startsWith('/api/') || reference.contains('/storage/view')) {
      return _api.getBytes(targetUrl);
    }

    final fileKey = _storageFileKey(uri);
    if (fileKey != null) {
      final candidates = <String>[fileKey];
      if (fileKey.startsWith('karratflow/')) {
        candidates.add(fileKey.replaceFirst('karratflow/', ''));
      }
      if (fileKey.startsWith('karatflow/')) {
        candidates.add(fileKey.replaceFirst('karatflow/', ''));
      }
      if (!fileKey.startsWith('karratflow/') &&
          !fileKey.startsWith('karatflow/')) {
        candidates.add('karratflow/$fileKey');
      }

      // Step 3a: Try server view proxy endpoint first (100% reliable, zero signature issues)
      for (final candidate in candidates) {
        try {
          final bytes = await _api.getBytes(
            '/storage/view?key=${Uri.encodeQueryComponent(candidate)}',
          );
          if (bytes.isNotEmpty) {
            return bytes;
          }
        } catch (_) {}
      }

      // Step 3b: Fallback to presigned download URL
      for (final candidate in candidates) {
        try {
          final signed = await getPresignedDownloadUrl(candidate);
          if (signed.downloadUrl.isNotEmpty) {
            final bytes = await _api.getAbsoluteBytes(signed.downloadUrl);
            if (bytes.isNotEmpty) {
              return bytes;
            }
          }
        } catch (_) {}
      }
    }

    // Direct download with internal/external auth handling
    return _api.getBytes(targetUrl);
  }

  String? _storageFileKey(Uri uri) {
    final isSigned = uri.queryParameters.keys.any(
      (key) =>
          key.toLowerCase() == 'x-amz-signature' ||
          key.toLowerCase() == 'x-amz-algorithm',
    );
    if (isSigned) return null;

    final proxyKey =
        uri.queryParameters['fileKey'] ?? uri.queryParameters['key'];
    if (proxyKey != null && proxyKey.trim().isNotEmpty) {
      return proxyKey.trim().replaceAll('\\', '/');
    }

    final host = uri.host.toLowerCase();
    final isCloudStorage =
        host.contains('amazonaws.com') ||
        host.contains('s3') ||
        host.contains('cloudflarestorage.com') ||
        host.contains('r2');
    if (!isCloudStorage) return null;

    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    if (segments.length > 1 &&
        (segments.first.toLowerCase() == 'karatflow' ||
            segments.first.toLowerCase() == 'karratflow')) {
      return segments.skip(1).join('/').trim().replaceAll('\\', '/');
    }

    final key = segments.join('/').trim().replaceAll('\\', '/');
    return key.isEmpty ? null : key;
  }

  // ── SECTION 11: Master Raw Materials & Preset Pricing Matrix ────
  Future<List<ApiMaterial>> listMaterials({
    String? category,
    String? search,
  }) async {
    try {
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
    } catch (_) {
      return [];
    }
  }

  Future<ApiMaterial> getMaterialById(String id) async {
    final response = await _api.get(ApiEndpoints.materialDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiMaterial.fromJson(data);
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

  Future<void> deleteMaterial(String id) async {
    await _api.delete(ApiEndpoints.materialDetails(id));
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

  Future<ApiInventoryItem> getInventoryById(String id) async {
    final response = await _api.get(ApiEndpoints.inventoryDetails(id));
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiInventoryItem.fromJson(data);
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
    String? notes,
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
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiInventoryItem.fromJson(data);
  }

  Future<ApiInventoryItem> updateInventoryItem(
    String id, {
    double? totalStock,
    double? reservedWip,
    double? freeBalance,
    String? location,
    String? notes,
  }) async {
    final response = await _api.patch(
      ApiEndpoints.inventoryDetails(id),
      data: {
        'totalStock': ?totalStock,
        'reservedWip': ?reservedWip,
        'freeBalance': ?freeBalance,
        if (location != null && location.isNotEmpty) 'location': location,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ApiInventoryItem.fromJson(data);
  }

  Future<void> deleteInventoryItem(String id) async {
    await _api.delete(ApiEndpoints.inventoryDetails(id));
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

  Future<void> acknowledgeDirective(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('Directive ID is missing.');
    }
    final response = await _api.patch(
      ApiEndpoints.acknowledgeDirective(id),
      data: <String, dynamic>{},
    );
    // A successful command may return only a message or HTTP 204.
    // Do not require a complete directive object to acknowledge an existing one.
    final body = response.data;
    if (body is Map && body['success'] == false) {
      throw StateError(
        body['message']?.toString() ?? 'Acknowledgement failed.',
      );
    }
  }

  // ── SECTION 14: Health (/health) ──────────────────────────────────
  Future<ApiHealthStatus> checkHealth() async {
    final response = await _api.get(ApiEndpoints.health);
    return ApiHealthStatus.fromJson(_dataMap(response.data));
  }

  // ── SECTION 15: Stockist Material Allocation & Issuances (/issuances) ─────
  Future<List<ApiPendingIssuance>> getPendingIssuancesQueue() async {
    try {
      final response = await _api.get(ApiEndpoints.issuancesPendingQueue);
      final list = _dataList(response.data);
      return list
          .map(
            (item) => ApiPendingIssuance.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ApiMaterialIssuance> issueMaterialsForOrderPart(
    String orderPartId, {
    required List<Map<String, dynamic>> items,
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.issueOrderPartMaterials(orderPartId),
      data: {'items': items, if (notes.isNotEmpty) 'notes': notes},
    );
    final data = _dataMap(response.data);
    return ApiMaterialIssuance.fromJson(data);
  }

  Future<ApiMaterialIssuance?> getMaterialIssuanceByPart(
    String orderPartId,
  ) async {
    try {
      final response = await _api.get(
        ApiEndpoints.getIssuanceByOrderPart(orderPartId),
      );
      final data = _dataMap(response.data);
      return ApiMaterialIssuance.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<ApiMaterialIssuance> reconcileMaterialIssuance(
    String issuanceId, {
    required double returnedGrossWeight,
    required double scrapDustWeight,
    int unusedStonesCount = 0,
    int brokenStonesCount = 0,
    String notes = '',
  }) async {
    final response = await _api.post(
      ApiEndpoints.reconcileIssuance(issuanceId),
      data: {
        'returnedGrossWeight': returnedGrossWeight,
        'scrapDustWeight': scrapDustWeight,
        'unusedStonesCount': unusedStonesCount,
        'brokenStonesCount': brokenStonesCount,
        if (notes.isNotEmpty) 'reconciliationNotes': notes,
      },
    );
    final data = _dataMap(response.data);
    return ApiMaterialIssuance.fromJson(data);
  }

  Future<List<ApiMaterialIssuance>> listMaterialIssuances({
    String status = '',
    String craftsmanId = '',
    String orderPartId = '',
  }) async {
    try {
      final response = await _api.get(
        ApiEndpoints.issuances,
        queryParameters: {
          if (status.isNotEmpty) 'status': status,
          if (craftsmanId.isNotEmpty) 'craftsmanId': craftsmanId,
          if (orderPartId.isNotEmpty) 'orderPartId': orderPartId,
        },
      );
      final list = _dataList(response.data);
      return list
          .map((i) => ApiMaterialIssuance.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
