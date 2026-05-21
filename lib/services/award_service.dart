import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/award.dart';
import '../models/user_data.dart';

class AwardService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of awards for a specific corps
  static Stream<List<Award>> streamAwards(String corpsId) {
    return _db
        .collection('awards')
        .where('corpsId', isEqualTo: corpsId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Award.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create an award
  static Future<void> createAward(Award award) async {
    await _db.collection('awards').add(award.toMap());
  }

  // Update an award
  static Future<void> updateAward(Award award) async {
    await _db.collection('awards').doc(award.id).update(award.toMap());
  }

  // Delete an award
  static Future<void> deleteAward(String awardId) async {
    await _db.collection('awards').doc(awardId).delete();
  }

  // Grant an award to a cadet manually or through engine
  static Future<void> grantAward(String awardId, String cadetId) async {
    final awardRef = _db.collection('awards').doc(awardId);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(awardRef);
      if (!doc.exists) return;
      
      final currentAward = Award.fromMap(doc.data()!, doc.id);
      if (!currentAward.awardedTo.contains(cadetId)) {
        final newAwardedTo = List<String>.from(currentAward.awardedTo)..add(cadetId);
        final newDates = Map<String, dynamic>.from(currentAward.awardedDates);
        newDates[cadetId] = DateTime.now().toIso8601String();
        
        transaction.update(awardRef, {
          'awardedTo': newAwardedTo,
          'awardedDates': newDates,
        });
      }
    });
  }

  // Revoke an award
  static Future<void> revokeAward(String awardId, String cadetId) async {
    final awardRef = _db.collection('awards').doc(awardId);
    await _db.runTransaction((transaction) async {
      final doc = await transaction.get(awardRef);
      if (!doc.exists) return;
      
      final currentAward = Award.fromMap(doc.data()!, doc.id);
      if (currentAward.awardedTo.contains(cadetId)) {
        final newAwardedTo = List<String>.from(currentAward.awardedTo)..remove(cadetId);
        final newDates = Map<String, dynamic>.from(currentAward.awardedDates);
        newDates.remove(cadetId);
        
        transaction.update(awardRef, {
          'awardedTo': newAwardedTo,
          'awardedDates': newDates,
        });
      }
    });
  }

  // Engine: Evaluate eligibility
  static bool isEligible(UserData cadet, Award award, {Map<String, double>? attendanceMap}) {
    if (award.awardedTo.contains(cadet.id)) return false; // Already has it

    final criteria = award.criteria;
    
    // Check Merits
    if (criteria.containsKey('minMerits')) {
      final int requiredMerits = int.tryParse(criteria['minMerits'].toString()) ?? 0;
      if (cadet.merits < requiredMerits) return false;
    }

    // Check Phase
    if (criteria.containsKey('minPhase')) {
      final int requiredPhase = _parsePhase(criteria['minPhase'].toString());
      final int cadetPhase = _parsePhase(cadet.phase ?? '0');
      if (cadetPhase < requiredPhase) return false;
    }

    // Check Time in Corps
    if (criteria.containsKey('minMonthsInCorps')) {
      final int requiredMonths = int.tryParse(criteria['minMonthsInCorps'].toString()) ?? 0;
      if (cadet.enrolmentDate != null) {
        final monthsInCorps = _calculateMonthsBetween(cadet.enrolmentDate!, DateTime.now());
        if (monthsInCorps < requiredMonths) return false;
      } else {
        // If no enrolment date, we can't verify time in corps. Fail safe.
        if (requiredMonths > 0) return false;
      }
    }

    // Check Exact Phase
    if (criteria.containsKey('exactPhase')) {
      final int exactRequired = _parsePhase(criteria['exactPhase'].toString());
      final int cadetPhase = _parsePhase(cadet.phase ?? '0');
      if (cadetPhase != exactRequired) return false;
    }

    // Check Required Tags
    if (criteria.containsKey('requiredTags')) {
      final List<dynamic> requiredTags = criteria['requiredTags'] is List ? criteria['requiredTags'] : [];
      for (final tag in requiredTags) {
        if (!cadet.tags.contains(tag.toString())) {
          return false;
        }
      }
    }

    // Check Attendance
    if (criteria.containsKey('minAttendance')) {
      final int requiredAtt = int.tryParse(criteria['minAttendance'].toString()) ?? 0;
      if (attendanceMap != null && attendanceMap.containsKey(cadet.id)) {
        final double cadetAtt = attendanceMap[cadet.id] ?? 0.0;
        if (cadetAtt < requiredAtt) return false;
      } else {
        // Fail safe if attendance data is missing but required
        if (requiredAtt > 0) return false;
      }
    }

    return true; // Passed all checks (or no criteria set)
  }

  static int _parsePhase(String phaseStr) {
    // Try parsing as int directly
    final val = int.tryParse(phaseStr);
    if (val != null) return val;
    // Handle roman numerals or text if necessary
    final lower = phaseStr.toLowerCase().trim();
    if (lower == '1' || lower == 'i' || lower == 'one') return 1;
    if (lower == '2' || lower == 'ii' || lower == 'two') return 2;
    if (lower == '3' || lower == 'iii' || lower == 'three') return 3;
    if (lower == '4' || lower == 'iv' || lower == 'four') return 4;
    if (lower == '5' || lower == 'v' || lower == 'five') return 5;
    return 0;
  }

  static int _calculateMonthsBetween(DateTime start, DateTime end) {
    int years = end.year - start.year;
    int months = end.month - start.month;
    return (years * 12) + months;
  }

  // Engine: Calculate attendance percentages for all cadets in the corps
  static Future<Map<String, double>> fetchCorpsAttendance(String corpsId) async {
    final snapshot = await _db.collection('corps').doc(corpsId).collection('attendance').get();
    
    Map<String, int> totalRecordsPerCadet = {};
    Map<String, int> presentCountPerCadet = {};

    for (var doc in snapshot.docs) {
      final statuses = doc.data()['statuses'] as Map<String, dynamic>? ?? {};
      statuses.forEach((cadetId, status) {
        totalRecordsPerCadet[cadetId] = (totalRecordsPerCadet[cadetId] ?? 0) + 1;
        if (status == 'Present' || status == 'Late') {
          presentCountPerCadet[cadetId] = (presentCountPerCadet[cadetId] ?? 0) + 1;
        }
      });
    }

    Map<String, double> attendanceMap = {};
    totalRecordsPerCadet.forEach((cadetId, total) {
      if (total > 0) {
        attendanceMap[cadetId] = ((presentCountPerCadet[cadetId] ?? 0) / total) * 100.0;
      }
    });

    return attendanceMap;
  }
}
