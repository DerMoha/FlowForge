import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_energy_requirement.dart';
import '../state/project_state.dart';
import '../state/app_state.dart';
import '../services/voice_service.dart';
import 'task_detail_sections.dart';

class TaskInputBar extends StatefulWidget {
  const TaskInputBar({super.key, required this.state});

  final FlowForgeState state;

  @override
  State<TaskInputBar> createState() => _TaskInputBarState();
}

class _TaskInputBarState extends State<TaskInputBar> {
  bool _isListening = false;
  String _preVoiceText = '';

  @override
  void dispose() {
    if (_isListening) {
      VoiceService.instance.stopListening((_) {});
    }
    super.dispose();
  }

  void _toggleVoiceInput() async {
    if (_isListening) {
      await VoiceService.instance.stopListening((isListening) {
        if (mounted) setState(() => _isListening = isListening);
      });
    } else {
      _preVoiceText = widget.state.todoInputController.text;
      await VoiceService.instance.startListening(
        onResult: (text) {
          if (mounted) {
            final newText = _preVoiceText.isEmpty
                ? text
                : '$_preVoiceText $text';
            widget.state.todoInputController.text = newText;
            widget.state.expandTodoComposer();
          }
        },
        onListeningStateChanged: (isListening) {
          if (mounted) setState(() => _isListening = isListening);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeProject = context.watch<ProjectState>().activeProject;
    final suggestedMinutes = state.estimatedTodoMinutesFor(
      state.newTodoEnergyRequirement,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: isDark ? 0.7 : 0.85,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.7),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bolt_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Quick capture',
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _isListening
                    ? Container(
                        key: const ValueKey<String>('voice-status-listening'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Listening',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activeProject != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: activeProject.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: activeProject.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Saving to ${activeProject.name}',
                    style: textTheme.labelMedium?.copyWith(
                      color: activeProject.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('todo-input'),
                  controller: state.todoInputController,
                  focusNode: state.todoInputFocusNode,
                  textInputAction: TextInputAction.done,
                  onTap: state.expandTodoComposer,
                  onChanged: (_) => state.expandTodoComposer(),
                  onSubmitted: (_) {
                    if (_isListening) _toggleVoiceInput();
                    state.addTodo(projectId: activeProject?.id);
                  },
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Add a task...',
                    hintStyle: _isListening
                        ? TextStyle(color: scheme.error)
                        : null,
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      key: const ValueKey<String>('todo-voice-button'),
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? scheme.error : scheme.primary,
                      ),
                      onPressed: _toggleVoiceInput,
                      tooltip: _isListening
                          ? 'Stop Listening'
                          : 'Voice Dictation',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey<String>('todo-add-button'),
                onPressed: () {
                  if (_isListening) _toggleVoiceInput();
                  state.addTodo(projectId: activeProject?.id);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: state.showTodoComposerDetails
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 10),
                      TaskDetailSections(
                        keyPrefix: 'todo',
                        energyRequirement: state.newTodoEnergyRequirement,
                        onEnergyChanged: state.setNewTodoEnergyRequirement,
                        estimateMinutes: state.newTodoEstimateMinutes,
                        onEstimateChanged: state.setNewTodoEstimateMinutes,
                        deadline: state.newTodoDeadline,
                        onDeadlineChanged: state.setNewTodoDeadline,
                        suggestedMinutes: suggestedMinutes,
                        onUseSuggestedEstimate: state.useSuggestedTodoEstimate,
                        estimateHelperText:
                            'Suggested: $suggestedMinutes min for ${state.newTodoEnergyRequirement.label.toLowerCase()} energy.',
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
