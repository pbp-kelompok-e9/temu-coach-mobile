import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';

class ReportProvider with ChangeNotifier {
  final CookieRequest request;
  ReportProvider(this.request);

  bool loading = false;
  String? error;

  Future<bool> createReport(int coachId, String reason) async {
    loading = true;
    error = null;
    notifyListeners();

    final url =
        'https://erico-putra-temucoach.pbp.cs.ui.ac.id/my_admin/api/report/create/coach/$coachId/';

    try {
      debugPrint("🚨 SEND REPORT TO: $url");
      debugPrint("📝 reason = $reason");

      final resp = await request.post(
        url,
        {
          'reason': reason,
        },
      );

      debugPrint("✅ REPORT RESPONSE: $resp");

      if (resp['success'] == true) {
        return true;
      } else {
        error = resp['error'] ?? 'Failed to report';
        return false;
      }
    } catch (e) {
      debugPrint("❌ REPORT ERROR: $e");
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
