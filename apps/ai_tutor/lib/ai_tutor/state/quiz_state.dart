import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/repositories/quiz_repository.dart';
import '../models/enums.dart';
import '../models/quiz.dart';
import '../services/ai/ai_provider.dart';
import '../services/ai/api_key_store.dart';
import '../services/ai/openai_provider.dart';

class QuizState extends ChangeNotifier {
  QuizState({
    required QuizRepository quizRepository,
    required ApiKeyStore apiKeyStore,
  })  : _repo = quizRepository,
        _keyStore = apiKeyStore {
    loadQuizzes();
  }

  final QuizRepository _repo;
  final ApiKeyStore _keyStore;

  final Map<String, AiProvider> _providers = {
    'openai': OpenAiProvider(),
    'openrouter': OpenAiProvider(providerId: 'openrouter'),
  };

  // Quiz list
  List<Quiz> _quizzes = [];
  bool _isLoading = false;

  // Active quiz
  Quiz? _activeQuiz;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {};
  QuizAttempt? _activeAttempt;

  // Generation
  bool _isGenerating = false;
  String? _error;

  // Results
  double? _lastScore;

  // Getters
  List<Quiz> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Quiz? get activeQuiz => _activeQuiz;
  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get answers => _answers;
  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;
  bool get isLastQuestion => _currentQuestionIndex >= _questions.length - 1;
  bool get hasAnsweredCurrent => _answers.containsKey(_currentQuestionIndex);
  double? get lastScore => _lastScore;
  bool get isQuizActive => _activeQuiz != null && _activeAttempt != null;

  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();

    _quizzes = await _repo.getAll();

    _isLoading = false;
    notifyListeners();
  }

  /// Generate a quiz from content using the active AI provider.
  Future<void> generateQuiz({
    required String content,
    required String title,
    required QuizSourceType sourceType,
    required String sourceId,
    int questionCount = 5,
    List<QuestionType> questionTypes = const [
      QuestionType.multipleChoice,
      QuestionType.trueFalse,
    ],
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final activeId = await _keyStore.getActiveProviderId();
      if (activeId == null) throw Exception('No AI provider configured.');

      final configs = await _keyStore.getConfigs();
      final config = configs.firstWhere((c) => c.providerId == activeId);
      final apiKey = await _keyStore.getApiKey(activeId);
      if (apiKey == null) throw Exception('No API key found.');

      final provider = _providers[activeId];
      if (provider == null) throw Exception('Unknown provider: $activeId');

      final runtimeConfig = ProviderRuntimeConfig(
        apiKey: apiKey,
        model: config.model,
        baseUrl: config.baseUrl,
      );

      final typeNames = questionTypes.map((t) => t.name).toList();
      final request = QuizGenerationRequest(
        content: content,
        questionCount: questionCount,
        questionTypes: typeNames,
      );

      final responseText =
          await provider.generateQuiz(runtimeConfig, request);

      // Parse the JSON response
      final parsed = _parseQuizResponse(responseText, questionTypes);

      // Save to database
      await _repo.createQuiz(
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
        questions: parsed,
      );

      await loadQuizzes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Start taking a quiz.
  Future<void> startQuiz(Quiz quiz) async {
    _activeQuiz = quiz;
    _questions = await _repo.getQuestions(quiz.id);
    _currentQuestionIndex = 0;
    _answers = {};
    _lastScore = null;
    _activeAttempt = await _repo.startAttempt(quiz.id);
    notifyListeners();
  }

  /// Answer the current question.
  void answerQuestion(String answer) {
    _answers[_currentQuestionIndex] = answer;
    notifyListeners();
  }

  /// Move to the next question.
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Move to the previous question.
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Submit the quiz and calculate score.
  Future<double> submitQuiz() async {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final answer = _answers[i];
      if (answer != null &&
          answer.trim().toLowerCase() ==
              _questions[i].correctAnswer.trim().toLowerCase()) {
        correct++;
      }
    }

    final score =
        _questions.isEmpty ? 0.0 : (correct / _questions.length) * 100;
    _lastScore = score;

    if (_activeAttempt != null) {
      await _repo.completeAttempt(_activeAttempt!.id, score);
    }

    notifyListeners();
    return score;
  }

  /// Close the active quiz.
  void closeQuiz() {
    _activeQuiz = null;
    _questions = [];
    _currentQuestionIndex = 0;
    _answers = {};
    _activeAttempt = null;
    notifyListeners();
  }

  /// Delete a quiz.
  Future<void> deleteQuiz(String id) async {
    await _repo.deleteQuiz(id);
    await loadQuizzes();
  }

  List<QuizQuestion> _parseQuizResponse(
    String responseText,
    List<QuestionType> requestedTypes,
  ) {
    // Strip markdown code fences if present
    var cleaned = responseText.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }

    final json = jsonDecode(cleaned);
    final List<dynamic> questionsList;

    if (json is List) {
      questionsList = json;
    } else if (json is Map && json.containsKey('questions')) {
      questionsList = json['questions'] as List;
    } else {
      throw Exception('Unexpected quiz response format');
    }

    return questionsList.map((q) {
      final map = q as Map<String, dynamic>;
      final typeStr = map['type'] as String? ?? 'multipleChoice';
      final type = QuestionType.values.firstWhere(
        (t) => t.name == typeStr || t.name == _snakeToCamel(typeStr),
        orElse: () => QuestionType.multipleChoice,
      );

      final options = (map['options'] as List?)
              ?.map((o) => o.toString())
              .toList() ??
          [];

      return QuizQuestion(
        id: '', // Will be assigned by repository
        quizId: '', // Will be assigned by repository
        type: type,
        prompt: map['question'] as String? ?? map['prompt'] as String? ?? '',
        options: options,
        correctAnswer: map['correctAnswer'] as String? ??
            map['correct_answer'] as String? ??
            map['answer'] as String? ??
            '',
        explanation: map['explanation'] as String?,
      );
    }).toList();
  }

  String _snakeToCamel(String s) {
    final parts = s.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
