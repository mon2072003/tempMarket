enum UserRole {
  customer('عميل', 'Customer'),
  vendor('تاجر / مورد', 'Vendor / Supplier'),
  admin('مدير النظام', 'Platform Admin');

  final String titleAr;
  final String titleEn;
  const UserRole(this.titleAr, this.titleEn);
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String address;
  final UserRole role;
  final double totalSpent;
  final int ordersCount;
  final DateTime? joinedDate;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.address,
    this.role = UserRole.customer,
    this.totalSpent = 0.0,
    this.ordersCount = 0,
    this.joinedDate,
    this.isActive = true,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? address,
    UserRole? role,
    double? totalSpent,
    int? ordersCount,
    DateTime? joinedDate,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      role: role ?? this.role,
      totalSpent: totalSpent ?? this.totalSpent,
      ordersCount: ordersCount ?? this.ordersCount,
      joinedDate: joinedDate ?? this.joinedDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
