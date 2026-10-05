// DISABLED: Factory workers don't use phones in this workflow.
// The Process Manager handles stage progression and completion on behalf of artisans.
// Original code preserved in: artisan_dashboard_page.dart.disabled
//
// To re-enable: rename .dart.disabled → .dart and restore app_shell.dart imports.

import 'package:flutter/material.dart';

/// Stub widget — Artisan dashboard is disabled.
/// Artisans don't have phones; Process Manager manages their workflow.
class ArtisanDashboardPage extends StatelessWidget {
  const ArtisanDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Artisan dashboard is disabled.\nProcess Manager handles this workflow.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
