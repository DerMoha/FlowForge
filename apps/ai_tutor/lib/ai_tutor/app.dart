import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/database/ai_tutor_database.dart';
import 'data/repositories/notebook_repository.dart';
import 'data/repositories/document_repository.dart';
import 'data/repositories/ai_repository.dart';
import 'data/repositories/quiz_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'services/ai/api_key_store.dart';
import 'services/pdf_service.dart';
import 'services/speech_service.dart';
import 'services/xp_event_service.dart';
import 'state/ai_chat_state.dart';
import 'state/document_state.dart';
import 'state/ink_state.dart';
import 'state/library_state.dart';
import 'state/notebook_state.dart';
import 'state/provider_config_state.dart';
import 'state/quiz_state.dart';
import 'state/progress_state.dart';
import 'state/voice_tutor_state.dart';
import 'theme/tutor_theme.dart';
import 'widgets/navigation/nav_shell.dart';

class AiTutorApp extends StatefulWidget {
  const AiTutorApp({super.key});

  @override
  State<AiTutorApp> createState() => _AiTutorAppState();
}

class _AiTutorAppState extends State<AiTutorApp> {
  late final AiTutorDatabase _db;
  late final NotebookRepository _notebookRepo;
  late final DocumentRepository _documentRepo;
  late final AiRepository _aiRepo;
  late final QuizRepository _quizRepo;
  late final ProgressRepository _progressRepo;
  late final PdfService _pdfService;
  late final ApiKeyStore _apiKeyStore;
  late final SpeechService _speechService;
  late final XpEventService _xpEventService;

  @override
  void initState() {
    super.initState();
    _db = AiTutorDatabase();
    _notebookRepo = NotebookRepository(_db);
    _documentRepo = DocumentRepository(_db);
    _aiRepo = AiRepository(_db);
    _quizRepo = QuizRepository(_db);
    _progressRepo = ProgressRepository(_db);
    _pdfService = PdfService();
    _apiKeyStore = ApiKeyStore();
    _speechService = SpeechService();
    _xpEventService = XpEventService();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database & Repositories
        Provider<AiTutorDatabase>.value(value: _db),
        Provider<NotebookRepository>.value(value: _notebookRepo),
        Provider<DocumentRepository>.value(value: _documentRepo),
        Provider<AiRepository>.value(value: _aiRepo),
        Provider<QuizRepository>.value(value: _quizRepo),
        Provider<ProgressRepository>.value(value: _progressRepo),

        // State providers
        ChangeNotifierProvider(
          create: (_) => LibraryState(
            notebookRepository: _notebookRepo,
            documentRepository: _documentRepo,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotebookState(notebookRepository: _notebookRepo),
        ),
        ChangeNotifierProvider(create: (_) => InkState()),
        ChangeNotifierProvider(
          create: (_) => DocumentState(
            documentRepository: _documentRepo,
            pdfService: _pdfService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AiChatState(
            aiRepository: _aiRepo,
            apiKeyStore: _apiKeyStore,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProviderConfigState(apiKeyStore: _apiKeyStore),
        ),
        ChangeNotifierProvider(
          create: (_) => QuizState(
            quizRepository: _quizRepo,
            apiKeyStore: _apiKeyStore,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceTutorState(
            speechService: _speechService,
            apiKeyStore: _apiKeyStore,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressState(
            progressRepository: _progressRepo,
            xpEventService: _xpEventService,
          ),
        ),
        Provider<PdfService>.value(value: _pdfService),
        Provider<ApiKeyStore>.value(value: _apiKeyStore),
        Provider<SpeechService>.value(value: _speechService),
        Provider<XpEventService>.value(value: _xpEventService),
      ],
      child: MaterialApp(
        title: 'AI Tutor',
        debugShowCheckedModeBanner: false,
        theme: TutorTheme.light(),
        darkTheme: TutorTheme.dark(),
        themeMode: ThemeMode.system,
        home: const NavShell(),
      ),
    );
  }
}
