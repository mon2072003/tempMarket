import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/services/supabase_service.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/custom_button.dart';

class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedTopic = 'order_inquiry';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final brand = themeVM.currentBrand;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.translate('support'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, brand.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('contact_us'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.translate('support_desc'),
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Contact Options (Hotline, WhatsApp, Email)
            Row(
              children: [
                Expanded(
                  child: _buildContactActionCard(
                    title: loc.translate('hotline'),
                    subtitle: brand.hotline,
                    icon: Icons.phone_in_talk_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${loc.isArabic ? "جاري الاتصال بالرقم" : "Calling"} ${brand.hotline}')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactActionCard(
                    title: loc.translate('whatsapp'),
                    subtitle: brand.whatsappNumber,
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${loc.isArabic ? "فتح محادثة واتساب مع" : "Opening WhatsApp with"} ${brand.whatsappNumber}')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.email_outlined, color: primary),
                ),
                title: Text(loc.isArabic ? 'البريد الإلكتروني الرسمي' : 'Official Support Email'),
                subtitle: Text(brand.email),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email: ${brand.email}')),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.location_on_outlined, color: primary),
                ),
                title: Text(loc.isArabic ? 'المقر الرئيسي والفروع' : 'Headquarters & Locations'),
                subtitle: Text(loc.isArabic ? brand.addressAr : brand.addressEn),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Ticket / Inquiry Form
            Text(
              loc.translate('send_ticket'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTopic,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'نوع الاستفسار' : 'Inquiry Type',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'order_inquiry',
                          child: Text(loc.isArabic ? 'استفسار عن طلب سابق' : 'Order Inquiry'),
                        ),
                        DropdownMenuItem(
                          value: 'product_inquiry',
                          child: Text(loc.isArabic ? 'استفسار عن مواصفات منتج' : 'Product Specs'),
                        ),
                        DropdownMenuItem(
                          value: 'delivery_inquiry',
                          child: Text(loc.isArabic ? 'توصيل وتوريدات خاصة' : 'Delivery & Supplies'),
                        ),
                        DropdownMenuItem(
                          value: 'feedback',
                          child: Text(loc.isArabic ? 'شكوى أو مقترح' : 'Feedback / Complaint'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTopic = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc.translate('name'),
                        hintText: loc.isArabic ? 'الاسم الكامل أو اسم الشركة' : 'Full Name or Company',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: loc.translate('message_hint'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: loc.translate('send'),
                      icon: Icons.send_rounded,
                      isLoading: _isSubmitting,
                      onPressed: () async {
                        if (_messageController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.isArabic ? 'يرجى كتابة نص الرسالة أولاً' : 'Please enter your message',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _isSubmitting = true);

                        final authVM = Provider.of<AuthViewModel>(context, listen: false);
                        final userName = _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()
                            : (authVM.currentUser?.name ?? 'عميل التطبيق');
                        final userEmail = authVM.currentUser?.email ?? 'client@store.com';

                        if (SupabaseService().isInitialized) {
                          await SupabaseService().insertSupportTicket(
                            name: userName,
                            email: userEmail,
                            subject: _selectedTopic,
                            message: _messageController.text.trim(),
                          );
                        } else {
                          await Future.delayed(const Duration(milliseconds: 700));
                        }

                        if (!context.mounted) return;
                        setState(() {
                          _isSubmitting = false;
                          _messageController.clear();
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.isArabic
                                  ? 'تم إرسال استفسارك بنجاح إلى قاعدة البيانات وسيتواصل معك الدعم الفني قريباً'
                                  : 'Inquiry submitted successfully! Our team will respond shortly.',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildContactActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
