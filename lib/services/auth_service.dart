import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';

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
            'name': name,
            'age': age,
            'citizenship': citizenship,
            'club': club,
            'license': license,
            'preffered_formation': prefferedFormation,
            'average_term_as_coach': averageTermAsCoach,
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
