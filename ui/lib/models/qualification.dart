class Qualification {
  final int? id;
  final int teacherId;
  final String? institution;
  final String? specialization;
  final String? certification;
  final int? yearObtained;
  final int? institutionId;
  final DateTime? createdAt;

  Qualification({
    this.id,
    required this.teacherId,
    this.institution,
    this.specialization,
    this.certification,
    this.yearObtained,
    this.institutionId,
    this.createdAt,
  });

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      id: json['id'] as int?,
      teacherId: json['teacher_id'] as int,
      institution: json['institution'] as String?,
      specialization: json['specialization'] as String?,
      certification: json['certification'] as String?,
      yearObtained: json['year_obtained'] as int?,
      institutionId: json['institution_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'teacher_id': teacherId,
      if (institution != null) 'institution': institution,
      if (specialization != null) 'specialization': specialization,
      if (certification != null) 'certification': certification,
      if (yearObtained != null) 'year_obtained': yearObtained,
      if (institutionId != null) 'institution_id': institutionId,
    };
  }
}
