import 'package:pbp_django_auth/pbp_django_auth.dart';

class ReportService {
  static const baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';
  final CookieRequest request;

  ReportService(this.request);

  Future<bool> createReport({
    required int coachId,
    required String reason,
  }) async {
    final response = await request.post(
      '$baseUrl/my_admin/api/report/create/',
      {
        'coach_id': coachId.toString(),
        'reason': reason,
      },
    );

    return response['status'] == true;
  }
}