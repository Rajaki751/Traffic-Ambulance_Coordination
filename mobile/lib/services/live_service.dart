import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:web_socket_channel/web_socket_channel.dart';

class LiveService {
  void Function()? onNotification;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;
  Timer? _retryTimer;
  bool _closed = true;
  int _retryAttempts = 0;
  String? _baseUrl;
  String? _token;
  String? _channelName;

  void connect({
    required String baseUrl,
    required String token,
    required String channel,
  }) {
    _baseUrl = baseUrl;
    _token = token;
    _channelName = channel;
    _closed = false;
    _retryAttempts = 0;
    _open();
  }

  void disconnect() {
    _closed = true;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    _sub?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _open() {
    if (_closed || _baseUrl == null || _token == null || _channelName == null) {
      return;
    }
    try {
      _sub?.cancel();
      _channel?.sink.close();
    } catch (_) {}
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_buildWsUrl()));
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _sub = _channel!.stream.listen(
      _onMessage,
      onDone: _onClosed,
      onError: (Object _) => _onClosed(),
    );
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_closed && _channel != null) {
        _channel!.sink.add('ping');
      }
    });
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic>? msg;
    try {
      msg = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = msg['type'];
    if (type == 'notification' ||
        type == 'notification_acknowledged' ||
        type == 'emergency_activated' ||
        type == 'emergency_ended' ||
        type == 'trip_stage_updated') {
      onNotification?.call();
    }
  }

  void _onClosed() {
    _pingTimer?.cancel();
    _channel = null;
    if (_closed) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _retryTimer?.cancel();
    final delaySeconds = math.min(30, 1 << _retryAttempts);
    _retryAttempts++;
    _retryTimer = Timer(Duration(seconds: delaySeconds), _open);
  }

  String _buildWsUrl() {
    final uri = Uri.parse(_baseUrl!);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.authority}/ws/live'
        '?token=${Uri.encodeQueryComponent(_token!)}'
        '&channel=$_channelName';
  }
}
