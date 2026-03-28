import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../../state/library_state.dart';
import '../../models/notebook.dart';
import '../../models/document.dart';
import '../../state/document_state.dart';
import '../document/document_screen.dart';
import '../notebook/notebook_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: library.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Library',
                            style: AppTypography.heading(context)),
                        const SizedBox(height: 8),
                        Text(
                          '${library.notebookCount} notebooks, '
                          '${library.documentCount} documents',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action buttons
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _createNotebook(context),
                              icon: const Icon(Icons.note_add),
                              label: const Text('New Notebook'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _importDocument(context),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Import PDF'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Notebooks section
                if (library.notebooks.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Text('Notebooks',
                          style: theme.textTheme.titleMedium),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: library.notebooks.length,
                      itemBuilder: (context, index) {
                        return _NotebookCard(
                            notebook: library.notebooks[index]);
                      },
                    ),
                  ),
                ],
                // Documents section
                if (library.documents.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: Text('Documents',
                          style: theme.textTheme.titleMedium),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: library.documents.length,
                      itemBuilder: (context, index) {
                        return _DocumentCard(
                            document: library.documents[index]);
                      },
                    ),
                  ),
                ],
                // Empty state
                if (library.notebooks.isEmpty && library.documents.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('No notebooks or documents yet',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Create a notebook or import a PDF to start',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _createNotebook(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Notebook'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Math 101',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                context.read<LibraryState>().createNotebook(title: title);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importDocument(BuildContext context) async {
    final docState = context.read<DocumentState>();
    final doc = await docState.importPdf();
    if (doc != null && context.mounted) {
      // Refresh library list is automatic via stream
    }
  }
}

class _NotebookCard extends StatelessWidget {
  const _NotebookCard({required this.notebook});

  final Notebook notebook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotebookScreen(notebook: notebook),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.book, color: theme.colorScheme.primary, size: 32),
            const Spacer(),
            Text(notebook.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (notebook.subject != null) ...[
              const SizedBox(height: 4),
              Text(notebook.subject!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final ImportedDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentScreen(document: document),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.picture_as_pdf,
                color: theme.colorScheme.error, size: 32),
            const Spacer(),
            Text(document.title,
                style: theme.textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${document.pageCount} pages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}
