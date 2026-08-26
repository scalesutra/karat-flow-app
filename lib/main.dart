import 'package:flutter/material.dart';

import 'app.dart';
import 'data/demo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DemoStore.instance.initialize();
  runApp(const JewelleryOpsApp());
}
