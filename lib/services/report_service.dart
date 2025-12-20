import 'package:pbp_django_auth/pbp_django_auth.dart';

class ReportService {
  final CookieRequest request;
  ReportService(this.request);

  Future<bool> createReport({
    required int coachId,
    required String reason,
  }) async {
    if (coachId == 0) {
      throw Exception('coachId is invalid (0)');
    }

    final url =
        'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reports/create/coach/$coachId/';

    try {
      print('SEND REPORT TO: $url');
      print('reason = $reason');

      final resp = await request.post(url, {
        'reason': reason,
      });

      print('REPORT RESPONSE: $resp');

      return resp['success'] == true;
    } catch (e) {
      print('REPORT ERROR: $e');
      rethrow;
    }
  }
}
