import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/brand_config.dart';
import '../core/services/supabase_service.dart';

class ThemeViewModel extends ChangeNotifier {
  static const _darkModeKey = 'local_dark_mode';
  static const _primaryColorKey = 'local_theme_primary';
  static const _secondaryColorKey = 'local_theme_secondary';
  static const _accentColorKey = 'local_theme_accent';

  ThemeViewModel({
    ThemeMode initialThemeMode = ThemeMode.light,
    int? savedPrimaryColor,
    int? savedSecondaryColor,
    int? savedAccentColor,
  }) : _themeMode = initialThemeMode,
       _savedPrimaryColor = savedPrimaryColor,
       _savedSecondaryColor = savedSecondaryColor,
       _savedAccentColor = savedAccentColor;

  ThemeMode _themeMode;
  BrandConfig _currentBrand = BrandConfig.defaultBrand;
  final int? _savedPrimaryColor;
  final int? _savedSecondaryColor;
  final int? _savedAccentColor;
  String? _brandSettingsError;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  BrandConfig get currentBrand => _currentBrand;
  String? get brandSettingsError => _brandSettingsError;

  Future<void> loadBrandSettings() async {
    try {
      final brand = await SupabaseService().getBrandSettings();
      _currentBrand = (brand ?? _currentBrand).copyWith(
        primaryColor: _savedPrimaryColor == null
            ? (brand ?? _currentBrand).primaryColor
            : Color(_savedPrimaryColor),
        secondaryColor: _savedSecondaryColor == null
            ? (brand ?? _currentBrand).secondaryColor
            : Color(_savedSecondaryColor),
        accentColor: _savedAccentColor == null
            ? (brand ?? _currentBrand).accentColor
            : Color(_savedAccentColor),
      );
      _brandSettingsError = null;
    } catch (error) {
      _brandSettingsError = error.toString();
      _currentBrand = _currentBrand.copyWith(
        primaryColor: _savedPrimaryColor == null
            ? _currentBrand.primaryColor
            : Color(_savedPrimaryColor),
        secondaryColor: _savedSecondaryColor == null
            ? _currentBrand.secondaryColor
            : Color(_savedSecondaryColor),
        accentColor: _savedAccentColor == null
            ? _currentBrand.accentColor
            : Color(_savedAccentColor),
      );
    }
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    unawaited(_saveDarkMode(isDark));
    notifyListeners();
  }

  void switchBrand(BrandConfig newBrand) {
    _currentBrand = newBrand;
    unawaited(_saveThemeColors(newBrand));
    notifyListeners();
  }

  void updateCustomColors({
    required Color primaryColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
    _currentBrand = _currentBrand.copyWith(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      accentColor: accentColor,
    );
    unawaited(_saveThemeColors(_currentBrand));
    notifyListeners();
  }

  Future<void> _saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDark);
  }

  Future<void> _saveThemeColors(BrandConfig brand) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, brand.primaryColor.toARGB32());
    await prefs.setInt(_secondaryColorKey, brand.secondaryColor.toARGB32());
    await prefs.setInt(_accentColorKey, brand.accentColor.toARGB32());
  }

  Future<bool> updateCustomBrand({
    String? brandNameAr,
    String? brandNameEn,
    String? sloganAr,
    String? sloganEn,
    BusinessType? businessType,
    String? hotline,
    String? whatsappNumber,
    String? email,
    String? addressAr,
    String? addressEn,
    Color? primaryColor,
  }) async {
    final updatedBrand = _currentBrand.copyWith(
      brandNameAr: brandNameAr,
      brandNameEn: brandNameEn,
      sloganAr: sloganAr,
      sloganEn: sloganEn,
      businessType: businessType,
      hotline: hotline,
      whatsappNumber: whatsappNumber,
      email: email,
      addressAr: addressAr,
      addressEn: addressEn,
      primaryColor: primaryColor,
    );
    try {
      await SupabaseService().saveBrandSettings(updatedBrand);
      _currentBrand = updatedBrand;
      unawaited(_saveThemeColors(updatedBrand));
      _brandSettingsError = null;
      notifyListeners();
      return true;
    } catch (error) {
      _brandSettingsError = error.toString();
      notifyListeners();
      return false;
    }
  }
}
