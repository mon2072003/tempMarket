class DriverApplicationModel {
  final String id;
  final String? userId;
  final String fullName;
  final String phone;
  final String nationalId;
  final String vehicleType; // motorcycle, car, van, truck
  final String city;
  final int experienceYears;
  final String? licenseImageUrl;
  final String status; // pending, approved, rejected
  final String? notes;
  final DateTime createdAt;

  const DriverApplicationModel({
    required this.id,
    this.userId,
    required this.fullName,
    required this.phone,
    required this.nationalId,
    required this.vehicleType,
    required this.city,
    this.experienceYears = 1,
    this.licenseImageUrl,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
  });

  factory DriverApplicationModel.fromJson(Map<String, dynamic> json) {
    return DriverApplicationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      nationalId: json['national_id']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? 'car',
      city: json['city']?.toString() ?? 'الرياض',
      experienceYears: (json['experience_years'] is num)
          ? (json['experience_years'] as num).toInt()
          : int.tryParse(json['experience_years']?.toString() ?? '1') ?? 1,
      licenseImageUrl: json['license_image_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'vehicle_type': vehicleType,
      'city': city,
      'experience_years': experienceYears,
      if (licenseImageUrl != null) 'license_image_url': licenseImageUrl,
      'status': status,
      if (notes != null) 'notes': notes,
    };
  }

  String vehicleTypeTitle(bool isArabic) {
    switch (vehicleType) {
      case 'motorcycle':
        return isArabic ? 'دراجة نارية' : 'Motorcycle';
      case 'car':
        return isArabic ? 'سيارة ركاب' : 'Car';
      case 'van':
        return isArabic ? 'فان بضائع' : 'Delivery Van';
      case 'truck':
        return isArabic ? 'دينا / شاحنة نقل' : 'Cargo Truck';
      default:
        return vehicleType;
    }
  }

  String statusTitle(bool isArabic) {
    switch (status) {
      case 'approved':
        return isArabic ? 'معتمد ومقبول' : 'Approved';
      case 'rejected':
        return isArabic ? 'مرفوض' : 'Rejected';
      case 'pending':
      default:
        return isArabic ? 'قيد المراجعة' : 'Pending Review';
    }
  }
}
