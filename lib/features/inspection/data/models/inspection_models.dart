import '../../../../core/network/api_response.dart';

DateTime? parseFlexibleDateTime(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return DateTime.tryParse(raw.toString());
}

class InspectionWorkOrder {
  InspectionWorkOrder({
    required this.id,
    required this.no,
    required this.deviceName,
    required this.routeName,
    required this.areaName,
    required this.inspectionTypeName,
    required this.serviceProviderName,
    this.inspectionDate,
    this.plannedTime,
    this.auditStatus,
    this.dispatchStatus,
    this.description,
  });

  final int id;
  final String no;
  final String deviceName;
  final String routeName;
  final String areaName;
  final String inspectionTypeName;
  final String serviceProviderName;
  final DateTime? inspectionDate;
  final DateTime? plannedTime;
  final int? auditStatus;
  final int? dispatchStatus;
  final String? description;

  factory InspectionWorkOrder.fromJson(Map<String, dynamic> json) {
    return InspectionWorkOrder(
      id: (json['id'] as num?)?.toInt() ?? 0,
      no: (json['no'] ?? '') as String,
      deviceName: (json['deviceName'] ?? '-') as String,
      routeName: (json['routeName'] ?? '-') as String,
      areaName: (json['areaName'] ?? '-') as String,
      inspectionTypeName: (json['inspectionTypeName'] ?? '-') as String,
      serviceProviderName: (json['serviceProviderName'] ?? '-') as String,
      inspectionDate: parseFlexibleDateTime(json['inspectionDate']),
      plannedTime: parseFlexibleDateTime(json['plannedTime']),
      auditStatus: (json['auditStatus'] as num?)?.toInt(),
      dispatchStatus: (json['dispatchStatus'] as num?)?.toInt(),
      description: json['description'] as String?,
    );
  }
}

class InspectionReport {
  InspectionReport({
    required this.id,
    required this.no,
    required this.title,
    required this.workOrderId,
    this.summary,
    this.conclusion,
    this.reportDate,
    this.auditStatus,
    this.workOrderNo,
  });

