import 'package:flutter/foundation.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatApiService _service;

  List<ChatSessionSummary> _sessions = [];
  final Map<int, List<ChatMessageModel>> _messages = {};
  bool _loading = false;
  bool _sending = false;
  int? _openSessionId;

  ChatProvider(this._service);

  List<ChatSessionSummary> get sessions => _sessions;
  bool get loading => _loading;
  bool get sending => _sending;
  int? get openSessionId => _openSessionId;

  int get totalUnread => _sessions.fold(0, (sum, s) => sum + s.unreadCount);

  List<ChatMessageModel> messagesFor(int sessionId) =>
      _messages[sessionId] ?? [];

  Future<void> loadSessions() async {
    _loading = true;
    notifyListeners();
    try {
      _sessions = await _service.fetchSessions();
    } catch (_) {
      _sessions = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_loading) return;
    await loadSessions();
    final open = _openSessionId;
    if (open != null) {
      await loadMessages(open, silent: true);
    }
  }

  Future<void> loadMessages(int sessionId, {bool silent = false}) async {
    _openSessionId = sessionId;
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _messages[sessionId] = await _service.fetchMessages(sessionId);
      _service.markRead(sessionId);
      _markSessionRead(sessionId);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> sendMessage(int sessionId, String message) async {
    if (_sending) return;
    _sending = true;
    notifyListeners();
    try {
      final msg = await _service.sendMessage(sessionId, message);
      final list = _messages[sessionId] ?? [];
      list.add(msg);
      _messages[sessionId] = list;
      await loadSessions();
    } catch (_) {
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void openSession(int sessionId) {
    _openSessionId = sessionId;
    _markSessionRead(sessionId);
  }

  void _markSessionRead(int sessionId) {
    final i = _sessions.indexWhere((s) => s.emergencySessionId == sessionId);
    if (i >= 0 && _sessions[i].unreadCount > 0) {
      final s = _sessions[i];
      _sessions[i] = ChatSessionSummary(
        emergencySessionId: s.emergencySessionId,
        vehicleNumber: s.vehicleNumber,
        destination: s.destination,
        status: s.status,
        lastMessage: s.lastMessage,
        lastMessageAt: s.lastMessageAt,
        unreadCount: 0,
      );
    }
  }
}
