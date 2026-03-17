// lib/core/models/user_model.dart

class UserModel {
  final int    id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final String kycStatus;
  final int    userStatus;
  final String phone;
  final String? govIdBase64;
  final String? govIdFilename;
  final String? selfieBase64;
  final String? selfieFilename;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    required this.kycStatus,
    required this.userStatus,
    this.phone          = '',
    this.govIdBase64,
    this.govIdFilename,
    this.selfieBase64,
    this.selfieFilename,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:             (json['id']           as num?)?.toInt() ?? 0,
    firstName:      (json['first_name']   as String?) ?? '',
    lastName:       (json['last_name']    as String?) ?? '',
    username:       (json['username']     as String?) ?? '',
    email:          (json['email']        as String?) ?? '',
    role:           (json['role']         as String?) ?? 'client',
    kycStatus:      (json['kyc_status']   as String?) ?? 'unverified',
    userStatus:     (json['user_status']  as num?)?.toInt() ?? 0,
    phone:          (json['phone']        as String?) ?? '',
    govIdBase64:    json['gov_id_base64']   as String?,
    govIdFilename:  json['gov_id_filename'] as String?,
    selfieBase64:   json['selfie_base64']   as String?,
    selfieFilename: json['selfie_filename'] as String?,
  );

  String get fullName => '$firstName $lastName'.trim();
}