import 'package:flutter/material.dart';

enum BusinessType {
  general('متجر عام', 'General Store', Icons.storefront),
  factory('مصنع وتوريدات', 'Factory & Supply', Icons.factory_outlined),
  mall('مول تجاري', 'Commercial Mall', Icons.shopping_bag_outlined),
  pharmacy(
    'صيدلية ورعاية صحية',
    'Pharmacy & Health',
    Icons.local_pharmacy_outlined,
  ),
  restaurant('مطعم ومأكولات', 'Restaurant & Food', Icons.restaurant_menu),
  hospital(
    'مستشفى ومركز طبي',
    'Hospital & Medical Center',
    Icons.local_hospital_outlined,
  ),
  shop(
    'محل ومتجر تجزئة',
    'Retail Shop & Store',
    Icons.store_mall_directory_outlined,
  ),
  supermarket(
    'سوبرماركت ومواد غذائية',
    'Supermarket & Groceries',
    Icons.shopping_cart_outlined,
  );

  final String titleAr;
  final String titleEn;
  final IconData icon;
  const BusinessType(this.titleAr, this.titleEn, this.icon);
}

class BrandConfig {
  final String brandId;
  final String brandNameAr;
  final String brandNameEn;
  final String sloganAr;
  final String sloganEn;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final BusinessType businessType;
  final String hotline;
  final String whatsappNumber;
  final String email;
  final String addressAr;
  final String addressEn;

  const BrandConfig({
    required this.brandId,
    required this.brandNameAr,
    required this.brandNameEn,
    required this.sloganAr,
    required this.sloganEn,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.businessType,
    required this.hotline,
    required this.whatsappNumber,
    required this.email,
    required this.addressAr,
    required this.addressEn,
  });

  Map<String, dynamic> toJson() => {
    'brand_id': brandId,
    'brand_name_ar': brandNameAr,
    'brand_name_en': brandNameEn,
    'slogan_ar': sloganAr,
    'slogan_en': sloganEn,
    'primary_color': primaryColor.toARGB32(),
    'secondary_color': secondaryColor.toARGB32(),
    'accent_color': accentColor.toARGB32(),
    'business_type': businessType.name,
    'hotline': hotline,
    'whatsapp_number': whatsappNumber,
    'email': email,
    'address_ar': addressAr,
    'address_en': addressEn,
  };

  factory BrandConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['business_type']?.toString();
    final businessType = BusinessType.values.where(
      (type) => type.name == typeName,
    );
    int colorValue(String key, Color fallback) =>
        (json[key] as num?)?.toInt() ?? fallback.toARGB32();

    return BrandConfig(
      brandId: json['brand_id']?.toString() ?? 'temp_market',
      brandNameAr: json['brand_name_ar']?.toString() ?? 'tempMarket',
      brandNameEn: json['brand_name_en']?.toString() ?? 'tempMarket',
      sloganAr: json['slogan_ar']?.toString() ?? '',
      sloganEn: json['slogan_en']?.toString() ?? '',
      primaryColor: Color(
        colorValue('primary_color', defaultBrand.primaryColor),
      ),
      secondaryColor: Color(
        colorValue('secondary_color', defaultBrand.secondaryColor),
      ),
      accentColor: Color(colorValue('accent_color', defaultBrand.accentColor)),
      businessType: businessType.isEmpty
          ? BusinessType.general
          : businessType.first,
      hotline: json['hotline']?.toString() ?? '',
      whatsappNumber: json['whatsapp_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      addressAr: json['address_ar']?.toString() ?? '',
      addressEn: json['address_en']?.toString() ?? '',
    );
  }

  static const BrandConfig defaultBrand = BrandConfig(
    brandId: 'temp_market',
    brandNameAr: 'tempMarket',
    brandNameEn: 'tempMarket',
    sloganAr: '',
    sloganEn: '',
    primaryColor: Color(0xFF2563EB),
    secondaryColor: Color(0xFF14B8A6),
    accentColor: Color(0xFFF59E0B),
    businessType: BusinessType.general,
    hotline: '',
    whatsappNumber: '',
    email: '',
    addressAr: '',
    addressEn: '',
  );

  BrandConfig copyWith({
    String? brandId,
    String? brandNameAr,
    String? brandNameEn,
    String? sloganAr,
    String? sloganEn,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    BusinessType? businessType,
    String? hotline,
    String? whatsappNumber,
    String? email,
    String? addressAr,
    String? addressEn,
  }) {
    return BrandConfig(
      brandId: brandId ?? this.brandId,
      brandNameAr: brandNameAr ?? this.brandNameAr,
      brandNameEn: brandNameEn ?? this.brandNameEn,
      sloganAr: sloganAr ?? this.sloganAr,
      sloganEn: sloganEn ?? this.sloganEn,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      businessType: businessType ?? this.businessType,
      hotline: hotline ?? this.hotline,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      addressAr: addressAr ?? this.addressAr,
      addressEn: addressEn ?? this.addressEn,
    );
  }

