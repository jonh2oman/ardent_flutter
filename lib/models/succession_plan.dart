import 'package:cloud_firestore/cloud_firestore.dart';

class SuccessionCandidate {
  final String staffId;
  final String readiness; // 'ready_now', '1_2_years', '3_plus_years'
  final String notes;

  SuccessionCandidate({
    required this.staffId,
    required this.readiness,
    required this.notes,
  });

  factory SuccessionCandidate.fromMap(Map<String, dynamic> map) {
    return SuccessionCandidate(
      staffId: map['staffId'] ?? '',
      readiness: map['readiness'] ?? 'ready_now',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staffId': staffId,
      'readiness': readiness,
      'notes': notes,
    };
  }
}

class SuccessionPlan {
  final String id;
  final String positionId;
  final String positionName;
  final String? currentIncumbentId;
  final DateTime? expectedRotationDate;
  final List<SuccessionCandidate> candidates;

  SuccessionPlan({
    required this.id,
    required this.positionId,
    required this.positionName,
    this.currentIncumbentId,
    this.expectedRotationDate,
    this.candidates = const [],
  });

  factory SuccessionPlan.fromMap(Map<String, dynamic> map, String id) {
    return SuccessionPlan(
      id: id,
      positionId: map['positionId'] ?? id,
      positionName: map['positionName'] ?? 'Unknown Position',
      currentIncumbentId: map['currentIncumbentId'],
      expectedRotationDate: map['expectedRotationDate'] != null 
          ? (map['expectedRotationDate'] as Timestamp).toDate() 
          : null,
      candidates: (map['candidates'] as List<dynamic>?)
              ?.map((c) => SuccessionCandidate.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positionId': positionId,
      'positionName': positionName,
      'currentIncumbentId': currentIncumbentId,
      'expectedRotationDate': expectedRotationDate != null 
          ? Timestamp.fromDate(expectedRotationDate!) 
          : null,
      'candidates': candidates.map((c) => c.toMap()).toList(),
    };
  }
}
