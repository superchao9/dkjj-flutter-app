import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/app_shell.dart';
import '../features/inspection/data/inspection_repository.dart';
import '../features/messages/data/message_repository.dart';
import '../features/modules/data/module_repository.dart';
import '../features/project/data/project_repository.dart';
import '../features/profile/data/profile_repository.dart';

class DkjjApp extends StatelessWidget {
  const DkjjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AuthRepository>(
          update: (_, apiClient, __) => AuthRepository(apiClient),
        ),
        ProxyProvider<ApiClient, MessageRepository>(
          update: (_, apiClient, __) => MessageRepository(apiClient),
        ),
        ProxyProvider<ApiClient, ProfileRepository>(
          update: (_, apiClient, __) => ProfileRepository(apiClient),
        ),
        ProxyProvider<ApiClient, InspectionRepository>(
          update: (_, apiClient, __) => InspectionRepository(apiClient),
        ),
        ProxyProvider<ApiClient, ProjectRepository>(
          update: (_, apiClient, __) => ProjectRepository(apiClient),
        ),
        ProxyProvider<ApiClient, ModuleRepository>(
          update: (_, apiClient, __) => ModuleRepository(apiClient),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthController>(
          create: (context) => AuthController(context.read<AuthRepository>()),
          update: (_, repository, controller) =>
              controller ?? AuthController(repository),
        ),
      ],
      child: Consumer<AuthController>(
        builder: (context, authController, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: authController.isBootstrapping
                ? const _BootstrapPage()
                : authController.isLoggedIn
                    ? const AppShell()
                    : const LoginPage(),
          );
        },
      ),
    );
  }
}

class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
