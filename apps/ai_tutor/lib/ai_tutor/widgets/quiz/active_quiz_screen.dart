import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../state/quiz_state.dart';
import 'quiz_results_screen.dart';

class ActiveQuizScreen extends StatelessWidget {
  const ActiveQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quizState = context.watch<QuizState>();
    final theme = Theme.of(context);
    final question = quizState.currentQuestion;

    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quizState.activeQuiz?.title ?? 'Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            quizState.closeQuiz();
            Navigator.pop(context);
          },
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Question ${quizState.currentQuestionIndex + 1} / ${quizState.questions.length}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (quizState.currentQuestionIndex + 1) /
                  quizState.questions.length,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 32),

            // Question prompt
            Text(question.prompt, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Answer area
            Expanded(
              child: _buildAnswerArea(context, quizState, question, theme),
            ),

            // Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: quizState.currentQuestionIndex > 0
                      ? () => quizState.previousQuestion()
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                ),
                if (quizState.isLastQuestion)
                  FilledButton.icon(
                    onPressed: quizState.hasAnsweredCurrent
                        ? () => _submit(context, quizState)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Submit'),
                  )
                else
                  FilledButton.icon(
                    onPressed: quizState.hasAnsweredCurrent
                        ? () => quizState.nextQuestion()
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerArea(
    BuildContext context,
    QuizState quizState,
    dynamic question,
    ThemeData theme,
  ) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _MultipleChoiceAnswers(
          options: question.options,
          selectedAnswer: quizState.answers[quizState.currentQuestionIndex],
          onSelected: (answer) => quizState.answerQuestion(answer),
        );
      case QuestionType.trueFalse:
        return _TrueFalseAnswers(
          selectedAnswer: quizState.answers[quizState.currentQuestionIndex],
          onSelected: (answer) => quizState.answerQuestion(answer),
        );
      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        return _TextAnswer(
          currentAnswer: quizState.answers[quizState.currentQuestionIndex],
          onChanged: (answer) => quizState.answerQuestion(answer),
        );
      default:
        return _TextAnswer(
          currentAnswer: quizState.answers[quizState.currentQuestionIndex],
          onChanged: (answer) => quizState.answerQuestion(answer),
        );
    }
  }

  Future<void> _submit(BuildContext context, QuizState quizState) async {
    final score = await quizState.submitQuiz();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultsScreen(score: score),
        ),
      );
    }
  }
}

class _MultipleChoiceAnswers extends StatelessWidget {
  const _MultipleChoiceAnswers({
    required this.options,
    required this.selectedAnswer,
    required this.onSelected,
  });

  final List<String> options;
  final String? selectedAnswer;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedAnswer == option;
        return InkWell(
          onTap: () => onSelected(option),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(option, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrueFalseAnswers extends StatelessWidget {
  const _TrueFalseAnswers({
    required this.selectedAnswer,
    required this.onSelected,
  });

  final String? selectedAnswer;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: ['True', 'False'].map((option) {
        final isSelected = selectedAnswer == option;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == 'True' ? 8 : 0,
              left: option == 'False' ? 8 : 0,
            ),
            child: InkWell(
              onTap: () => onSelected(option),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3)
                      : null,
                ),
                child: Center(
                  child: Text(
                    option,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TextAnswer extends StatefulWidget {
  const _TextAnswer({
    required this.currentAnswer,
    required this.onChanged,
  });

  final String? currentAnswer;
  final ValueChanged<String> onChanged;

  @override
  State<_TextAnswer> createState() => _TextAnswerState();
}

class _TextAnswerState extends State<_TextAnswer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAnswer ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Type your answer...',
      ),
      maxLines: 3,
    );
  }
}
