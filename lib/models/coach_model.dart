class Coach {
  final int id;
  final String name;
  final int age;
  final String citizenship;
  final String? foto; // url atau path
  final String club;
  final String license;
  final String prefferedFormation;
  final double averageTermAsCoach;
  final String description;
  final double ratePerSession;
  

  Coach({
    required this.id,
    required this.name,
    required this.age,
    required this.citizenship,
    this.foto,
    required this.club,
    required this.license,
    required this.prefferedFormation,
    required this.averageTermAsCoach,
    required this.description,
    required this.ratePerSession,
    
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    return Coach(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      citizenship: json['citizenship'] ?? '',
      foto: json['foto'] as String?,
      club: json['club'] ?? '',
      license: json['license'] ?? '',
      prefferedFormation: json['preffered_formation'] ?? json['prefferedFormation'] ?? '',
      averageTermAsCoach: (json['average_term_as_coach'] is num) ? (json['average_term_as_coach'] as num).toDouble() : double.tryParse('${json['average_term_as_coach']}') ?? 0.0,
      description: json['description'] ?? '',
      ratePerSession: (json['rate_per_session'] is num) ? (json['rate_per_session'] as num).toDouble() : double.tryParse('${json['rate_per_session']}') ?? 0.0,
      
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'citizenship': citizenship,
      'foto': foto,
      'club': club,
      'license': license,
      'preffered_formation': prefferedFormation,
      'average_term_as_coach': averageTermAsCoach,
      'description': description,
      'rate_per_session': ratePerSession,
      
    };
  }
}
