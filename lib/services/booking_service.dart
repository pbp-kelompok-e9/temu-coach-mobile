import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  static const String baseUrl = 'http://localhost:8000';
  final CookieRequest request;

  BookingService(this.request);

  /// Fetch all bookings for the current user
  Future<List<Booking>> fetchBookings() async {
    try {
      final url = '$baseUrl/api/booking/';
      final response = await request.get(url);

      if (response is Map) {
        final bookings = response['bookings'];
        if (bookings is List) {
          return bookings
              .map<Booking>(
                (e) => Booking.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        }
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch single booking detail by id
  Future<Booking?> fetchBookingDetail(int id) async {
    try {
      final url = '$baseUrl/api/booking/$id/';
      final response = await request.get(url);

      if (response is Map) {
        return Booking.fromJson(Map<String, dynamic>.from(response));
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new booking
  Future<BookingResponse> createBooking(BookingRequest bookingRequest) async {
    try {
      final url = '$baseUrl/api/booking/create/';
      final response = await request.postJson(
        url,
        jsonEncode(bookingRequest.toJson()),
      );

      if (response is Map) {
        return BookingResponse.fromJson(Map<String, dynamic>.from(response));
      }

      return BookingResponse(
        success: false,
        error: 'Invalid response from server',
      );
    } catch (e) {
      return BookingResponse(success: false, error: e.toString());
    }
  }

  /// Update booking notes
  Future<BookingResponse> updateBooking(int bookingId, String notes) async {
    try {
      final url = '$baseUrl/api/booking/$bookingId/update/';
      final response = await request.postJson(
        url,
        jsonEncode({'notes': notes}),
      );

      if (response is Map) {
        return BookingResponse.fromJson(Map<String, dynamic>.from(response));
      }

      return BookingResponse(
        success: false,
        error: 'Invalid response from server',
      );
    } catch (e) {
      return BookingResponse(success: false, error: e.toString());
    }
  }

  /// Delete/cancel a booking
  Future<BookingResponse> deleteBooking(int bookingId) async {
    try {
      final url = '$baseUrl/api/booking/$bookingId/delete/';
      final response = await request.postJson(url, jsonEncode({}));

      if (response is Map) {
        return BookingResponse.fromJson(Map<String, dynamic>.from(response));
      }

      return BookingResponse(
        success: false,
        error: 'Invalid response from server',
      );
    } catch (e) {
      return BookingResponse(success: false, error: e.toString());
    }
  }
}
