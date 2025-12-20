class ReportModel {
  final int id;
  final String coach;
  final String reporter;
  final String reason;
  final DateTime createdAt;

  ReportModel({
    this.id = 0,
    required this.coach,
    required this.reporter,
    required this.reason,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? 0,
      coach: json['coach']?.toString() ?? '-',
      reporter: json['reporter']?.toString() ?? '-',
      reason: json['reason'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
