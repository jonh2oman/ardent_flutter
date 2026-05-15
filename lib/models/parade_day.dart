class ParadeDay {
  final String date;
  final String title;
  final String? type; // 'Parade Night', 'Training Day', 'Special Event'
  final Map<String, dynamic> periods; // { 'p1': { 'Phase 1': { 'lessonId': 'M108.01', 'instructor': 'CI Smith', 'location': 'Main Deck' } } }
  final Map<String, String> dutyRoster; // { 'dutyOfficer': 'Lt(N) Jones', 'dutyPO': 'CPO2 Doe', ... }
  final List<String> announcements;

  ParadeDay({
    required this.date,
    required this.title,
    this.type,
    required this.periods,
    this.dutyRoster = const {},
    this.announcements = const [],
  });

  factory ParadeDay.fromMap(Map<String, dynamic> data, String date) {
    return ParadeDay(
      date: date,
      title: data['title'] ?? '',
      type: data['type'],
      periods: Map<String, dynamic>.from(data['periods'] ?? {}),
      dutyRoster: Map<String, String>.from(data['dutyRoster'] ?? {}),
      announcements: List<String>.from(data['announcements'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'periods': periods,
      'dutyRoster': dutyRoster,
      'announcements': announcements,
    };
  }
}
