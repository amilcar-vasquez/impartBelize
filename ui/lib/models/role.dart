class Role {
  final int roleId;
  final String roleName;

  Role({required this.roleId, required this.roleName});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['id'] as int,
      roleName: json['role_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'role_id': roleId, 'role_name': roleName};
  }
}
