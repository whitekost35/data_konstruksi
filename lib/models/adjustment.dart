class WeeklyAdjustment {
  final String id;
  final String workerId;
  final String weekStartDate;
  final double manualOvertime;
  final double privateKasbon;

  WeeklyAdjustment({
    required this.id,
    required this.workerId,
    required this.weekStartDate,
    this.manualOvertime = 0.0,
    this.privateKasbon = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'week_start_date': weekStartDate,
      'manual_overtime': manualOvertime,
      'private_kasbon': privateKasbon,
    };
  }

  factory WeeklyAdjustment.fromMap(Map<String, dynamic> map) {
    return WeeklyAdjustment(
      id: map['id']?.toString() ?? '',
      workerId: map['worker_id'] ?? '',
      weekStartDate: map['week_start_date'] ?? '',
      manualOvertime: (map['manual_overtime'] ?? 0.0).toDouble(),
      privateKasbon: (map['private_kasbon'] ?? 0.0).toDouble(),
    );
  }
}
