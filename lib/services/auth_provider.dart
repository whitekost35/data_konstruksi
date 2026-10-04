import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  String? _role;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? get role => _role;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAdmin => _role?.toLowerCase() == 'admin';
  bool get isOwner => _role?.toLowerCase() == 'owner';

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');
    if (savedRole != null) {
      _role = savedRole;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String pin) async {
    _isLoading = true;
    notifyListeners();

    try {
      final role = await _service.verifyPin(pin);
      if (role != null) {
        _role = role;
        _isAuthenticated = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', role);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _role = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    notifyListeners();
  }
}
