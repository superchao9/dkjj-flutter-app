class LoginToken {
  LoginToken({
    required this.accessToken,
    this.refreshToken,
    this.expiresTime,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresTime;

  factory LoginToken.fromJson(Map<String, dynamic> json) {
    return LoginToken(
      accessToken: (json['accessToken'] ?? json['token'] ?? '') as String,
      refreshToken: json['refreshToken'] as String?,
      expiresTime: (json['expiresTime'] as num?)?.toInt(),
    );
  }
}

class CaptchaChallenge {
  CaptchaChallenge({
    required this.token,
    required this.secretKey,
    required this.originalImageBase64,
    required this.jigsawImageBase64,
  });

  final String token;
  final String secretKey;
  final String originalImageBase64;
  final String jigsawImageBase64;

  factory CaptchaChallenge.fromJson(Map<String, dynamic> json) {
    return CaptchaChallenge(
      token: (json['token'] ?? '') as String,
      secretKey: (json['secretKey'] ?? '') as String,
      originalImageBase64: (json['originalImageBase64'] ?? '') as String,
      jigsawImageBase64: (json['jigsawImageBase64'] ?? '') as String,
    );
  }
}

class UserInfo {
  UserInfo({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
  });

  final int id;
  final String username;
  final String nickname;
  final String? avatar;

  String get displayName => nickname.isNotEmpty ? nickname : username;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['userId'] ?? json['id'] ?? -1) as int,
      username: (json['username'] ?? '') as String,
      nickname: (json['nickname'] ?? '') as String,
      avatar: json['avatar'] as String?,
    );
  }
}

class PermissionInfo {
  PermissionInfo({
    required this.user,
    required this.roles,
    required this.permissions,
  });

  final UserInfo user;
  final List<String> roles;
  final List<String> permissions;

  factory PermissionInfo.fromJson(Map<String, dynamic> json) {
    return PermissionInfo(
      user: UserInfo.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}
