import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../core/services/supabase_service.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../main_navigation_view.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final brand = themeVM.currentBrand;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Icon & Badge
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, brand.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withAlpha(80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        brand.businessType.icon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Brand Title
                  Text(
                    loc.isArabic ? brand.brandNameAr : brand.brandNameEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.isArabic ? brand.sloganAr : brand.sloganEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Title
                  Text(
                    loc.translate('login'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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

                  // Password
                  CustomTextField(
                    label: loc.translate('password'),
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    isPassword: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? loc.translate('password') : null,
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: loc.isArabic ? Alignment.centerLeft : Alignment.centerRight,
                    child: TextButton(
                      onPressed: _sendPasswordReset,
                      child: Text(
                        loc.translate('forgot_password'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message if any
                  if (authVM.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        authVM.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Login Button
                  CustomButton(
                    text: loc.translate('login'),
                    isLoading: authVM.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final success = await authVM.login(_emailController.text, _passwordController.text);
                        if (success && context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationView()));
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Continue as Guest Button
                  CustomButton(
                    text: loc.isArabic ? 'تسجيل الدخول كضيف' : 'Continue as Guest',
                    isOutlined: true,
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationView())),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(loc.translate('dont_have_account'), style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withAlpha(160))),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView())),
                        child: Text(loc.translate('register'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    final loc = AppLocalizations.of(context);
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.isArabic ? 'أدخل بريدك الإلكتروني أولاً' : 'Enter your email address first.')));
      return;
    }
    try {
      await SupabaseService().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.isArabic ? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك' : 'Password reset link sent to your email.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }
}
/*
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.isArabic
                                  ? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك'
                                  : 'Password reset link sent to your email',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        loc.translate('forgot_password'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message if any
                  if (authVM.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        authVM.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Login Button
                  CustomButton(
                    text: loc.translate('login'),
                    isLoading: authVM.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        final success = await authVM.login(
                          _emailController.text,
                          _passwordController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationView(),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Continue as Guest Button
                  CustomButton(
                    text: loc.isArabic ? 'الدخول كزائر واستكشاف المنتجات' : 'Continue as Guest',
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationView(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.translate('dont_have_account'),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withAlpha(160),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterView(),
                            ),
                          );
                        },
                        child: Text(
                          loc.translate('register'),
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
      ),
    );
  }
}
*/
