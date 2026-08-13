import 'package:flutter/foundation.dart';

import '../services/junction_service.dart';

class JunctionProvider extends ChangeNotifier {
  final JunctionService _service;
  JunctionProvider(this._service);

  List<JunctionPoint> _junctions = [];
  List<JunctionClearanceRecord> _clearanceHistory = [];
  bool _loading = false;
  String? _message;

  List<JunctionPoint> get junctions => _junctions;
  List<JunctionClearanceRecord> get clearanceHistory => _clearanceHistory;
  bool get loading => _loading;
  String? get message => _message;

  Future<void> loadKathmanduJunctions() async {
    _loading = true;
    notifyListeners();
    try {
      _junctions = await _service.getKathmanduJunctions();
      _message = null;
    } catch (e) {
      _message = 'Could not load Kathmandu junctions';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadClearanceHistory() async {
    _loading = true;
    notifyListeners();
    try {
      _clearanceHistory = await _service.getMyClearanceHistory();
      _message = null;
    } catch (e) {
      _message = 'Could not load clearance history';
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> clearJunction({
    required JunctionPoint junction,
    int? emergencySessionId,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.markCleared(
        junctionName: junction.name,
        latitude: junction.lat,
        longitude: junction.lon,
        emergencySessionId: emergencySessionId,
      );
      _message = '${junction.name} marked cleared';
      await loadClearanceHistory();
    } catch (e) {
      _message = 'Failed to mark junction';
    }
    _loading = false;
    notifyListeners();
  }
}
