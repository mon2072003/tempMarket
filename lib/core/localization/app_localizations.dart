import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isArabic => locale.languageCode == 'ar';

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'app_title': 'منصة التجارة المتكاملة',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب جديد',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirm_password': 'تأكيد كلمة المرور',
      'name': 'الاسم الكامل',
      'phone': 'رقم الهاتف',
      'forgot_password': 'هل نسيت كلمة المرور؟',
      'dont_have_account': 'ليس لديك حساب؟ سجل الآن',
      'already_have_account': 'لديك حساب بالفعل؟ سجل دخولك',
      'home': 'الرئيسية',
      'categories': 'التصنيفات',
      'all_categories': 'جميع الفئات',
      'all_products': 'كل المنتجات',
      'featured_products': 'أبرز المنتجات',
      'search_hint': 'ابحث عن منتج، كود، أو تصنيف...',
      'cart': 'سلة المشتريات',
      'empty_cart': 'سلة المشتريات فارغة حالياً',
      'add_to_cart': 'إضافة إلى السلة',
      'buy_now': 'شراء فوري',
      'quantity': 'الكمية',
      'price': 'السعر',
      'total': 'المجموع الكلي',
      'subtotal': 'المجموع الفرعي',
      'tax': 'ضريبة القيمة المضافة (15%)',
      'delivery_fee': 'رسوم التوصيل',
      'free_delivery': 'توصيل مجاني',
      'discount': 'الخصم',
      'coupon_code': 'رمز الكوبون أو كود الخصم',
      'apply_coupon': 'تطبيق',
      'checkout': 'متابعة الدفع والطلب',
      'order_success': 'تم تأكيد طلبك بنجاح!',
      'order_id': 'رقم الطلب',
      'order_history': 'سجل المشتريات والطلبات',
      'my_orders': 'طلباتي السابقة',
      'no_orders': 'لا توجد طلبات سابقة حتى الآن',
      'order_status': 'حالة الطلب',
      'status_placed': 'تم استلام الطلب',
      'status_processing': 'قيد التجهيز والتغليف',
      'status_on_the_way': 'في الطريق إليك',
      'status_delivered': 'تم التسليم بنجاح',
      'live_tracking': 'تتبع خط السير المباشر',
      'driver_info': 'بيانات مندوب التوصيل',
      'call_driver': 'اتصال بالسائق',
      'chat_driver': 'مراسلة السائق',
      'eta': 'الوقت المتوقع للوصول',
      'destination': 'عنوان التوصيل',
      'support': 'الدعم والمساعدة',
      'contact_us': 'تواصل معنا',
      'support_desc': 'فريق الدعم الفني متواجد على مدار الساعة لخدمتكم',
      'hotline': 'الخط الساخن المباشر',
      'whatsapp': 'محادثة فورية عبر واتساب',
      'send_ticket': 'إرسال استفسار أو شكوى',
      'message_hint': 'اكتب رسالتك أو استفسارك هنا بالتفصيل...',
      'send': 'إرسال الرسالة',
      'settings': 'الإعدادات',
      'profile': 'الملف الشخصي',
      'edit_profile': 'تعديل البيانات',
      'save_changes': 'حفظ التغييرات',
      'dark_mode': 'الوضع الداكن (Dark Mode)',
      'language': 'لغة التطبيق',
      'switch_theme_demo': 'تجربة هوية متجر أخرى (White-Label Demo)',
      'logout': 'تسجيل الخروج',
      'sar': 'ج.م',
      'specifications': 'المواصفات والتفاصيل',
      'description': 'الوصف',
      'in_stock': 'متوفر بالمخزون',
      'out_of_stock': 'نفذت الكمية',
      'rating': 'التقييم',
      'reviews': 'تقييمات العملاء',
      'filter_by': 'تصفية حسب النشاط',
    },
    'en': {
      'app_title': 'Multi-Store Commerce Platform',
      'login': 'Login',
      'register': 'Create Account',
      'email': 'Email Address',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'name': 'Full Name',
      'phone': 'Phone Number',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account? Register",
      'already_have_account': 'Already have an account? Sign In',
      'home': 'Home',
      'categories': 'Categories',
      'all_categories': 'All Categories',
      'all_products': 'All Products',
      'featured_products': 'Featured Products',
      'search_hint': 'Search product, code, or category...',
      'cart': 'Shopping Cart',
      'empty_cart': 'Your shopping cart is currently empty',
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'quantity': 'Quantity',
      'price': 'Price',
      'total': 'Grand Total',
      'subtotal': 'Subtotal',
      'tax': 'VAT (15%)',
      'delivery_fee': 'Delivery Fee',
      'free_delivery': 'Free Delivery',
      'discount': 'Discount',
      'coupon_code': 'Coupon or promo code',
      'apply_coupon': 'Apply',
      'checkout': 'Proceed to Checkout',
      'order_success': 'Your order has been placed successfully!',
      'order_id': 'Order #',
      'order_history': 'Purchased History & Orders',
      'my_orders': 'My Orders',
      'no_orders': 'No past orders yet',
      'order_status': 'Order Status',
      'status_placed': 'Order Placed',
      'status_processing': 'Preparing & Packing',
      'status_on_the_way': 'On the Way',
      'status_delivered': 'Delivered Successfully',
      'live_tracking': 'Live Delivery Tracking',
      'driver_info': 'Courier Info',
      'call_driver': 'Call Driver',
      'chat_driver': 'Message Driver',
      'eta': 'Estimated Arrival',
      'destination': 'Delivery Address',
      'support': 'Help & Support',
      'contact_us': 'Contact Us',
      'support_desc': 'Our technical support team is available 24/7 to help you',
      'hotline': 'Direct Hotline',
      'whatsapp': 'Instant WhatsApp Chat',
      'send_ticket': 'Submit Inquiry or Ticket',
      'message_hint': 'Type your message or inquiry here...',
      'send': 'Send Message',
      'settings': 'Settings',
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'save_changes': 'Save Changes',
      'dark_mode': 'Dark Mode',
      'language': 'tempMarket Language',
      'switch_theme_demo': 'Switch Store Identity (White-Label Demo)',
      'logout': 'Sign Out',
      'sar': 'EGP',
      'specifications': 'Specifications & Details',
      'description': 'Description',
      'in_stock': 'In Stock',
      'out_of_stock': 'Out of Stock',
      'rating': 'Rating',
      'reviews': 'Customer Reviews',
      'filter_by': 'Filter by Business',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
