import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../services/auth_service.dart';

class AdminProvider with ChangeNotifier {
  final CookieRequest request;

  // pakai baseUrl yang sama dengan AuthService
  static const String baseUrl = AuthService.baseUrl;

  bool loading = false;
  String? error;

  List<dynamic> reports = [];
  List<dynamic> coachRequests = [];

  AdminProvider(this.request);

  Future<void> loadData() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      // ---- GET REPORTS ----
      final reportsResp =
          await request.get('$baseUrl/my_admin/api/reports/');
      debugPrint('reportsResp: $reportsResp');

      // ---- GET COACH REQUESTS ----
      final coachResp =
          await request.get('$baseUrl/my_admin/api/coach-requests/');
      debugPrint('coachResp: $coachResp');

      reports = List<dynamic>.from(reportsResp['reports'] ?? []);
      coachRequests = List<dynamic>.from(coachResp['requests'] ?? []);
    } catch (e, st) {
      error = e.toString();
      debugPrint('AdminProvider.loadData error: $e\n$st');
    } finally {
      // PENTING: selalu turun, bahkan kalau error
      loading = false;
      notifyListeners();
    }
  }

  Future<void> approve(int coachId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/coach/$coachId/approve/',
        {}, // body kosong ok, yang penting POST
      );
      debugPrint('approve resp: $resp');
      await loadData();
    } catch (e, st) {
      debugPrint('approve error: $e\n$st');
    }
  }

  Future<void> reject(int coachId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/coach/$coachId/reject/',
        {},
      );
      debugPrint('reject resp: $resp');
      await loadData();
    } catch (e, st) {
      debugPrint('reject error: $e\n$st');
    }
  }

  Future<void> ban(int coachId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/coach/$coachId/ban/',
        {},
      );
      debugPrint('ban resp: $resp');
      await loadData();
    } catch (e, st) {
      debugPrint('ban error: $e\n$st');
    }
  }

  Future<void> deleteReport(int reportId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/report/$reportId/delete/',
        {},
      );
      debugPrint('deleteReport resp: $resp');
      await loadData();
    } catch (e, st) {
      debugPrint('deleteReport error: $e\n$st');
    }
  }
}
