import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/review_model.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/localization/app_localizations.dart';

class ProductDetailsView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsView({super.key, required this.product});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsViewModel>(context, listen: false)
          .loadReviewsForProduct(widget.product.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;

    // Listen to ProductsViewModel to get real-time updated product (e.g. newly added reviews)
    final productsVM = Provider.of<ProductsViewModel>(context);
    final liveProduct = productsVM.findProductById(widget.product.id) ??
        widget.product.copyWith(rating: 0, reviewCount: 0, reviews: const []);
    final reviewCountsByStar = <int, int>{
      for (var stars = 1; stars <= 5; stars++)
        stars: liveProduct.reviews
            .where((review) => review.rating.round() == stars)
            .length,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('specifications'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.isArabic ? 'تم نسخ رابط المنتج' : 'Product link copied'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel & Gallery
            SizedBox(
              height: 320,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: liveProduct.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        liveProduct.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: primary.withAlpha(25),
                          child: Icon(Icons.inventory_2_outlined, size: 64, color: primary),
                        ),
                      );
                    },
                  ),

                  // Discount Badge
                  if (liveProduct.hasDiscount)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withAlpha(80),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${loc.translate('discount')} ${liveProduct.discountPercentage}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Image Dots Indicator
                  if (liveProduct.images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          liveProduct.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _selectedImageIndex == index ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _selectedImageIndex == index
                                  ? primary
                                  : Colors.white.withAlpha(160),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Meta Information
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inventory summary: make the quantity and availability status distinct.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: liveProduct.inStock
                          ? const Color(0xFF10B981).withAlpha(14)
                          : const Color(0xFFEF4444).withAlpha(14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (liveProduct.inStock
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444))
                            .withAlpha(90),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          color: liveProduct.inStock
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isArabic ? 'الكمية المتاحة' : 'Available quantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                liveProduct.inStock
                                    ? '${liveProduct.stockCount} ${liveProduct.localizedUnit(loc.isArabic)}'
                                    : (loc.isArabic ? '0 (نفد المخزون)' : '0 (out of stock)'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: liveProduct.inStock
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: (liveProduct.inStock
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withAlpha(24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            liveProduct.inStock
                                ? (loc.isArabic ? 'متوفر' : 'In stock')
                                : (loc.isArabic ? 'غير متوفر' : 'Unavailable'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: liveProduct.inStock
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),                  const SizedBox(height: 14),

                  // Product Title
                  Text(
                    liveProduct.localizedName(loc.isArabic),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Section
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      Text(
                        liveProduct.price.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.translate('sar'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      if (liveProduct.hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${liveProduct.oldPrice!.toStringAsFixed(0)} ${loc.translate('sar')}',
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurface.withAlpha(100),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    loc.translate('description'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    liveProduct.localizedDesc(loc.isArabic),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withAlpha(190),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Specifications Table
                  if (liveProduct.localizedSpecs(loc.isArabic).isNotEmpty) ...[
                    Text(
                      loc.translate('specifications'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        children: liveProduct.localizedSpecs(loc.isArabic).entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: theme.colorScheme.outlineVariant.withAlpha(40),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.translate('quantity'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withAlpha(80),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Customer Reviews & User Comments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                        loc.isArabic ? 'تقييمات وآراء العملاء' : 'Customer Reviews & Ratings',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddReviewDialog(context, liveProduct),
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        label: Text(
                          loc.isArabic ? 'أضف تقييمك' : 'Write Review',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating Score Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.isArabic ? 'متوسط التقييم' : 'Average rating',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              liveProduct.reviewCount == 0
                                  ? '—'
                                  : liveProduct.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: primary,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < liveProduct.rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 18,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.isArabic
                                  ? 'عدد التقييمات: ${liveProduct.reviewCount}'
                                  : 'Review count: ${liveProduct.reviewCount}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              for (final stars in [5, 4, 3, 2, 1])
                                _buildRatingBar(
                                  stars,
                                  reviewCountsByStar[stars] ?? 0,
                                  liveProduct.reviewCount,
                                  theme,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // List of Reviews / User Comments
                  if (liveProduct.reviews.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          loc.isArabic ? 'كن أول من يكتب تقييماً لهذا المنتج!' : 'Be the first to review this product!',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withAlpha(130),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: liveProduct.reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final rev = liveProduct.reviews[idx];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage(rev.userAvatar),
                                      backgroundColor: primary.withAlpha(20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                rev.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (rev.isVerifiedPurchase) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withAlpha(25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.check, size: 10, color: Color(0xFF10B981)),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        loc.isArabic ? 'شراء مؤكد' : 'Verified',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          color: Color(0xFF10B981),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                i < rev.rating.round()
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                size: 14,
                                                color: const Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${rev.date.month}/${rev.date.day}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface.withAlpha(110),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  rev.comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: theme.colorScheme.onSurface.withAlpha(190),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 100), // Bottom padding for sticky button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('total'),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                  Text(
                    '${(liveProduct.price * _quantity).toStringAsFixed(0)} ${loc.translate('sar')}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Consumer<CartViewModel>(
                  builder: (context, cartVM, child) {
                    return ElevatedButton.icon(
                      onPressed: () {
                        cartVM.addToCart(liveProduct, quantity: _quantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.isArabic ? 'تمت الإضافة إلى سلة المشتريات!' : 'Added to cart!',
                            ),
                            action: SnackBarAction(
                              label: loc.translate('cart'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: Text(loc.translate('add_to_cart')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars ★', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 6,
                backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 24,
            child: Text('$count', textAlign: TextAlign.end, style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, ProductModel product) {
    final loc = AppLocalizations.of(context);
    final productsVM = Provider.of<ProductsViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final user = authVM.currentUser;

    double selectedStars = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(loc.isArabic ? 'تقييم المنتج وكتابة تعليق' : 'Rate & Review Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.localizedName(loc.isArabic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Interactive Star Rating Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        icon: Icon(
                          starValue <= selectedStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 32,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedStars = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  Text(
                    '$selectedStars / 5.0',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Review Comment Field
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: loc.isArabic
                          ? 'شاركنا برأيك وتجربتك حول جودة هذا المنتج ومواصفاته بالتفصيل...'
                          : 'Write your thoughts and feedback on this product...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(loc.isArabic ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (commentController.text.trim().isNotEmpty) {
                    final newReview = ReviewModel(
                      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                      userName: user?.name ?? (loc.isArabic ? 'عميل المنصة' : 'Verified Buyer'),
                      userAvatar: user?.avatarUrl ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                      rating: selectedStars,
                      date: DateTime.now(),
                      comment: commentController.text.trim(),
                      isVerifiedPurchase: true,
                    );

                    final saved = await productsVM.addReviewToProduct(product.id, newReview);
                    if (!context.mounted) return;
                    if (!saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.isArabic ? 'تعذر حفظ التقييم. حاول مرة أخرى.' : 'Could not save your review. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          loc.isArabic
                              ? 'شكراً لك! تمت إضافة تقييمك وتعليقك بنجاح'
                              : 'Thank you! Your review was posted successfully',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: Text(loc.isArabic ? 'نشر التقييم' : 'Submit Review'),
              ),
            ],
          );
        },
      ),
    );
  }
}
