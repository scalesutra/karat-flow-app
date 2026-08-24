import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/demo_store.dart';
import '../../../data/repositories/karatflow_api_repository.dart';
import '../../../domain/models.dart';
import 'admin_event.dart';
import 'admin_state.dart';

export 'admin_event.dart';
export 'admin_state.dart';

/// Admin Governance & Operations BLoC with Strict Live Backend APIs (/employees, /customers, /sketches, /stages) & Debug Logs
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc({required DemoStore store, KaratFlowApiRepository? apiRepository})
    : _store = store,
      _api = apiRepository ?? KaratFlowApiRepository(),
      super(const AdminInitial()) {
    on<FetchAdminDashboardEvent>(_onFetchDashboard);
    on<AddArtisanEvent>(_onAddArtisan);
    on<SendDirectiveEvent>(_onSendDirective);
    on<ApproveSketchDesignEvent>(_onApproveSketchDesign);
  }

  final DemoStore _store;
  final KaratFlowApiRepository _api;

  Future<void> _onFetchDashboard(
    FetchAdminDashboardEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    debugPrint(
      '👑 [AdminBloc] Fetching live admin dashboard from GET /employees, GET /customers, GET /sketches...',
    );
    try {
      final employees = await _api.listEmployees();
      final customers = await _api.listCustomers();
      final sketches = await _api.listSketches();

      debugPrint(
        '✅ [AdminBloc] Received ${employees.length} employees, ${customers.length} clients, ${sketches.length} sketches.',
      );

      final mappedTeam = employees.map((emp) {
        return TeamMember(
          id: emp.id,
          name: emp.name,
          craft: emp.role,
          shift: 'General Shift',
          activeLotsCount: emp.workerAssignmentsCount,
          status: emp.isActive
              ? EmployeeStatus.available
              : EmployeeStatus.blocked,
          todayEfficiencyPercent: 100,
          currentAssignment: 'Assignments: ${emp.workerAssignmentsCount}',
        );
      }).toList();
      _store.setTeam(mappedTeam);

      final mappedClients = customers.map((c) {
        return ClientInfo(
          id: c.id,
          firmName: c.name,
          city: c.city,
          contactPerson: c.contactPerson,
          phone: c.phone,
          creditLimitLakhs: c.creditLimitLakhs,
          outstandingBalance: c.outstandingLakhs * 100000.0,
          activeOrdersCount: c.ordersCount,
        );
      }).toList();
      _store.setClients(mappedClients);

      final mappedDesigns = sketches.map((sk) {
        return JewelleryDesign(
          id: sk.id,
          name: sk.title,
          code: sk.designNumber,
          category: JewelleryCategory.necklaces,
          purity: '22KT',
          grossWeightGrams: 48.65,
          estimatedPrice: 382000.0,
          imageUrl: sk.sketchUrl,
          description: sk.adminInstructions ?? 'Raw client 2D sketch',
        );
      }).toList();
      _store.setDesigns(mappedDesigns);

      final rawDirectives = List<Map<String, String>>.from(
        _store.adminDirectives,
      );

      emit(
        AdminLoaded(
          team: mappedTeam,
          clients: mappedClients,
          designs: mappedDesigns,
          directives: rawDirectives,
        ),
      );
    } catch (e) {
      debugPrint('❌ [AdminBloc] Failed to fetch admin overview: $e');
      emit(
        AdminError(
          'Failed to fetch admin overview from live API: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onAddArtisan(
    AddArtisanEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());
    debugPrint(
      '➕ [AdminBloc] Onboarding new employee on POST /employees: ${event.member.name}...',
    );
    try {
      final sanitizedName = event.member.name.toLowerCase().replaceAll(
        ' ',
        '.',
      );
      await _api.onboardEmployee(
        name: event.member.name,
        email: '$sanitizedName@karratflow.com',
        phone: event.phone,
        stageId: event.stageId,
        role: 'OTHER_EMPLOYEE',
      );

      debugPrint('🎉 [AdminBloc] Employee onboarded successfully on server.');
      emit(
        AdminActionSuccess(
          'Artisan ${event.member.name} registered successfully on live backend.',
        ),
      );
      add(const FetchAdminDashboardEvent());
    } catch (e) {
      debugPrint('❌ [AdminBloc] Failed to add artisan: $e');
      emit(AdminError('Failed to add artisan on live server: ${e.toString()}'));
    }
  }

  Future<void> _onSendDirective(
    SendDirectiveEvent event,
    Emitter<AdminState> emit,
  ) async {
    try {
      _store.addAdminDirective(event.recipient, event.directive);
      emit(AdminActionSuccess('Directive dispatched to ${event.recipient}.'));
      add(const FetchAdminDashboardEvent());
    } catch (e) {
      emit(AdminError('Failed to send directive: ${e.toString()}'));
    }
  }

  Future<void> _onApproveSketchDesign(
    ApproveSketchDesignEvent event,
    Emitter<AdminState> emit,
  ) async {
    debugPrint(
      '✍️ [AdminBloc] Approving sketch on PATCH /sketches/${event.designCode}/review...',
    );
    try {
      await _api.reviewSketch(
        id: event.designCode,
        status: 'APPROVED',
        adminInstructions: 'Approved for 3D CAD modeling',
      );

      debugPrint('✅ [AdminBloc] Sketch approved successfully on live backend.');
      emit(
        AdminActionSuccess(
          'Sketch ${event.designCode} approved on live server for 3D CAD modeling.',
        ),
      );
      add(const FetchAdminDashboardEvent());
    } catch (e) {
      debugPrint('❌ [AdminBloc] Failed to approve sketch: $e');
      emit(AdminError('Failed to approve sketch on live API: ${e.toString()}'));
    }
  }
}
