import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000';

  final CookieRequest request;

  AuthService(this.request);

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await request.post(
        '$baseUrl/accounts/api/login/',
        jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response['status'] == true) {
        return {
          'success': true,
          'message': response['message'],
          'user': UserModel.fromJson(response['user']),
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> registerCustomer({
    required String username,
    required String email,
    required String password1,
    required String password2,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await request.post(
        '$baseUrl/accounts/api/register/',
        jsonEncode({
          'username': username,
          'email': email,
          'password1': password1,
          'password2': password2,
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'user_type': 'customer',
        }),
      );

      if (response['status'] == true) {
        return {
          'success': true,
          'message': response['message'],
          'user': response['user'] != null
              ? UserModel.fromJson(response['user'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> registerCoach({
    required String username,
    required String email,
    required String password1,
    required String password2,
    String? firstName,
    String? lastName,
    required int age,
    required int experienceYears,
    required String expertise,
    required String certifications,
    required String location,
    required int ratePerSession,
    String? description,
  }) async {
    try {
      final response = await request.post(
        '$baseUrl/accounts/api/register/',
        jsonEncode({
          'username': username,
          'email': email,
          'password1': password1,
          'password2': password2,
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
          'user_type': 'coach',
          'coach_data': {
            'age': age,
            'experience_years': experienceYears,
            'expertise': expertise,
            'certifications': certifications,
            'location': location,
            'rate_per_session': ratePerSession,
            'description': description ?? '',
          }
        }),
      );

      if (response['status'] == true) {
        return {
          'success': true,
          'message': response['message'],
          'user': response['user'] != null
              ? UserModel.fromJson(response['user'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registrasi gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await request.post(
        '$baseUrl/accounts/api/logout/',
        jsonEncode({}),
      );

      if (response['status'] == true) {
        return {
          'success': true,
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Logout gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  bool get isLoggedIn => request.loggedIn;
}
