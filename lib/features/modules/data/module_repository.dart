import '../../../core/network/api_client.dart';
import 'module_models.dart';

class ModuleRepository {
  ModuleRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DynamicPageResult> fetchPage(
    ModuleDefinition module, {
    Map<String, dynamic>? query,
  }) async {
    final path = module.pagePath ?? module.listPath;
    final raw = await _apiClient.get<dynamic>(
      path!,
      queryParameters: query,
      parser: (value) => value,
    );
    if (module.pageResult) {
      final map = (raw as Map<String, dynamic>?) ?? <String, dynamic>{};
      final list = (map['list'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      return DynamicPageResult(
        total: (map['total'] as num?)?.toInt() ?? list.length,
        list: list,
      );
    }
    final list = (raw as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return DynamicPageResult(total: list.length, list: list);
  }

  Future<Map<String, dynamic>> fetchDetail(
    ModuleDefinition module,
    dynamic id,
  ) async {
    final raw = await _apiClient.get<dynamic>(
      module.detailPath!,
      queryParameters: {'id': id},
      parser: (value) => value,
    );
    return (raw as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<void> create(ModuleDefinition module, Map<String, dynamic> data) {
    return _apiClient.post<void>(
      module.createPath!,
      data: data,
      parser: (_) {},
    );
  }

  Future<void> update(ModuleDefinition module, Map<String, dynamic> data) {
    return _apiClient.put<void>(
      module.updatePath!,
      data: data,
      parser: (_) {},
    );
  }

  Future<void> delete(ModuleDefinition module, dynamic id) {
    return _apiClient.delete<void>(
      module.deletePath!,
      queryParameters: {'id': id},
      parser: (_) {},
    );
  }

  Future<void> submit(ModuleDefinition module, dynamic id) {
    return _apiClient.put<void>(
      module.submitPath!,
      queryParameters: {'id': id},
      parser: (_) {},
    );
  }

  Future<Map<String, dynamic>> fetchApprovalDetail(String processInstanceId) async {
    final raw = await _apiClient.get<dynamic>(
      '/bpm/process-instance/get-approval-detail',
      queryParameters: {'processInstanceId': processInstanceId},
      parser: (value) => value,
    );
    return (raw as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  Future<DynamicPageResult> fetchProcessCenterPage({
    required bool manager,
    Map<String, dynamic>? query,
  }) async {
    final raw = await _apiClient.get<dynamic>(
      manager
          ? '/bpm/process-instance/manager-page'
          : '/bpm/process-instance/my-page',
      queryParameters: query,
      parser: (value) => value,
    );
    final map = (raw as Map<String, dynamic>?) ?? <String, dynamic>{};
    final list = (map['list'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return DynamicPageResult(
      total: (map['total'] as num?)?.toInt() ?? list.length,
      list: list,
    );
  }
}
