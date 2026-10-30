class LeaveBalanceDto {
  const LeaveBalanceDto({required this.availableDays, required this.totalDays});

  final int availableDays;
  final int totalDays;

  factory LeaveBalanceDto.fromJson(Map<String, dynamic> json) => LeaveBalanceDto(
    availableDays: json['availableDays'] as int,
    totalDays: json['totalDays'] as int,
  );

  Map<String, dynamic> toJson() => {
    'availableDays': availableDays,
    'totalDays': totalDays,
  };
}
