class ProductModel {
  final int id;
  final String name;
  final String description;
  final String category;
  final List<String> images;
  final int likes;
  final int views;
  final int interestCount;
  final String status;
  final String innovatorName;
  final String innovatorUsername;
  final int innovatorId;
  final String kycStatus;
  final DateTime createdAt;

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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? '',
        images: json['images'] != null
            ? List<String>.from(json['images'])
            : [],
        likes: json['likes'] ?? 0,
        views: json['views'] ?? 0,
        interestCount: json['interest_count'] ?? 0,
        status: json['status'] ?? 'pending',
        innovatorName: json['innovator_name'] ?? '',
        innovatorUsername: json['innovator_username'] ?? '',
        innovatorId: json['innovator_id'] ?? 0,
        kycStatus: json['kyc_status'] ?? 'unverified',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ??
            DateTime.now(),
      );

  String get coverImage =>
      images.isNotEmpty ? images.first : '';

  bool get isVerifiedInnovator => kycStatus == 'verified';
}