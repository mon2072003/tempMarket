import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/supabase_service.dart';

// ViewModels
import 'viewmodels/theme_viewmodel.dart';
import 'viewmodels/localization_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/products_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/orders_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';

// Views
import 'views/auth/login_view.dart';
import 'views/main_navigation_view.dart';
import 'views/auth/password_update_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService().initialize();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeViewModel(
            initialThemeMode: preferences.getBool('local_dark_mode') == true
                ? ThemeMode.dark
                : ThemeMode.light,
            savedPrimaryColor: preferences.getInt('local_theme_primary'),
            savedSecondaryColor: preferences.getInt('local_theme_secondary'),
            savedAccentColor: preferences.getInt('local_theme_accent'),
          )..loadBrandSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocalizationViewModel(
            initialLocale: Locale(
              preferences.getString('local_language_code') ?? 'ar',
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProductsViewModel()),
        ChangeNotifierProvider(create: (_) => CartViewModel()),
        ChangeNotifierProvider(create: (_) => OrdersViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
      ],
      child: const MultiStoreCommerceApp(),
    ),
  );
}

class MultiStoreCommerceApp extends StatelessWidget {
  const MultiStoreCommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVM = Provider.of<ThemeViewModel>(context);
    final locVM = Provider.of<LocalizationViewModel>(context);

    return MaterialApp(
      title: themeVM.currentBrand.brandNameEn.isEmpty
          ? 'tempMarket'
          : themeVM.currentBrand.brandNameEn,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(themeVM.currentBrand),
      darkTheme: AppTheme.getDarkTheme(themeVM.currentBrand),
      themeMode: themeVM.themeMode,
      locale: locVM.currentLocale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    final service = SupabaseService();
    if (service.isInitialized) {
      _authSubscription = service.client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.passwordRecovery && mounted) {
          setState(() => _isPasswordRecovery = true);
        }
      });
    } else {
      _authSubscription = const Stream<AuthState>.empty().listen((_) {});
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPasswordRecovery) {
      return PasswordUpdateView(
        onCompleted: () => setState(() => _isPasswordRecovery = false),
      );
    }
    final authVM = Provider.of<AuthViewModel>(context);
    if (!authVM.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return authVM.isAuthenticated
        ? const MainNavigationView()
        : const LoginView();
  }
}
