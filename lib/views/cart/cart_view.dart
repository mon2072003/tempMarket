import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../../viewmodels/orders_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/address_picker_dialog.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final _couponController = TextEditingController();
  bool _isSubmitting = false;
  bool _isApplyingCoupon = false;
  String _deliveryAddress = 'الرياض - حي النخيل - شارع الأمير نايف';

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;
    final cartVM = Provider.of<CartViewModel>(context);

    if (cartVM.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('cart'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 72,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.translate('empty_cart'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  loc.isArabic
                      ? 'تصفح تشكيلة منتجاتنا المتنوعة وأضف ما يناسبك إلى السلة'
                      : 'Explore our catalog and add items you like to cart',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${loc.translate('cart')} (${cartVM.itemCount})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: loc.isArabic ? 'إفراغ السلة' : 'Clear Cart',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              cartVM.clearCart();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // List of Cart Items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartVM.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cartVM.items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 75,
                            height: 75,
                            child: Image.network(
                              item.product.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: primary.withAlpha(25),
                                child: Icon(Icons.inventory_2_outlined, color: primary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title, unit, price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.localizedName(loc.isArabic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.product.price.toStringAsFixed(0)} ${loc.translate('sar')} / ${item.product.localizedUnit(loc.isArabic)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withAlpha(140),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${item.totalPrice.toStringAsFixed(0)} ${loc.translate('sar')}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity +/- Controls
                        Column(
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => cartVM.decrementQuantity(item.product.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                                      ),
                                    ),
                                    child: const Icon(Icons.remove, size: 14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => cartVM.incrementQuantity(item.product.id),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Coupon Field
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: loc.translate('coupon_code'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isApplyingCoupon ? null : () async {
                        setState(() => _isApplyingCoupon = true);
                        final applied = await cartVM.applyCoupon(_couponController.text);
                        if (!mounted) return;
                        setState(() => _isApplyingCoupon = false);
                        if (applied) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.isArabic ? 'تم تطبيق كود الخصم بنجاح!' : 'Coupon applied!',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.isArabic ? 'رمز الخصم غير صالح أو منتهي الصلاحية.' : 'Invalid or expired promo code.',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: _isApplyingCoupon
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(loc.translate('apply_coupon')),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Order Price Breakdown Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      loc.translate('subtotal'),
                      '${cartVM.subtotal.toStringAsFixed(2)} ${loc.translate('sar')}',
                      theme,
                    ),
                    const SizedBox(height: 10),
                    if (cartVM.discountAmount > 0) ...[
                      _buildSummaryRow(
                        '${loc.translate('discount')} (${cartVM.appliedCoupon})',
                        '- ${cartVM.discountAmount.toStringAsFixed(2)} ${loc.translate('sar')}',
                        theme,
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildSummaryRow(
                      loc.translate('tax'),
                      '${cartVM.taxAmount.toStringAsFixed(2)} ${loc.translate('sar')}',
                      theme,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      loc.translate('delivery_fee'),
                      cartVM.deliveryFee == 0
                          ? loc.translate('free_delivery')
                          : '${cartVM.deliveryFee.toStringAsFixed(2)} ${loc.translate('sar')}',
                      theme,
                      color: cartVM.deliveryFee == 0 ? const Color(0xFF10B981) : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    _buildSummaryRow(
                      loc.translate('total'),
                      '${cartVM.grandTotal.toStringAsFixed(2)} ${loc.translate('sar')}',
                      theme,
                      isBold: true,
                      fontSize: 18,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),

            // Delivery Address & Google Maps Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              loc.isArabic ? 'عنوان التوصيل (خريطة جوجل / GPS)' : 'Delivery Address (Map / GPS)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final chosen = await AddressPickerDialog.show(
                              context,
                              initialAddress: _deliveryAddress,
                            );
                            if (chosen != null && chosen.isNotEmpty) {
                              setState(() => _deliveryAddress = chosen);
                            }
                          },
                          icon: const Icon(Icons.edit_location_rounded, size: 16),
                          label: Text(loc.isArabic ? 'تغيير' : 'Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.outline.withAlpha(30)),
                      ),
                      child: Text(
                        _deliveryAddress,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Checkout Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  setState(() => _isSubmitting = true);
                  final ordersVM = Provider.of<OrdersViewModel>(context, listen: false);

                  final newOrder = await ordersVM.placeOrder(
                    items: cartVM.items,
                    subtotal: cartVM.subtotal,
                    tax: cartVM.taxAmount,
                    deliveryFee: cartVM.deliveryFee,
                    discount: cartVM.discountAmount,
                    total: cartVM.grandTotal,
                    address: _deliveryAddress,
                    paymentMethod: 'دفع إلكتروني (بطاقة مدى)',
                  );

                  if (!context.mounted) return;
                  if (newOrder == null) {
                    setState(() => _isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ordersVM.errorMessage ?? 'Payment could not be completed.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  cartVM.clearCart();
                  await Provider.of<ProductsViewModel>(context, listen: false)
                      .loadProductsFromSupabase();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order completed successfully.')),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        loc.translate('checkout'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value,
    ThemeData theme, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? theme.colorScheme.onSurface.withAlpha(isBold ? 255 : 180),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: color ?? (isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}
