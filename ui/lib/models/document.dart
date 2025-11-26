class Document {
  final int? id;
  final int teacherId;
  final String docType;
  final String filePath;
  final int? uploadedBy;
  final bool verified;
  final int? verifiedBy;
  final String? remarks;
  final int? applicationId;
  final DateTime? createdAt;

  Document({
    this.id,
    required this.teacherId,
    required this.docType,
    required this.filePath,
    this.uploadedBy,
    this.verified = false,
    this.verifiedBy,
    this.remarks,
    this.applicationId,
    this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as int?,
      teacherId: json['teacher_id'] as int,
      docType: json['doc_type'] as String,
      filePath: json['file_path'] as String,
      uploadedBy: json['uploaded_by'] as int?,
      verified: json['verified'] as bool? ?? false,
      verifiedBy: json['verified_by'] as int?,
      remarks: json['remarks'] as String?,
      applicationId: json['application_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'teacher_id': teacherId,
      'doc_type': docType,
      'file_path': filePath,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      'verified': verified,
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (remarks != null) 'remarks': remarks,
      if (applicationId != null) 'application_id': applicationId,
    };
  }
}
