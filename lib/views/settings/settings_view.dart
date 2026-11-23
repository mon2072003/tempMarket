import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/localization_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/config/brand_config.dart';
import '../auth/login_view.dart' show LoginView;
import '../profile/user_profile_view.dart';
import '../admin/admin_dashboard_view.dart';
import '../notifications/notifications_view.dart';
import '../courier/courier_application_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final locVM = Provider.of<LocalizationViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final primary = theme.colorScheme.primary;
    final user = authVM.currentUser;
    final avatarUrl = user?.avatarUrl.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card (Clickable to open UserProfileView)
            Card(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProfileView()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primary.withAlpha(25),
                        child: avatarUrl.isEmpty
                            ? Icon(Icons.person, size: 30, color: primary)
                            : ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.person, size: 30, color: primary),
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                          ? child
                                          : Icon(Icons.person, size: 30, color: primary),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? (loc.isArabic ? 'زائر غير مسجل' : 'Guest User'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'user@example.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withAlpha(140),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.isArabic ? 'عرض وتعديل الملف الشخصي' : 'View & Edit Profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Platform Management & Services
            Text(
              loc.isArabic ? 'إدارة المنصة والخدمات' : 'Management & Services',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  if (user?.role.name == 'admin') ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.dashboard_customize_rounded, color: Color(0xFF10B981)),
                    ),
                    title: Text(loc.isArabic ? 'لوحة إدارة المنصة والتقارير' : 'Admin Dashboard & Reports'),
                    subtitle: Text(loc.isArabic ? 'بيانات المستخدمين، تقارير المبيعات، ومراقبة السحابة' : 'User directory, sales analytics, cloud stats'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardView()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ],
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B)),
                    ),
                    title: Text(loc.isArabic ? 'مركز الإشعارات والتنبيهات' : 'Notifications Center'),
                    subtitle: Text(loc.isArabic ? 'تحديثات الشحن والطلبات والعروض' : 'Shipment updates & promos'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsView()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF3B82F6)),
                    ),
                    title: Text(loc.isArabic ? 'التقديم كمندوب توصيل' : 'Apply as Courier'),
                    subtitle: Text(
                      loc.isArabic ? 'انضم إلى فريق التوصيل وابدأ استقبال الطلبات' : 'Join the delivery team and receive delivery requests',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CourierApplicationView()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Flexible color customization
            Text(
              loc.isArabic ? 'تخصيص ألوان tempMarket' : 'Customize tempMarket Colors',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              loc.isArabic
                  ? 'اختر أي نشاط لتشاهد تغير ثيم وهوية التطبيق بالكامل تلقائياً'
                  : 'Choose your own primary, secondary, and accent colors',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withAlpha(130),
              ),
            ),
            const SizedBox(height: 12),

            if (BrandConfig.availableThemes.isNotEmpty) Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: BrandConfig.availableThemes.map((brand) {
                    final isCurrent = themeVM.currentBrand.brandId == brand.brandId;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: brand.primaryColor.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(brand.businessType.icon, color: brand.primaryColor, size: 20),
                      ),
                      title: Text(
                        loc.isArabic ? brand.brandNameAr : brand.brandNameEn,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        loc.isArabic ? brand.businessType.titleAr : brand.businessType.titleEn,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle_rounded, color: brand.primaryColor)
                          : const SizedBox.shrink(),
                      onTap: () {
                        themeVM.switchBrand(brand);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.isArabic
                                  ? 'تم تطبيق هوية: ${brand.brandNameAr}'
                                  : 'Applied theme: ${brand.brandNameEn}',
                            ),
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: Icon(Icons.palette_outlined, color: primary),
                title: Text(loc.isArabic ? 'اختيار ألوان مخصصة' : 'Choose Custom Colors'),
                subtitle: Text(loc.isArabic ? 'تعديل اللون الأساسي والثانوي ولون التمييز' : 'Set primary, secondary, and accent colors'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _showColorEditor(context, themeVM, loc),
              ),
            ),
            const SizedBox(height: 20),

            // tempMarket preferences (Dark Mode, Language)
            Text(
              loc.isArabic ? 'تفضيلات التطبيق' : 'Preferences',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  // Dark Mode Switch
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeVM.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: primary,
                      ),
                    ),
                    title: Text(loc.translate('dark_mode')),
                    subtitle: Text(
                      themeVM.isDarkMode
                          ? (loc.isArabic ? 'مفعل' : 'Enabled')
                          : (loc.isArabic ? 'غير مفعل' : 'Disabled'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: themeVM.isDarkMode,
                    onChanged: (val) => themeVM.toggleTheme(val),
                  ),
                  const Divider(height: 1),

                  // Language Switch
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.language_rounded, color: primary),
                    ),
                    title: Text(loc.translate('language')),
                    subtitle: Text(
                      locVM.isArabic ? 'العربية (Arabic)' : 'English (الإنجليزية)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => locVM.toggleLanguage(),
                      child: Text(locVM.isArabic ? 'English' : 'عربي'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                ),
                title: Text(
                  loc.translate('logout'),
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  authVM.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorEditor(
    BuildContext context,
    ThemeViewModel themeVM,
    AppLocalizations loc,
  ) async {
    String hex(Color color) => color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    Color? parse(String value) {
      final clean = value.trim().replaceFirst('#', '');
      if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(clean)) return null;
      return Color(int.parse('FF$clean', radix: 16));
    }

    final primaryCtrl = TextEditingController(text: hex(themeVM.currentBrand.primaryColor));
    final secondaryCtrl = TextEditingController(text: hex(themeVM.currentBrand.secondaryColor));
    final accentCtrl = TextEditingController(text: hex(themeVM.currentBrand.accentColor));
    final palettes = <String, List<Color>>{
      'Nile': [const Color(0xFF006C8F), const Color(0xFFF2A900), const Color(0xFF00A6A6)],
      'Desert': [const Color(0xFF9B2C2C), const Color(0xFFD69E2E), const Color(0xFFED8936)],
      'Sahara': [const Color(0xFF5B4636), const Color(0xFFC68B59), const Color(0xFFE7C9A9)],
      'Fresh': [const Color(0xFF166534), const Color(0xFF65A30D), const Color(0xFF22C55E)],
      'Modern': [const Color(0xFF4F46E5), const Color(0xFF7C3AED), const Color(0xFFEC4899)],
    };

    final applied = await showDialog<List<Color>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(loc.isArabic ? 'تخصيص ألوان tempMarket' : 'Customize tempMarket Colors'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  loc.isArabic ? 'لوحات ألوان جاهزة' : 'Ready-made palettes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: palettes.entries.map((entry) {
                  return InkWell(
                    onTap: () {
                      setDialogState(() {
                        primaryCtrl.text = hex(entry.value[0]);
                        secondaryCtrl.text = hex(entry.value[1]);
                        accentCtrl.text = hex(entry.value[2]);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 52,
                      height: 36,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeVM.currentBrand.primaryColor.withAlpha(80)),
                      ),
                      child: Row(
                        children: entry.value
                            .map((color) => Expanded(
                                  child: Container(
                                    color: color,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      parse(primaryCtrl.text) ?? themeVM.currentBrand.primaryColor,
                      parse(secondaryCtrl.text) ?? themeVM.currentBrand.secondaryColor,
                    ],
                  ),
                ),
                child: Text(
                  loc.isArabic ? 'معاينة الألوان' : 'Color preview',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: primaryCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Primary (#RRGGBB)'),
              ),
              TextField(
                controller: secondaryCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Secondary (#RRGGBB)'),
              ),
              TextField(
                controller: accentCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Accent (#RRGGBB)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setDialogState(() {
                primaryCtrl.text = '1E3A8A';
                secondaryCtrl.text = 'D97706';
                accentCtrl.text = '2563EB';
              });
            },
            child: Text(loc.isArabic ? 'إعادة الافتراضي' : 'Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final colors = [
                parse(primaryCtrl.text),
                parse(secondaryCtrl.text),
                parse(accentCtrl.text),
              ];
              if (colors.any((color) => color == null)) return;
              Navigator.pop(dialogContext, [colors[0]!, colors[1]!, colors[2]!]);
            },
            child: Text(loc.isArabic ? 'تطبيق' : 'Apply'),
          ),
        ],
        ),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      primaryCtrl.dispose();
      secondaryCtrl.dispose();
      accentCtrl.dispose();
    });

    if (applied != null && context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
      themeVM.updateCustomColors(
        primaryColor: applied[0],
        secondaryColor: applied[1],
        accentColor: applied[2],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.isArabic ? 'تم تطبيق الألوان المخصصة.' : 'Custom colors applied.')),
      );
      });
    }
  }
}
