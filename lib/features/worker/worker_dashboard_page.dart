// DISABLED: Factory workers don't use phones in this workflow.
// The Process Manager handles stage progression and completion on behalf of workers.
// Original code preserved in: worker_dashboard_page.dart.disabled
//
// To re-enable: rename .dart.disabled → .dart and restore app_shell.dart imports.

import 'package:flutter/material.dart';
import '../../data/demo_store.dart';

/// Stub widget — Worker dashboard is disabled.
/// Workers don't have phones; Process Manager manages their workflow.
class WorkerDashboardPage extends StatelessWidget {
  const WorkerDashboardPage({super.key, this.store});

  final DemoStore? store;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Worker dashboard is disabled.\nProcess Manager handles this workflow.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
