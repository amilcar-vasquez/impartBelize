class User {
  final int userId;
  final String username;
  final String email;
  final int roleId;
  final String? roleName;
  final bool isActive;
  final bool isActivated;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.roleId,
    this.roleName,
    required this.isActive,
    required this.isActivated,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      roleId: json['role_id'] as int,
      roleName: json['role_name'] as String?,
      isActive: json['is_active'] as bool,
      isActivated: json['is_activated'] as bool,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role_id': roleId,
      'role_name': roleName,
      'is_active': isActive,
      'is_activated': isActivated,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => roleId == 1;
  bool get isRegularUser => roleId == 2;
}
