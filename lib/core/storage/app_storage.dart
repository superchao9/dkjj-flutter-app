import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  AppStorage._();

  static final AppStorage instance = AppStorage._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresTimeKey = 'expires_time';
  static const _tenantIdKey = 'tenant_id';
  static const _tenantNameKey = 'tenant_name';

  late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  String? get accessToken => _preferences.getString(_accessTokenKey);
  String? get refreshToken => _preferences.getString(_refreshTokenKey);
  int? get expiresTime => _preferences.getInt(_expiresTimeKey);
  int? get tenantId => _preferences.getInt(_tenantIdKey);
  String? get tenantName => _preferences.getString(_tenantNameKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresTime,
  }) async {
    await _preferences.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _preferences.setString(_refreshTokenKey, refreshToken);
    } else {
      await _preferences.remove(_refreshTokenKey);
    }
    if (expiresTime != null) {
      await _preferences.setInt(_expiresTimeKey, expiresTime);
    } else {
      await _preferences.remove(_expiresTimeKey);
    }
  }

  Future<void> clearTokens() async {
    await _preferences.remove(_accessTokenKey);
    await _preferences.remove(_refreshTokenKey);
    await _preferences.remove(_expiresTimeKey);
  }

  Future<void> saveTenantId(int tenantId) async {
    await _preferences.setInt(_tenantIdKey, tenantId);
  }

  Future<void> saveTenantName(String tenantName) async {
    await _preferences.setString(_tenantNameKey, tenantName);
  }

  Future<void> clearTenantId() async {
    await _preferences.remove(_tenantIdKey);
  }

  Future<void> clearTenantName() async {
    await _preferences.remove(_tenantNameKey);
  }
}
