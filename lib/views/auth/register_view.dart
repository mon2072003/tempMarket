import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../main_navigation_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('register')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.isArabic ? 'إنشاء حساب جديد' : 'Create New Account',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  loc.isArabic
                      ? 'سجل حسابك للتمتع بتجربة تسوق سريعة وتتبع مباشر لكافة طلباتك'
                      : 'Join us for fast shopping and live order tracking',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                CustomTextField(
                  label: loc.translate('name'),
                  hint: loc.isArabic ? 'الاسم الثلاثي أو اسم المنشأة' : 'Full Name or Company',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? loc.translate('name') : null,
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  label: loc.translate('email'),
                  hint: 'name@example.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? loc.translate('email') : null,
                ),
                const SizedBox(height: 16),

                // Phone
                CustomTextField(
                  label: loc.translate('phone'),
                  hint: '+966500000000',
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? loc.translate('phone') : null,
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: loc.translate('password'),
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  isPassword: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'كلمة المرور يجب ألا تقل عن 6 خانات' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label: loc.translate('confirm_password'),
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return loc.isArabic
                          ? 'كلمة المرور غير متطابقة'
                          : 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Error message
                if (authVM.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      authVM.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Submit Button
                CustomButton(
                  text: loc.translate('register'),
                  isLoading: authVM.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final success = await authVM.register(
                        name: _nameController.text,
                        email: _emailController.text,
                        phone: _phoneController.text,
                        password: _passwordController.text,
                      );
                      if (success && context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationView(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.translate('already_have_account'),
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        loc.translate('login'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
