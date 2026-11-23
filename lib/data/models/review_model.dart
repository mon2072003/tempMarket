class ReviewModel {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final DateTime date;
  final String comment;
  final bool isVerifiedPurchase;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.date,
    required this.comment,
    this.isVerifiedPurchase = true,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'عميل موثق',
      userAvatar: json['user_avatar']?.toString() ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 5.0,
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      comment: json['comment']?.toString() ?? '',
      isVerifiedPurchase: json['is_verified_purchase'] ?? true,
    );
  }

  Map<String, dynamic> toJson(String productId) {
    return {
      'id': id,
      'product_id': productId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'is_verified_purchase': isVerifiedPurchase,
    };
  }
}
