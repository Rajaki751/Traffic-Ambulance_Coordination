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

  Future<ChatMessageModel> sendMessage(int sessionId, String message) async {
    final res = await _api.post('/api/v1/chat/sessions/$sessionId/messages',
        data: {'message': message});
    return ChatMessageModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markRead(int sessionId) async {
    await _api.post('/api/v1/chat/sessions/$sessionId/read');
  }
}
