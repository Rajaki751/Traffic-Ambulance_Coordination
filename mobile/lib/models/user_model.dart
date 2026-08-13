enum UserRole { admin, driver, officer }

class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['user_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      token: token ?? json['access_token'],
    );
  }

  static UserRole _parseRole(dynamic role) {
    final r = role.toString().toLowerCase();
    if (r == 'driver') return UserRole.driver;
    if (r == 'officer') return UserRole.officer;
    return UserRole.admin;
  }

  bool get isDriver => role == UserRole.driver;
  bool get isOfficer => role == UserRole.officer;
}
