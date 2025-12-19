import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';

class CustomerDashboardProvider with ChangeNotifier {
  final CookieRequest request;
  static const String baseUrl = AuthService.baseUrl;

  bool loading = false;
  String? error;

  List<Booking> upcomingBookings = [];
  List<Booking> completedBookings = [];

  CustomerDashboardProvider(this.request);

  Future<void> fetchMyBookings() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await request.get(
        '$baseUrl/api/booking/',
      );

      final List<dynamic> data = resp['bookings'] ?? [];

      final now = DateTime.now();

      upcomingBookings.clear();
      completedBookings.clear();

      for (final item in data) {
        final booking = Booking.fromJson(item);

        final endDateTime = DateTime.parse(
          '${booking.date} ${booking.endTime}',
        );

        if (endDateTime.isAfter(now)) {
          upcomingBookings.add(booking);
        } else {
          completedBookings.add(booking);
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      final resp = await request.post(
        '$baseUrl/api/booking/$bookingId/delete/',
        {},
      );

      await fetchMyBookings();
      return resp['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
