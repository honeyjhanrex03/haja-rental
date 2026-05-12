enum DiscountType { percentage, fixed }

class Coupon {
  final String id;
  final String code;
  final double discountValue;
  final DiscountType type;
  final DateTime? expirationDate;
  final bool isActive;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountValue,
    this.type = DiscountType.percentage,
    this.expirationDate,
    this.isActive = true,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'fixed' ? DiscountType.fixed : DiscountType.percentage,
      expirationDate: json['expiration_date'] != null ? DateTime.tryParse(json['expiration_date']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'discount_value': discountValue,
      'type': type == DiscountType.fixed ? 'fixed' : 'percentage',
      'expiration_date': expirationDate?.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  bool get isValid => isActive && !isExpired;
}
