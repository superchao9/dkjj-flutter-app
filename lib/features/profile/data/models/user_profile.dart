class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    required this.nickname,
    this.email,
    this.mobile,
    this.avatar,
    this.loginIp,
    this.loginDate,
    this.deptName,
    this.roles = const [],
  });

  final int id;
  final String username;
  final String nickname;
  final String? email;
  final String? mobile;
  final String? avatar;
  final String? loginIp;
  final DateTime? loginDate;
  final String? deptName;
  final List<String> roles;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawRoles = (json['roles'] as List<dynamic>? ?? const []);
    final rawDept = json['dept'] as Map<String, dynamic>?;
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '') as String,
      nickname: (json['nickname'] ?? '') as String,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      avatar: json['avatar'] as String?,
      loginIp: json['loginIp'] as String?,
      loginDate: _parseDateTime(json['loginDate']),
      deptName: rawDept?['name'] as String?,
      roles: rawRoles
          .whereType<Map<String, dynamic>>()
          .map((item) => (item['name'] ?? '') as String)
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
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
