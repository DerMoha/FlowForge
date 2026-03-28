import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import '../../models/document.dart';
import '../../models/enums.dart';
import '../../state/document_state.dart';
import '../chat/ai_chat_panel.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key, required this.document});

  final ImportedDocument document;

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final PdfViewerController _controller = PdfViewerController();
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentState>().loadDocument(widget.document);
    });
  }

  @override
  Widget build(BuildContext context) {
    final docState = context.watch<DocumentState>();
    final theme = Theme.of(context);
    final sourceUri = widget.document.sourceUri;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          if (docState.pageCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Page ${docState.currentPageIndex + 1} / ${docState.pageCount}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _controller.zoomDown(),
            tooltip: 'Zoom out',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _controller.zoomUp(),
            tooltip: 'Zoom in',
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
      body: docState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(child: _buildPdfViewer(sourceUri, docState)),
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
                      targetType: ConversationTargetType.document,
                      targetId: widget.document.id,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPdfViewer(String sourceUri, DocumentState docState) {
    final file = File(sourceUri);
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            const Text('PDF file not found'),
          ],
        ),
      );
    }

    return PdfViewer.file(
      sourceUri,
      controller: _controller,
      params: PdfViewerParams(
        onViewerReady: (document, controller) {
          docState.updatePageCount(document.pages.length);
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
