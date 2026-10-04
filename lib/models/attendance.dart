enum AttendanceStatus {
  full,
  half,
  lembur1,
  lembur2,
  lemburEkstra,
  off;

  double get value => {
    AttendanceStatus.full: 1.0,
    AttendanceStatus.half: 0.5,
    AttendanceStatus.lembur1: 1.0,
    AttendanceStatus.lembur2: 1.0,
    AttendanceStatus.lemburEkstra: 1.0,
    AttendanceStatus.off: 0.0,
  }[this]!;

  String get label => {
    AttendanceStatus.full: 'FULL',
    AttendanceStatus.half: '1/2 HARI',
    AttendanceStatus.lembur1: 'LEMBUR 1',
    AttendanceStatus.lembur2: 'LEMBUR 2',
    AttendanceStatus.lemburEkstra: 'LEMBUR EKSTRA',
    AttendanceStatus.off: 'OFF',
  }[this]!;
}

class AttendanceRecord {
  final String id;
  final String workerId;
  final String date;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.id,
    required this.workerId,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'status': status.name.toUpperCase(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id']?.toString() ?? '',
      workerId: map['worker_id'] ?? '',
      date: map['date'] ?? '',
      status: _parseStatus(map['status']),
    );
  }

  static AttendanceStatus _parseStatus(String? status) {
    if (status == null) return AttendanceStatus.off;
    final s = status.toUpperCase().replaceAll('_', '').replaceAll(' ', '');
    switch (s) {
      case 'FULL': return AttendanceStatus.full;
      case 'HALF': return AttendanceStatus.half;
      case 'LEMBUR1': return AttendanceStatus.lembur1;
      case 'LEMBUR2': return AttendanceStatus.lembur2;
      case 'LEMBUREKSTRA': return AttendanceStatus.lemburEkstra;
      case 'OFF': return AttendanceStatus.off;
      default: return AttendanceStatus.off;
    }
  }
}
