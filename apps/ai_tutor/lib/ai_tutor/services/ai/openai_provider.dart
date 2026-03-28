import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// OpenAI-compatible provider (works with OpenAI, OpenRouter, any compatible API).
class OpenAiProvider implements AiProvider {
  OpenAiProvider({this.providerId = 'openai'});

  final String providerId;

  @override
  String get id => providerId;

  @override
  Future<void> testConnection(ProviderRuntimeConfig config) async {
    final url = _baseUrl(config);
    final response = await http.post(
      Uri.parse('$url/chat/completions'),
      headers: _headers(config),
      body: jsonEncode({
        'model': config.model,
        'messages': [
          {'role': 'user', 'content': 'Hi'}
        ],
        'max_tokens': 5,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Connection test failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Stream<AiStreamChunk> sendChat(
    ProviderRuntimeConfig config,
    AiChatRequest request,
  ) async* {
    final url = _baseUrl(config);
    final messages = <Map<String, String>>[];

    if (request.systemPrompt != null) {
      messages.add({'role': 'system', 'content': request.systemPrompt!});
    }
    for (final msg in request.messages) {
      messages.add({'role': msg.role, 'content': msg.content});
    }

    final httpRequest = http.Request(
      'POST',
      Uri.parse('$url/chat/completions'),
    );
    httpRequest.headers.addAll(_headers(config));
    httpRequest.body = jsonEncode({
      'model': config.model,
      'messages': messages,
      'stream': true,
    });

    final client = http.Client();
    try {
      final response = await client.send(httpRequest);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Chat request failed (${response.statusCode}): $body');
      }

      // Parse SSE stream
      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (line.isEmpty || !line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') {
          yield const AiStreamChunk(content: '', isDone: true);
          break;
        }

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices[0] as Map<String, dynamic>)['delta'] as Map<String, dynamic>?;
          if (delta == null) continue;
          final content = delta['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield AiStreamChunk(content: content);
          }
        } catch (_) {
          // Skip malformed chunks
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<String> generateQuiz(
    ProviderRuntimeConfig config,
    QuizGenerationRequest request,
  ) async {
    final url = _baseUrl(config);
    final response = await http.post(
      Uri.parse('$url/chat/completions'),
      headers: _headers(config),
      body: jsonEncode({
        'model': config.model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a quiz generator. Generate a quiz in JSON format. '
                'Return ONLY valid JSON with no markdown formatting.',
          },
          {
            'role': 'user',
            'content': 'Generate ${request.questionCount} questions '
                '(types: ${request.questionTypes.join(", ")}) '
                'based on this content:\n\n${request.content}',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Quiz generation failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List;
    final message = (choices[0] as Map<String, dynamic>)['message']
        as Map<String, dynamic>;
    return message['content'] as String;
  }

  @override
  Future<String> summarize(
    ProviderRuntimeConfig config,
    String content,
  ) async {
    final url = _baseUrl(config);
    final response = await http.post(
      Uri.parse('$url/chat/completions'),
      headers: _headers(config),
      body: jsonEncode({
        'model': config.model,
        'messages': [
          {
            'role': 'system',
            'content': 'Summarize the following content concisely.',
          },
          {'role': 'user', 'content': content},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Summarize failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List;
    final message = (choices[0] as Map<String, dynamic>)['message']
        as Map<String, dynamic>;
    return message['content'] as String;
  }

  String _baseUrl(ProviderRuntimeConfig config) =>
      config.baseUrl ?? 'https://api.openai.com/v1';

  Map<String, String> _headers(ProviderRuntimeConfig config) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      };
}
