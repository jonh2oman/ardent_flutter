
class CorpsData {
  final String id;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> trainingYears;

  CorpsData({
    required this.id,
    required this.settings,
    required this.trainingYears,
  });

  factory CorpsData.fromMap(Map<String, dynamic> data, String id) {
    return CorpsData(
      id: id,
      settings: data['settings'] ?? {},
      trainingYears: data['trainingYears'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settings': settings,
      'trainingYears': trainingYears,
    };
  }
}
