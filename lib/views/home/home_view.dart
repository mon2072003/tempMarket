import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../core/services/media_service.dart';
import 'widgets/category_chip.dart';
import 'widgets/product_card.dart';
import 'widgets/banner_slider.dart';
import '../notifications/notifications_view.dart';
import '../admin/admin_dashboard_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final productsVM = Provider.of<ProductsViewModel>(context);
    final brand = themeVM.currentBrand;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(brand.businessType.icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                loc.isArabic ? brand.brandNameAr : brand.brandNameEn,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ),
          ],
        ),
        actions: [
          // Admin Dashboard Button
          if (authVM.currentUser?.role.name == 'admin') IconButton(
            tooltip: loc.isArabic ? 'لوحة إدارة المنصة والتقارير' : 'Admin & Reports',
            icon: const Icon(Icons.dashboard_customize_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardView()),
              );
            },
          ),

          // Notifications with Unread Count Badge
          Consumer<NotificationsViewModel>(
            builder: (context, notifVM, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: loc.isArabic ? 'الإشعارات' : 'Notifications',
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsView()),
                      );
                    },
                  ),
                  if (notifVM.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${notifVM.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => productsVM.loadProductsFromSupabase(),
        child: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: productsVM.setSearchQuery,
                decoration: InputDecoration(
                  hintText: loc.translate('search_hint'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: productsVM.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => productsVM.setSearchQuery(''),
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Promotional Brand Banner
          SliverToBoxAdapter(
            child: BannerSlider(brand: brand),
          ),

          // Category Header & Horizontal Category Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.translate('categories'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${productsVM.categories.length} ${loc.translate('categories')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: productsVM.categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return CategoryChip(
                            category: null,
                            isSelected: productsVM.selectedCategoryId == null,
                            onTap: () => productsVM.selectCategory(null),
                          );
                        }
                        final category = productsVM.categories[index - 1];
                        return CategoryChip(
                          category: category,
                          isSelected: productsVM.selectedCategoryId == category.id,
                          onTap: () => productsVM.selectCategory(category.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.translate('all_products'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${productsVM.products.length} ${loc.isArabic ? "منتج" : "items"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Products Grid (Responsive for Mobile & Web)
          productsVM.isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : (productsVM.products.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(40),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_outlined,
                                    size: 48,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  productsVM.errorMessage != null
                                      ? productsVM.errorMessage!
                                      : (loc.isArabic
                                          ? 'لا توجد منتجات مسجلة في قاعدة بيانات tempMarket'
                                          : 'No products available yet'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  loc.isArabic
                                      ? 'التطبيق يعرض المنتجات حصرياً من tempMarket. يمكنك إضافة أول منتج الآن أو رفع البيانات النموذجية بضغطة زر واحدة.'
                                      : 'Products will appear here once they are available.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: false,
                                      child: ElevatedButton.icon(
                                      onPressed: () => _showAddProductDialog(context),
                                      icon: const Icon(Icons.add_rounded),
                                      label: Text(loc.isArabic ? 'إضافة منتج إلى tempMarket' : 'Add Product'),
                                    ),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final success = await productsVM.refreshProductsFromSupabase();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success
                                                    ? (loc.isArabic
                                                        ? 'تم تحديث المنتجات في tempMarket بنجاح!'
                                                        : 'Products refreshed!')
                                                    : (loc.isArabic
                                                        ? 'فشل رفع البيانات: ${productsVM.errorMessage}'
                                                        : 'Failed to refresh products'),
                                              ),
                                              backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.cloud_upload_outlined),
                                      label: Text(loc.isArabic ? 'تحديث المنتجات' : 'Refresh Products'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final crossAxisCount = width > 900
                              ? 4
                              : (width > 600 ? 3 : 2);

                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = productsVM.products[index];
                                return ProductCard(product: product);
                              },
                              childCount: productsVM.products.length,
                            ),
                          );
                        },
                      ),
                    )),

          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      ),
    ),
  );
}

  void _showAddProductDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    final themeVM = Provider.of<ThemeViewModel>(context, listen: false);

    final nameArController = TextEditingController();
    final nameEnController = TextEditingController();
    final priceController = TextEditingController();
    final imageUrlController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600',
    );
    final descController = TextEditingController();
    String selectedBusinessType = themeVM.currentBrand.businessType.name;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  loc.isArabic ? 'إضافة منتج جديد' : 'Add Product',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedBusinessType,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'نوع المتجر / النشاط' : 'Business Type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'factory', child: Text('مصنع وتوريدات (Factory)')),
                      DropdownMenuItem(value: 'mall', child: Text('مول تجاري (Mall)')),
                      DropdownMenuItem(value: 'pharmacy', child: Text('صيدلية (Pharmacy)')),
                      DropdownMenuItem(value: 'restaurant', child: Text('مطعم (Restaurant)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedBusinessType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameArController,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'اسم المنتج (عربي)' : 'Name (Arabic)',
                      hintText: 'مثال: أسمنت بورتلاندي عالي الجودة',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameEnController,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'اسم المنتج (إنجليزي)' : 'Name (English)',
                      hintText: 'e.g. Portland Cement Grade 52.5',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'السعر بالجنيه المصري' : 'Price (EGP)',
                      suffixText: loc.translate('sar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageUrlController,
                          decoration: InputDecoration(
                            labelText: loc.isArabic ? 'رابط صورة المنتج أو رفعها' : 'Image URL or Upload',
                            prefixIcon: const Icon(Icons.image_outlined, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: loc.isArabic ? 'اختيار صورة للمنتج في tempMarket' : 'Choose product image',
                        icon: const Icon(Icons.add_a_photo_rounded),
                        onPressed: () async {
                          final uploadedUrl = await MediaService.pickAndUploadProductImage(dialogCtx);
                          if (uploadedUrl != null) {
                            setDialogState(() {
                              imageUrlController.text = uploadedUrl;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: loc.isArabic ? 'الوصف' : 'Description',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final nameAr = nameArController.text.trim();
                        final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                        if (nameAr.isEmpty || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.isArabic
                                    ? 'يرجى كتابة اسم المنتج وسعره بشكل صحيح'
                                    : 'Please enter a valid product name and price',
                              ),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        final newProduct = ProductModel(
                          id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
                          nameAr: nameAr,
                          nameEn: nameEnController.text.trim().isNotEmpty
                              ? nameEnController.text.trim()
                              : nameAr,
                          descriptionAr: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : 'منتج عالي الجودة متاح الآن في tempMarket.',
                          descriptionEn: 'High quality product available now.',
                          price: price,
                          categoryId: 'cat_raw_materials',
                          businessType: selectedBusinessType,
                          images: [
                            imageUrlController.text.trim().isNotEmpty
                                ? imageUrlController.text.trim()
                                : 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600',
                          ],
                          unitAr: 'قطعة',
                          unitEn: 'Piece',
                          inStock: true,
                          stockCount: 50,
                          isFeatured: true,
                        );

                        final success = await productsVM.addProductToSupabase(newProduct);

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? (loc.isArabic
                                        ? 'تمت إضافة المنتج بنجاح!'
                                        : 'Product added successfully!')
                                    : (loc.isArabic
                                        ? 'تعذر إضافة المنتج: ${productsVM.errorMessage}'
                                        : 'Failed: ${productsVM.errorMessage}'),
                              ),
                              backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(loc.isArabic ? 'إضافة المنتج' : 'Add Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  void _showAddCategoryDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    final themeVM = Provider.of<ThemeViewModel>(context, listen: false);
    final arController = TextEditingController();
    final enController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(loc.isArabic ? 'إضافة تصنيف جديد (لوحة الإدارة)' : 'Add New Category (Admin)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: arController,
              decoration: const InputDecoration(
                labelText: 'اسم التصنيف (بالعربية)',
                hintText: 'مثال: قطع غيار، مستلزمات طبية',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: enController,
              decoration: const InputDecoration(
                labelText: 'Category Name (English)',
                hintText: 'e.g. Spare Parts, Supplies',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (arController.text.trim().isNotEmpty) {
                final newCat = CategoryModel(
                  id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                  nameAr: arController.text.trim(),
                  nameEn: enController.text.trim().isNotEmpty
                      ? enController.text.trim()
                      : arController.text.trim(),
                  icon: Icons.category_rounded,
                  businessType: themeVM.currentBrand.businessType.name,
                );
                productsVM.addAdminCategory(newCat);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc.isArabic ? 'تمت إضافة التصنيف بنجاح!' : 'Category added!'),
                  ),
                );
              }
            },
            child: Text(loc.isArabic ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}
