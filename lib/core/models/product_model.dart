// lib/core/models/product_model.dart

class ProductModel {
  final int    id;
  final String name;
  final String description;
  final String category;
  final List<String> images;
  final int    likes;
  final int    views;
  final int    interestCount;
  final String status;
  final String innovatorName;
  final String innovatorUsername;
  final int    innovatorId;
  final String kycStatus;
  final DateTime createdAt;

  // Extended fields
  final String? videoBase64;
  final String? videoFilename;
  final String? externalLink;
  final String? qrImage;
  final bool    isDraft;
  final String? phone;
  final String? govIdBase64;
  final String? govIdFilename;
  final String? selfieBase64;
  final String? selfieFilename;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.images,
    required this.likes,
    required this.views,
    required this.interestCount,
    required this.status,
    required this.innovatorName,
    required this.innovatorUsername,
    required this.innovatorId,
    required this.kycStatus,
    required this.createdAt,
    this.videoBase64,
    this.videoFilename,
    this.externalLink,
    this.qrImage,
    this.isDraft    = false,
    this.phone,
    this.govIdBase64,
    this.govIdFilename,
    this.selfieBase64,
    this.selfieFilename,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id:                (json['id']             as num?)?.toInt() ?? 0,
        name:               json['name']            as String? ?? '',
        description:        json['description']     as String? ?? '',
        category:           json['category']        as String? ?? '',
        images: json['images'] != null
            ? List<String>.from(json['images'] as List)
            : [],
        likes:         (json['likes']          as num?)?.toInt() ?? 0,
        views:         (json['views']          as num?)?.toInt() ?? 0,
        interestCount: (json['interest_count'] as num?)?.toInt() ?? 0,
        status:             json['status']          as String? ?? 'pending',
        innovatorName:      json['innovator_name']  as String? ?? '',
        innovatorUsername:  json['innovator_username'] as String? ?? '',
        innovatorId:   (json['innovator_id']    as num?)?.toInt() ?? 0,
        kycStatus:          json['kyc_status']       as String? ?? 'unverified',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        videoBase64:    json['video_base64']    as String?,
        videoFilename:  json['video_filename']  as String?,
        externalLink:   json['external_link']   as String?,
        qrImage:        json['qr_image']         as String?,
        isDraft:       (json['is_draft']        as num?)?.toInt() == 1,
        phone:          json['phone']            as String?,
        govIdBase64:    json['gov_id_base64']    as String?,
        govIdFilename:  json['gov_id_filename']  as String?,
        selfieBase64:   json['selfie_base64']    as String?,
        selfieFilename: json['selfie_filename']  as String?,
      );

  String get coverImage        => images.isNotEmpty ? images.first : '';
  bool   get isVerifiedInnovator => kycStatus == 'verified';
}