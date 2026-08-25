import 'package:flutter/material.dart';

import '../../core/widgets/common_snackbar.dart';
import '../../data/demo_store.dart';
import '../../domain/models.dart';

Future<Instruction?> showInstructionComposer(
  BuildContext context, {
  required DemoStore store,
  WorkItem? target,
}) async {
  CommonSnackbar.error(
    context,
    title: 'Instructions API Unavailable',
    message: 'The backend does not expose an instructions endpoint.',
  );
  return null;
}
