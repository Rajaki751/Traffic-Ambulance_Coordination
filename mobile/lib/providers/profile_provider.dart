import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;
  ProfileProvider(this._service);

  ProfileModel? _profile;
  bool _loading = false;
  String? _error;
  String? _success;

  ProfileModel? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;
  String? get success => _success;

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _service.getProfile();
    } catch (e) {
      _error = 'Failed to load profile';
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> updateName(String name) async {
    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      _profile = await _service.updateProfile(name: name);
      _success = 'Name updated successfully';
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update name';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _success = 'Password changed successfully';
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to change password. Check your current password.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
