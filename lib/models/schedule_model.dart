class Schedule {
  final int id;
  final int coachId;
  final String date; // ISO format yyyy-mm-dd
  final String startTime; // hh:mm:ss
  final String endTime; // hh:mm:ss
  final bool isBooked;

  Schedule({
    required this.id,
    required this.coachId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? 0,
      coachId: json['coach'] ?? 0,
      date: json['tanggal'] ?? json['date'] ?? '',
      startTime: json['jam_mulai'] ?? json['start_time'] ?? '',
      endTime: json['jam_selesai'] ?? json['end_time'] ?? '',
      isBooked: json['is_booked'] ?? json['isBooked'] ?? false,
    );
  }
}
