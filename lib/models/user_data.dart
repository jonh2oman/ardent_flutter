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
      phase: data['phase'],
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
    };
  }
}
