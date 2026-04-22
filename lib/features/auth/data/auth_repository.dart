import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../core/utils/aes_cipher.dart';
import 'models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginToken> login({
    required String username,
    required String password,
    required int tenantId,
    required String captchaVerification,
  }) {
    return _apiClient.post<LoginToken>(
      '/system/auth/login',
      data: {
        'username': username,
        'password': password,
        'captchaVerification': captchaVerification,
      },
      parser: (raw) => LoginToken.fromJson(raw as Map<String, dynamic>),
      skipAuth: true,
    );
  }

  Future<int> getTenantIdByName(String tenantName) {
    return _apiClient.get<int>(
      '/system/tenant/get-id-by-name',
      queryParameters: {'name': tenantName},
      parser: (raw) => (raw as num?)?.toInt() ?? 0,
      skipAuth: true,
    );
  }

  Future<CaptchaChallenge> fetchCaptcha({
    String captchaType = 'blockPuzzle',
  }) async {
    final body = await _apiClient.postRaw(
      '/system/captcha/get',
      data: {'captchaType': captchaType},
      skipAuth: true,
    );
    final code = body['repCode']?.toString() ?? '';
    if (code != '0000') {
      throw ApiException(
        (body['repMsg'] ?? body['msg'] ?? '获取验证码失败').toString(),
      );
    }
    final data = body['repData'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('验证码数据格式错误，请稍后重试');
    }
    return CaptchaChallenge.fromJson(data);
  }

  Future<String> verifyCaptcha({
    required CaptchaChallenge challenge,
    required double x,
    double y = 5.0,
    String captchaType = 'blockPuzzle',
  }) async {
    final pointJson = '{"x":$x,"y":$y}';
    final encryptedPoint = challenge.secretKey.isNotEmpty
        ? AesCipher.encrypt(pointJson, challenge.secretKey)
        : pointJson;
    final body = await _apiClient.postRaw(
      '/system/captcha/check',
      data: {
        'captchaType': captchaType,
        'pointJson': encryptedPoint,
        'token': challenge.token,
      },
      skipAuth: true,
    );
    final code = body['repCode']?.toString() ?? '';
    if (code != '0000') {
      throw ApiException(
        (body['repMsg'] ?? body['msg'] ?? '验证码校验失败，请重试').toString(),
      );
    }
    final verificationRaw = '${challenge.token}---$pointJson';
    return challenge.secretKey.isNotEmpty
        ? AesCipher.encrypt(verificationRaw, challenge.secretKey)
        : verificationRaw;
  }

  Future<PermissionInfo> getPermissionInfo() {
    return _apiClient.get<PermissionInfo>(
      '/system/auth/get-permission-info',
      parser: (raw) => PermissionInfo.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>(
        '/system/auth/logout',
        parser: (_) {},
      );
    } catch (_) {
      // Keep logout resilient on the client side.
    } finally {
      await AppStorage.instance.clearTokens();
    }
  }

  Future<void> persistToken(LoginToken token) {
    return AppStorage.instance.saveTokens(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresTime: token.expiresTime,
    );
  }

  String? get currentToken => AppStorage.instance.accessToken;
  int? get currentTenantId => AppStorage.instance.tenantId;
  String? get currentTenantName => AppStorage.instance.tenantName;

  Future<void> persistTenantId(int tenantId) {
    return AppStorage.instance.saveTenantId(tenantId);
  }

  Future<void> persistTenantName(String tenantName) {
    return AppStorage.instance.saveTenantName(tenantName);
  }
}
