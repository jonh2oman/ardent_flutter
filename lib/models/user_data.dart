
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
  });

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
    };
  }
}
