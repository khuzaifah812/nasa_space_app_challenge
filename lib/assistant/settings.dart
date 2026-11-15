// How the assistant reaches an AI model.
//
// Everything comes from the .env file in the project folder, read when the
// app is built:   flutter run --dart-define-from-file=.env
// To change the key, edit .env and build again. Nothing is typed in the app
// and nothing is written in the source code.
//
// Without a key the assistant still answers from the app's own data.

const envProvider = String.fromEnvironment('AI_PROVIDER');
const envKey = String.fromEnvironment('AI_API_KEY');
const envModel = String.fromEnvironment('AI_MODEL');
const envProxy = String.fromEnvironment('AI_PROXY_URL');

class AssistantSettings {
  const AssistantSettings({
    this.provider = 'none',
    this.apiKey = '',
    this.model = '',
    this.proxyUrl = '',
  });

  /// 'none' (offline), 'groq', 'deepseek', 'anthropic', 'gemini', 'openai' or
  /// 'proxy'.
  final String provider;
  final String apiKey;
  final String model;
  final String proxyUrl;

  static const defaultModels = {
    'groq': 'llama-3.3-70b-versatile',
    'deepseek': 'deepseek-chat',
    'anthropic': 'claude-haiku-5-5',
    'gemini': 'gemini-2.0-flash',
    'openai': 'gpt-4o-mini',
  };

  bool get online =>
      provider == 'proxy' ? proxyUrl.isNotEmpty : provider != 'none' && apiKey.isNotEmpty;

  String get modelOrDefault =>
      model.isNotEmpty ? model : (defaultModels[provider] ?? '');

  /// The settings this build was made with.
  static const fromEnv = AssistantSettings(
    provider: envProxy != ''
        ? 'proxy'
        : envKey == ''
            ? 'none'
            : envProvider != ''
                ? envProvider
                : 'groq',
    apiKey: envKey,
    model: envModel,
    proxyUrl: envProxy,
  );
}
