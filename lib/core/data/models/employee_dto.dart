class OfficeConfigDto {
  const OfficeConfigDto({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;

  factory OfficeConfigDto.fromJson(Map<String, dynamic> json) =>
      OfficeConfigDto(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
  };
}

class EmployeeDto {
  const EmployeeDto({
    required this.employeeId,
    required this.name,
    required this.department,
    required this.office,
  });

  final String employeeId;
  final String name;
  final String department;
  final OfficeConfigDto office;

  factory EmployeeDto.fromJson(Map<String, dynamic> json) => EmployeeDto(
    employeeId: json['employeeId'] as String,
    name: json['name'] as String,
    department: json['department'] as String,
    office: OfficeConfigDto.fromJson(
      Map<String, dynamic>.from(json['office'] as Map),
    ),
  );

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'name': name,
    'department': department,
    'office': office.toJson(),
  };
}
