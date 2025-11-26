class Education {
  final int? id;
  final int teacherId;
  final String institution;
  final String? level;
  final String? program;
  final String? degree;
  final int? yearObtained;
  final int? institutionId;
  final DateTime? createdAt;

  Education({
    this.id,
    required this.teacherId,
    required this.institution,
    this.level,
    this.program,
    this.degree,
    this.yearObtained,
    this.institutionId,
    this.createdAt,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] as int?,
      teacherId: json['teacher_id'] as int,
      institution: json['institution'] as String,
      level: json['level'] as String?,
      program: json['program'] as String?,
      degree: json['degree'] as String?,
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
      'institution': institution,
      if (level != null) 'level': level,
      if (program != null) 'program': program,
      if (degree != null) 'degree': degree,
      if (yearObtained != null) 'year_obtained': yearObtained,
      if (institutionId != null) 'institution_id': institutionId,
    };
  }
}
