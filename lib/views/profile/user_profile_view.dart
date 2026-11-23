import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/orders_viewmodel.dart';
import '../../data/models/order_model.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/media_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/address_picker_dialog.dart';
import '../auth/password_update_view.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isEditing = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final ordersVM = Provider.of<OrdersViewModel>(context);
    final user = authVM.currentUser;
    final avatarUrl = user?.avatarUrl.trim() ?? '';
    final primary = theme.colorScheme.primary;
    final accountOrders = ordersVM.orders
        .where((order) => order.status != OrderStatus.cancelled)
        .toList();
    final ordersCount = accountOrders.length;
    final totalSpent = accountOrders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final rewardPoints = totalSpent.floor();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('profile'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_outlined),
            tooltip: _isEditing ? loc.translate('save_changes') : loc.translate('edit_profile'),
            onPressed: () {
              if (_isEditing) {
                authVM.updateProfile(
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  address: _addressController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      loc.isArabic ? 'تم حفظ التعديلات بنجاح!' : 'Profile updated successfully!',
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar & Header Card with ImagePicker to Supabase
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: primary.withAlpha(25),
                    child: _isUploadingAvatar
                        ? const CircularProgressIndicator()
                        : avatarUrl.isEmpty
                            ? Icon(Icons.person, size: 48, color: primary)
                            : ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.person, size: 48, color: primary),
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : Icon(Icons.person, size: 48, color: primary),
                                ),
                              ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final successText = loc.isArabic
                            ? 'تم تحديث صورة الحساب بنجاح!'
                            : 'Profile picture updated successfully!';

                        setState(() => _isUploadingAvatar = true);
                        final uploadedUrl = await MediaService.pickAndUploadUserAvatar(context);
                        if (!mounted) return;
                        setState(() => _isUploadingAvatar = false);

                        if (uploadedUrl != null) {
                          authVM.updateProfile(avatarUrl: uploadedUrl);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(successText),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? (loc.isArabic ? 'مستخدم المنصة' : 'Platform User'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                loc.isArabic ? (user?.role.titleAr ?? 'عميل') : (user?.role.titleEn ?? 'Customer'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Account Stats Strip
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      loc.isArabic ? 'الطلبات' : 'Orders',
                      '$ordersCount',
                      Icons.shopping_bag_outlined,
                      primary,
                    ),
                    Container(height: 35, width: 1, color: Colors.grey.withAlpha(50)),
                    _buildStatItem(
                      loc.isArabic ? 'المدفوعات' : 'Spent',
                      '${totalSpent.toStringAsFixed(0)} ${loc.translate("sar")}',
                      Icons.wallet_outlined,
                      const Color(0xFF10B981),
                    ),
                    Container(height: 35, width: 1, color: Colors.grey.withAlpha(50)),
                    _buildStatItem(
                      loc.isArabic ? 'نقاط الولاء' : 'Rewards',
                      '$rewardPoints',
                      Icons.stars_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Profile Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.isArabic ? 'المعلومات الشخصية' : 'Personal Information',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: loc.translate('name'),
                      hint: loc.translate('name'),
                      prefixIcon: Icons.person_outline,
                      controller: _nameController,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: loc.translate('email'),
                      hint: loc.translate('email'),
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      readOnly: true, // Email usually locked
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: loc.translate('phone'),
                      hint: loc.translate('phone'),
                      prefixIcon: Icons.phone_outlined,
                      controller: _phoneController,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: loc.translate('destination'),
                            hint: loc.translate('destination'),
                            prefixIcon: Icons.location_on_outlined,
                            controller: _addressController,
                            maxLines: 2,
                            readOnly: !_isEditing,
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: IconButton.filledTonal(
                              tooltip: loc.isArabic ? 'تحديد العنوان عبر خريطة جوجل / GPS' : 'Pick on Map / GPS',
                              icon: const Icon(Icons.my_location_rounded),
                              onPressed: () async {
                                final chosen = await AddressPickerDialog.show(
                                  context,
                                  initialAddress: _addressController.text,
                                );
                                if (chosen != null && chosen.isNotEmpty) {
                                  setState(() => _addressController.text = chosen);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 18),
                      CustomButton(
                        text: loc.translate('save_changes'),
                        onPressed: () {
                          authVM.updateProfile(
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            address: _addressController.text.trim(),
                          );
                          setState(() => _isEditing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.isArabic ? 'تم حفظ التعديلات بنجاح' : 'Saved!',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account Security & Settings Shortcuts
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_reset_rounded, color: primary),
                    ),
                    title: Text(loc.isArabic ? 'تغيير كلمة المرور' : 'Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PasswordUpdateView(),
                      ),
                    ),
                    /*onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.isArabic
                                ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك'
                                : 'Password reset link sent to email',
                          ),
                        ),
                      );
                    },*/
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.security_rounded, color: Color(0xFF10B981)),
                    ),
                    title: Text(loc.isArabic ? 'المصادقة الثنائية (2FA)' : 'Two-Factor Auth'),
                    subtitle: Text(loc.isArabic ? 'مفعل لحماية حسابك' : 'Enabled'),
                    trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          ),
        ),
      ],
    );
  }
}
