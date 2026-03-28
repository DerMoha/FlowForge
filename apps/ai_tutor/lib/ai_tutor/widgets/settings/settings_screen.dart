import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../../state/provider_config_state.dart';
import 'provider_setup_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final providerState = context.watch<ProviderConfigState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Text('Settings', style: AppTypography.heading(context)),
            ),
          ),

          // AI Providers section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('AI Providers', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => _showAddProvider(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Provider'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure AI providers to enable chat, quiz generation, '
                    'and summarization features.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Provider cards
          if (providerState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (providerState.configs.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.key_off,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('No providers configured',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Add an OpenAI or OpenRouter API key to get started.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.builder(
                itemCount: providerState.configs.length,
                itemBuilder: (context, index) {
                  final config = providerState.configs[index];
                  final isActive =
                      config.providerId == providerState.activeProviderId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(config.label,
                                    style: theme.textTheme.titleSmall),
                                Text(config.model,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    )),
                              ],
                            ),
                          ),
                          if (!isActive)
                            TextButton(
                              onPressed: () => providerState
                                  .setActiveProvider(config.providerId),
                              child: const Text('Activate'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _confirmDelete(
                                context, providerState, config),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddProvider(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ProviderSetupDialog(),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProviderConfigState state,
    dynamic config,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Remove "${config.label}" and its API key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              state.deleteProvider(config.providerId);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
