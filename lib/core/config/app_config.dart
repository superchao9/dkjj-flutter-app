enum AppEnvironment { dev, test, prod }

class AppConfig {
  const AppConfig._();

  static late AppEnvironment environment;
  static late String appName;
  static late String baseUrl;

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String _globalAppName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: '',
  );

  static const String _globalBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _devAppName = String.fromEnvironment(
    'APP_NAME_DEV',
    defaultValue: '低空基础设施管理系统',
  );
  static const String _testAppName = String.fromEnvironment(
    'APP_NAME_TEST',
    defaultValue: '低空基础设施管理系统',
  );
  static const String _prodAppName = String.fromEnvironment(
    'APP_NAME_PROD',
    defaultValue: '低空基础设施管理系统',
  );

  static const String _devBaseUrl = String.fromEnvironment(
    'API_BASE_URL_DEV',
    defaultValue: 'http://10.0.2.2:48080/admin-api',
  );
  static const String _testBaseUrl = String.fromEnvironment(
    'API_BASE_URL_TEST',
    defaultValue: 'http://10.0.2.2:48080/admin-api',
  );
  static const String _prodBaseUrl = String.fromEnvironment(
    'API_BASE_URL_PROD',
    defaultValue: 'http://10.0.2.2:48080/admin-api',
  );

  static void init(AppEnvironment env) {
    environment = env;
    final defaultByEnv = switch (env) {
      AppEnvironment.dev => _EnvConfig(_devAppName, _devBaseUrl),
      AppEnvironment.test => _EnvConfig(_testAppName, _testBaseUrl),
      AppEnvironment.prod => _EnvConfig(_prodAppName, _prodBaseUrl),
    };
    appName = _globalAppName.trim().isEmpty
        ? defaultByEnv.appName
        : _globalAppName.trim();
    baseUrl = _globalBaseUrl.trim().isEmpty
        ? defaultByEnv.baseUrl
        : _globalBaseUrl.trim();
  }
}

class _EnvConfig {
  const _EnvConfig(this.appName, this.baseUrl);

  final String appName;
  final String baseUrl;
}
