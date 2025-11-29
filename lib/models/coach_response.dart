import 'coach_model.dart';

class CoachResponse {
  final List<Coach> coaches;

  CoachResponse({required this.coaches});

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    final list = json['coaches'] ?? json['results'] ?? json['data'] ?? [];
    final items = <Coach>[];
    if (list is List) {
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          items.add(Coach.fromJson(e));
        } else if (e is Map) {
          items.add(Coach.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return CoachResponse(coaches: items);
  }
}
