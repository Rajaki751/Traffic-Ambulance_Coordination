import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _showTrafficOverlay = true;

  bool get showTrafficOverlay => _showTrafficOverlay;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrafficOverlay = prefs.getBool('show_traffic_overlay') ?? true;
    notifyListeners();
  }

  Future<void> setShowTrafficOverlay(bool v) async {
    _showTrafficOverlay = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_traffic_overlay', v);
    notifyListeners();
  }
}
