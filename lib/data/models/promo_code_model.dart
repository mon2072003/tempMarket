class PromoCodeModel {
  final String code;
  final double discountPercent;
  final bool isActive;
  final DateTime? expiresAt;

  const PromoCodeModel({
    required this.code,
    required this.discountPercent,
    this.isActive = true,
    this.expiresAt,
  });

  factory PromoCodeModel.fromJson(Map<String, dynamic> json) {
    return PromoCodeModel(
      code: json['code']?.toString() ?? '',
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code.trim().toUpperCase(),
        'discount_percent': discountPercent,
        'is_active': isActive,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      };
}
