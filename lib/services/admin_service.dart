import 'package:pbp_django_auth/pbp_django_auth.dart';

class AdminService {
  static const String baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';
  final CookieRequest request;

  AdminService(this.request);

  Future<dynamic> fetchReports() async {
    return await request.get('$baseUrl/my_admin/api/reports/');
  }

  Future<dynamic> fetchCoachRequests() async {
    return await request.get('$baseUrl/my_admin/api/coach-requests/');
  }

  Future<bool> approveCoach(int id) async {
    final response = await request.post(
      '$baseUrl/my_admin/api/coach/$id/approve/',
      {},
    );
    return response['status'] == true;
  }

  Future<bool> rejectCoach(int id) async {
    final response = await request.post(
      '$baseUrl/my_admin/api/coach/$id/reject/',
      {},
    );
    return response['status'] == true;
  }

  Future<bool> banCoach(int id) async {
    final response = await request.post(
      '$baseUrl/my_admin/api/coach/$id/ban/',
      {},
    );
    return response['status'] == true;
  }

  Future<bool> deleteReport(int id) async {
    final response = await request.post(
      '$baseUrl/my_admin/api/report/$id/delete/',
      {},
    );
    return response['status'] == true;
  }
}
