import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/quiz_state.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key, required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final quizState = context.read<QuizState>();
    final theme = Theme.of(context);

    final isPassing = score >= 70;
    final emoji = score >= 90
        ? 'Excellent!'
        : score >= 70
            ? 'Good job!'
            : score >= 50
                ? 'Keep practicing'
                : 'Study more';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score circle
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 12,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: isPassing
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.round()}%',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPassing
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(emoji, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${_correctCount(quizState)} of ${quizState.questions.length} correct',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Review answers
              if (quizState.questions.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Review', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: quizState.questions.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final q = quizState.questions[index];
                      final userAnswer = quizState.answers[index];
                      final isCorrect = userAnswer != null &&
                          userAnswer.trim().toLowerCase() ==
                              q.correctAnswer.trim().toLowerCase();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect
                                      ? Colors.green
                                      : theme.colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(q.prompt,
                                      style: theme.textTheme.bodyMedium),
                                ),
                              ],
                            ),
                            if (!isCorrect) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Text(
                                  'Your answer: ${userAnswer ?? "(skipped)"}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Text(
                                  'Correct: ${q.correctAnswer}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                            if (q.explanation != null) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Text(
                                  q.explanation!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Retake
                      final quiz = quizState.activeQuiz;
                      if (quiz != null) {
                        await quizState.startQuiz(quiz);
                        if (context.mounted) {
                          Navigator.pop(context); // Back to active quiz
                        }
                      }
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Retake'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      quizState.closeQuiz();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.done),
                    label: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _correctCount(QuizState quizState) {
    int count = 0;
    for (int i = 0; i < quizState.questions.length; i++) {
      final answer = quizState.answers[i];
      if (answer != null &&
          answer.trim().toLowerCase() ==
              quizState.questions[i].correctAnswer.trim().toLowerCase()) {
        count++;
      }
    }
    return count;
  }
}
