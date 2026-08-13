import 'api_service.dart';

class ProfileModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? vehicleNumber;
  final String? assignedZone;

  ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.vehicleNumber,
    this.assignedZone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      vehicleNumber: json['vehicle_number'] as String?,
      assignedZone: json['assigned_zone'] as String?,
    );
  }
}

class ProfileService {
  final ApiService _api;
  ProfileService(this._api);

  Future<ProfileModel> getProfile() async {
    final res = await _api.get('/api/v1/profile/me');
    return ProfileModel.fromJson(res.data);
  }

  Future<ProfileModel> updateProfile({String? name}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    final res = await _api.patch('/api/v1/profile/me', data: data);
    return ProfileModel.fromJson(res.data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/api/v1/profile/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
