class ReviewModel {
  final String coach;
  final String user;
  final int rate;
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewModel({
    required this.coach,
    required this.user,
    required this.rate,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      coach: json['coach'] as String,
      user: json['user'] as String,
      rate: json['rate'] as int,
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coach': coach,
      'user': user,
      'rate': rate,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
