import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService service;

  List reports = [];
  List coachRequests = [];
  bool loading = false;

  AdminProvider(CookieRequest req) : service = AdminService(req);

  Future<void> loadData() async {
    loading = true;
    notifyListeners();

    reports = await service.fetchReports();
    coachRequests = await service.fetchCoachRequests();

    loading = false;
    notifyListeners();
  }

  Future<void> approve(int id) async {
    await service.approveCoach(id);
    await loadData();
  }

  Future<void> reject(int id) async {
    await service.rejectCoach(id);
    await loadData();
  }

  Future<void> ban(int id) async {
    await service.banCoach(id);
    await loadData();
  }

  Future<void> deleteReport(int id) async {
    await service.deleteReport(id);
    await loadData();
  }
}
