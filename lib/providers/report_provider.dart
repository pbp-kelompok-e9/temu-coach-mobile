import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../utils/error_mapper.dart';

class ReportProvider with ChangeNotifier {
  final CookieRequest request;
  ReportProvider(this.request);

  bool loading = false;
  String? error;

Future<bool> createReport(int coachId, String reason) async {
  loading = true;
  error = null;
  notifyListeners();

  final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/report/$coachId/';

  try {
    final resp = await request.post(
      url,
      {
        'reason': reason,
      },
    );

    if (resp['success'] == true) {
      return true;
    } else {
      error = resp['error'] ?? 'Gagal mengirim laporan';
      return false;
    }
  } catch (e) {
    error = ErrorMapper.message(e);
    return false;
  } finally {
    loading = false;
    notifyListeners();
  }
}
}
