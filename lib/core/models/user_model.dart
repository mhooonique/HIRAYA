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
  final String? dateOfBirth;
  final String? city;
  final String? province;
  final String? govIdBase64;
  final String? govIdFilename;
  final String? selfieBase64;
  final String? selfieFilename;
  final Map<String, String> socialLinks;
  final String? avatarBase64;

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
    this.dateOfBirth,
    this.city,
    this.province,
    this.govIdBase64,
    this.govIdFilename,
    this.selfieBase64,
    this.selfieFilename,
    this.socialLinks    = const {},
    this.avatarBase64,
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
    dateOfBirth:    json['date_of_birth'] as String?,
    city:           json['city']          as String?,
    province:       json['province']      as String?,
    govIdBase64:    json['gov_id_base64']   as String?,
    govIdFilename:  json['gov_id_filename'] as String?,
    selfieBase64:   json['selfie_base64']   as String?,
    selfieFilename: json['selfie_filename'] as String?,
    avatarBase64:   json['avatar_base64']   as String?,
    socialLinks: (() {
      final raw = json['social_links'];
      if (raw == null) return <String, String>{};
      if (raw is Map) {
        return Map<String, String>.fromEntries(
          raw.entries.map((e) => MapEntry(e.key.toString(), e.value?.toString() ?? '')),
        );
      }
      return <String, String>{};
    })(),
  );

  String get fullName => '$firstName $lastName'.trim();

  UserModel copyWith({String? avatarBase64, bool clearAvatar = false}) => UserModel(
    id:             id,
    firstName:      firstName,
    lastName:       lastName,
    username:       username,
    email:          email,
    role:           role,
    kycStatus:      kycStatus,
    userStatus:     userStatus,
    phone:          phone,
    dateOfBirth:    dateOfBirth,
    city:           city,
    province:       province,
    govIdBase64:    govIdBase64,
    govIdFilename:  govIdFilename,
    selfieBase64:   selfieBase64,
    selfieFilename: selfieFilename,
    socialLinks:    socialLinks,
    avatarBase64:   clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
  );
}