  final int id;
  final String no;
  final String title;
  final int workOrderId;
  final String? summary;
  final String? conclusion;
  final DateTime? reportDate;
  final int? auditStatus;
  final String? workOrderNo;

  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    final workOrderDetail = json['workOrderDetail'] as Map<String, dynamic>?;
    return InspectionReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      no: (json['no'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      workOrderId: (json['workOrderId'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String?,
      conclusion: json['conclusion'] as String?,
      reportDate: parseFlexibleDateTime(json['reportDate']),
      auditStatus: (json['auditStatus'] as num?)?.toInt(),
      workOrderNo: (workOrderDetail?['no'] ?? json['workOrderNo']) as String?,
    );
  }
}

class InspectionCollectionTask {
  InspectionCollectionTask({
    required this.workOrderId,
    required this.no,
    required this.routeName,
    required this.areaName,
    required this.deviceName,
    this.plannedTime,
  });

  final int workOrderId;
  final String no;
  final String routeName;
  final String areaName;
  final String deviceName;
  final DateTime? plannedTime;

  factory InspectionCollectionTask.fromJson(Map<String, dynamic> json) {
    return InspectionCollectionTask(
      workOrderId: (json['workOrderId'] as num?)?.toInt() ?? 0,
      no: (json['no'] ?? '') as String,
      routeName: (json['routeName'] ?? '-') as String,
      areaName: (json['areaName'] ?? '-') as String,
      deviceName: (json['deviceName'] ?? '-') as String,
      plannedTime: parseFlexibleDateTime(json['plannedTime']),
    );
  }
}

class InspectionMetricPoint {
  InspectionMetricPoint({
    this.time,
    this.value,
    this.warningSummary,
  });

  final DateTime? time;
  final num? value;
  final String? warningSummary;

  factory InspectionMetricPoint.fromJson(Map<String, dynamic> json) {
    return InspectionMetricPoint(
      time: parseFlexibleDateTime(json['time']),
      value: json['value'] as num?,
      warningSummary: json['warningSummary'] as String?,
    );
  }
}

class InspectionMetric {
  InspectionMetric({
    required this.metricCode,
    required this.metricName,
    required this.history,
    this.metricUnit,
    this.currentValue,
    this.currentTime,
    this.warningType,
  });

  final String metricCode;
  final String metricName;
  final String? metricUnit;
  final num? currentValue;
  final DateTime? currentTime;
  final String? warningType;
  final List<InspectionMetricPoint> history;

  factory InspectionMetric.fromJson(Map<String, dynamic> json) {
    final history = (json['history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InspectionMetricPoint.fromJson)
        .toList(growable: false);
    return InspectionMetric(
      metricCode: (json['metricCode'] ?? '') as String,
      metricName: (json['metricName'] ?? '') as String,
      metricUnit: json['metricUnit'] as String?,
      currentValue: json['currentValue'] as num?,
      currentTime: parseFlexibleDateTime(json['currentTime']),
      warningType: json['warningType'] as String?,
      history: history,
    );
  }
}

class InspectionTrackPoint {
  InspectionTrackPoint({
    this.lng,
    this.lat,
    this.speed,
    this.pointTime,
    this.warningSummary,
  });

  final num? lng;
  final num? lat;
  final num? speed;
  final DateTime? pointTime;
  final String? warningSummary;

  factory InspectionTrackPoint.fromJson(Map<String, dynamic> json) {
    return InspectionTrackPoint(
      lng: json['lng'] as num?,
      lat: json['lat'] as num?,
      speed: json['speed'] as num?,
      pointTime: parseFlexibleDateTime(json['pointTime']),
      warningSummary: json['warningSummary'] as String?,
    );
  }
}

class InspectionProcessTrace {
  InspectionProcessTrace({
    required this.title,
    required this.content,
    this.traceTime,
  });

  final String title;
  final String content;
  final DateTime? traceTime;

  factory InspectionProcessTrace.fromJson(Map<String, dynamic> json) {
    return InspectionProcessTrace(
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      traceTime: parseFlexibleDateTime(json['traceTime']),
    );
  }
}

class InspectionCollectionDashboard {
  InspectionCollectionDashboard({
    required this.workOrders,
    required this.deviceMetrics,
    required this.operationMetrics,
    required this.safetyMetrics,
    required this.trackPoints,
  });

  final List<InspectionCollectionTask> workOrders;
  final List<InspectionMetric> deviceMetrics;
  final List<InspectionMetric> operationMetrics;
  final List<InspectionMetric> safetyMetrics;
  final List<InspectionTrackPoint> trackPoints;

  factory InspectionCollectionDashboard.fromJson(Map<String, dynamic> json) {
    return InspectionCollectionDashboard(
      workOrders: (json['workOrders'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionCollectionTask.fromJson)
          .toList(growable: false),
      deviceMetrics: (json['deviceMetrics'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionMetric.fromJson)
          .toList(growable: false),
      operationMetrics: (json['operationMetrics'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionMetric.fromJson)
          .toList(growable: false),
      safetyMetrics: (json['safetyMetrics'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionMetric.fromJson)
          .toList(growable: false),
      trackPoints: (json['trackPoints'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionTrackPoint.fromJson)
          .toList(growable: false),
    );
  }
}

class AnalysisSummaryCard {
  AnalysisSummaryCard({
    required this.title,
    required this.value,
    this.unit,
    this.description,
    this.accent,
  });

  final String title;
  final num value;
  final String? unit;
  final String? description;
  final String? accent;

  factory AnalysisSummaryCard.fromJson(Map<String, dynamic> json) {
    return AnalysisSummaryCard(
      title: (json['title'] ?? '') as String,
      value: (json['value'] as num?) ?? 0,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      accent: json['accent'] as String?,
    );
  }
}

class AnalysisRiskItem {
  AnalysisRiskItem({
    required this.workOrderNo,
    required this.deviceName,
    required this.metricName,
    this.metricValue,
    this.metricUnit,
    this.riskLevel,
    this.description,
    this.collectedTime,
  });

  final String workOrderNo;
  final String deviceName;
  final String metricName;
  final num? metricValue;
  final String? metricUnit;
  final String? riskLevel;
  final String? description;
  final DateTime? collectedTime;

  factory AnalysisRiskItem.fromJson(Map<String, dynamic> json) {
    return AnalysisRiskItem(
      workOrderNo: (json['workOrderNo'] ?? '') as String,
      deviceName: (json['deviceName'] ?? '-') as String,
      metricName: (json['metricName'] ?? '-') as String,
      metricValue: json['metricValue'] as num?,
      metricUnit: json['metricUnit'] as String?,
      riskLevel: json['riskLevel'] as String?,
      description: json['description'] as String?,
      collectedTime: parseFlexibleDateTime(json['collectedTime']),
    );
  }
}

class AnalysisReportInsight {
  AnalysisReportInsight({
    required this.title,
    this.workOrderNo,
    this.reportNo,
    this.auditStatusName,
    this.reportTime,
    this.summary,
  });

  final String title;
  final String? workOrderNo;
  final String? reportNo;
  final String? auditStatusName;
  final DateTime? reportTime;
  final String? summary;

  factory AnalysisReportInsight.fromJson(Map<String, dynamic> json) {
    return AnalysisReportInsight(
      title: (json['title'] ?? '-') as String,
      workOrderNo: json['workOrderNo'] as String?,
      reportNo: json['reportNo'] as String?,
      auditStatusName: json['auditStatusName'] as String?,
      reportTime: parseFlexibleDateTime(json['reportTime']),
      summary: json['summary'] as String?,
    );
  }
}

class InspectionAnalysisOverview {
  InspectionAnalysisOverview({
    required this.summaryCards,
    required this.riskItems,
    required this.latestReports,
    required this.pendingSyncCount,
    required this.syncedCount,
  });

  final List<AnalysisSummaryCard> summaryCards;
  final List<AnalysisRiskItem> riskItems;
  final List<AnalysisReportInsight> latestReports;
  final int pendingSyncCount;
  final int syncedCount;

  factory InspectionAnalysisOverview.fromJson(Map<String, dynamic> json) {
    return InspectionAnalysisOverview(
      summaryCards: (json['summaryCards'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalysisSummaryCard.fromJson)
          .toList(growable: false),
      riskItems: (json['riskItems'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalysisRiskItem.fromJson)
          .toList(growable: false),
      latestReports: (json['latestReports'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnalysisReportInsight.fromJson)
          .toList(growable: false),
      pendingSyncCount: (json['pendingSyncCount'] as num?)?.toInt() ?? 0,
      syncedCount: (json['syncedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

typedef WorkOrderPage = PageResult<InspectionWorkOrder>;
typedef ReportPage = PageResult<InspectionReport>;
