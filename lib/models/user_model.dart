class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String userType;
  final bool isCoach;
  final bool isCustomer;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.isCoach,
    required this.isCustomer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userType: json['user_type'] ?? 'customer',
      isCoach: json['is_coach'] ?? false,
      isCustomer: json['is_customer'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'is_coach': isCoach,
      'is_customer': isCustomer,
    };
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return username;
    return '$firstName $lastName'.trim();
  }
}
