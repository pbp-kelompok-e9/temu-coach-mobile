import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../services/auth_service.dart';

class AdminProvider with ChangeNotifier {
  final CookieRequest request;

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
      final reportsResp =
          await request.get('$baseUrl/my_admin/api/reports/');
      final coachResp =
          await request.get('$baseUrl/my_admin/api/coach-requests/');

      reports = List<dynamic>.from(reportsResp['reports'] ?? []);
      coachRequests = List<dynamic>.from(coachResp['requests'] ?? []);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> approve(int coachId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/coach/$coachId/approve/',
        {},
      );
      await loadData();
      return resp['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(int coachId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/coach/$coachId/reject/',
        {},
      );
      await loadData();
      return resp['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> ban(int coachId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/coach/$coachId/ban/',
        {},
      );
      await loadData();
      return resp['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteReport(int reportId) async {
    try {
      final resp = await request.post(
        '$baseUrl/my_admin/api/report/$reportId/delete/',
        {},
      );
      await loadData();
      return resp['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
