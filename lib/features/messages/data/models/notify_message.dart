class NotifyMessage {
  NotifyMessage({
    required this.id,
    required this.templateNickname,
    required this.templateContent,
    required this.templateType,
    required this.readStatus,
    this.readTime,
    this.createTime,
  });

  final int id;
  final String templateNickname;
  final String templateContent;
  final int templateType;
  final bool readStatus;
  final DateTime? readTime;
  final DateTime? createTime;

  factory NotifyMessage.fromJson(Map<String, dynamic> json) {
    return NotifyMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      templateNickname: (json['templateNickname'] ?? '') as String,
      templateContent: (json['templateContent'] ?? '') as String,
      templateType: (json['templateType'] as num?)?.toInt() ?? 0,
      readStatus: json['readStatus'] == true,
      readTime: _parseDateTime(json['readTime']),
      createTime: _parseDateTime(json['createTime']),
    );
  }
}

DateTime? _parseDateTime(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return DateTime.tryParse(raw.toString());
}
