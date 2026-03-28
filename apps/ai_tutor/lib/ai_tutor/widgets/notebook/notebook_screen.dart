import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../models/enums.dart';
import '../../models/notebook.dart';
import '../../state/ink_state.dart';
import '../../state/notebook_state.dart';
import '../chat/ai_chat_panel.dart';
import 'ink_canvas.dart';
import 'floating_tool_palette.dart';

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key, required this.notebook});

  final Notebook notebook;

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    // Load notebook and first page strokes after frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notebookState = context.read<NotebookState>();
      await notebookState.loadNotebook(widget.notebook);
      _loadCurrentPageStrokes();
    });
  }

  Future<void> _loadCurrentPageStrokes() async {
    final notebookState = context.read<NotebookState>();
    final inkState = context.read<InkState>();
    final page = notebookState.currentPage;
    if (page == null) return;

    final repo = context.read<NotebookRepository>();
    final strokes = await repo.getStrokes(page.id);
    inkState.loadStrokes(strokes);
  }

  @override
  Widget build(BuildContext context) {
    final notebookState = context.watch<NotebookState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notebook.title),
        actions: [
          // Page indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                notebookState.pageCount > 0
                    ? 'Page ${notebookState.currentPageIndex + 1} / ${notebookState.pageCount}'
                    : '',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          // Page navigation
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: notebookState.hasPreviousPage
                ? () {
                    notebookState.previousPage();
                    _loadCurrentPageStrokes();
                  }
                : null,
            tooltip: 'Previous page',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: notebookState.hasNextPage
                ? () {
                    notebookState.nextPage();
                    _loadCurrentPageStrokes();
                  }
                : null,
            tooltip: 'Next page',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await notebookState.addPage();
              _loadCurrentPageStrokes();
            },
            tooltip: 'Add page',
          ),
          const VerticalDivider(),
          IconButton(
            icon: Icon(_showChat ? Icons.chat : Icons.chat_outlined),
            onPressed: () => setState(() => _showChat = !_showChat),
            tooltip: 'AI Chat',
            color: _showChat ? theme.colorScheme.primary : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notebookState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Main canvas area
                Expanded(
                  child: Stack(
                    children: [
                      // Paper background
                      Positioned.fill(
                        child: Container(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          child: const InkCanvas(),
                        ),
                      ),
                      // Floating tool palette (left side)
                      const Positioned(
                        left: 16,
                        top: 16,
                        child: FloatingToolPalette(),
                      ),
                    ],
                  ),
                ),
                // Page thumbnail sidebar
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('Pages',
                            style: theme.textTheme.labelMedium),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: notebookState.pageCount,
                          itemBuilder: (context, index) {
                            final isActive =
                                index == notebookState.currentPageIndex;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  notebookState.goToPage(index);
                                  _loadCurrentPageStrokes();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isActive
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant,
                                      width: isActive ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: isActive
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // AI Chat panel
                if (_showChat)
                  Container(
                    width: 360,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: AiChatPanel(
                      targetType: ConversationTargetType.notebook,
                      targetId: widget.notebook.id,
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    // Don't close notebook state here — it's provided above
    super.dispose();
  }
}
