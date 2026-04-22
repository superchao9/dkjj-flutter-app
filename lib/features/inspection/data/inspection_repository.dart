import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import 'models/inspection_models.dart';

class InspectionRepository {
  InspectionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PageResult<InspectionWorkOrder>> getWorkOrders({
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return _apiClient.get<PageResult<InspectionWorkOrder>>(
      '/inspur/inspection-work-order/page',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
      parser: (raw) => PageResult<InspectionWorkOrder>.fromJson(
        raw as Map<String, dynamic>,
        InspectionWorkOrder.fromJson,
      ),
    );
  }

  Future<PageResult<InspectionReport>> getReports({
    int pageNo = 1,
    int pageSize = 20,
  }) {
    return _apiClient.get<PageResult<InspectionReport>>(
      '/inspur/inspection-report/page',
      queryParameters: {'pageNo': pageNo, 'pageSize': pageSize},
      parser: (raw) => PageResult<InspectionReport>.fromJson(
        raw as Map<String, dynamic>,
        InspectionReport.fromJson,
      ),
    );
  }

  Future<InspectionCollectionDashboard> getCollectionDashboard({
    int? workOrderId,
  }) {
    return _apiClient.get<InspectionCollectionDashboard>(
      '/inspur/inspection-collection/dashboard',
      queryParameters: workOrderId == null ? null : {'workOrderId': workOrderId},
      parser: (raw) =>
          InspectionCollectionDashboard.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<List<InspectionProcessTrace>> getProcessTraces(int workOrderId) {
    return _apiClient.get<List<InspectionProcessTrace>>(
      '/inspur/inspection-process-trace/list-by-work-order',
      queryParameters: {'workOrderId': workOrderId},
      parser: (raw) => (raw as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionProcessTrace.fromJson)
          .toList(growable: false),
    );
  }

  Future<InspectionAnalysisOverview> getAnalysisOverview() {
    return _apiClient.get<InspectionAnalysisOverview>(
      '/inspur/inspection-analysis/overview',
      parser: (raw) =>
          InspectionAnalysisOverview.fromJson(raw as Map<String, dynamic>),
    );
  }
}
