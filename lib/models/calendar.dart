class ParadeDay {
  final String date;
  final String type; // 'lhq', 'training-day', 'weekend', 'other'
  final String title;
  final Map<String, dynamic> periods; // 1, 2, 3
  final List<dynamic> mandatoryEvents;

  ParadeDay({
    required this.date,
    required this.type,
    this.title = '',
    this.periods = const {},
    this.mandatoryEvents = const [],
  });

  factory ParadeDay.fromMap(String date, Map<String, dynamic> map) {
    return ParadeDay(
      date: date,
      type: map['type'] ?? 'lhq',
      title: map['title'] ?? '',
      periods: map['periods'] ?? {},
      mandatoryEvents: map['mandatoryEvents'] ?? [],
    );
  }
}

class PeriodLesson {
  final String lessonId;
  final String instructor;
  final String location;
  final String level; // Phase 1, 2, 3, 4

  PeriodLesson({
    required this.lessonId,
    required this.instructor,
    required this.location,
    required this.level,
  });

  factory PeriodLesson.fromMap(Map<String, dynamic> map) {
    return PeriodLesson(
      lessonId: map['lessonId'] ?? '',
      instructor: map['instructor'] ?? '',
      location: map['location'] ?? '',
      level: map['level'] ?? '',
    );
  }
}
