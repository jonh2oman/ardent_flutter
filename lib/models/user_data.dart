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
  final bool isArchived;
  final DateTime? dob;
  final String? element;
  final String? phase;
  final DateTime? enrolmentDate;
  final DateTime? lastPromotionDate;
  
  // Economy
  final int merits;
  final double cashBalance;
  
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
  final List<String> tags;

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
    this.isArchived = false,
    this.dob,
    this.element,
    this.phase,
    this.merits = 0,
    this.cashBalance = 0.0,
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
    this.enrolmentDate,
    this.lastPromotionDate,
    this.tags = const [],
  });

  bool get isValid => (firstName != null && firstName!.isNotEmpty && firstName!.toLowerCase() != 'null') || 
                      (lastName != null && lastName!.isNotEmpty && lastName!.toLowerCase() != 'null');

  String get name {
    String f = (firstName ?? '').toString();
    String l = (lastName ?? '').toString();
    if (f.toLowerCase() == 'null') f = '';
    if (l.toLowerCase() == 'null') l = '';
    String fullName = "$f $l".trim();
    if (fullName.isEmpty) {
      return email.isNotEmpty ? email : "Incomplete Profile";
    }
    return fullName;
  }

  factory UserData.fromMap(Map<String, dynamic> data, String id) {
    final enrolmentDate = data['enrolmentDate'] != null ? DateTime.tryParse(data['enrolmentDate'].toString()) : null;
    final lastPromotionDate = data['lastPromotionDate'] != null ? DateTime.tryParse(data['lastPromotionDate'].toString()) : null;

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
      isArchived: data['isArchived'] ?? false,
      dob: data['dob'] != null ? DateTime.tryParse(data['dob'].toString()) : null,
      element: data['element'],
      phase: data['phase']?.toString(),
      merits: data['merits'] ?? 0,
      cashBalance: (data['cashBalance'] ?? 0.0).toDouble(),
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
      enrolmentDate: enrolmentDate,
      lastPromotionDate: lastPromotionDate,
      tags: List<String>.from(data['tags'] ?? []),
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
      'isArchived': isArchived,
      'dob': dob?.toIso8601String(),
      'element': element,
      'phase': phase,
      'merits': merits,
      'cashBalance': cashBalance,
      'trainingRecords': trainingRecords,
      'uniformSizes': uniformSizes,
      'issuedKit': issuedKit,
      'currentInventory': issuedKit, // Mirroring for compatibility if needed
      'cin': cin,
      'phone': phone,
      'personalEmail': personalEmail,
      'cadetEmail': cadetEmail,
      'address': address,
      'parents': parents,
      'provincialHealthNumber': provincialHealthNumber,
      'privateInsuranceProvider': privateInsuranceProvider,
      'onboardingChecklist': onboardingChecklist,
      'enrolmentDate': enrolmentDate?.toIso8601String(),
      'lastPromotionDate': lastPromotionDate?.toIso8601String(),
      'tags': tags,
    };
  }
}
