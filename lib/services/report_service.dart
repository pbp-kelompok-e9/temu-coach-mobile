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
        'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/report/$coachId/';

    try {
      final resp = await request.post(url, {
        'reason': reason,
      });

      return resp['success'] == true;
    } catch (e) {
      rethrow;
    }
  }
}