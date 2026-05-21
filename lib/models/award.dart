class Award {
  final String id;
  final String corpsId;
  final String name;
  final String description;
  final String type; // 'General' or 'Unit'
  final String manualPrerequisites;
  final Map<String, dynamic> criteria;
  final List<String> awardedTo;
  final Map<String, dynamic> awardedDates;

  Award({
    required this.id,
    required this.corpsId,
    required this.name,
    required this.description,
    required this.type,
    this.manualPrerequisites = '',
    this.criteria = const {},
    this.awardedTo = const [],
    this.awardedDates = const {},
  });

  factory Award.fromMap(Map<String, dynamic> data, String id) {
    return Award(
      id: id,
      corpsId: data['corpsId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'Unit',
      manualPrerequisites: data['manualPrerequisites'] ?? '',
      criteria: Map<String, dynamic>.from(data['criteria'] ?? {}),
      awardedTo: List<String>.from(data['awardedTo'] ?? []),
      awardedDates: Map<String, dynamic>.from(data['awardedDates'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'corpsId': corpsId,
      'name': name,
      'description': description,
      'type': type,
      'manualPrerequisites': manualPrerequisites,
      'criteria': criteria,
      'awardedTo': awardedTo,
      'awardedDates': awardedDates,
    };
  }
}
