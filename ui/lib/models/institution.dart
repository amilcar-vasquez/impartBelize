class Institution {
  final int id;
  final String name;
  final int? districtId;
  final String? institutionType;

  Institution({
    required this.id,
    required this.name,
    this.districtId,
    this.institutionType,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['institution_id'] as int,
      name: json['name'] as String,
      districtId: json['district_id'] as int?,
      institutionType: json['institution_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institution_id': id,
      'name': name,
      if (districtId != null) 'district_id': districtId,
      if (institutionType != null) 'institution_type': institutionType,
    };
  }

  @override
  String toString() {
    return 'Institution(id: $id, name: $name, districtId: $districtId, type: $institutionType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Institution &&
        other.id == id &&
        other.name == name &&
        other.districtId == districtId &&
        other.institutionType == institutionType;
  }

  @override
  int get hashCode => Object.hash(id, name, districtId, institutionType);
}
