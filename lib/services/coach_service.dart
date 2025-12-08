import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/coach_model.dart';
import '../models/schedule_model.dart';

class CoachService {
  static const String baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';
  final CookieRequest request;

  CoachService(this.request);

  /// Fetch list of coaches with optional query, country filter and sort
  Future<List<Coach>> fetchCoaches({String? query, String? country, String? sort}) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) params['search'] = query;
      if (country != null && country.isNotEmpty) params['citizenship'] = country;
      if (sort != null && sort.isNotEmpty) params['ordering'] = sort; // backend may use 'ordering'

      String url = '$baseUrl/api/coach/';
      if (params.isNotEmpty) {
        final queryString = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
        url = '$url?$queryString';
      }

      final response = await request.get(url);

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
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch single coach detail by id
  Future<Coach?> fetchCoachDetail(int id) async {
    try {
      final url = '$baseUrl/api/coach/$id/';
      final response = await request.get(url);
      if (response is Map) {
        return Coach.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch schedules for a coach
  Future<List<Schedule>> fetchSchedules(int coachId) async {
    try {
      final url = '$baseUrl/api/schedule/?coach=$coachId';
      final response = await request.get(url);
      if (response is List) {
        return response.map<Schedule>((e) => Schedule.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (response is Map) {
        final list = response['results'] ?? response['data'] ?? [];
        if (list is List) {
          return list.map<Schedule>((e) => Schedule.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
