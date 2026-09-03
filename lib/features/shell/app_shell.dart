import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jewellery_ops_mobile/features/auth/bloc/auth_bloc.dart';
import '../../core/services/live_data_bloc_coordinator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/localization.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/widgets.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';
import '../admin/manage_page.dart';
import '../admin/reports_page.dart';
import '../admin/stock_page.dart';
import '../cad_designer/cad_dashboard_page.dart';
import '../cad_designer/cad_design_library_page.dart';
import '../cad_designer/cad_more_page.dart';
import '../front_office/cart_page.dart';
import '../front_office/clients_page.dart';
import '../front_office/designs_page.dart';
import '../front_office/front_office_more_page.dart';
import '../front_office/orders_page.dart';
import '../raw_designer/raw_designer_dashboard_page.dart';
import '../profile/role_profile_page.dart';
import '../status/admin_status_page.dart';
import '../tasks/task_pages.dart';
import '../workshop/product_manager_page.dart';
import '../workshop/team_page.dart';
import '../workshop/workshop_more_page.dart';
import '../workshop_artisan/artisan_dashboard_page.dart';
import '../worker/worker_dashboard_page.dart';
import '../stockist/stockist_dashboard_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.role,
    required this.store,
    required this.onRoleChanged,
  });

  final AppRole role;
  final DemoStore store;
  final ValueChanged<AppRole> onRoleChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = context.read<AuthBloc>().state;
        final activeRole = authState is AuthAuthenticated
            ? AppRole.fromRoleString(authState.role)
            : widget.role;
        LiveDataBlocCoordinator.refreshForRole(context, activeRole);
      }
    });
  }

  Future<void> _refreshApiData() async {
    LiveDataBlocCoordinator.refreshForRole(context, widget.role);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _selectedIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          LiveDataBlocCoordinator.refreshForRole(context, widget.role);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final destinations = _destinations(widget.role, widget.store);
        final pages = _pages(widget.role);
        final isDesktopOrTablet =
            Responsive.isDesktop(context) || Responsive.isTablet(context);

        final safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

        final body = CommonRefreshIndicator(
          enabled: true,
          theme: _indicatorTheme(widget.role),
          showIndicator: false,
          onRefresh: _refreshApiData,
          child: KeyedSubtree(
            key: ValueKey('${widget.role.name}_$safeIndex'),
            child: pages[safeIndex],
          ),
        );

        return Scaffold(
          appBar: CommonAppBar(
            subtitle: _greeting(widget.role),
            currentRole: widget.role,
            onRoleChanged: widget.onRoleChanged,
          ),
          body: Row(
            children: [
              if (isDesktopOrTablet) ...[
                NavigationRail(
                  extended: Responsive.isDesktop(context),
                  selectedIndex: safeIndex,
                  onDestinationSelected: _select,
                  groupAlignment: -0.9,
                  backgroundColor: AppColors.paper,
                  indicatorColor: AppColors.sage,
                  destinations: destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: _destinationIcon(item, selected: false),
                          selectedIcon: _destinationIcon(item, selected: true),
                          label: CommonText.labelSmall(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: Stack(children: [Positioned.fill(child: body)]),
              ),
            ],
          ),
          bottomNavigationBar: isDesktopOrTablet
              ? null
              : NavigationBar(
                  selectedIndex: safeIndex,
                  onDestinationSelected: _select,
                  destinations: destinations
                      .map(
                        (item) => NavigationDestination(
                          icon: _destinationIcon(item, selected: false),
                          selectedIcon: _destinationIcon(item, selected: true),
                          label: item.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  List<Widget> _pages(AppRole role) => switch (role) {
    AppRole.admin => [
      AdminStatusPage(store: widget.store),
      AdminReportsPage(store: widget.store),
      AdminStockPage(store: widget.store),
      AdminManagePage(store: widget.store),
      AdminTasksPage(store: widget.store),
    ],
    AppRole.processManager => [
      ProductManagerPage(store: widget.store),
      TeamWorkloadPage(store: widget.store),
      WorkshopMorePage(store: widget.store),
    ],
    AppRole.cadDesigner => [
      CadDashboardPage(store: widget.store),
      CadDesignLibraryPage(store: widget.store),
      CadMorePage(store: widget.store),
    ],
    AppRole.frontOffice => [
      OrdersPage(store: widget.store),
      DesignsPage(store: widget.store),
      CartPage(store: widget.store, onBrowseDesigns: () => _select(1)),
      ClientsPage(store: widget.store),
      FrontOfficeMorePage(store: widget.store),
    ],
    AppRole.rawDesigner => [
      const RawDesignerDashboardPage(),
      RoleProfilePage(
        title: 'Raw Designer Profile',
        description: 'Review your authenticated studio identity and session.',
        store: widget.store,
        role: AppRole.rawDesigner,
      ),
    ],
    AppRole.workshopArtisan => [
      WorkerDashboardPage(store: widget.store),
      RoleProfilePage(
        title: 'Workshop Artisan Profile',
        description: 'Review your authenticated workshop identity and session.',
        store: widget.store,
        role: AppRole.workshopArtisan,
      ),
    ],
    AppRole.worker => [
      WorkerDashboardPage(store: widget.store),
      RoleProfilePage(
        title: 'Worker Bench Profile',
        description: 'Review your authenticated worker bench identity and session.',
        store: widget.store,
        role: AppRole.worker,
      ),
    ],
    AppRole.stockist => [
      StockistDashboardPage(
        store: widget.store,
        initialTab: 'REQUISITIONS',
      ),
      StockistDashboardPage(
        store: widget.store,
        initialTab: 'ALL',
      ),
      RoleProfilePage(
        title: 'Stockist Vault Profile',
        description:
            'Review your authenticated vault stockist identity and session.',
        store: widget.store,
        role: AppRole.stockist,
      ),
    ],
  };

  void _select(int index) => setState(() => _selectedIndex = index);

  static String _greeting(AppRole role) => switch (role) {
    AppRole.admin => AppStrings.adminDashboard.trClean,
    AppRole.frontOffice => AppStrings.frontOfficeSubtitle.trClean,
    AppRole.processManager => AppStrings.workshopSubtitle.trClean,
    AppRole.cadDesigner => AppStrings.cadSubtitle.trClean,
    AppRole.rawDesigner => 'Raw Design Studio',
    AppRole.workshopArtisan => 'My Workshop Bench',
    AppRole.worker => 'Worker Bench Operations',
    AppRole.stockist => 'Vault Stockist Portal',
  };

  static IndicatorTheme _indicatorTheme(AppRole role) => switch (role) {
    AppRole.processManager => IndicatorTheme.workshop,
    AppRole.frontOffice => IndicatorTheme.frontOffice,
    AppRole.cadDesigner => IndicatorTheme.cad,
    AppRole.rawDesigner => IndicatorTheme.cad,
    AppRole.workshopArtisan => IndicatorTheme.workshop,
    AppRole.worker => IndicatorTheme.workshop,
    AppRole.stockist => IndicatorTheme.universal,
    AppRole.admin => IndicatorTheme.universal,
  };
}

class _Destination {
  const _Destination(this.label, this.icon, {this.badge});

  final String label;
  final IconData icon;
  final int? badge;
}

List<_Destination> _destinations(AppRole role, DemoStore store) {
  final adminPendingCount =
      store.actionableInstructionCount + store.pendingCadApprovalsCount;
  final tasksBadge = adminPendingCount > 0 ? adminPendingCount : null;
  final cartBadge = store.cartItemsCount > 0 ? store.cartItemsCount : null;

  final cadNewBadge = store.cadNewCount > 0 ? store.cadNewCount : null;
  final reqBadge = store.pendingRequisitionsCount > 0
      ? store.pendingRequisitionsCount
      : null;

  return switch (role) {
    AppRole.admin => [
      _Destination(AppStrings.status.trClean, Icons.space_dashboard_outlined),
      _Destination('Reports', Icons.query_stats_outlined),
      _Destination(AppStrings.navStock.trClean, Icons.inventory_2_outlined),
      _Destination(AppStrings.navManage.trClean, Icons.tune),
      _Destination(
        AppStrings.navTasks.trClean,
        Icons.task_alt_outlined,
        badge: tasksBadge,
      ),
    ],
    AppRole.frontOffice => [
      _Destination(AppStrings.navOrders.trClean, Icons.receipt_long_outlined),
      _Destination(
        AppStrings.navDesigns.trClean,
        Icons.auto_awesome_mosaic_outlined,
      ),
      _Destination(
        AppStrings.navCart.trClean,
        Icons.shopping_bag_outlined,
        badge: cartBadge,
      ),
      _Destination(AppStrings.navClients.trClean, Icons.storefront_outlined),
      _Destination(AppStrings.navMore.trClean, Icons.more_horiz),
    ],
    AppRole.processManager => [
      _Destination(
        AppStrings.productManager.trClean,
        Icons.space_dashboard_outlined,
      ),
      _Destination('Team', Icons.groups_outlined),
      _Destination(AppStrings.navMore.trClean, Icons.more_horiz),
    ],
    AppRole.cadDesigner => [
      _Destination(
        AppStrings.cadDashboard.trClean,
        Icons.view_in_ar_outlined,
        badge: cadNewBadge,
      ),
      _Destination(
        AppStrings.cadDesignLibrary.trClean,
        Icons.auto_awesome_mosaic_outlined,
      ),
      _Destination(AppStrings.navMore.trClean, Icons.more_horiz),
    ],
    AppRole.rawDesigner => [
      _Destination('Sketches', Icons.draw_outlined),
      _Destination('Profile', Icons.person_outline_rounded),
    ],
    AppRole.workshopArtisan => [
      _Destination('My Tasks', Icons.handyman_outlined),
      _Destination('Profile', Icons.person_outline_rounded),
    ],
    AppRole.worker => [
      _Destination('Bench Tasks', Icons.precision_manufacturing_outlined),
      _Destination('Profile', Icons.person_outline_rounded),
    ],
    AppRole.stockist => [
      _Destination(
        'Requisitions',
        Icons.move_to_inbox_rounded,
        badge: reqBadge,
      ),
      _Destination('Vault Stock', Icons.inventory_2_outlined),
      _Destination('Profile', Icons.person_outline_rounded),
    ],
  };
}

Widget _destinationIcon(_Destination item, {required bool selected}) {
  final icon = Icon(item.icon, fill: selected ? 1 : 0);
  if (item.badge == null) return icon;
  return Badge(label: Text('${item.badge}'), child: icon);
}
