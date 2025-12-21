// lib/models/review_model.dart

class ReviewModel {
  final int id;
  final String coach;
  final String user;
  final int rate;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    this.id = 0,
    required this.coach,
    required this.user,
    required this.rate,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      // 1. ID: Ambil ID atau default 0
      id: json['id'] ?? 0,

      // 2. COACH: Cek null dulu biar gak Crash
      coach: json['coach'] != null ? json['coach'].toString() : '-',

      // 3. USER: Handle kalau backend kirim object user atau cuma string username
      user: json['user'] is Map 
          ? json['user']['username'] 
          : (json['user']?.toString() ?? 'Anonymous'),

      // 4. RATE: Pastikan int
      rate: json['rate'] is int 
          ? json['rate'] 
          : int.tryParse(json['rate'].toString()) ?? 0,

      // 5. REVIEW: Boleh null
      review: json['review'],

      // 6. CREATED AT: Parsing aman
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),

      // 7. UPDATED AT: Fallback ke createdAt kalau null
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : (json['created_at'] != null 
              ? DateTime.parse(json['created_at']) 
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach': coach,
      'user': user,
      'rate': rate,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}