class AttendanceRecord {
  final String dateId; // The ID of the training night
  final Map<String, String> statuses; // cadetUid -> 'Present', 'Absent', 'Excused', 'Late'

  AttendanceRecord({
    required this.dateId,
    required this.statuses,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceRecord(
      dateId: id,
      statuses: Map<String, String>.from(data['statuses'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statuses': statuses,
    };
  }
}
