import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'auth_service.dart';

class ReportService {
  static const String baseUrl = 'http://localhost:8000';
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

    print('SENDING REPORT...');
    print('coachId: $coachId');
    print('reason: $reason');

    return response['status'] == true;
  }
}