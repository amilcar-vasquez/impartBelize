class Application {
  final int applicationId;
  final int teacherId;
  final int userId;
  final String applicationType;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final int? reviewedBy;
  final String? rejectionReason;
  final String? notes;
  final String? licenseNumber;
  final DateTime? licenseIssuedDate;
  final DateTime? licenseExpiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from teacher join (if needed)
  String? teacherFirstName;
  String? teacherLastName;
  String? teacherEmail;
  int? teacherDistrictId;

  Application({
    required this.applicationId,
    required this.teacherId,
    required this.userId,
    required this.applicationType,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
    this.licenseNumber,
    this.licenseIssuedDate,
    this.licenseExpiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.teacherFirstName,
    this.teacherLastName,
    this.teacherEmail,
    this.teacherDistrictId,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      applicationId: json['application_id'],
      teacherId: json['teacher_id'],
      userId: json['user_id'],
      applicationType: json['application_type'],
      status: json['status'],
      submittedAt: DateTime.parse(json['submitted_at']),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      reviewedBy: json['reviewed_by'],
      rejectionReason: json['rejection_reason'],
      notes: json['notes'],
      licenseNumber: json['license_number'],
      licenseIssuedDate: json['license_issued_date'] != null
          ? DateTime.parse(json['license_issued_date'])
          : null,
      licenseExpiryDate: json['license_expiry_date'] != null
          ? DateTime.parse(json['license_expiry_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      teacherFirstName: json['teacher_first_name'],
      teacherLastName: json['teacher_last_name'],
      teacherEmail: json['teacher_email'],
      teacherDistrictId: json['teacher_district_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_id': applicationId,
      'teacher_id': teacherId,
      'user_id': userId,
      'application_type': applicationType,
      'status': status,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'notes': notes,
      'license_number': licenseNumber,
      'license_issued_date': licenseIssuedDate?.toIso8601String(),
      'license_expiry_date': licenseExpiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get teacherFullName {
    if (teacherFirstName != null && teacherLastName != null) {
      return '$teacherFirstName $teacherLastName';
    }
    return 'Unknown Teacher';
  }
}
