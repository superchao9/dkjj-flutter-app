import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_storage.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.init(environment);
  await AppStorage.instance.init();
  runApp(const DkjjApp());
}
