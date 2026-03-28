import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/provider_config_state.dart';

class ProviderSetupDialog extends StatefulWidget {
  const ProviderSetupDialog({super.key});

  @override
  State<ProviderSetupDialog> createState() => _ProviderSetupDialogState();
}

class _ProviderSetupDialogState extends State<ProviderSetupDialog> {
  int _selectedTemplateIndex = 0;
  String? _selectedModel;
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final template = ProviderConfigState.providerTemplates[0];
    _selectedModel = template.defaultModel;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerState = context.watch<ProviderConfigState>();
    final theme = Theme.of(context);
    final templates = ProviderConfigState.providerTemplates;
    final template = templates[_selectedTemplateIndex];

    return AlertDialog(
      title: const Text('Add AI Provider'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider selector
            Text('Provider', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: templates.asMap().entries.map((e) {
                return ButtonSegment(
                  value: e.key,
                  label: Text(e.value.label),
                );
              }).toList(),
              selected: {_selectedTemplateIndex},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedTemplateIndex = set.first;
                  final t = templates[set.first];
                  _selectedModel = t.defaultModel;
                });
              },
            ),
            const SizedBox(height: 16),

            // Model selector
            Text('Model', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedModel,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: template.models
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedModel = v),
            ),
            const SizedBox(height: 16),

            // API Key
            Text('API Key', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: template.id == 'openai'
                    ? 'sk-...'
                    : 'sk-or-...',
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test result
            if (providerState.testResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: providerState.testResult!.startsWith('Connection')
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  providerState.testResult!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: providerState.testResult!.startsWith('Connection')
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            providerState.clearTestResult();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: providerState.isTesting ||
                  _apiKeyController.text.trim().isEmpty
              ? null
              : () {
                  providerState.testConnection(
                    providerId: template.id,
                    apiKey: _apiKeyController.text.trim(),
                    model: _selectedModel!,
                    baseUrl: template.baseUrl,
                  );
                },
          child: providerState.isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test'),
        ),
        FilledButton(
          onPressed: _apiKeyController.text.trim().isEmpty
              ? null
              : () {
                  providerState.saveProvider(
                    providerId: template.id,
                    label: template.label,
                    model: _selectedModel!,
                    apiKey: _apiKeyController.text.trim(),
                    baseUrl: template.baseUrl,
                  );
                  providerState.clearTestResult();
                  Navigator.pop(context);
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
