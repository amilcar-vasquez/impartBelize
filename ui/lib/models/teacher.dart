class Teacher {
  final int id;
  final int? userId;
  final String firstName;
  final String lastName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? ssn;
  final String? maritalStatus;
  final String email;
  final String? address;
  final int? districtId;
  final String? phoneNumber;
  final String? profileStatus;
  final DateTime createdAt;

  Teacher({
    required this.id,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.dateOfBirth,
    this.ssn,
    this.maritalStatus,
    required this.email,
    this.address,
    this.districtId,
    this.phoneNumber,
    this.profileStatus,
    required this.createdAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['teacher_id'] as int,
      userId: json['user_id'] as int?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      gender: json['gender'] as String?,
      email: json['email'] as String,
      dateOfBirth: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      ssn: json['ssn'] as String?,
      maritalStatus: json['marital_status'] as String?,
      address: json['address'] as String?,
      districtId: json['district_id'] as int?,
      phoneNumber: json['phone'] as String?,
      profileStatus: json['profile_status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get fullName {
    return '$firstName $lastName';
  }

  Map<String, dynamic> toJson() {
    return {
      'teacher_id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'dob': dateOfBirth?.toIso8601String(),
      'ssn': ssn,
      'marital_status': maritalStatus,
      'email': email,
      'address': address,
      'district_id': districtId,
      'phone': phoneNumber,
      'profile_status': profileStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
