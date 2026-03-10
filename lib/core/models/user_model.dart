class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final String kycStatus;
  final int userStatus;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    required this.kycStatus,
    required this.userStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        username: json['username'],
        email: json['email'],
        role: json['role'],
        kycStatus: json['kyc_status'] ?? 'unverified',
        userStatus: json['user_status'] ?? 0,
      );

  String get fullName => '$firstName $lastName';
}