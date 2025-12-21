import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';

class AuthProvider with ChangeNotifier {
  static const _kSavedUsername = 'auth.saved_username';
  static const _kSavedPassword = 'auth.saved_password';

  final CookieRequest _request;
  late final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._request) {
    _authService = AuthService(_request);
  }

  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedUsername, username);
    await prefs.setString(_kSavedPassword, password);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedUsername);
    await prefs.remove(_kSavedPassword);
  }

  Future<Map<String, String>?> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_kSavedUsername);
    final password = prefs.getString(_kSavedPassword);
    if (username == null || username.isEmpty) return null;
    if (password == null || password.isEmpty) return null;
    return {'username': username, 'password': password};
  }

  /// Attempt auto-login using saved credentials.
  /// Returns true if login succeeds, false otherwise.
  Future<bool> tryAutoLogin() async {
    if (!ConnectivityService().isConnected) {
      return false;
    }
    final creds = await _loadCredentials();
    if (creds == null) return false;
    return login(creds['username']!, creds['password']!, persist: false);
  }
  CookieRequest get request => _request;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _request.loggedIn && _user != null;
  bool get isCoach => _user?.isCoach ?? false;
  bool get isCustomer => _user?.isCustomer ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String username, String password, {bool persist = true}) async {
    if (!ConnectivityService().isConnected) {
      _setError('Tidak ada koneksi internet');
      return false;
    }
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.login(
        username: username,
        password: password,
      );

      if (result['success'] == true) {
        _user = result['user'] as UserModel;
        if (persist) {
          await _saveCredentials(username, password);
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('ClientException')) {
        _setError('Tidak ada koneksi internet');
      } else {
        _setError('Terjadi kesalahan: $msg');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerCustomer({
    required String username,
    required String email,
    required String password1,
    required String password2,
    String? firstName,
    String? lastName,
  }) async {
    if (!ConnectivityService().isConnected) {
      _setError('Tidak ada koneksi internet');
      return false;
    }
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.registerCustomer(
        username: username,
        email: email,
        password1: password1,
        password2: password2,
        firstName: firstName,
        lastName: lastName,
      );

      if (result['success'] == true) {
        final loginSuccess = await login(username, password1);
        _setLoading(false);
        return loginSuccess;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('ClientException')) {
        _setError('Tidak ada koneksi internet');
      } else {
        _setError('Terjadi kesalahan: $msg');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerCoach({
    required String username,
    required String email,
    required String password1,
    required String password2,
    String? firstName,
    String? lastName,
    required int age,
    required String citizenship,
    required String club,
    required String license,
    required String prefferedFormation,
    required double averageTermAsCoach,
    required int ratePerSession,
    String? description,
  }) async {
    if (!ConnectivityService().isConnected) {
      _setError('Tidak ada koneksi internet');
      return false;
    }
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.registerCoach(
        username: username,
        email: email,
        password1: password1,
        password2: password2,
        firstName: firstName,
        lastName: lastName,
        age: age,
        citizenship: citizenship,
        club: club,
        license: license,
        prefferedFormation: prefferedFormation,
        averageTermAsCoach: averageTermAsCoach,
        ratePerSession: ratePerSession,
        description: description,
      );

      _setLoading(false);

      if (result['success'] == true) {
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('ClientException')) {
        _setError('Tidak ada koneksi internet');
      } else {
        _setError('Terjadi kesalahan: $msg');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<bool> logout() async {
    // Logout should always clear local session, even if offline
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.logout();

      if (result['success'] == true) {
        _user = null;
        await _clearCredentials();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _user = null;
      await _clearCredentials();
      _setError(null);
      _setLoading(false);
      notifyListeners();
      return true;
    }
  }
}
