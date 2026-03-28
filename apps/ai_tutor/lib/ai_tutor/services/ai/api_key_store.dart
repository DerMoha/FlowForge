import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/conversation.dart';

/// Secure storage for AI provider API keys and configurations.
class ApiKeyStore {
  static const _storage = FlutterSecureStorage();
  static const _configsKey = 'ai_provider_configs';
  static const _activeProviderKey = 'active_provider_id';

  /// Get all saved provider configs.
  Future<List<ProviderConfig>> getConfigs() async {
    final json = await _storage.read(key: _configsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => _configFromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save a provider config (add or update by providerId).
  Future<void> saveConfig(ProviderConfig config) async {
    final configs = await getConfigs();
    final index = configs.indexWhere((c) => c.providerId == config.providerId);
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }
    await _storage.write(
      key: _configsKey,
      value: jsonEncode(configs.map(_configToJson).toList()),
    );
  }

  /// Delete a provider config.
  Future<void> deleteConfig(String providerId) async {
    final configs = await getConfigs();
    configs.removeWhere((c) => c.providerId == providerId);
    await _storage.write(
      key: _configsKey,
      value: jsonEncode(configs.map(_configToJson).toList()),
    );
    // Also delete the API key
    await deleteApiKey(providerId);
  }

  /// Store an API key securely.
  Future<void> saveApiKey(String providerId, String apiKey) async {
    await _storage.write(key: 'api_key_$providerId', value: apiKey);
  }

  /// Retrieve an API key.
  Future<String?> getApiKey(String providerId) async {
    return _storage.read(key: 'api_key_$providerId');
  }

  /// Delete an API key.
  Future<void> deleteApiKey(String providerId) async {
    await _storage.delete(key: 'api_key_$providerId');
  }

  /// Get the active provider ID.
  Future<String?> getActiveProviderId() async {
    return _storage.read(key: _activeProviderKey);
  }

  /// Set the active provider ID.
  Future<void> setActiveProviderId(String providerId) async {
    await _storage.write(key: _activeProviderKey, value: providerId);
  }

  Map<String, dynamic> _configToJson(ProviderConfig config) => {
        'providerId': config.providerId,
        'label': config.label,
        'baseUrl': config.baseUrl,
        'model': config.model,
        'isEnabled': config.isEnabled,
      };

  ProviderConfig _configFromJson(Map<String, dynamic> json) => ProviderConfig(
        providerId: json['providerId'] as String,
        label: json['label'] as String,
        baseUrl: json['baseUrl'] as String?,
        model: json['model'] as String,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );
}
