class AttendanceRecord {
  final String cadetId;
  final String status; // 'present', 'absent', 'excused'
  final bool excused;
  final bool arrivedLate;
  final bool leftEarly;

  AttendanceRecord({
    required this.cadetId,
    required this.status,
    this.excused = false,
    this.arrivedLate = false,
    this.leftEarly = false,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      cadetId: map['cadetId'] ?? '',
      status: map['status'] ?? '',
      excused: map['excused'] ?? false,
      arrivedLate: map['arrivedLate'] ?? false,
      leftEarly: map['leftEarly'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cadetId': cadetId,
      'status': status,
      'excused': excused,
      'arrivedLate': arrivedLate,
      'leftEarly': leftEarly,
    };
  }
}
