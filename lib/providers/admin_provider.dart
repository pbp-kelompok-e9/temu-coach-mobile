import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../services/auth_service.dart';
import '../utils/error_mapper.dart';
enum ReportSort {
  newest,
  oldest,
  mostReports,
  leastReports,
}

class AdminProvider with ChangeNotifier {
  final CookieRequest request;

  static const String baseUrl = AuthService.baseUrl;

  bool loading = false;
  String? error;

  ReportSort currentSort = ReportSort.newest;

  List<dynamic> allReports = [];
  List<dynamic> reports = [];
  List<dynamic> coachRequests = [];

  AdminProvider(this.request);

  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    try {
      final resp =
          await request.get('$baseUrl/my_admin/api/reports/');

      allReports = List<dynamic>.from(resp['reports'] ?? []);
      _applySort();

      final coachResp =
        await request.get('$baseUrl/my_admin/api/coach-requests/');

      coachRequests = List<dynamic>.from(coachResp['requests'] ?? []);
      
    } catch (e) {
      error = ErrorMapper.message(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setSort(ReportSort sort) {
    currentSort = sort;
    _applySort();
    notifyListeners();
  }

  void _applySort() {
    reports = List<dynamic>.from(allReports);

    switch (currentSort) {
      case ReportSort.newest:
        reports.sort((a, b) =>
            b['created_at'].compareTo(a['created_at']));
        break;

      case ReportSort.oldest:
        reports.sort((a, b) =>
            a['created_at'].compareTo(b['created_at']));
        break;

      case ReportSort.mostReports:
        _sortByCoachReportCount(desc: true);
        break;

      case ReportSort.leastReports:
        _sortByCoachReportCount(desc: false);
        break;
    }
  }

  void _sortByCoachReportCount({required bool desc}) {
    final Map<int, int> countPerCoach = {};

    for (final r in allReports) {
      final coachId = r['coach_id'];
      countPerCoach[coachId] =
          (countPerCoach[coachId] ?? 0) + 1;
    }

    reports.sort((a, b) {
      final countA = countPerCoach[a['coach_id']] ?? 0;
      final countB = countPerCoach[b['coach_id']] ?? 0;

      if (countA != countB) {
        return desc
            ? countB.compareTo(countA)
            : countA.compareTo(countB);
      }

      return b['created_at'].compareTo(a['created_at']);
    });
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
