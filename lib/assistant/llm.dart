// Calls an AI model. Four routes: Anthropic, Google Gemini and OpenAI
// directly, or a proxy you host that holds the key (server/worker.js).
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../l10n/strings.dart';
import 'knowledge.dart';
import 'settings.dart';

class ChatMessage {
  const ChatMessage(this.role, this.text);
  final String role; // 'user' or 'assistant'
  final String text;
}

class LlmException implements Exception {
  LlmException(this.message);
  final String message;
  @override
  String toString() => message;
}

String systemPrompt(String knowledge) => '''
You are the AgriSmart assistant inside a mobile app that helps smallholder
farmers choose crop rotations using NASA Earth observation data.

Language: ALWAYS answer in ${languageNames[Lang.code]} (${Lang.code}), whatever
language the question is in, unless the farmer asks for another language.

How to answer:
- Use the FIELD DATA below as your first source. Quote its numbers when they
  answer the question (rain, heat, soil wetness, seasons, scores, risks).
- For anything the field data does not cover, use your general knowledge of
  farming, soils, crops, pests, markets and climate, and of NASA datasets
  (POWER, SMAP, GPM, MODIS, Landsat, ECOSTRESS, GRACE). Say when something is
  general knowledge rather than this field's data.
- Be short and plain: a farmer reads this on a phone. Prefer 3 to 6 short
  sentences or a short list. No jargon without a one-line explanation.
- Never invent numbers. If the data is sample data, say so.
- If the farmer is stuck in the app, explain the next step: screens are
  Welcome, Language, How it works, Add your field (country, place search,
  NASA map, "Read NASA records"), What you grow now, Soil and limits, What
  matters to you, then tabs Home, Conditions, Rotations (options, side by
  side, detail), Review, Learn (glossary, crop table, language, assistant
  settings).
- Remind the farmer, when it matters, to check planting dates, varieties and
  pests with a local extension officer. The app supports judgment; it does
  not replace it.

FIELD DATA
$knowledge
''';

Future<String> askModel(
    AssistantSettings s, List<ChatMessage> history, String knowledge) async {
  final system = systemPrompt(knowledge);
  final recent = history.length > 12 ? history.sublist(history.length - 12) : history;
  http.Response res;
  try {
    res = await _send(s, system, recent).timeout(const Duration(seconds: 60));
  } on LlmException {
    rethrow;
  } catch (_) {
    throw LlmException(t('as_netError'));
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw LlmException('${t('as_apiError')} (${res.statusCode}): '
        '${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');
  }
  final json = jsonDecode(res.body) as Map<String, dynamic>;
  switch (s.provider) {
    case 'anthropic':
      final content = json['content'] as List<dynamic>;
      return content.map((c) => (c as Map<String, dynamic>)['text'] ?? '').join();
    case 'gemini':
      final cands = json['candidates'] as List<dynamic>;
      final parts = ((cands.first as Map<String, dynamic>)['content']
          as Map<String, dynamic>)['parts'] as List<dynamic>;
      return parts.map((p) => (p as Map<String, dynamic>)['text'] ?? '').join();
    case 'openai':
    case 'deepseek':
    case 'groq':
      final choices = json['choices'] as List<dynamic>;
      return ((choices.first as Map<String, dynamic>)['message']
          as Map<String, dynamic>)['content'] as String;
    default:
      return (json['reply'] ?? json['text'] ?? '') as String;
  }
}

Future<http.Response> _send(
    AssistantSettings s, String system, List<ChatMessage> msgs) {
  final headers = {'Content-Type': 'application/json'};
  switch (s.provider) {
    case 'anthropic':
      headers['x-api-key'] = s.apiKey;
      headers['anthropic-version'] = '2023-06-01';
      // lets a web build call the API from the browser
      headers['anthropic-dangerous-direct-browser-access'] = 'true';
      return http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: headers,
        body: jsonEncode({
          'model': s.modelOrDefault,
          'max_tokens': 700,
          'system': system,
          'messages': [
            for (final m in msgs) {'role': m.role, 'content': m.text},
          ],
        }),
      );
    case 'gemini':
      return http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/'
            '${s.modelOrDefault}:generateContent?key=${s.apiKey}'),
        headers: headers,
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': system}
            ]
          },
          'contents': [
            for (final m in msgs)
              {
                'role': m.role == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': m.text}
                ],
              },
          ],
          'generationConfig': {'maxOutputTokens': 700},
        }),
      );
    case 'openai':
    case 'deepseek':
    case 'groq':
      // Groq and DeepSeek speak the same chat format as OpenAI
      headers['Authorization'] = 'Bearer ${s.apiKey}';
      return http.post(
        Uri.parse(const {
          'groq': 'https://api.groq.com/openai/v1/chat/completions',
          'deepseek': 'https://api.deepseek.com/chat/completions',
          'openai': 'https://api.openai.com/v1/chat/completions',
        }[s.provider]!),
        headers: headers,
        body: jsonEncode({
          'model': s.modelOrDefault,
          'max_tokens': 700,
          'messages': [
            {'role': 'system', 'content': system},
            for (final m in msgs) {'role': m.role, 'content': m.text},
          ],
        }),
      );
    case 'proxy':
      return http.post(
        Uri.parse(s.proxyUrl),
        headers: headers,
        body: jsonEncode({
          'system': system,
          'language': Lang.code,
          'messages': [
            for (final m in msgs) {'role': m.role, 'content': m.text},
          ],
        }),
      );
    default:
      throw LlmException(t('as_offlineOnly'));
  }
}

/// Export for the proxy or for debugging: the full grounding text.
String groundingFor(dynamic analysis) => fieldKnowledge(analysis);
