import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    bootstrap();
  }

  final AuthRepository _repository;

  bool _isBootstrapping = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  PermissionInfo? _session;
  int? _tenantId;
  String? _tenantName;

  bool get isBootstrapping => _isBootstrapping;
  bool get isSubmitting => _isSubmitting;
  bool get isLoggedIn => _session != null;
  String? get errorMessage => _errorMessage;
  PermissionInfo? get session => _session;
  UserInfo? get user => _session?.user;
  int? get tenantId => _tenantId;
  String? get tenantName => _tenantName;

  Future<void> bootstrap() async {
    _isBootstrapping = true;
    notifyListeners();
    try {
      _tenantId = _repository.currentTenantId;
      _tenantName = _repository.currentTenantName;
      if ((_repository.currentToken ?? '').isNotEmpty) {
        _session = await _repository.getPermissionInfo();
      }
    } catch (_) {
      await _repository.logout();
      _session = null;
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    required String tenantName,
    required String captchaVerification,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _tenantName = tenantName.trim();
    notifyListeners();
    try {
      final tenantId = await _repository.getTenantIdByName(_tenantName!);
      if (tenantId <= 0) {
        throw ApiException('未查询到对应租户，请检查租户名称');
      }
      _tenantId = tenantId;
      await _repository.persistTenantId(tenantId);
      await _repository.persistTenantName(_tenantName!);
      final token = await _repository.login(
        username: username,
        password: password,
        tenantId: tenantId,
        captchaVerification: captchaVerification,
      );
      await _repository.persistToken(token);
      _session = await _repository.getPermissionInfo();
      return true;
    } catch (error) {
      _errorMessage = _mapErrorMessage(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _session = null;
    _tenantId = null;
    notifyListeners();
  }

  String _mapErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains("type 'Null' is not a subtype")) {
      return '服务返回了异常数据，请稍后重试或联系管理员';
    }
    if (message.isEmpty) {
      return '登录失败，请稍后重试';
    }
    return message;
  }
}
