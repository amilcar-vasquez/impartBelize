class District {
  final int id;
  final String name;

  District({
    required this.id,
    required this.name,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['district_id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'district_id': id,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'District(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
