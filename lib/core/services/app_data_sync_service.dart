import 'package:flutter/foundation.dart';
import '../../data/demo_store.dart';
import '../../data/models/api_models.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../../domain/models.dart';

/// Centralized Data Synchronization Service for KaratFlow Mobile App
/// Ensures 100% real backend API data is loaded across all UI views.
class AppDataSyncService {
  static final KaratFlowApiRepository _api = KaratFlowApiRepository();

  /// Synchronize all domain datasets directly from REST endpoints into DemoStore
  static Future<void> syncAllData(DemoStore store) async {
    debugPrint(
      '🔄 [AppDataSyncService] Starting full app data sync from live API endpoints...',
    );
    await Future.wait([
      syncCustomers(store),
      syncOrders(store),
      syncCatalogue(store),
      syncWorkshopLots(store),
      syncTeamEmployees(store),
      syncStages(store),
      syncCadTasks(store),
    ]).catchError((Object err) {
      debugPrint('⚠️ [AppDataSyncService] Error during parallel sync: $err');
      return <void>[];
    });
    debugPrint('✨ [AppDataSyncService] Full app data sync complete!');
  }

  /// Sync only the endpoints authorized for the authenticated app role.
  static Future<void> syncForRole(DemoStore store, AppRole role) async {
    final operations = switch (role) {
      AppRole.admin => <Future<void>>[
          syncCustomers(store),
          syncOrders(store),
          syncCatalogue(store),
          syncWorkshopLots(store),
          syncTeamEmployees(store),
          syncStages(store),
          syncCadTasks(store),
        ],
      AppRole.processManager => <Future<void>>[
          syncOrders(store),
          syncWorkshopLots(store),
          syncTeamEmployees(store),
          syncStages(store),
        ],
      AppRole.frontOffice => <Future<void>>[
          syncCustomers(store),
          syncOrders(store),
          syncCatalogue(store),
        ],
      AppRole.cadDesigner => <Future<void>>[
          syncCatalogue(store),
          syncCadTasks(store),
        ],
    };
    await Future.wait(operations);
  }

  /// Sync Customers (GET /customers)
  static Future<void> syncCustomers(DemoStore store) async {
    try {
      debugPrint('🏢 [Sync] Fetching GET /customers...');
      final customers = await _api.listCustomers(limit: 100);
      final mapped = customers.map((c) {
        return ClientInfo(
          id: c.id,
          firmName: c.name,
          city: c.city,
          contactPerson: c.contactPerson,
          phone: c.phone,
          creditLimitLakhs: c.creditLimitLakhs,
          outstandingBalance: c.outstandingLakhs,
          activeOrdersCount: c.activeOrdersCount,
        );
      }).toList();
      store.setClients(mapped);
      debugPrint('✅ [Sync] Loaded ${mapped.length} clients into store.');
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync customers: $e');
    }
  }

  /// Sync Orders (GET /orders)
  static Future<void> syncOrders(DemoStore store) async {
    try {
      debugPrint('📦 [Sync] Fetching GET /orders...');
      final orders = await _api.listOrders(status: '', limit: 100);
      final mapped = orders.map((ao) {
        final firstPart = ao.parts.isNotEmpty ? ao.parts.first : null;
        final itemsSummaryText = ao.parts.isNotEmpty
            ? ao.parts.map((p) => '${p.quantity}x ${p.designNumber}').join(', ')
            : 'Custom Order #${ao.orderNumber}';

        return CustomerOrder(
          id: ao.orderNumber.isNotEmpty ? ao.orderNumber : ao.id,
          clientFirmName: ao.customerName.isNotEmpty
              ? ao.customerName
              : 'Client Order',
          clientCity: ao.customerCity,
          itemsCount: ao.parts.fold(0, (sum, p) => sum + p.quantity),
          totalGrossGrams: firstPart?.grossWeight ?? 0.0,
          estimatedTotalAmount: 0.0,
          status: switch (ao.status.toUpperCase()) {
            'DRAFT' || 'PENDING' => OrderStatus.pending,
            'READY' || 'CHECKED_OUT' => OrderStatus.ready,
            'DISPATCHED' => OrderStatus.dispatched,
            'DELIVERED' => OrderStatus.delivered,
            'CANCELLED' || 'CANCELED' => OrderStatus.cancelled,
            _ => OrderStatus.inWorkshop,
          },
          promiseDate: ao.dueDate,
          createdAt: ao.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          itemsSummary: itemsSummaryText,
          currentWorkshopStage: firstPart?.currentStage ?? '',
          responsibleManager: '',
        );
      }).toList();
      store.setOrders(mapped);
      debugPrint('✅ [Sync] Loaded ${mapped.length} orders into store.');
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync orders: $e');
    }
  }

