class CorpsData {
  final String id;
  final String name;
  final String element;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> trainingYears;

  CorpsData({
    required this.id,
    required this.name,
    required this.element,
    required this.settings,
    required this.trainingYears,
  });

  factory CorpsData.fromMap(Map<String, dynamic> data, String id) {
    return CorpsData(
      id: id,
      name: data['name'] ?? 'Unknown Unit',
      element: data['element'] ?? 'Sea',
      settings: data['settings'] ?? {},
      trainingYears: data['trainingYears'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'element': element,
      'settings': settings,
      'trainingYears': trainingYears,
    };
  }
}
