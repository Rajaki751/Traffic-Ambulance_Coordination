import '../models/chat_models.dart';
import 'api_service.dart';

class ChatApiService {
  final ApiService _api;
  ChatApiService(this._api);

  Future<List<ChatSessionSummary>> fetchSessions({int limit = 30}) async {
    final res = await _api.get('/api/v1/chat/sessions', query: {'limit': limit});
    return (res.data as List)
        .map((e) => ChatSessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageModel>> fetchMessages(
    int sessionId, {
    int limit = 100,
  }) async {
    final res = await _api.get('/api/v1/chat/sessions/$sessionId/messages',
        query: {'limit': limit});
    return (res.data as List)
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageModel> sendMessage(
    int sessionId,
    String message, {
    double? latitude,
    double? longitude,
  }) async {
    final res = await _api.post(
      '/api/v1/chat/sessions/$sessionId/messages',
      data: {
        'message': message,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return ChatMessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markRead(int sessionId) async {
    await _api.post('/api/v1/chat/sessions/$sessionId/read');
  }
}
