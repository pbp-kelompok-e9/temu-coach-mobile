import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/coach_model.dart';
import '../models/schedule_model.dart';
import '../services/coach_service.dart';

class CoachProvider with ChangeNotifier {
  final CookieRequest request;
  late final CoachService _service;

  List<Coach> _coaches = [];
  bool _isLoading = false;
  String? _error;

  // UI state
  String _searchQuery = '';
  String _selectedCountry = '';
  String _sort = '';

  CoachProvider(this.request) {
    _service = CoachService(request);
  }

  List<Coach> get coaches => _coaches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get searchQuery => _searchQuery;
  String get selectedCountry => _selectedCountry;
  String get sort => _sort;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  Future<void> fetchCoaches({String? query, String? country, String? sortBy}) async {
    _setLoading(true);
    _setError(null);
    try {
      final list = await _service.fetchCoaches(query: query, country: country, sort: sortBy);
      _coaches = list;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Coach?> fetchCoachDetail(int id) async {
    try {
      return await _service.fetchCoachDetail(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<List<Schedule>> fetchSchedules(int coachId) async {
    try {
      return await _service.fetchSchedules(coachId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCountry(String c) {
    _selectedCountry = c;
    notifyListeners();
  }

  void setSort(String s) {
    _sort = s;
    notifyListeners();
  }
}
