import '../../../../core/network/api_response.dart';
import '../../../inspection/data/models/inspection_models.dart';

class ProjectDeviceInfo {
  ProjectDeviceInfo({
    required this.id,
    required this.deviceName,
    required this.deviceCode,
    this.categoryName,
    this.manufacturer,
    this.model,
    this.specification,
    this.deviceStatus,
    this.createTime,
  });

  final int id;
  final String deviceName;
  final String deviceCode;
  final String? categoryName;
  final String? manufacturer;
  final String? model;
  final String? specification;
  final int? deviceStatus;
  final DateTime? createTime;

  factory ProjectDeviceInfo.fromJson(Map<String, dynamic> json) {
    return ProjectDeviceInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      deviceName: (json['deviceName'] ?? '-') as String,
      deviceCode: (json['deviceCode'] ?? '-') as String,
      categoryName: json['categoryName'] as String?,
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      specification: json['specification'] as String?,
      deviceStatus: (json['deviceStatus'] as num?)?.toInt(),
      createTime: parseFlexibleDateTime(json['createTime']),
    );
  }
}

class ProjectDeviceWarningSummary {
  ProjectDeviceWarningSummary({
    required this.total,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.pending,
    required this.handled,
  });

  final int total;
  final int level1;
  final int level2;
  final int level3;
  final int pending;
  final int handled;

  factory ProjectDeviceWarningSummary.fromJson(Map<String, dynamic> json) {
    return ProjectDeviceWarningSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      level1: (json['level1'] as num?)?.toInt() ?? 0,
      level2: (json['level2'] as num?)?.toInt() ?? 0,
      level3: (json['level3'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      handled: (json['handled'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProjectDeviceWarningRecord {
  ProjectDeviceWarningRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.monitorType,
    required this.warningType,
    this.dataValue,
    this.dataUnit,
    this.warningLevel,
    this.handleStatus,
    this.longitude,
    this.latitude,
    this.warningTime,
    this.abnormalReason,
  });

  final int id;
  final int deviceId;
  final String deviceName;
  final String monitorType;
  final String warningType;
  final num? dataValue;
  final String? dataUnit;
  final int? warningLevel;
  final int? handleStatus;
  final double? longitude;
  final double? latitude;
  final DateTime? warningTime;
  final String? abnormalReason;

  factory ProjectDeviceWarningRecord.fromJson(Map<String, dynamic> json) {
    return ProjectDeviceWarningRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      deviceId: (json['deviceId'] as num?)?.toInt() ?? 0,
      deviceName: (json['deviceName'] ?? '-') as String,
      monitorType: (json['monitorType'] ?? '-') as String,
      warningType: (json['warningType'] ?? '-') as String,
      dataValue: json['dataValue'] as num?,
      dataUnit: json['dataUnit'] as String?,
      warningLevel: (json['warningLevel'] as num?)?.toInt(),
      handleStatus: (json['handleStatus'] as num?)?.toInt(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      warningTime: parseFlexibleDateTime(json['warningTime']),
      abnormalReason: json['abnormalReason'] as String?,
    );
  }
}

class ProjectAssetLedger {
  ProjectAssetLedger({
    required this.id,
    required this.assetId,
    this.assetCode,
    this.assetName,
    this.assetCategory,
    this.businessType,
    this.lifecycleNode,
    this.useDept,
    this.keeperUser,
    this.storageLocation,
    this.assetStatus,
    this.occurDate,
  });

  final int id;
  final int assetId;
  final String? assetCode;
  final String? assetName;
  final String? assetCategory;
  final String? businessType;
  final String? lifecycleNode;
  final String? useDept;
  final String? keeperUser;
  final String? storageLocation;
  final String? assetStatus;
  final DateTime? occurDate;

  factory ProjectAssetLedger.fromJson(Map<String, dynamic> json) {
    return ProjectAssetLedger(
      id: (json['id'] as num?)?.toInt() ?? 0,
      assetId: (json['assetId'] as num?)?.toInt() ?? 0,
      assetCode: json['assetCode'] as String?,
      assetName: json['assetName'] as String?,
      assetCategory: json['assetCategory'] as String?,
      businessType: json['businessType'] as String?,
      lifecycleNode: json['lifecycleNode'] as String?,
      useDept: json['useDept'] as String?,
      keeperUser: json['keeperUser'] as String?,
      storageLocation: json['storageLocation'] as String?,
      assetStatus: json['assetStatus'] as String?,
      occurDate: parseFlexibleDateTime(json['occurDate']),
    );
  }
}

typedef ProjectDevicePage = PageResult<ProjectDeviceInfo>;
typedef ProjectWarningPage = PageResult<ProjectDeviceWarningRecord>;
typedef ProjectAssetPage = PageResult<ProjectAssetLedger>;
