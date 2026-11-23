import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../data/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isReady = false;
  bool _isApprovedCourier = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  bool get isApprovedCourier => _isApprovedCourier;
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    _initAuth();
  }

  void _initAuth() {
    final supabase = SupabaseService();
    if (supabase.isInitialized) {
      final user = supabase.client.auth.currentUser;
      if (user != null) {
        _mapSupabaseUser(user);
      }
      _isReady = true;
      notifyListeners();
      // Listen to Supabase auth state changes
      supabase.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          _mapSupabaseUser(session.user);
        } else {
          _currentUser = null;
          _isApprovedCourier = false;
          notifyListeners();
        }
      });
    } else {
      _currentUser = null;
      _isReady = true;
      notifyListeners();
    }
  }

  void _mapSupabaseUser(User user) {
    final metadata = user.userMetadata ?? {};
    _currentUser = UserModel(
      id: user.id,
      name: metadata['name']?.toString() ?? user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      phone: metadata['phone']?.toString() ?? user.phone ?? '',
      avatarUrl: metadata['avatar_url']?.toString() ?? '',
      address: metadata['address']?.toString() ?? 'ط§ظ„ظ…ظ…ظ„ظƒط© ط§ظ„ط¹ط±ط¨ظٹط© ط§ظ„ط³ط¹ظˆط¯ظٹط©',
      role: metadata['role'] == 'admin' ? UserRole.admin : UserRole.customer,
    );
    notifyListeners();
    _loadCourierApproval();
  }

  Future<void> _loadCourierApproval() async {
    final approved = await SupabaseService().isCurrentUserApprovedCourier();
    if (_isApprovedCourier != approved) {
      _isApprovedCourier = approved;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final supabase = SupabaseService();

    if (!supabase.isInitialized) {
      _errorMessage = 'الخدمة غير متاحة حالياً. حاول مرة أخرى لاحقاً';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await supabase.signIn(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        _mapSupabaseUser(response.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'ط§ظ„ط¨ط±ظٹط¯ ط§ظ„ط¥ظ„ظƒطھط±ظˆظ†ظٹ ط£ظˆ ظƒظ„ظ…ط© ط§ظ„ظ…ط±ظˆط± ط؛ظٹط± طµط­ظٹط­ط©';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'ط­ط¯ط« ط®ط·ط£ ط£ط«ظ†ط§ط، طھط³ط¬ظٹظ„ ط§ظ„ط¯ط®ظˆظ„: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final supabase = SupabaseService();

    if (!supabase.isInitialized) {
      _errorMessage = 'الخدمة غير متاحة حالياً. حاول مرة أخرى لاحقاً';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await supabase.signUp(
        email: email.trim(),
        password: password.trim(),
        name: name.trim(),
        phone: phone.trim(),
      );

      if (response.user != null) {
        final profileCreated = await supabase.createProfileForSignup(
          userId: response.user!.id,
          name: name.trim(),
          phone: phone.trim(),
        );
        if (!profileCreated) {
          _errorMessage =
              'Account created, but the profile record could not be saved.';
        }
        _mapSupabaseUser(response.user!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'طھط¹ط°ط± ط¥ظ†ط´ط§ط، ط§ظ„ط­ط³ط§ط¨طŒ ظٹط±ط¬ظ‰ ط§ظ„ظ…ط­ط§ظˆظ„ط© ظ…ط±ط© ط£ط®ط±ظ‰';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'ط®ط·ط£ ظپظٹ ط¥ظ†ط´ط§ط، ط§ظ„ط­ط³ط§ط¨: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final supabase = SupabaseService();
    if (supabase.isInitialized) {
      await supabase.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      address: address,
      avatarUrl: avatarUrl,
    );
    notifyListeners();

    final supabase = SupabaseService();
    if (supabase.isInitialized) {
      try {
        await supabase.client.auth.updateUser(
          UserAttributes(
            data: {
              if (name != null) 'name': name,
              if (phone != null) 'phone': phone,
              if (address != null) 'address': address,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
            },
          ),
        );
        if (supabase.client.auth.currentUser != null) {
          await supabase.updateUserProfile(
            userId: supabase.client.auth.currentUser!.id,
            name: name ?? _currentUser!.name,
            phone: phone ?? _currentUser!.phone,
            address: address ?? _currentUser!.address,
            avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
          );
        }
      } catch (_) {}
    }
  }
}