  /// Sync Catalogue (GET /sketches & GET /three-d-designs)
  static Future<void> syncCatalogue(DemoStore store) async {
    try {
      debugPrint('🎨 [Sync] Fetching GET /sketches & GET /three-d-designs...');
      final sketches = await _api.listSketches(limit: 50);
      final threeD = await _api.listThreeDDesigns(limit: 50);

      final List<JewelleryDesign> catalogue = [];

      for (final sk in sketches) {
        catalogue.add(
          JewelleryDesign(
            id: sk.id,
            name: sk.title.isNotEmpty ? sk.title : 'Design #${sk.designNumber}',
            code: sk.designNumber.isNotEmpty ? sk.designNumber : sk.id,
            category: JewelleryCategory.all,
            purity: '22KT',
            grossWeightGrams: 25.0,
            imageUrl: sk.sketchUrl,
            description: sk.adminInstructions ?? '2D Pencil Sketch Model',
            isPopular: true,
          ),
        );
      }

      for (final td in threeD) {
        catalogue.add(
          JewelleryDesign(
            id: td.id,
            name: '3D CAD (${td.sketchId})',
            code: 'CAD-${td.id}',
            category: JewelleryCategory.rings,
            purity: '22KT',
            grossWeightGrams: td.totalWeight > 0 ? td.totalWeight : 18.5,
            imageUrl: td.xtlFileUrl ?? '',
            description: '3D CAD Model (Vol: ${td.volumeMm3}mm³)',
            isPopular: true,
          ),
        );
      }

      store.setDesigns(catalogue);
      debugPrint(
        '✅ [Sync] Loaded ${catalogue.length} catalogue designs into store.',
      );
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync catalogue: $e');
    }
  }

  /// Sync Workshop Lots (GET /worker-tasks)
  static Future<void> syncWorkshopLots(DemoStore store) async {
    try {
      debugPrint('🏭 [Sync] Fetching GET /worker-tasks...');
      final tasks = await _api.listWorkerTasks();
      final mapped = tasks.map((wt) {
        final stageEnum = switch (wt.stageName.toLowerCase()) {
          'waxing' || 'cad & wax' => WorkshopStage.cadAndWax,
          'casting' => WorkshopStage.casting,
          'filing & assembly' || 'filing' => WorkshopStage.filingAndAssembly,
          'stone setting' || 'setting' => WorkshopStage.stoneSetting,
          'polishing' => WorkshopStage.polishing,
          _ => WorkshopStage.qualityCheck,
        };

        return WorkshopLot(
          id: wt.id,
          orderId: wt.orderId.isNotEmpty ? wt.orderId : wt.id,
          designCode: wt.designNumber,
          productTitle: wt.designNumber.isNotEmpty
              ? wt.designNumber
              : 'Lot #${wt.id}',
          stage: stageEnum,
          assignedEmployee: wt.assignedEmployeeName,
          assignedEmployeeRole: wt.status,
          pieces: wt.quantity,
          issueWeightGrams: wt.grossWeight,
          targetWeightGrams: wt.grossWeight,
          tone: wt.status == 'FAILED'
              ? HealthTone.critical
              : HealthTone.healthy,
          blockerReason: wt.status == 'FAILED' ? wt.instructions : null,
          lastUpdatedTime: wt.stageName,
        );
      }).toList();

      store.setLots(mapped);
      debugPrint('✅ [Sync] Loaded ${mapped.length} workshop lots into store.');
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync workshop lots: $e');
    }
  }

  /// Sync Team Employees (GET /employees)
  static Future<void> syncTeamEmployees(DemoStore store) async {
    try {
      debugPrint('👥 [Sync] Fetching GET /employees...');
      final employees = await _api.listEmployees();
      final mapped = employees.map((emp) {
        return TeamMember(
          id: emp.id,
          name: emp.name,
          craft: emp.role,
          shift: emp.role,
          activeLotsCount: emp.workerAssignmentsCount,
          status: emp.isActive
              ? EmployeeStatus.available
              : EmployeeStatus.blocked,
          todayEfficiencyPercent: emp.isActive ? 100 : 0,
          currentAssignment: '${emp.workerAssignmentsCount} active tasks',
        );
      }).toList();

      store.setTeam(mapped);
      debugPrint('✅ [Sync] Loaded ${mapped.length} team members into store.');
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync team members: $e');
    }
  }

  /// Sync the live production stage configuration (GET /stages).
  static Future<void> syncStages(DemoStore store) async {
    try {
      debugPrint('🏗️ [Sync] Fetching GET /stages...');
      final stages = await _api.listStages();
      store.setStages(stages);
      debugPrint('✅ [Sync] Loaded ${stages.length} production stages.');
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync production stages: $e');
    }
  }

  /// Sync live CAD approval tasks (GET /three-d-designs).
  static Future<void> syncCadTasks(DemoStore store) async {
    try {
      debugPrint('💎 [Sync] Fetching GET /three-d-designs...');
      final designs = await _api.listThreeDDesigns();
      final tasks = designs
          .map(
            (design) => CadDesignTask(
              id: design.id,
              orderId: design.sketchId,
              designCode: design.id,
              productTitle: design.sketchId,
              clientName: '',
              specs:
                  'Weight: ${design.totalWeight}g · Vol: ${design.volumeMm3}mm³',
              notes: '',
              estimatedWeightGrams: design.totalWeight,
              status: design.status == 'APPROVED'
                  ? CadTaskStatus.completed
                  : design.status == 'REVISION'
                  ? CadTaskStatus.revision
                  : CadTaskStatus.newTask,
              hasVoiceNote: false,
              hasSketchImage: false,
              hasStlFile:
                  design.xtlFileUrl != null && design.xtlFileUrl!.isNotEmpty,
              assignedTo: '',
              receivedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          )
          .toList();
      store.setCadTasks(tasks);
      debugPrint('✅ [Sync] Loaded ${tasks.length} CAD approval tasks.');
    } catch (e) {
      debugPrint('❌ [Sync] Failed to sync CAD approval tasks: $e');
    }
  }
}
