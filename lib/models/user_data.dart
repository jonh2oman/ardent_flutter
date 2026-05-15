class UserData {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? rank;
  final String? position; // e.g. 'Commanding Officer', 'Training Officer'
  final String corpsId;
  // Permissions & Security
  final bool isAdmin;
  final Map<String, dynamic> permissions; // { 'modules': { 'supply': true, ... } }
  final bool isSupportAdmin;
  final bool isPendingAssignment;
  final DateTime? dob;
  final String? element;
  final String? phase;
  
  // Economy
  final int merits;
  
  // Training Progress
  final Map<String, dynamic> trainingRecords;

  // Logistics & Uniform
  final Map<String, dynamic> uniformSizes; // { 'tunic': '36R', 'boots': '9.5', ... }
  final List<dynamic> issuedKit; // [ { 'item': 'Tunic', 'serial': '1234', 'date': '...' } ]

  // New Fields from Web App
  final String? cin;
  final String? phone;
  final String? personalEmail;
  final String? cadetEmail;
  final Map<String, dynamic>? address;
  final List<dynamic>? parents;
  final String? provincialHealthNumber;
  final String? privateInsuranceProvider;
  final Map<String, dynamic>? onboardingChecklist;

  UserData({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.rank,
    this.position,
    required this.corpsId,
    this.isAdmin = false,
    this.permissions = const {},
    this.isSupportAdmin = false,
    this.isPendingAssignment = false,
    this.dob,
    this.element,
    this.phase,
    this.merits = 0,
    this.trainingRecords = const {},
    this.uniformSizes = const {},
    this.issuedKit = const [],
    this.cin,
    this.phone,
    this.personalEmail,
    this.cadetEmail,
    this.address,
    this.parents,
    this.provincialHealthNumber,
    this.privateInsuranceProvider,
    this.onboardingChecklist,
  });

  String get name => "${firstName ?? ''} ${lastName ?? ''}".trim();

  factory UserData.fromMap(Map<String, dynamic> data, String id) {
    return UserData(
      id: id,
      email: data['email'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      rank: data['rank'],
      position: data['position'],
      corpsId: data['corpsId'] ?? 'PENDING',
      isAdmin: data['isAdmin'] ?? false,
      permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
      isSupportAdmin: data['isSupportAdmin'] ?? false,
      isPendingAssignment: data['isPendingAssignment'] ?? false,
      dob: data['dob'] != null ? DateTime.tryParse(data['dob'].toString()) : null,
      element: data['element'],
      phase: data['phase']?.toString(),
      merits: data['merits'] ?? 0,
      trainingRecords: Map<String, dynamic>.from(data['trainingRecords'] ?? {}),
      uniformSizes: Map<String, dynamic>.from(data['uniformSizes'] ?? {}),
      issuedKit: List<dynamic>.from(data['issuedKit'] ?? []),
      cin: data['cin'],
      phone: data['phone'],
      personalEmail: data['personalEmail'],
      cadetEmail: data['cadetEmail'],
      address: data['address'],
      parents: data['parents'],
      provincialHealthNumber: data['provincialHealthNumber'],
      privateInsuranceProvider: data['privateInsuranceProvider'],
      onboardingChecklist: data['onboardingChecklist'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'rank': rank,
      'position': position,
      'corpsId': corpsId,
      'isAdmin': isAdmin,
      'permissions': permissions,
      'isSupportAdmin': isSupportAdmin,
      'isPendingAssignment': isPendingAssignment,
      'dob': dob?.toIso8601String(),
      'element': element,
      'phase': phase,
      'merits': merits,
      'trainingRecords': trainingRecords,
      'uniformSizes': uniformSizes,
      'issuedKit': issuedKit,
      'cin': cin,
      'phone': phone,
      'personalEmail': personalEmail,
      'cadetEmail': cadetEmail,
      'address': address,
      'parents': parents,
      'provincialHealthNumber': provincialHealthNumber,
      'privateInsuranceProvider': privateInsuranceProvider,
      'onboardingChecklist': onboardingChecklist,
    };
  }
}
