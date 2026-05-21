import '../models/user_data.dart';

class PromotionRequirement {
  final String nextRank;
  final int monthsInCurrentRank;
  final String? requiredPhase;
  final List<String> requiredLessons;
  final int? minimumAge;

  const PromotionRequirement({
    required this.nextRank,
    required this.monthsInCurrentRank,
    this.requiredPhase,
    this.requiredLessons = const [],
    this.minimumAge,
  });
}

class PromotionLogic {
  static const List<String> rankOrder = [
    'Ordinary Cadet',
    'Able Cadet',
    'Leading Cadet',
    'Master Cadet',
    'Petty Officer 2nd Class',
    'Petty Officer 1st Class',
    'Chief Petty Officer 2nd Class',
    'Chief Petty Officer 1st Class',
  ];

  static final Map<String, PromotionRequirement> requirements = {
    'Ordinary Cadet': const PromotionRequirement(
      nextRank: 'Able Cadet',
      monthsInCurrentRank: 5,
      requiredPhase: 'Phase 1',
    ),
    'Able Cadet': const PromotionRequirement(
      nextRank: 'Leading Cadet',
      monthsInCurrentRank: 6,
      requiredPhase: 'Phase 2',
    ),
    'Leading Cadet': const PromotionRequirement(
      nextRank: 'Master Cadet',
      monthsInCurrentRank: 6,
      requiredPhase: 'Phase 3',
    ),
    'Master Cadet': const PromotionRequirement(
      nextRank: 'Petty Officer 2nd Class',
      monthsInCurrentRank: 6,
      requiredPhase: 'Phase 4',
      minimumAge: 14,
    ),
    'Petty Officer 2nd Class': const PromotionRequirement(
      nextRank: 'Petty Officer 1st Class',
      monthsInCurrentRank: 6,
      minimumAge: 15,
    ),
  };

  static Map<String, dynamic> checkEligibility(UserData cadet) {
    final currentRank = cadet.rank ?? 'Ordinary Cadet';
    final req = requirements[currentRank];
    
    if (req == null) return {'eligible': false, 'reason': 'Highest rank reached or unknown rank'};

    final List<String> reasons = [];
    bool eligible = true;

    // 1. Check Time in Rank
    final startDate = cadet.lastPromotionDate ?? cadet.enrolmentDate;
    if (startDate == null) {
      eligible = false;
      reasons.add('No enrolment or promotion date on file');
    } else {
      final months = DateTime.now().difference(startDate).inDays / 30;
      if (months < req.monthsInCurrentRank) {
        eligible = false;
        reasons.add('Need ${req.monthsInCurrentRank - months.floor()} more months in rank');
      }
    }

    // 2. Check Phase Completion
    if (req.requiredPhase != null) {
      final records = cadet.trainingRecords[req.requiredPhase] ?? [];
      // For simplicity, we'll assume 80% completion of mandatory EOs in that phase
      // In a real app, you'd check specific EOs
      if (records.length < 5) { // Placeholder: at least 5 lessons
        eligible = false;
        reasons.add('Incomplete ${req.requiredPhase}');
      }
    }

    // 3. Check Age
    if (req.minimumAge != null && cadet.dob != null) {
      final age = DateTime.now().difference(cadet.dob!).inDays / 365;
      if (age < req.minimumAge!) {
        eligible = false;
        reasons.add('Minimum age of ${req.minimumAge} not met');
      }
    }

    return {
      'eligible': eligible,
      'reasons': reasons,
      'nextRank': req.nextRank,
    };
  }
}
