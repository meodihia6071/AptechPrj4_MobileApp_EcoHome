class AccountProfile {
  const AccountProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.identityNumber,
    required this.dateOfBirth,
  });

  final String fullName;
  final String phoneNumber;
  final String email;
  final String identityNumber;
  final DateTime? dateOfBirth;

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    fullName: json['fullName']?.toString() ?? '--',
    phoneNumber: json['phoneNumber']?.toString() ?? '--',
    email: json['email']?.toString() ?? '--',
    identityNumber: json['identityNumber']?.toString() ?? '--',
    dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
  );
}
