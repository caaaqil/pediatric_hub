import '../../core/network/api_client.dart';
import '../models/misc.dart';

/// `backend/src/routes/chatbot.routes.js`
///
/// PediaBot runs on Gemini 2.0 Flash with a Groq fallback, plus admin keyword
/// templates that short-circuit the model (`chatbot.service.js`).
class ChatbotRepository {
  const ChatbotRepository(this._api);

  final ApiClient _api;

  /// `POST /chatbot/session` — resumes the active session unless `forceNew`.
  Future<ChatbotSession> startSession({
    bool forceNew = false,
    String language = 'so',
  }) async {
    final dynamic data = await _api.postData(
      '/chatbot/session',
      body: <String, dynamic>{'forceNew': forceNew, 'language': language},
    );
    return ChatbotSession.fromJson(asMap(data));
  }

  /// `POST /chatbot/:sessionId/close` — archives it into the history list.
  Future<void> closeSession(String sessionId) async {
    await _api.postData('/chatbot/$sessionId/close');
  }

  /// `GET /chatbot/sessions` — up to 25 archived sessions.
  Future<List<ChatbotSession>> sessions() async {
    final dynamic data = await _api.getData('/chatbot/sessions');
    return asMapList(data).map(ChatbotSession.fromJson).toList();
  }

  /// `GET /chatbot/:sessionId/history` — every message, oldest first.
  Future<List<ChatbotMessage>> history(String sessionId) async {
    final dynamic data = await _api.getData('/chatbot/$sessionId/history');
    return asMapList(data).map(ChatbotMessage.fromJson).toList();
  }

  /// `POST /chatbot/:sessionId/chat` — returns the stored AI reply row.
  Future<ChatbotMessage> send({
    required String sessionId,
    required String message,
    String language = 'so',
  }) async {
    final dynamic data = await _api.postData(
      '/chatbot/$sessionId/chat',
      body: <String, dynamic>{'message': message, 'language': language},
    );
    return ChatbotMessage.fromJson(asMap(data));
  }

  // ── Admin templates ───────────────────────────────────────────────────────

  /// `GET /chatbot/templates` (ADMIN)
  Future<List<ChatbotTemplate>> templates() async {
    final dynamic data = await _api.getData('/chatbot/templates');
    return asMapList(data).map(ChatbotTemplate.fromJson).toList();
  }

  /// `POST /chatbot/templates` (ADMIN) — upsert keyed on `triggerKeyword`.
  Future<ChatbotTemplate> saveTemplate({
    required String triggerKeyword,
    required String response,
  }) async {
    final dynamic data = await _api.postData(
      '/chatbot/templates',
      body: <String, dynamic>{
        'triggerKeyword': triggerKeyword,
        'response': response,
      },
    );
    return ChatbotTemplate.fromJson(asMap(data));
  }

  /// `DELETE /chatbot/templates/:id` (ADMIN)
  Future<void> deleteTemplate(String id) =>
      _api.deleteData('/chatbot/templates/$id');
}
