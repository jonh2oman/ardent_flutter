class CorpsData {
  final String id;
  final String name;
  final String element;
  final String? logoUrl;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> trainingYears;

  CorpsData({
    required this.id,
    required this.name,
    required this.element,
    this.logoUrl,
    required this.settings,
    required this.trainingYears,
  });

  factory CorpsData.fromMap(Map<String, dynamic> data, String id) {
    return CorpsData(
      id: id,
      name: data['name'] ?? 'Unknown Unit',
      element: data['element'] ?? 'Sea',
      logoUrl: data['logoUrl'],
      settings: data['settings'] ?? {},
      trainingYears: data['trainingYears'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'element': element,
      'logoUrl': logoUrl,
      'settings': settings,
      'trainingYears': trainingYears,
    };
  }

  // Helpers for Unit Info
  String get coName => settings['unitInfo']?['coName'] ?? 'COMMANDING OFFICER';
  String get coRank => settings['unitInfo']?['coRank'] ?? 'LT(N)';
  String get unitDesignation => settings['unitInfo']?['unitDesignation'] ?? name;
  String get websiteUrl => settings['unitInfo']?['websiteUrl'] ?? '';
  String get address => settings['unitInfo']?['address'] ?? '';
  String get ordersHeaderEn => settings['unitInfo']?['ordersHeaderEn'] ?? 'RCSU (Atlantic) - NL Area\n220 Southside Road\nSt. John’s, NL';
  String get ordersHeaderFr => settings['unitInfo']?['ordersHeaderFr'] ?? 'URSC (Atlantique) - Secteur T.N.L\n220 Southside Road\nSt. John’s, T.N.L';
}