  static const BrandConfig factoryBrand = BrandConfig(
    brandId: 'factory_pro',
    brandNameAr: 'مصنع النخبة للصناعات',
    brandNameEn: 'Elite Industrial Group',
    sloganAr: 'أجود المنتجات الصناعية مباشرة من خط الإنتاج',
    sloganEn: 'Premium industrial supplies direct from production',
    primaryColor: Color(0xFF1E3A8A), // Deep Industrial Navy
    secondaryColor: Color(0xFFD97706), // Industrial Amber
    accentColor: Color(0xFF2563EB),
    businessType: BusinessType.factory,
    hotline: '19876',
    whatsappNumber: '+966500000001',
    email: 'info@elitefactory.com',
    addressAr: 'المنطقة الصناعية الثالثة - جدة',
    addressEn: '3rd Industrial Zone, Jeddah',
  );

  static const BrandConfig mallBrand = BrandConfig(
    brandId: 'mega_mall',
    brandNameAr: 'جراند سنترال مول',
    brandNameEn: 'Grand Central Mall',
    sloganAr: 'وجهتك الأولى لأفخم الماركات العالمية',
    sloganEn: 'Your premier destination for world brands',
    primaryColor: Color(0xFF6B21A8), // Royal Luxury Purple
    secondaryColor: Color(0xFFEC4899), // Pink Accent
    accentColor: Color(0xFF9333EA),
    businessType: BusinessType.mall,
    hotline: '19555',
    whatsappNumber: '+966500000002',
    email: 'contact@grandmall.com',
    addressAr: 'طريق الملك فهد - الرياض',
    addressEn: 'King Fahd Road, Riyadh',
  );

  static const BrandConfig pharmacyBrand = BrandConfig(
    brandId: 'care_pharmacy',
    brandNameAr: 'صيدليات الشفاء التخصصية',
    brandNameEn: 'Al-Shifa Care Pharmacy',
    sloganAr: 'صحتكم وسلامتكم في المقام الأول مع توصيل فوري',
    sloganEn: 'Your health first with instant prescription delivery',
    primaryColor: Color(0xFF0D9488), // Medical Teal
    secondaryColor: Color(0xFF10B981), // Fresh Green
    accentColor: Color(0xFF14B8A6),
    businessType: BusinessType.pharmacy,
    hotline: '19222',
    whatsappNumber: '+966500000003',
    email: 'care@alshifapharmacy.com',
    addressAr: 'شارع التخصصي - الرياض',
    addressEn: 'Takhassusi St, Riyadh',
  );

  static const BrandConfig restaurantBrand = BrandConfig(
    brandId: 'tasty_bistro',
    brandNameAr: 'مطعم ومشاوي الديوان',
    brandNameEn: 'Al-Diwan Gourmet Kitchen',
    sloganAr: 'أشهى المأكولات الطازجة الساخنة تصلك حتى باب بيتك',
    sloganEn: 'Fresh authentic culinary delights delivered hot to your door',
    primaryColor: Color(0xFFDC2626), // Appetite Red
    secondaryColor: Color(0xFFF59E0B), // Warm Gold
    accentColor: Color(0xFFEF4444),
    businessType: BusinessType.restaurant,
    hotline: '19111',
    whatsappNumber: '+966500000004',
    email: 'order@aldiwanrestaurant.com',
    addressAr: 'شارع الأمير سلطان - جدة',
    addressEn: 'Prince Sultan St, Jeddah',
  );

  static const BrandConfig hospitalBrand = BrandConfig(
    brandId: 'hope_hospital',
    brandNameAr: 'مستشفى ومجمع الأمل الطبي',
    brandNameEn: 'Al-Amal Medical Center',
    sloganAr: 'رعاية صحية متقدمة وخدمات طبية وتجهيزات على مدار الساعة',
    sloganEn: 'Advanced healthcare and medical supplies around the clock',
    primaryColor: Color(0xFF0284C7), // Medical Sky Blue
    secondaryColor: Color(0xFF0EA5E9),
    accentColor: Color(0xFF38BDF8),
    businessType: BusinessType.hospital,
    hotline: '19777',
    whatsappNumber: '+966500000005',
    email: 'care@hopehospital.com',
    addressAr: 'طريق الملك عبدالله - الرياض',
    addressEn: 'King Abdullah Road, Riyadh',
  );

  static const BrandConfig shopBrand = BrandConfig(
    brandId: 'elegance_shop',
    brandNameAr: 'متجر الأناقة العصري',
    brandNameEn: 'Elegance Retail Boutique',
    sloganAr: 'أحدث خطوط الموضة والإلكترونيات ومستلزمات الحياة العصرية',
    sloganEn: 'Trendy fashion, electronics, and lifestyle essentials',
    primaryColor: Color(0xFF4F46E5), // Modern Indigo
    secondaryColor: Color(0xFF818CF8),
    accentColor: Color(0xFF6366F1),
    businessType: BusinessType.shop,
    hotline: '19333',
    whatsappNumber: '+966500000006',
    email: 'shop@eleganceboutique.com',
    addressAr: 'مركز العروبة التجاري - الرياض',
    addressEn: 'Al-Orouba Center, Riyadh',
  );

  static List<BrandConfig> get availableThemes => [];
}
