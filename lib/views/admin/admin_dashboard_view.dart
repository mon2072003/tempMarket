import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/config/brand_config.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/media_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/promo_code_model.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/orders_viewmodel.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userSearchQuery = '';
  String _productSearchQuery = '';

  // Controllers for Brand / Service Type Settings
  late TextEditingController _brandNameArCtrl;
  late TextEditingController _brandNameEnCtrl;
  late TextEditingController _hotlineCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late BusinessType _selectedBusinessType;

  // Controllers for Push Notification Broadcast
  final _notifTitleArCtrl = TextEditingController();
  final _notifTitleEnCtrl = TextEditingController();
  final _notifBodyArCtrl = TextEditingController();
  final _notifBodyEnCtrl = TextEditingController();
  bool _isSendingNotif = false;
  bool _isSavingBrandSettings = false;
  final _brandSettingsFormKey = GlobalKey<FormState>();

  // Real-time Supabase Data
  List<Map<String, dynamic>> _supabaseProfiles = [];
  List<Map<String, dynamic>> _supabaseOrders = [];
  List<Map<String, dynamic>> _driverApplications = [];
  List<Map<String, dynamic>> _supabaseReviews = [];
  String? _reviewAnalyticsError;
  bool _isLoadingSupabaseData = false;
  List<PromoCodeModel> _promoCodes = [];
  bool _isLoadingPromoCodes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    final currentBrand = Provider.of<ThemeViewModel>(
      context,
      listen: false,
    ).currentBrand;
    _brandNameArCtrl = TextEditingController(text: currentBrand.brandNameAr);
    _brandNameEnCtrl = TextEditingController(text: currentBrand.brandNameEn);
    _hotlineCtrl = TextEditingController(text: currentBrand.hotline);
    _whatsappCtrl = TextEditingController(text: currentBrand.whatsappNumber);
    _emailCtrl = TextEditingController(text: currentBrand.email);
    _addressCtrl = TextEditingController(text: currentBrand.addressAr);
    _selectedBusinessType = currentBrand.businessType;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Provider.of<AuthViewModel>(
            context,
            listen: false,
          ).currentUser?.role.name !=
          'admin')
        return;
      _loadSupabaseAdminData();
      _loadPromoCodes();
    });
  }

  Future<void> _loadSupabaseAdminData() async {
    final supabase = SupabaseService();
    if (!supabase.isInitialized) return;

    setState(() => _isLoadingSupabaseData = true);
    try {
      final profiles = await supabase.getProfiles();
      final orders = await supabase.getOrdersWithItems();
      final applications = await supabase.getDriverApplications();
      if (mounted) {
        setState(() {
          _supabaseProfiles = profiles;
          _supabaseOrders = orders;
          _driverApplications = applications;
        });
      }
    } catch (_) {}
    try {
      final reviews = await supabase.getAllReviews();
      if (mounted) {
        setState(() {
          _supabaseReviews = reviews;
          _reviewAnalyticsError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _reviewAnalyticsError = error.toString());
    }
    if (mounted) {
      setState(() => _isLoadingSupabaseData = false);
    }
  }

  Future<void> _loadPromoCodes() async {
    if (!SupabaseService().isInitialized) return;
    if (mounted) setState(() => _isLoadingPromoCodes = true);
    try {
      final promos = await SupabaseService().getPromoCodes();
      if (mounted) setState(() => _promoCodes = promos);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load promo codes.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPromoCodes = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _brandNameArCtrl.dispose();
    _brandNameEnCtrl.dispose();
    _hotlineCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notifTitleArCtrl.dispose();
    _notifTitleEnCtrl.dispose();
    _notifBodyArCtrl.dispose();
    _notifBodyEnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final loc = AppLocalizations.of(context);
    if (!authVM.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authVM.currentUser?.role.name != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.isArabic ? 'للمديرين فقط' : 'Admin access only'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              loc.isArabic
                  ? 'سجل الدخول بحساب مدير لفتح لوحة الإدارة.'
                  : 'Sign in with an admin account to open the manager dashboard.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.isArabic ? 'لوحة تحكم وإدارة المنصة' : 'Platform Admin Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: loc.isArabic
                ? 'تحديث بيانات tempMarket'
                : 'Refresh tempMarket data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final refreshSuccessText = loc.isArabic
                  ? 'تم تحديث بيانات tempMarket'
                  : 'tempMarket data refreshed';
              final productsVM = Provider.of<ProductsViewModel>(
                context,
                listen: false,
              );

              await _loadSupabaseAdminData();
              if (!mounted) return;
              productsVM.loadProductsFromSupabase();
              messenger.showSnackBar(
                SnackBar(content: Text(refreshSuccessText)),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(140),
          tabs: [
            Tab(
              icon: const Icon(Icons.analytics_outlined, size: 20),
              text: loc.isArabic ? 'التقارير والمبيعات' : 'Reports & Sales',
            ),
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 20),
              text: loc.isArabic ? 'إدارة المنتجات' : 'Products Management',
            ),
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              text: loc.isArabic ? 'المنتجات المشتراة' : 'Purchased Products',
            ),
            Tab(
              icon: const Icon(Icons.manage_accounts_outlined, size: 20),
              text: loc.isArabic ? 'بيانات المستخدمين' : 'Users Management',
            ),
            Tab(
              icon: const Icon(Icons.delivery_dining_outlined, size: 20),
              text: loc.isArabic ? 'مراجعة طلبات المندوبين' : 'Courier Review',
            ),
            Tab(
              icon: const Icon(Icons.local_offer_outlined, size: 20),
              text: loc.isArabic ? 'رموز الخصم' : 'Promo Codes',
            ),
            Tab(
              icon: const Icon(Icons.tune_rounded, size: 20),
              text: loc.isArabic ? 'هوية الخدمة والتواصل' : 'Brand & Contacts',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isLoadingSupabaseData)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(theme, loc, primary),
                _buildProductsTab(theme, loc, primary),
                _buildPurchasedOrdersTab(theme, loc, primary),
                _buildUsersTab(theme, loc, primary),
                _buildCourierApplicationsTab(theme, loc, primary),
                _buildPromoCodesTab(theme, loc, primary),
                _buildBrandSettingsTab(theme, loc, primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: REPORTS & ANALYTICS (SUPABASE DATA)
  // ==========================================
  Widget _buildReportsTab(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    final productsVM = Provider.of<ProductsViewModel>(context);

    final totalOrdersCount = _supabaseOrders.length;
    double totalRevenue = 0.0;
    int completedOrdersCount = 0;

    if (_supabaseOrders.isNotEmpty) {
      for (final o in _supabaseOrders) {
        totalRevenue += (o['total'] as num?)?.toDouble() ?? 0.0;
        if (o['status'] == 'delivered') completedOrdersCount++;
      }
    }

    final avgOrderVal = totalOrdersCount > 0
        ? (totalRevenue / totalOrdersCount)
        : 0.0;
    final userCount = _supabaseProfiles.length;
    final reviewRatings = _supabaseReviews
        .map((row) => (row['rating'] as num?)?.toDouble())
        .whereType<double>()
        .where((rating) => rating >= 1 && rating <= 5)
        .toList();
    final averageReviewRating = reviewRatings.isEmpty
        ? 0.0
        : reviewRatings.reduce((a, b) => a + b) / reviewRatings.length;
    final ratingDistribution = <int, int>{
      for (var stars = 5; stars >= 1; stars--)
        stars: reviewRatings.where((rating) => rating.round() == stars).length,
    };
    final productReviewGroups = <String, List<double>>{};
    for (final row in _supabaseReviews) {
      final rating = (row['rating'] as num?)?.toDouble();
      final productId = row['product_id']?.toString();
      if (rating != null && productId != null && rating >= 1 && rating <= 5) {
        productReviewGroups.putIfAbsent(productId, () => []).add(rating);
      }
    }
    final topReviewedProducts = productReviewGroups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_done_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    loc.isArabic
                        ? 'تقارير tempMarket محدثة مباشرة ببيانات المعاملات'
                        : 'Reports show live sales and customer metrics',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KPI Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWide ? 1.4 : 1.25,
                children: [
                  _buildKpiCard(
                    title: loc.isArabic ? 'إجمالي المبيعات' : 'Total Revenue',
                    value:
                        '${totalRevenue.toStringAsFixed(1)} ${loc.translate("sar")}',
                    growth: '+28.4%',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF10B981),
                    theme: theme,
                  ),
                  _buildKpiCard(
                    title: loc.isArabic ? 'إجمالي الطلبات' : 'Total Orders',
                    value:
                        '$totalOrdersCount ${loc.isArabic ? "طلب" : "orders"}',
                    growth: '+14.2%',
                    icon: Icons.shopping_cart_checkout_outlined,
                    color: const Color(0xFF3B82F6),
                    theme: theme,
                  ),
                  _buildKpiCard(
                    title: loc.isArabic
                        ? 'طلبات اكتملت بنجاح'
                        : 'Delivered Orders',
                    value:
                        '$completedOrdersCount ${loc.isArabic ? "مكتمل" : "completed"}',
                    growth: '+19.0%',
                    icon: Icons.task_alt_rounded,
                    color: const Color(0xFF8B5CF6),
                    theme: theme,
                  ),
                  _buildKpiCard(
                    title: loc.isArabic
                        ? 'المستخدمين المسجلين'
                        : 'Registered Users',
                    value: '$userCount ${loc.isArabic ? "مستخدم" : "users"}',
                    growth: '+35.5%',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    theme: theme,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Average Basket & Products Metric
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.point_of_sale_rounded,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.isArabic
                              ? 'متوسط قيمة سلة الشراء (AOV)'
                              : 'Average Order Value (AOV)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(140),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${avgOrderVal.toStringAsFixed(1)} ${loc.translate("sar")}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${productsVM.products.length} ${loc.isArabic ? "منتج مسجل" : "products"}',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reviews_outlined, color: primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.isArabic
                              ? 'تحليلات تقييمات العملاء'
                              : 'Customer review analytics',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isLoadingSupabaseData)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_reviewAnalyticsError != null)
                    Text(
                      loc.isArabic
                          ? 'تعذر تحميل التقييمات من قاعدة البيانات: $_reviewAnalyticsError'
                          : 'Could not load review rows from the database: $_reviewAnalyticsError',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _reviewMetric(
                            loc.isArabic ? 'إجمالي التقييمات' : 'Total reviews',
                            '${_supabaseReviews.length}',
                            Icons.rate_review_outlined,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _reviewMetric(
                            loc.isArabic ? 'متوسط النجوم' : 'Average rating',
                            reviewRatings.isEmpty
                                ? '—'
                                : '${averageReviewRating.toStringAsFixed(2)} / 5',
                            Icons.star_rounded,
                            theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (final stars in [5, 4, 3, 2, 1])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              child: Text(
                                '$stars',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: reviewRatings.isEmpty
                                    ? 0
                                    : ratingDistribution[stars]! /
                                          reviewRatings.length,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(8),
                                color: primary,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${ratingDistribution[stars]}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (topReviewedProducts.isNotEmpty) ...[
                      const Divider(height: 22),
                      Text(
                        loc.isArabic
                            ? 'الأكثر حصولًا على تقييمات'
                            : 'Most reviewed products',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      for (final entry in topReviewedProducts.take(5))
                        Builder(
                          builder: (context) {
                            final matchingProducts = productsVM.products.where(
                              (p) => p.id == entry.key,
                            );
                            final product = matchingProducts.isEmpty
                                ? null
                                : matchingProducts.first;
                            final mean =
                                entry.value.reduce((a, b) => a + b) /
                                entry.value.length;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                product?.localizedName(loc.isArabic) ??
                                    entry.key,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                '${mean.toStringAsFixed(1)} âک… آ· ${entry.value.length}',
                              ),
                            );
                          },
                        ),
                    ],
                    if (_supabaseReviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          loc.isArabic
                              ? 'لا توجد تقييمات محفوظة حتى الآن.'
                              : 'No reviews have been saved yet.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Top Selling Categories & Products Overview
          Text(
            loc.isArabic
                ? 'نظرة سريعة على الكتالوج والمنتجات'
                : 'Products Overview',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productsVM.products.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final prod = productsVM.products[i];
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      prod.images.isNotEmpty ? prod.images.first : '',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: primary.withAlpha(30),
                        child: Icon(Icons.inventory_2_outlined, color: primary),
                      ),
                    ),
                  ),
                  title: Text(
                    prod.localizedName(loc.isArabic),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${prod.price} ${loc.translate("sar")} | ${loc.isArabic ? "المخزون:" : "Stock:"} ${prod.stockCount}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: prod.inStock
                          ? Colors.green.withAlpha(25)
                          : Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      prod.inStock
                          ? (loc.isArabic ? 'متوفر' : 'In Stock')
                          : (loc.isArabic ? 'نفذ' : 'Out'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: prod.inStock ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: PRODUCTS MANAGEMENT (EDIT, DELETE, ADD)
  // ==========================================
  Widget _productInfoBadge(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    final productsVM = Provider.of<ProductsViewModel>(context);
    final filteredProds = productsVM.products.where((p) {
      if (_productSearchQuery.isEmpty) return true;
      final query = _productSearchQuery.toLowerCase();
      return p.nameAr.toLowerCase().contains(query) ||
          p.nameEn.toLowerCase().contains(query) ||
          p.price.toString().contains(query);
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () => _showAddProductModal(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          loc.isArabic ? 'إضافة منتج جديد' : 'Add Product',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Quick Action Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) =>
                        setState(() => _productSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: loc.isArabic
                          ? 'بحث في المنتجات بالاسم أو السعر...'
                          : 'Search products...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(100),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: loc.isArabic
                      ? 'إدارة التصنيفات'
                      : 'Manage categories',
                  style: IconButton.styleFrom(
                    backgroundColor: primary.withAlpha(20),
                  ),
                  icon: Icon(Icons.category_outlined, color: primary),
                  onPressed: () => _showCategoryManager(context),
                ),
                IconButton(
                  tooltip: loc.isArabic ? 'تحديث المنتجات' : 'Refresh Products',
                  style: IconButton.styleFrom(
                    backgroundColor: primary.withAlpha(20),
                  ),
                  icon: Icon(Icons.cloud_sync_rounded, color: primary),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final isAr = loc.isArabic;
                    final success = await productsVM
                        .refreshProductsFromSupabase();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? (isAr
                                    ? 'تم تحديث منتجات tempMarket'
                                    : 'tempMarket products refreshed!')
                              : 'Failed: ${productsVM.errorMessage}',
                        ),
                        backgroundColor: success
                            ? const Color(0xFF10B981)
                            : Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: productsVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withAlpha(100),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.isArabic
                              ? 'لا توجد منتجات مطابقة'
                              : 'No products found',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filteredProds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final prod = filteredProds[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Product Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  prod.images.isNotEmpty
                                      ? prod.images.first
                                      : '',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 64,
                                    height: 64,
                                    color: primary.withAlpha(25),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Product Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.localizedName(loc.isArabic),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${prod.price} ${loc.translate("sar")} | ${loc.isArabic ? "المخزون:" : "Stock:"} ${prod.stockCount} ${prod.localizedUnit(loc.isArabic)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withAlpha(160),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prod.businessType,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Wrap(
                                      spacing: 5,
                                      runSpacing: 4,
                                      children: [
                                        _productInfoBadge(
                                          Icons.photo_library_outlined,
                                          '${prod.images.length} ${loc.isArabic ? "صور" : "photos"}',
                                          theme,
                                        ),
                                        _productInfoBadge(
                                          Icons.star_rounded,
                                          '${prod.rating.toStringAsFixed(1)} (${prod.reviewCount})',
                                          theme,
                                        ),
                                        if (prod.hasDiscount)
                                          _productInfoBadge(
                                            Icons.local_offer_outlined,
                                            '-${prod.discountPercentage}%',
                                            theme,
                                          ),
                                        if (prod.isFeatured)
                                          _productInfoBadge(
                                            Icons.rocket_launch_outlined,
                                            loc.isArabic ? 'مميز' : 'Featured',
                                            theme,
                                          ),
                                        _productInfoBadge(
                                          prod.inStock
                                              ? Icons.check_circle_outline
                                              : Icons.remove_circle_outline,
                                          prod.inStock
                                              ? (loc.isArabic
                                                    ? 'متاح'
                                                    : 'In stock')
                                              : (loc.isArabic
                                                    ? 'نفد'
                                                    : 'Out of stock'),
                                          theme,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Edit & Delete Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Color(0xFF3B82F6),
                                      size: 20,
                                    ),
                                    tooltip: loc.isArabic
                                        ? 'تعديل المنتج'
                                        : 'Edit Product',
                                    onPressed: () =>
                                        _showEditProductDialog(context, prod),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    tooltip: loc.isArabic
                                        ? 'حذف المنتج'
                                        : 'Delete Product',
                                    onPressed: () =>
                                        _showDeleteConfirmDialog(context, prod),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryManager(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final categories = productsVM.categories;
            return AlertDialog(
              title: Text(
                loc.isArabic ? 'إدارة التصنيفات' : 'Manage categories',
              ),
              content: SizedBox(
                width: 420,
                child: categories.isEmpty
                    ? Text(
                        loc.isArabic
                            ? 'لا توجد تصنيفات بعد'
                            : 'No categories yet',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final productCount = productsVM.allProducts
                              .where(
                                (product) => product.categoryId == category.id,
                              )
                              .length;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.category_outlined),
                            title: Text(category.localizedName(loc.isArabic)),
                            subtitle: Text(
                              '${category.nameAr} • $productCount ${loc.isArabic ? 'منتج' : 'products'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    final saved = await _showCategoryEditor(
                                      context,
                                      category,
                                    );
                                    if (saved && mounted) setDialogState(() {});
                                  },
                                ),
                                IconButton(
                                  tooltip: loc.isArabic ? 'حذف' : 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: productCount > 0
                                      ? () => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  loc.isArabic
                                                      ? 'انقل المنتجات إلى تصنيف آخر قبل حذف هذا التصنيف.'
                                                      : 'Move this category’s products to another category before deleting it.',
                                                ),
                                              ),
                                            )
                                      : () async {
                                          final deleted = await productsVM
                                              .deleteAdminCategory(category.id);
                                          if (!context.mounted) return;
                                          if (deleted) {
                                            setDialogState(() {});
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  loc.isArabic
                                                      ? 'تعذر حذف التصنيف.'
                                                      : 'Could not delete the category.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    final saved = await _showCategoryEditor(context);
                    if (saved && mounted) setDialogState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: Text(loc.isArabic ? 'إضافة تصنيف' : 'Add category'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(loc.translate('cancel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showCategoryEditor(
    BuildContext context, [
    CategoryModel? category,
  ]) async {
    final loc = AppLocalizations.of(context);
    final nameArController = TextEditingController(
      text: category?.nameAr ?? '',
    );
    final nameEnController = TextEditingController(
      text: category?.nameEn ?? '',
    );
    var businessType = category?.businessType ?? 'all';
    var isSaving = false;
    var errorText = '';
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            category == null
                ? (loc.isArabic ? 'إضافة تصنيف' : 'Add category')
                : (loc.isArabic ? 'تعديل التصنيف' : 'Edit category'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameArController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: loc.isArabic
                        ? 'اسم التصنيف بالعربية'
                        : 'Category name in Arabic',
                  ),
                ),
                TextField(
                  controller: nameEnController,
                  decoration: InputDecoration(
                    labelText: loc.isArabic
                        ? 'اسم التصنيف بالإنجليزية'
                        : 'Category name in English',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: businessType,
                  decoration: InputDecoration(
                    labelText: loc.isArabic ? 'نوع النشاط' : 'Business type',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(loc.isArabic ? 'الكل' : 'All'),
                    ),
                    DropdownMenuItem(
                      value: 'factory',
                      child: Text(loc.isArabic ? 'مصنع' : 'Factory'),
                    ),
                    DropdownMenuItem(
                      value: 'mall',
                      child: Text(loc.isArabic ? 'متجر' : 'Mall'),
                    ),
                    DropdownMenuItem(
                      value: 'pharmacy',
                      child: Text(loc.isArabic ? 'صيدلية' : 'Pharmacy'),
                    ),
                    DropdownMenuItem(
                      value: 'restaurant',
                      child: Text(loc.isArabic ? 'مطعم' : 'Restaurant'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null)
                      setDialogState(() => businessType = value);
                  },
                ),
                if (errorText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(errorText, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final nameAr = nameArController.text.trim();
                      final nameEn = nameEnController.text.trim();
                      if (nameAr.isEmpty || nameEn.isEmpty) {
                        setDialogState(
                          () => errorText = loc.isArabic
                              ? 'أدخل اسم التصنيف باللغتين.'
                              : 'Enter the category name in both languages.',
                        );
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        errorText = '';
                      });
                      final value = CategoryModel(
                        id:
                            category?.id ??
                            'cat_${DateTime.now().microsecondsSinceEpoch}',
                        nameAr: nameAr,
                        nameEn: nameEn,
                        businessType: businessType,
                        productCount: category?.productCount ?? 0,
                        icon: Icons.category_outlined,
                      );
                      final success = category == null
                          ? await productsVM.addAdminCategory(value)
                          : await productsVM.updateAdminCategory(value);
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setDialogState(() {
                          isSaving = false;
                          errorText =
                              productsVM.errorMessage ??
                              (loc.isArabic
                                  ? 'تعذر حفظ التصنيف. تحقق من الاتصال وحاول مرة أخرى.'
                                  : 'Could not save the category. Check your connection and try again.');
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
    nameArController.dispose();
    nameEnController.dispose();
    return saved ?? false;
  }

  // ==========================================
  // TAB 3: PURCHASED PRODUCTS & ORDERS LOG
  // ==========================================
  Widget _buildPurchasedOrdersTab(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    final ordersVM = Provider.of<OrdersViewModel>(context);
    final allOrders = ordersVM.orders;

    // Filter into In-Progress vs Successfully Delivered
    final inProgressOrders = allOrders
        .where((o) => o.status != OrderStatus.delivered)
        .toList();
    final deliveredOrders = allOrders
        .where((o) => o.status == OrderStatus.delivered)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              indicatorColor: primary,
              labelColor: primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.pending_actions_rounded, size: 18),
                  text:
                      '${loc.isArabic ? "قيد الشراء والتجهيز" : "In Progress"} (${inProgressOrders.length})',
                ),
                Tab(
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  text:
                      '${loc.isArabic ? "تم شراؤها بنجاح" : "Completed Purchases"} (${deliveredOrders.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPurchasedOrdersList(
                  inProgressOrders,
                  theme,
                  loc,
                  primary,
                  isInProgress: true,
                ),
                _buildPurchasedOrdersList(
                  deliveredOrders,
                  theme,
                  loc,
                  primary,
                  isInProgress: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedOrdersList(
    List<OrderModel> orders,
    ThemeData theme,
    AppLocalizations loc,
    Color primary, {
    required bool isInProgress,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInProgress
                  ? Icons.hourglass_empty_rounded
                  : Icons.inventory_rounded,
              size: 56,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              isInProgress
                  ? (loc.isArabic
                        ? 'لا توجد طلبات جارية حالياً'
                        : 'No in-progress orders')
                  : (loc.isArabic
                        ? 'لا توجد منتجات مشتراة مكتملة بعد'
                        : 'No completed purchases yet'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.translate("order_id")}: ${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? Colors.amber.withAlpha(30)
                            : Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.localized(loc.isArabic),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInProgress
                              ? Colors.amber.shade900
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Purchased Items List
                Text(
                  loc.isArabic
                      ? 'المنتجات المشتراة في هذا الطلب:'
                      : 'Purchased Items:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item.product.images.isNotEmpty
                                ? item.product.images.first
                                : '',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 36,
                              color: primary.withAlpha(20),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.product.localizedName(loc.isArabic),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity} x ${item.product.price} = ${item.totalPrice.toStringAsFixed(1)} ${loc.translate("sar")}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),

                // Order Footer (Address & Total)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.deliveryAddress,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  160,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${loc.translate("total")}: ${order.total.toStringAsFixed(1)} ${loc.translate("sar")}',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 4: USERS MANAGEMENT (SUPABASE PROFILES)
  // ==========================================
  Widget _buildUsersTab(ThemeData theme, AppLocalizations loc, Color primary) {
    final displayUsers = _supabaseProfiles.map((p) {
      return UserModel(
        id: p['id']?.toString() ?? '',
        name: p['name']?.toString() ?? 'مستخدم',
        email: p['id']?.toString() ?? '—',
        phone: p['phone']?.toString() ?? '0500000000',
        role: UserRole.customer,
        address: p['address']?.toString() ?? 'الرياض',
        avatarUrl:
            p['avatar_url']?.toString() ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      );
    }).toList();

    final filteredUsers = displayUsers.where((u) {
      if (_userSearchQuery.isEmpty) return true;
      return u.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          u.phone.contains(_userSearchQuery) ||
          u.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (val) => setState(() => _userSearchQuery = val),
            decoration: InputDecoration(
              hintText: loc.isArabic
                  ? 'بحث في المستخدمين بالاسم أو الهاتف...'
                  : 'Search users...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
                100,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Users Count Badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.isArabic ? "إجمالي المستخدمين:" : "Total Users:"} ${filteredUsers.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (_supabaseProfiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Live',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Users List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    backgroundColor: primary.withAlpha(30),
                    child: user.avatarUrl.isEmpty
                        ? Icon(Icons.person, color: primary)
                        : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${user.phone} | ${user.address}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.role.name.toUpperCase(),
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourierApplicationsTab(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    if (_driverApplications.isEmpty) {
      return Center(
        child: Text(
          loc.isArabic
              ? 'لا توجد طلبات مندوبين حالياً'
              : 'No courier applications yet',
          style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(150)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSupabaseAdminData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _driverApplications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final app = _driverApplications[index];
          final status = app['status']?.toString() ?? 'pending';
          final licenseUrl = app['license_image_url']?.toString();
          final statusColor = status == 'approved'
              ? const Color(0xFF10B981)
              : status == 'rejected'
              ? Colors.red
              : Colors.orange;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: primary.withAlpha(20),
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          app['full_name']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(
                          _applicationStatusTitle(status, loc.isArabic),
                          style: const TextStyle(fontSize: 10),
                        ),
                        side: BorderSide(color: statusColor.withAlpha(100)),
                        backgroundColor: statusColor.withAlpha(20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('${app['phone'] ?? ''} • ${app['city'] ?? ''}'),
                  const SizedBox(height: 4),
                  Text(
                    '${app['vehicle_type'] ?? 'car'} • ${app['experience_years'] ?? 0} years experience',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  if (licenseUrl != null && licenseUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(licenseUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(
                        loc.isArabic
                            ? 'عرض مستند الرخصة'
                            : 'View license document',
                      ),
                    ),
                  ],
                  if (status == 'pending') ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _updateDriverApplicationStatus(
                            app['id'].toString(),
                            'rejected',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(loc.isArabic ? 'رفض' : 'Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updateDriverApplicationStatus(
                            app['id'].toString(),
                            'approved',
                          ),
                          child: Text(loc.isArabic ? 'اعتماد' : 'Approve'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateDriverApplicationStatus(String id, String status) async {
    final success = await SupabaseService().updateDriverApplicationStatus(
      id,
      status,
    );
    if (!mounted) return;
    if (success) {
      setState(() {
        final index = _driverApplications.indexWhere(
          (app) => app['id']?.toString() == id,
        );
        if (index != -1) _driverApplications[index]['status'] = status;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (AppLocalizations.of(context).isArabic
                    ? 'تم تحديث الطلب.'
                    : 'Application updated.')
              : (AppLocalizations.of(context).isArabic
                    ? 'تعذر تحديث الطلب.'
                    : 'Could not update application.'),
        ),
      ),
    );
  }

  String _applicationStatusTitle(String status, bool isArabic) {
    if (!isArabic) return status.toUpperCase();
    switch (status) {
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'قيد المراجعة';
    }
  }

  // ==========================================
  // TAB 6: BRAND, SERVICE TYPE & CONTACT SETTINGS
  // ==========================================
  Widget _buildPromoCodesTab(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoCodeEditor(context),
        icon: const Icon(Icons.add),
        label: Text(loc.isArabic ? 'إنشاء رمز خصم' : 'Create promo code'),
      ),
      body: _isLoadingPromoCodes
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPromoCodes,
              child: _promoCodes.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 140),
                        Icon(
                          Icons.local_offer_outlined,
                          size: 56,
                          color: primary.withAlpha(150),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            loc.isArabic
                                ? 'لا توجد رموز خصم بعد'
                                : 'No promo codes yet',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: _promoCodes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final promo = _promoCodes[index];
                        final expired =
                            promo.expiresAt != null &&
                            promo.expiresAt!.isBefore(DateTime.now());
                        final enabled = promo.isActive && !expired;
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.local_offer,
                              color: enabled ? primary : Colors.grey,
                            ),
                            title: Text(
                              promo.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${promo.discountPercent.toStringAsFixed(promo.discountPercent % 1 == 0 ? 0 : 1)}% • '
                              '${enabled ? (loc.isArabic ? 'فعال' : 'Active') : (loc.isArabic ? 'غير فعال' : 'Inactive')}'
                              '${promo.expiresAt == null ? '' : ' • ${promo.expiresAt!.toLocal().toString().split(' ').first}'}',
                            ),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: loc.isArabic ? 'تعديل' : 'Edit',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _showPromoCodeEditor(context, promo),
                                ),
                                IconButton(
                                  tooltip: loc.isArabic ? 'حذف' : 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final service = SupabaseService();
                                    final deleted = await service
                                        .deletePromoCode(promo.code);
                                    if (!mounted) return;
                                    if (deleted) {
                                      setState(
                                        () => _promoCodes.removeWhere(
                                          (item) => item.code == promo.code,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            service.lastPromoCodeError ??
                                                (loc.isArabic
                                                    ? 'تعذر حذف رمز الخصم.'
                                                    : 'Could not delete promo code.'),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _showPromoCodeEditor(
    BuildContext context, [
    PromoCodeModel? promo,
  ]) async {
    final loc = AppLocalizations.of(context);
    final codeController = TextEditingController(text: promo?.code ?? '');
    final discountController = TextEditingController(
      text: promo == null ? '' : promo.discountPercent.toString(),
    );
    final expiryController = TextEditingController(
      text: promo?.expiresAt == null
          ? ''
          : promo!.expiresAt!.toLocal().toString().split(' ').first,
    );
    var isActive = promo?.isActive ?? true;
    var isSaving = false;
    var errorText = '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            promo == null
                ? (loc.isArabic ? 'إنشاء رمز خصم' : 'Create promo code')
                : (loc.isArabic ? 'تعديل رمز الخصم' : 'Edit promo code'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  readOnly: promo != null,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: loc.isArabic ? 'رمز الخصم' : 'Promo code',
                  ),
                ),
                TextField(
                  controller: discountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.isArabic ? 'نسبة الخصم (%)' : 'Discount (%)',
                  ),
                ),
                TextField(
                  controller: expiryController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: loc.isArabic
                        ? 'تاريخ الانتهاء (اختياري)'
                        : 'Expiry date (optional)',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate:
                              promo?.expiresAt != null &&
                                  promo!.expiresAt!.isAfter(DateTime.now())
                              ? promo.expiresAt!
                              : DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (selected != null) {
                          expiryController.text = selected
                              .toIso8601String()
                              .split('T')
                              .first;
                        }
                      },
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.isArabic ? 'فعال' : 'Active'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
                if (errorText.isNotEmpty)
                  Text(errorText, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final code = codeController.text.trim().toUpperCase();
                      final discount = double.tryParse(
                        discountController.text.trim(),
                      );
                      final expiryText = expiryController.text.trim();
                      final expiresAt = expiryText.isEmpty
                          ? null
                          : DateTime.tryParse('${expiryText}T23:59:59');
                      if (!RegExp(r'^[A-Z0-9_-]{3,30}$').hasMatch(code) ||
                          discount == null ||
                          discount <= 0 ||
                          discount > 100 ||
                          (expiryText.isNotEmpty && expiresAt == null)) {
                        setDialogState(
                          () => errorText = loc.isArabic
                              ? 'أدخل رمزاً صحيحاً ونسبة خصم بين 1 و100 وتاريخاً صالحاً.'
                              : 'Enter a valid code, a discount from 1 to 100, and a valid expiry date.',
                        );
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        errorText = '';
                      });
                      final service = SupabaseService();
                      final saved = await service.savePromoCode(
                        PromoCodeModel(
                          code: code,
                          discountPercent: discount,
                          isActive: isActive,
                          expiresAt: expiresAt,
                        ),
                        isNew: promo == null,
                      );
                      if (!dialogContext.mounted) return;
                      if (saved) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setDialogState(() {
                          isSaving = false;
                          errorText =
                              service.lastPromoCodeError ??
                              (loc.isArabic
                                  ? 'تعذر حفظ الرمز. تحقق من الاتصال وحاول مرة أخرى.'
                                  : 'Could not save the code. Check your connection and try again.');
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.isArabic ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeController.dispose();
      discountController.dispose();
      expiryController.dispose();
      if (saved == true && mounted) _loadPromoCodes();
    });
  }

  Widget _buildServiceContactForm(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
    ThemeViewModel themeVM,
  ) {
    final isArabic = loc.isArabic;
    final requiredMessage = isArabic
        ? '\u0645\u0637\u0644\u0648\u0628'
        : 'Required';
    final emailMessage = isArabic
        ? '\u0623\u062f\u062e\u0644 \u0628\u0631\u064a\u062f\u0627\u064b \u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a\u0627\u064b \u0635\u062d\u064a\u062d\u0627\u064b'
        : 'Enter a valid email address';

    InputDecoration decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(55),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
    );

    Widget responsivePair(Widget first, Widget second) => LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final width = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(width: width, child: first),
            SizedBox(width: width, child: second),
          ],
        );
      },
    );

    Widget sectionHeading(IconData icon, String title, String description) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    final phoneKeyboard = TextInputType.phone;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _brandSettingsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionHeading(
                Icons.storefront_outlined,
                isArabic
                    ? '\u0646\u0648\u0639 \u0627\u0644\u062e\u062f\u0645\u0629 \u0648\u0647\u0648\u064a\u0629 \u0627\u0644\u0645\u0646\u0635\u0629'
                    : 'Service type & brand identity',
                isArabic
                    ? '\u0627\u062e\u062a\u0631 \u0646\u0634\u0627\u0637 \u0627\u0644\u0645\u0646\u0635\u0629 \u0648\u062d\u062f\u062b \u0627\u0633\u0645\u0647\u0627 \u0628\u0627\u0644\u0644\u063a\u062a\u064a\u0646.'
                    : 'Choose the platform’s business category and its bilingual display name.',
              ),
              DropdownButtonFormField<BusinessType>(
                initialValue: _selectedBusinessType,
                isExpanded: true,
                decoration: decoration(
                  isArabic
                      ? '\u0646\u0648\u0639 \u0627\u0644\u0646\u0634\u0627\u0637'
                      : 'Business category',
                  Icons.category_outlined,
                ),
                items: BusinessType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          isArabic ? type.titleAr : type.titleEn,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedBusinessType = value);
                },
              ),
              const SizedBox(height: 18),
              responsivePair(
                TextFormField(
                  controller: _brandNameArCtrl,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                  decoration: decoration(
                    isArabic
                        ? '\u0627\u0633\u0645 \u0627\u0644\u062e\u062f\u0645\u0629 \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629'
                        : 'Service name (Arabic)',
                    Icons.translate_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? requiredMessage
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                TextFormField(
                  controller: _brandNameEnCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: decoration(
                    isArabic
                        ? '\u0627\u0633\u0645 \u0627\u0644\u062e\u062f\u0645\u0629 \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629'
                        : 'Service name (English)',
                    Icons.translate_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? requiredMessage
                      : null,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 24),
              sectionHeading(
                Icons.support_agent_rounded,
                isArabic
                    ? '\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0627\u0644\u062a\u0648\u0627\u0635\u0644'
                    : 'Contact information',
                isArabic
                    ? '\u0623\u0636\u0641 \u0642\u0646\u0648\u0627\u062a \u0627\u0644\u062a\u0648\u0627\u0635\u0644 \u0627\u0644\u0638\u0627\u0647\u0631\u0629 \u0644\u0644\u0639\u0645\u0644\u0627\u0621.'
                    : 'Add the customer-facing support channels for your platform.',
              ),
              responsivePair(
                TextFormField(
                  controller: _hotlineCtrl,
                  keyboardType: phoneKeyboard,
                  textDirection: TextDirection.ltr,
                  decoration: decoration(
                    loc.translate('hotline'),
                    Icons.phone_in_talk_rounded,
                  ),
                ),
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: phoneKeyboard,
                  textDirection: TextDirection.ltr,
                  decoration: decoration(
                    loc.translate('whatsapp'),
                    Icons.chat_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: decoration(
                  loc.translate('email'),
                  Icons.email_outlined,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : emailMessage;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                textDirection: TextDirection.rtl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                minLines: 1,
                decoration: decoration(
                  isArabic
                      ? '\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u0645\u0642\u0631'
                      : 'Business address',
                  Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onPressed: _isSavingBrandSettings
                      ? null
                      : () async {
                          if (!(_brandSettingsFormKey.currentState
                                  ?.validate() ??
                              false))
                            return;
                          setState(() => _isSavingBrandSettings = true);
                          final saved = await themeVM.updateCustomBrand(
                            brandNameAr: _brandNameArCtrl.text.trim(),
                            brandNameEn: _brandNameEnCtrl.text.trim(),
                            businessType: _selectedBusinessType,
                            hotline: _hotlineCtrl.text.trim(),
                            whatsappNumber: _whatsappCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                            addressAr: _addressCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() => _isSavingBrandSettings = false);
                          final message = saved
                              ? (isArabic
                                    ? '\u062a\u0645 \u062d\u0641\u0638 \u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u062e\u062f\u0645\u0629 \u0648\u0627\u0644\u062a\u0648\u0627\u0635\u0644 \u0628\u0646\u062c\u0627\u062d.'
                                    : 'Service and contact settings saved.')
                              : (themeVM.brandSettingsError ??
                                    'Could not save settings. Please try again.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: saved
                                  ? const Color(0xFF10B981)
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: _isSavingBrandSettings
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSavingBrandSettings
                        ? (isArabic
                              ? '\u062c\u0627\u0631\u064a \u0627\u0644\u062d\u0641\u0638...'
                              : 'Saving...')
                        : loc.translate('save_changes'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSettingsTab(
    ThemeData theme,
    AppLocalizations loc,
    Color primary,
  ) {
    final themeVM = Provider.of<ThemeViewModel>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Type & Brand Customizer Header
          Text(
            loc.isArabic
                ? '\u062a\u062e\u0635\u064a\u0635 \u0646\u0648\u0639 \u0627\u0644\u062e\u062f\u0645\u0629 \u0648\u0647\u0648\u064a\u0629 \u0627\u0644\u0645\u0646\u0635\u0629'
                : 'Customize Service Type & Brand',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            loc.isArabic
                ? '\u062d\u062f\u062b \u0646\u0648\u0639 \u0627\u0644\u062e\u062f\u0645\u0629 \u0648\u0627\u0633\u0645 \u0627\u0644\u0645\u0646\u0635\u0629 \u0648\u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062a\u0648\u0627\u0635\u0644.'
                : 'Instantly update tempMarket service type, brand title, and contact details',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: 16),

          _buildServiceContactForm(theme, loc, primary, themeVM),
          const SizedBox(height: 24),
          // PUSH NOTIFICATIONS BROADCAST SECTION
          Text(
            loc.isArabic
                ? 'بث إشعار عام للمستخدمين'
                : 'Send Notification to Users',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            loc.isArabic
                ? 'إرسال إشعار فوري لجميع المستخدمين لحثهم على عروض جديدة أو تنبيهات عامة'
                : 'Send an instant notification to all users',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _notifTitleArCtrl,
                    decoration: InputDecoration(
                      labelText: loc.isArabic
                          ? 'عنوان الإشعار (عربي)'
                          : 'Notification Title (AR)',
                      hintText: 'مثال: خصم 20% لفترة محدودة!',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notifBodyArCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: loc.isArabic
                          ? 'نص الإشعار (عربي)'
                          : 'Notification Body (AR)',
                      hintText:
                          'اغتنم فرصة العروض الحصرية على كافة المنتجات اليوم...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSendingNotif
                          ? null
                          : () async {
                              final title = _notifTitleArCtrl.text.trim();
                              final body = _notifBodyArCtrl.text.trim();
                              if (title.isEmpty || body.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      loc.isArabic
                                          ? 'يرجى كتابة عنوان ونص الإشعار'
                                          : 'Please enter title and body',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSendingNotif = true);
                              final messenger = ScaffoldMessenger.of(context);
                              final successText = loc.isArabic
                                  ? 'تم إرسال الإشعار بنجاح!'
                                  : 'Notification sent successfully!';
                              final failText = loc.isArabic
                                  ? 'فشل إرسال الإشعار، تأكد من الاتصال'
                                  : 'Failed to send notification';

                              final notif = NotificationModel(
                                id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
                                titleAr: title,
                                titleEn: title,
                                bodyAr: body,
                                bodyEn: body,
                                timestamp: DateTime.now(),
                                isRead: false,
                                type: NotificationType.promo,
                              );

                              final success = await SupabaseService()
                                  .insertNotification(notif);
                              if (!mounted) return;
                              setState(() => _isSendingNotif = false);

                              if (success) {
                                _notifTitleArCtrl.clear();
                                _notifBodyArCtrl.clear();
                              }
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success ? successText : failText,
                                  ),
                                  backgroundColor: success
                                      ? const Color(0xFF10B981)
                                      : Colors.red,
                                ),
                              );
                            },
                      icon: _isSendingNotif
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        loc.isArabic
                            ? 'إرسال الإشعار لجميع المستخدمين'
                            : 'Send Push Notification',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ==========================================
  // MODAL: ADD PRODUCT TO SUPABASE
  // ==========================================
  void _showAddProductModal(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final oldPriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '100');
    final descCtrl = TextEditingController();
    String bType = _selectedBusinessType.name;
    String? selectedCategoryId = productsVM.categories.isNotEmpty
        ? productsVM.categories.first.id
        : null;
    Uint8List? pickedBytes;
    String? pickedFileName;
    final extraPickedImages = <({Uint8List bytes, String name})>[];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.isArabic ? 'إضافة منتج جديد' : 'Add New Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Image picker button
                    Center(
                      child: InkWell(
                        onTap: () async {
                          final picked = await MediaService.pickProductImage(
                            context,
                          );
                          if (picked != null) {
                            setModalState(() {
                              pickedBytes = picked.bytes;
                              pickedFileName = picked.name;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(60),
                            ),
                          ),
                          child: pickedBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    pickedBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 36,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      loc.isArabic
                                          ? 'التقاط أو اختيار صورة المنتج'
                                          : 'Select Product Image',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: extraPickedImages.length >= 7
                              ? null
                              : () async {
                                  final picked =
                                      await MediaService.pickProductImage(
                                        context,
                                      );
                                  if (picked != null)
                                    setModalState(
                                      () => extraPickedImages.add((
                                        bytes: picked.bytes,
                                        name: picked.name,
                                      )),
                                    );
                                },
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            loc.isArabic
                                ? 'إضافة صور أخرى (${extraPickedImages.length}/7)'
                                : 'Add more photos (${extraPickedImages.length}/7)',
                          ),
                        ),
                        ...extraPickedImages.asMap().entries.map(
                          (entry) => InputChip(
                            avatar: ClipOval(
                              child: Image.memory(
                                entry.value.bytes,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                            label: Text('${entry.key + 2}'),
                            onDeleted: () => setModalState(
                              () => extraPickedImages.removeAt(entry.key),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: nameArCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم المنتج (عربي)'
                            : 'Product Name (AR)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameEnCtrl,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'اسم المنتج (إنجليزي)'
                            : 'Product Name (EN)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value:
                          productsVM.categories.any(
                            (category) => category.id == selectedCategoryId,
                          )
                          ? selectedCategoryId
                          : null,
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'تصنيف المنتج'
                            : 'Product category',
                        border: const OutlineInputBorder(),
                      ),
                      items: productsVM.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.localizedName(loc.isArabic)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setModalState(() => selectedCategoryId = value),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.translate('price'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: loc.isArabic ? 'المخزون' : 'Stock',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: oldPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: loc.isArabic
                            ? 'السعر قبل الخصم (اختياري)'
                            : 'Original price (optional offer)',
                        helperText: loc.isArabic
                            ? 'اتركه فارغًا إذا لم يوجد عرض'
                            : 'Leave blank when there is no offer',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: loc.translate('description'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final nameAr = nameArCtrl.text.trim();
                                final price =
                                    double.tryParse(priceCtrl.text.trim()) ??
                                    0.0;
                                final oldPrice = double.tryParse(
                                  oldPriceCtrl.text.trim(),
                                );
                                if (nameAr.isEmpty ||
                                    price <= 0 ||
                                    (oldPrice != null && oldPrice <= price) ||
                                    (pickedBytes == null &&
                                        extraPickedImages.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        loc.isArabic
                                            ? 'يرجى إدخال اسم وسعر صحيح للمنتج'
                                            : 'Invalid name or price',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                final newProd = ProductModel(
                                  id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                                  nameAr: nameAr,
                                  nameEn: nameEnCtrl.text.trim().isNotEmpty
                                      ? nameEnCtrl.text.trim()
                                      : nameAr,
                                  descriptionAr: descCtrl.text.trim(),
                                  descriptionEn: descCtrl.text.trim(),
                                  price: price,
                                  oldPrice: oldPrice,
                                  categoryId: selectedCategoryId ?? '',
                                  businessType: bType,
                                  images: const [],
                                  inStock: true,
                                  stockCount:
                                      int.tryParse(stockCtrl.text.trim()) ??
                                      100,
                                  unitAr: 'قطعة',
                                  unitEn: 'Piece',
                                );

                                final success = await productsVM
                                    .addProductToSupabase(
                                      newProd,
                                      imageBytesList: [
                                        if (pickedBytes != null) pickedBytes!,
                                        ...extraPickedImages.map(
                                          (image) => image.bytes,
                                        ),
                                      ],
                                      imageFileNames: [
                                        if (pickedFileName != null)
                                          pickedFileName!,
                                        ...extraPickedImages.map(
                                          (image) => image.name,
                                        ),
                                      ],
                                    );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? (loc.isArabic
                                                  ? 'تمت إضافة المنتج بنجاح!'
                                                  : 'Product added successfully!')
                                            : 'Failed: ${productsVM.errorMessage}',
                                      ),
                                      backgroundColor: success
                                          ? const Color(0xFF10B981)
                                          : Colors.red,
                                    ),
                                  );
                                  if (success) Navigator.pop(ctx);
                                }
                              },
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                loc.isArabic ? 'حفظ المنتج' : 'Save Product',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // DIALOG: EDIT PRODUCT IN SUPABASE
  // ==========================================
  void _showEditProductDialog(BuildContext context, ProductModel product) {
    final loc = AppLocalizations.of(context);
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nameArCtrl = TextEditingController(text: product.nameAr);
    final nameEnCtrl = TextEditingController(text: product.nameEn);
    final descriptionArCtrl = TextEditingController(
      text: product.descriptionAr,
    );
    final descriptionEnCtrl = TextEditingController(
      text: product.descriptionEn,
    );
    final priceCtrl = TextEditingController(text: product.price.toString());
    final oldPriceCtrl = TextEditingController(
      text: product.oldPrice?.toString() ?? '',
    );
    final stockCtrl = TextEditingController(
      text: product.stockCount.toString(),
    );
    final unitArCtrl = TextEditingController(text: product.unitAr);
    final unitEnCtrl = TextEditingController(text: product.unitEn);
    final specsArCtrl = TextEditingController(
      text: product.specificationsAr.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'),
    );
    final specsEnCtrl = TextEditingController(
      text: product.specificationsEn.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n'),
    );
    final keptImages = List<String>.from(product.images);
    final pendingImages = <({Uint8List bytes, String name})>[];
    final availableBusinessTypes = BusinessType.values
        .map((type) => type.name)
        .toList();
    var selectedCategoryId = product.categoryId;
    var selectedBusinessType = product.businessType;
    var isInStock = product.inStock;
    var isFeatured = product.isFeatured;
    var isSaving = false;
    final isArabic = loc.isArabic;
    final requiredMessage = isArabic
        ? '\u0645\u0637\u0644\u0648\u0628'
        : 'Required';
    final invalidPriceMessage = isArabic
        ? '\u0623\u062f\u062e\u0644 \u0633\u0639\u0631\u0627\u064b \u0635\u062d\u064a\u062d\u0627\u064b \u0623\u0643\u0628\u0631 \u0645\u0646 \u0635\u0641\u0631'
        : 'Enter a valid price greater than zero';
    final invalidStockMessage = isArabic
        ? '\u0623\u062f\u062e\u0644 \u0643\u0645\u064a\u0629 \u0635\u0627\u0644\u062d\u0629 \u0644\u0644\u0645\u062e\u0632\u0648\u0646'
        : 'Enter a valid stock quantity';
    String text(String english, String arabic) => isArabic ? arabic : english;

    Map<String, String> parseSpecifications(String value) {
      final result = <String, String>{};
      for (final line in value.split('\n')) {
        final separator = line.indexOf(':');
        if (separator <= 0) continue;
        final key = line.substring(0, separator).trim();
        final detail = line.substring(separator + 1).trim();
        if (key.isNotEmpty && detail.isNotEmpty) result[key] = detail;
      }
      return result;
    }

    Widget field(
      TextEditingController controller,
      String label, {
      IconData? icon,
      TextInputType? keyboardType,
      TextDirection? direction,
      int maxLines = 1,
      String? Function(String?)? validator,
      TextInputAction? action,
    }) => TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: direction,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : null,
      textInputAction: action,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );

    Widget imageTile({
      required Widget image,
      required VoidCallback onRemove,
      required String label,
    }) => SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
          Positioned(
            right: 3,
            top: 3,
            child: IconButton.filledTonal(
              tooltip: label,
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 16),
            ),
          ),
        ],
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (formContext, setDialogState) {
          final categories = productsVM.categories;
          final validCategory =
              categories.any((item) => item.id == selectedCategoryId)
              ? selectedCategoryId
              : null;
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: Theme.of(formContext).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text(
                      'Edit product details',
                      '\u062a\u0639\u062f\u064a\u0644 \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u0645\u0646\u062a\u062c',
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.sizeOf(formContext).width < 680
                  ? MediaQuery.sizeOf(formContext).width * 0.82
                  : 620,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(formContext).height * 0.68,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            text(
                              'Product photos',
                              '\u0635\u0648\u0631 \u0627\u0644\u0645\u0646\u062a\u062c',
                            ),
                            style: Theme.of(formContext).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...keptImages.asMap().entries.map(
                              (entry) => imageTile(
                                label: text(
                                  'Remove photo',
                                  '\u062d\u0630\u0641 \u0627\u0644\u0635\u0648\u0631\u0629',
                                ),
                                image: Image.network(
                                  entry.value,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Theme.of(
                                      formContext,
                                    ).colorScheme.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                    ),
                                  ),
                                ),
                                onRemove: () => setDialogState(
                                  () => keptImages.removeAt(entry.key),
                                ),
                              ),
                            ),
                            ...pendingImages.asMap().entries.map(
                              (entry) => imageTile(
                                label: text(
                                  'Remove photo',
                                  '\u062d\u0630\u0641 \u0627\u0644\u0635\u0648\u0631\u0629',
                                ),
                                image: Image.memory(
                                  entry.value.bytes,
                                  fit: BoxFit.cover,
                                ),
                                onRemove: () => setDialogState(
                                  () => pendingImages.removeAt(entry.key),
                                ),
                              ),
                            ),
                            if (keptImages.length + pendingImages.length < 7)
                              SizedBox(
                                width: 84,
                                height: 84,
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final picked =
                                              await MediaService.pickProductImage(
                                                formContext,
                                              );
                                          if (picked == null ||
                                              !formContext.mounted)
                                            return;
                                          setDialogState(
                                            () => pendingImages.add((
                                              bytes: picked.bytes,
                                              name: picked.name,
                                            )),
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        field(
                          nameArCtrl,
                          text(
                            'Product name (Arabic)',
                            '\u0627\u0633\u0645 \u0627\u0644\u0645\u0646\u062a\u062c \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
                          ),
                          direction: TextDirection.rtl,
                          icon: Icons.translate_rounded,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? requiredMessage
                              : null,
                          action: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        field(
                          nameEnCtrl,
                          text(
                            'Product name (English)',
                            '\u0627\u0633\u0645 \u0627\u0644\u0645\u0646\u062a\u062c \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
                          ),
                          direction: TextDirection.ltr,
                          icon: Icons.translate_rounded,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? requiredMessage
                              : null,
                          action: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        field(
                          descriptionArCtrl,
                          text(
                            'Description (Arabic)',
                            '\u0627\u0644\u0648\u0635\u0641 \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
                          ),
                          direction: TextDirection.rtl,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        field(
                          descriptionEnCtrl,
                          text(
                            'Description (English)',
                            '\u0627\u0644\u0648\u0635\u0641 \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
                          ),
                          direction: TextDirection.ltr,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: validCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: text(
                              'Category',
                              '\u0627\u0644\u062a\u0635\u0646\u064a\u0641',
                            ),
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          items: categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category.id,
                                  child: Text(
                                    category.localizedName(isArabic),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setDialogState(() => selectedCategoryId = value);
                          },
                          validator: (value) =>
                              value == null ? requiredMessage : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedBusinessType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: text(
                              'Business type',
                              '\u0646\u0648\u0639 \u0627\u0644\u0646\u0634\u0627\u0637',
                            ),
                            prefixIcon: const Icon(Icons.storefront_outlined),
                          ),
                          items: [
                            if (!availableBusinessTypes.contains(
                              selectedBusinessType,
                            ))
                              DropdownMenuItem(
                                value: selectedBusinessType,
                                child: Text(selectedBusinessType),
                              ),
                            ...BusinessType.values.map(
                              (type) => DropdownMenuItem(
                                value: type.name,
                                child: Text(
                                  isArabic ? type.titleAr : type.titleEn,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null)
                              setDialogState(
                                () => selectedBusinessType = value,
                              );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: field(
                                priceCtrl,
                                text('Price', '\u0627\u0644\u0633\u0639\u0631'),
                                icon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  final price = double.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  return price == null || price <= 0
                                      ? invalidPriceMessage
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: field(
                                oldPriceCtrl,
                                text(
                                  'Original price',
                                  '\u0627\u0644\u0633\u0639\u0631 \u0642\u0628\u0644 \u0627\u0644\u062e\u0635\u0645',
                                ),
                                icon: Icons.sell_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  final oldPrice = value?.trim() ?? '';
                                  if (oldPrice.isEmpty) return null;
                                  final parsed = double.tryParse(oldPrice);
                                  final price = double.tryParse(
                                    priceCtrl.text.trim(),
                                  );
                                  return parsed == null ||
                                          price == null ||
                                          parsed <= price
                                      ? text(
                                          'Must be greater than the sale price',
                                          '\u064a\u062c\u0628 \u0623\u0646 \u064a\u0643\u0648\u0646 \u0623\u0643\u0628\u0631 \u0645\u0646 \u0633\u0639\u0631 \u0627\u0644\u0628\u064a\u0639',
                                        )
                                      : null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: field(
                                stockCtrl,
                                text(
                                  'Stock quantity',
                                  '\u0643\u0645\u064a\u0629 \u0627\u0644\u0645\u062e\u0632\u0648\u0646',
                                ),
                                icon: Icons.inventory_2_outlined,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final stock = int.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  return stock == null || stock < 0
                                      ? invalidStockMessage
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: field(
                                unitArCtrl,
                                text(
                                  'Unit (Arabic)',
                                  '\u0648\u062d\u062f\u0629 \u0627\u0644\u0642\u064a\u0627\u0633 \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
                                ),
                                direction: TextDirection.rtl,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        field(
                          unitEnCtrl,
                          text(
                            'Unit (English)',
                            '\u0648\u062d\u062f\u0629 \u0627\u0644\u0642\u064a\u0627\u0633 \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
                          ),
                          direction: TextDirection.ltr,
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            text(
                              'Available for purchase',
                              '\u0645\u062a\u0627\u062d \u0644\u0644\u0634\u0631\u0627\u0621',
                            ),
                          ),
                          value: isInStock,
                          onChanged: (value) =>
                              setDialogState(() => isInStock = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            text(
                              'Featured product',
                              '\u0645\u0646\u062a\u062c \u0645\u0645\u064a\u0632',
                            ),
                          ),
                          value: isFeatured,
                          onChanged: (value) =>
                              setDialogState(() => isFeatured = value),
                        ),
                        const SizedBox(height: 8),
                        field(
                          specsArCtrl,
                          text(
                            'Specifications (Arabic)',
                            '\u0627\u0644\u0645\u0648\u0627\u0635\u0641\u0627\u062a \u0628\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
                          ),
                          direction: TextDirection.rtl,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text(
                            'Enter one item per line as name: value.',
                            '\u0623\u062f\u062e\u0644 \u0643\u0644 \u0645\u0648\u0627\u0635\u0641\u0629 \u0641\u064a \u0633\u0637\u0631 \u0628\u0635\u064a\u063a\u0629 \u0627\u0644\u0627\u0633\u0645: \u0627\u0644\u0642\u064a\u0645\u0629.',
                          ),
                          style: Theme.of(formContext).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        field(
                          specsEnCtrl,
                          text(
                            'Specifications (English)',
                            '\u0627\u0644\u0645\u0648\u0627\u0635\u0641\u0627\u062a \u0628\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
                          ),
                          direction: TextDirection.ltr,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: Text(loc.translate('cancel')),
              ),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false))
                          return;
                        setDialogState(() => isSaving = true);
                        final price = double.parse(priceCtrl.text.trim());
                        final oldPriceText = oldPriceCtrl.text.trim();
                        final updated = product.copyWith(
                          nameAr: nameArCtrl.text.trim(),
                          nameEn: nameEnCtrl.text.trim(),
                          descriptionAr: descriptionArCtrl.text.trim(),
                          descriptionEn: descriptionEnCtrl.text.trim(),
                          price: price,
                          oldPrice: double.tryParse(oldPriceText),
                          clearOldPrice: oldPriceText.isEmpty,
                          categoryId: selectedCategoryId,
                          businessType: selectedBusinessType,
                          images: List<String>.unmodifiable(keptImages),
                          inStock: isInStock,
                          stockCount: int.parse(stockCtrl.text.trim()),
                          unitAr: unitArCtrl.text.trim(),
                          unitEn: unitEnCtrl.text.trim(),
                          specificationsAr: parseSpecifications(
                            specsArCtrl.text,
                          ),
                          specificationsEn: parseSpecifications(
                            specsEnCtrl.text,
                          ),
                          isFeatured: isFeatured,
                        );
                        final success = await productsVM
                            .updateProductInSupabase(
                              updated,
                              newImages: List.unmodifiable(pendingImages),
                            );
                        if (!mounted || !formContext.mounted) return;
                        setDialogState(() => isSaving = false);
                        if (success) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                text(
                                  'Product updated successfully.',
                                  '\u062a\u0645 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0645\u0646\u062a\u062c \u0628\u0646\u062c\u0627\u062d.',
                                ),
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                productsVM.errorMessage ??
                                    text(
                                      'Could not update product.',
                                      '\u062a\u0639\u0630\u0631 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0645\u0646\u062a\u062c.',
                                    ),
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  isSaving
                      ? text(
                          'Saving...',
                          '\u062c\u0627\u0631\u064a \u0627\u0644\u062d\u0641\u0638...',
                        )
                      : loc.translate('save_changes'),
                ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameArCtrl.dispose();
        nameEnCtrl.dispose();
        descriptionArCtrl.dispose();
        descriptionEnCtrl.dispose();
        priceCtrl.dispose();
        oldPriceCtrl.dispose();
        stockCtrl.dispose();
        unitArCtrl.dispose();
        unitEnCtrl.dispose();
        specsArCtrl.dispose();
        specsEnCtrl.dispose();
      });
    });
  }

  // DIALOG: CONFIRM DELETE PRODUCT
  // ==========================================
  void _showDeleteConfirmDialog(BuildContext context, ProductModel product) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(loc.isArabic ? 'تأكيد الحذف' : 'Confirm Delete'),
          content: Text(
            loc.isArabic
                ? 'هل أنت متأكد من رغبتك في حذف المنتج "${product.nameAr}" نهائياً من قاعدة بيانات tempMarket؟'
                : 'Are you sure you want to permanently delete "${product.nameEn}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(loc.translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final productsVM = Provider.of<ProductsViewModel>(
                  context,
                  listen: false,
                );
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(dialogCtx).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      loc.isArabic
                          ? '\u062c\u0627\u0631\u064a \u062d\u0630\u0641 \u0627\u0644\u0645\u0646\u062a\u062c...'
                          : 'Deleting product...',
                    ),
                    duration: const Duration(seconds: 30),
                  ),
                );
                final success = await productsVM.deleteProductFromSupabase(
                  product.id,
                );
                if (!mounted) return;
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (loc.isArabic
                                ? '\u062a\u0645 \u062d\u0630\u0641 \u0627\u0644\u0645\u0646\u062a\u062c \u0628\u0646\u062c\u0627\u062d.'
                                : 'Product deleted successfully.')
                          : (loc.isArabic
                                ? '\u062a\u0639\u0630\u0631 \u062d\u0630\u0641 \u0627\u0644\u0645\u0646\u062a\u062c: ${productsVM.errorMessage ?? ''}'
                                : productsVM.errorMessage ??
                                      'Could not delete product.'),
                    ),
                    backgroundColor: success
                        ? const Color(0xFF10B981)
                        : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(loc.isArabic ? 'حذف نهائي' : 'Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Widget _reviewMetric(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(130),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String growth,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    growth,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
