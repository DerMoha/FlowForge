import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/voice_tutor_state.dart';

class VoiceTutorScreen extends StatelessWidget {
  const VoiceTutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceState = context.watch<VoiceTutorState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Tutor'),
        actions: [
          if (voiceState.isSpeaking || voiceState.isListening)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => voiceState.stop(),
              tooltip: 'Stop',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => voiceState.clearHistory(),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status indicator
              _StatusOrb(status: voiceState.status),
              const SizedBox(height: 32),

              // Status text
              Text(
                _statusLabel(voiceState.status),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Recognized text
              if (voiceState.recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You said:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 4),
                      Text(voiceState.recognizedText,
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),

              if (voiceState.responseText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tutor:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                      const SizedBox(height: 4),
                      Text(voiceState.responseText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                    ],
                  ),
                ),
              ],

              // Error
              if (voiceState.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  voiceState.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              // Push-to-talk button
              Text(
                voiceState.isListening
                    ? 'Release to send'
                    : 'Hold to speak',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTapDown: (_) {
                  if (voiceState.isIdle) voiceState.startListening();
                },
                onTapUp: (_) {
                  if (voiceState.isListening) voiceState.stopListening();
                },
                onTapCancel: () {
                  if (voiceState.isListening) voiceState.stopListening();
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: voiceState.isListening
                        ? theme.colorScheme.error
                        : voiceState.isIdle
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    voiceState.isListening
                        ? Icons.mic
                        : voiceState.isProcessing
                            ? Icons.hourglass_top
                            : voiceState.isSpeaking
                                ? Icons.volume_up
                                : Icons.mic_none,
                    size: 36,
                    color: voiceState.isIdle || voiceState.isListening
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(VoiceTutorStatus status) {
    switch (status) {
      case VoiceTutorStatus.idle:
        return 'Ready';
      case VoiceTutorStatus.listening:
        return 'Listening...';
      case VoiceTutorStatus.processing:
        return 'Thinking...';
      case VoiceTutorStatus.speaking:
        return 'Speaking...';
    }
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({required this.status});

  final VoiceTutorStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color;
    switch (status) {
      case VoiceTutorStatus.idle:
        color = theme.colorScheme.surfaceContainerHighest;
      case VoiceTutorStatus.listening:
        color = theme.colorScheme.error;
      case VoiceTutorStatus.processing:
        color = theme.colorScheme.tertiary;
      case VoiceTutorStatus.speaking:
        color = theme.colorScheme.primary;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: status == VoiceTutorStatus.listening ? 120 : 100,
      height: status == VoiceTutorStatus.listening ? 120 : 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 3),
      ),
      child: Center(
        child: status == VoiceTutorStatus.processing
            ? CircularProgressIndicator(color: color)
            : Icon(
                status == VoiceTutorStatus.speaking
                    ? Icons.graphic_eq
                    : Icons.smart_toy,
                size: 48,
                color: color,
              ),
      ),
    );
  }
}
