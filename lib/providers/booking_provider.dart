import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  final CookieRequest request;
  late final BookingService _service;

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this.request) {
    _service = BookingService(request);
  }

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  /// Fetch all bookings
  Future<void> fetchBookings() async {
    _setLoading(true);
    _setError(null);
    try {
      final list = await _service.fetchBookings();
      _bookings = list;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch single booking detail
  Future<Booking?> fetchBookingDetail(int id) async {
    _setLoading(true);
    _setError(null);
    try {
      final booking = await _service.fetchBookingDetail(id);
      return booking;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new booking
  Future<BookingResponse> createBooking(BookingRequest bookingRequest) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _service.createBooking(bookingRequest);
      if (response.success) {
        // Refresh bookings after successful creation
        await fetchBookings();
      }
      return response;
    } catch (e) {
      _setError(e.toString());
      return BookingResponse(success: false, error: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Update booking notes
  Future<BookingResponse> updateBooking(int bookingId, String notes) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _service.updateBooking(bookingId, notes);
      if (response.success) {
        // Refresh bookings after successful update
        await fetchBookings();
      }
      return response;
    } catch (e) {
      _setError(e.toString());
      return BookingResponse(success: false, error: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Delete/cancel a booking
  Future<BookingResponse> deleteBooking(int bookingId) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _service.deleteBooking(bookingId);
      if (response.success) {
        // Refresh bookings after successful deletion
        await fetchBookings();
      }
      return response;
    } catch (e) {
      _setError(e.toString());
      return BookingResponse(success: false, error: e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Get upcoming bookings (date in the future)
  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _bookings.where((booking) {
      try {
        final bookingDate = DateTime.parse(booking.date);
        return bookingDate.isAfter(now) || bookingDate.isAtSameMomentAs(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Get completed bookings (date in the past)
  List<Booking> get completedBookings {
    final now = DateTime.now();
    return _bookings.where((booking) {
      try {
        final bookingDate = DateTime.parse(booking.date);
        return bookingDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList();
  }
}
