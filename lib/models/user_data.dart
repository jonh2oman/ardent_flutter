class UserData {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? rank;
  final String corpsId;
  final String? displayName;
  final bool isSupportAdmin;
  final bool isPendingAssignment;
  final DateTime? dob;
  final String? element;
  final String? phase;
  
  // Economy
  final int merits;
  
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
    required this.corpsId,
    this.displayName,
    this.isSupportAdmin = false,
    this.isPendingAssignment = false,
    this.dob,
    this.element,
    this.phase,
    this.merits = 0,
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

  String get name => displayName ?? "${firstName ?? ''} ${lastName ?? ''}".trim();

  factory UserData.fromMap(Map<String, dynamic> data, String id) {
    return UserData(
      id: id,
      email: data['email'] ?? '',
      firstName: data['firstName'],
      lastName: data['lastName'],
      rank: data['rank'],
      corpsId: data['corpsId'] ?? 'PENDING',
      displayName: data['displayName'],
      isSupportAdmin: data['isSupportAdmin'] ?? false,
      isPendingAssignment: data['isPendingAssignment'] ?? false,
      dob: data['dob'] != null ? DateTime.tryParse(data['dob'].toString()) : null,
      element: data['element'],
      phase: data['phase']?.toString(),
      merits: data['merits'] ?? 0,
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
      'corpsId': corpsId,
      'displayName': displayName,
      'isSupportAdmin': isSupportAdmin,
      'isPendingAssignment': isPendingAssignment,
      'dob': dob?.toIso8601String(),
      'element': element,
      'phase': phase,
      'merits': merits,
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
