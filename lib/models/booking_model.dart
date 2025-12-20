class Booking {
  final int id;
  final int jadwalId;
  final String customerUsername;
  final String? notes;
  final int coachId;
  final String coachName;
  final String? coachPhoto;
  final String date;
  final String startTime;
  final String endTime;
  final double rate;

  Booking({
    required this.id,
    required this.jadwalId,
    required this.customerUsername,
    this.notes,
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rate,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      jadwalId: json['jadwal_id'] ?? 0,
      customerUsername: json['customer_username'] ?? '',
      notes: json['notes'],
      coachId: json['coach_id'] ?? 0,
      coachName: json['coach_name'] ?? '',
      coachPhoto: json['coach_photo'],
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jadwal_id': jadwalId,
      'customer_username': customerUsername,
      'notes': notes,
      'coach_id': coachId,
      'coach_name': coachName,
      'coach_photo': coachPhoto,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'rate': rate,
    };
  }
}

class BookingRequest {
  final int jadwalId;
  final String notes;

  BookingRequest({required this.jadwalId, this.notes = ''});

  Map<String, dynamic> toJson() {
    return {'jadwal_id': jadwalId, 'notes': notes};
  }
}

class BookingResponse {
  final bool success;
  final String message;
  final int? bookingId;
  final String? error;

  BookingResponse({
    required this.success,
    this.message = '',
    this.bookingId,
    this.error,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      bookingId: json['booking_id'],
      error: json['error'],
    );
  }
}
