import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final CookieRequest _request;
  late final AuthService _authService;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._request) {
    _authService = AuthService(_request);
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.isLoggedIn && _user != null;
  bool get isCoach => _user?.isCoach ?? false;
  bool get isCustomer => _user?.isCustomer ?? true;

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

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.login(
        username: username,
        password: password,
      );

      if (result['success'] == true) {
        _user = result['user'] as UserModel;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
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
      _setError('Terjadi kesalahan: ${e.toString()}');
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
    required String name,
    required int age,
    required String citizenship,
    required String club,
    required String license,
    required String prefferedFormation,
    required double averageTermAsCoach,
    required int ratePerSession,
    String? description,
  }) async {
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
        name: name,
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
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> logout() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.logout();

      if (result['success'] == true) {
        _user = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Terjadi kesalahan: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }
}
