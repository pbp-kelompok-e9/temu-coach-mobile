import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/coach_model.dart';
import '../models/schedule_model.dart';

class CoachService {
  static const String baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';
  final CookieRequest request;

  CoachService(this.request);

  /// Check if response indicates an authentication error (HTML response)
  bool _isHtmlResponse(dynamic response) {
    if (response is String) {
      final trimmed = response.trim();
      return trimmed.startsWith('<!') || trimmed.startsWith('<html') || trimmed.startsWith('<');
    }
    return false;
  }

  /// Fetch list of coaches with optional query, country filter and sort
  Future<List<Coach>> fetchCoaches({String? query, String? country, String? sort}) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) params['search'] = query;
      if (country != null && country.isNotEmpty) params['citizenship'] = country;
      if (sort != null && sort.isNotEmpty) params['ordering'] = sort;

      String url = '$baseUrl/api/coach/';
      if (params.isNotEmpty) {
        final queryString = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
        url = '$url?$queryString';
      }

      final response = await request.get(url);

      // Check for HTML response (authentication redirect)
      if (_isHtmlResponse(response)) {
        throw Exception('Session expired. Please login again.');
      }

      // Expecting a JSON list or object with 'results' or 'coaches'
      if (response is List) {
        return response.map<Coach>((e) => Coach.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (response is Map) {
        final list = response['results'] ?? response['coaches'] ?? response['data'] ?? [];
        if (list is List) {
          return list.map<Coach>((e) => Coach.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }

      return [];
    } on FormatException catch (e) {
      // Handle JSON parse error (likely HTML response)
      throw Exception('Session expired or invalid response. Please login again.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Coach?> fetchCoachDetail(int id) async {
    try {
      final url = '$baseUrl/api/coach/$id/';
      final response = await request.get(url);
      
      // Check for HTML response (authentication redirect)
      if (_isHtmlResponse(response)) {
        throw Exception('Session expired. Please login again.');
      }
      
      if (response is Map) {
        return Coach.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } on FormatException catch (e) {
      throw Exception('Session expired or invalid response. Please login again.');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Schedule>> fetchSchedules(int coachId) async {
    try {
      final url = '$baseUrl/coach/api/schedule/?coach=$coachId';
      final response = await request.get(url);
      
      // Check for HTML response (authentication redirect or 404)
      if (_isHtmlResponse(response)) {
        throw Exception('Invalid response from server. Please check your connection or login again.');
      }
      
      if (response is List) {
        final schedules = response.map<Schedule>((e) => Schedule.fromJson(Map<String, dynamic>.from(e))).toList();
        return schedules;
      } else if (response is Map) {
        // Check for error response
        if (response['status'] == 'error' || response['error'] != null) {
          return [];
        }
        final list = response['results'] ?? response['data'] ?? [];
        if (list is List) {
          final schedules = list.map<Schedule>((e) => Schedule.fromJson(Map<String, dynamic>.from(e))).toList();
          return schedules;
        }
      }
      
      return [];
    } on FormatException catch (e) {
      throw Exception('Invalid data received from server.');
    } catch (e) {
      rethrow;
    }
  }
}