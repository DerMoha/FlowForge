import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/practice_state.dart';

class PracticeStartDialog extends StatefulWidget {
  const PracticeStartDialog({super.key});

  @override
  State<PracticeStartDialog> createState() => _PracticeStartDialogState();
}

class _PracticeStartDialogState extends State<PracticeStartDialog> {
  final _controller = TextEditingController();
  bool _loading = false;

  final List<String> _suggestions = [
    'Integration by parts',
    'Solving quadratic equations',
    'Newton\'s laws of motion',
    'Photosynthesis',
    'Python list comprehensions',
    'Chain rule in calculus',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start(String topic) async {
    if (topic.trim().isEmpty) return;
    setState(() => _loading = true);
    final state = context.read<PracticeState>();
    Navigator.of(context).pop(topic.trim());
    await state.startSession(topic: topic.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined),
                  const SizedBox(width: 10),
                  Text('Start Practice', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'What topic would you like to practice?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                onSubmitted: _start,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Topic',
                  hintText: 'e.g. Integration by parts, Newton\'s laws...',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Suggestions',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggestions
                    .map((s) => ActionChip(
                          label: Text(s),
                          onPressed: _loading ? null : () => _start(s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () => _start(_controller.text),
                    child: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Start'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
