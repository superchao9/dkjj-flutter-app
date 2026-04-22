import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'models/project_models.dart';

class ProjectRepository {
  ProjectRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PageResult<ProjectDeviceInfo>> getDevices({
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return _apiClient.get<PageResult<ProjectDeviceInfo>>(
      '/project/device-info/page',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
      parser: (raw) => PageResult<ProjectDeviceInfo>.fromJson(
        raw as Map<String, dynamic>,
        ProjectDeviceInfo.fromJson,
      ),
    );
  }

  Future<ProjectDeviceWarningSummary> getWarningSummary() {
    return _apiClient.get<ProjectDeviceWarningSummary>(
      '/project/device-warning-record/summary',
      queryParameters: const {'pageNo': 1, 'pageSize': 20},
      parser: (raw) =>
          ProjectDeviceWarningSummary.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<PageResult<ProjectDeviceWarningRecord>> getWarnings({
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return _apiClient.get<PageResult<ProjectDeviceWarningRecord>>(
      '/project/device-warning-record/page',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
      parser: (raw) => PageResult<ProjectDeviceWarningRecord>.fromJson(
        raw as Map<String, dynamic>,
        ProjectDeviceWarningRecord.fromJson,
      ),
    );
  }

  Future<PageResult<ProjectAssetLedger>> getAssets({
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return _apiClient.get<PageResult<ProjectAssetLedger>>(
      '/project/asset-ledger/page',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
      parser: (raw) => PageResult<ProjectAssetLedger>.fromJson(
        raw as Map<String, dynamic>,
        ProjectAssetLedger.fromJson,
      ),
    );
  }
}
