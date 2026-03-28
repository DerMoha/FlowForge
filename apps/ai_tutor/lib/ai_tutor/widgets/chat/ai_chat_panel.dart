import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../state/ai_chat_state.dart';

/// Side panel for AI chat, can be embedded in notebook or document screens.
class AiChatPanel extends StatefulWidget {
  const AiChatPanel({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  final ConversationTargetType targetType;
  final String targetId;

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiChatState>().openConversation(
            targetType: widget.targetType,
            targetId: widget.targetId,
          );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AiChatState>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<AiChatState>();
    final theme = Theme.of(context);

    // Auto-scroll when new messages arrive or streaming
    if (chatState.messages.isNotEmpty || chatState.isStreaming) {
      _scrollToBottom();
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('AI Tutor', style: theme.textTheme.titleSmall),
              const Spacer(),
              if (chatState.activeConfig != null)
                Chip(
                  label: Text(
                    chatState.activeConfig!.label,
                    style: theme.textTheme.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: chatState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : chatState.messages.isEmpty && !chatState.isStreaming
                  ? _buildEmptyState(theme)
                  : _buildMessageList(chatState, theme),
        ),

        // Error banner
        if (chatState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.errorContainer,
            child: Text(
              chatState.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),

        // Input
        _buildInput(chatState, theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Ask me anything about your material',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(AiChatState chatState, ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: chatState.messages.length + (chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatState.messages.length && chatState.isStreaming) {
          // Streaming message bubble
          return _MessageBubble(
            content: chatState.streamingContent,
            isUser: false,
            isStreaming: true,
          );
        }
        final message = chatState.messages[index];
        return _MessageBubble(
          content: message.content,
          isUser: message.role == MessageRole.user,
        );
      },
    );
  }

  Widget _buildInput(AiChatState chatState, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: chatState.hasActiveProvider
                    ? 'Ask a question...'
                    : 'Configure a provider in Settings first',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              enabled: chatState.hasActiveProvider && !chatState.isStreaming,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: chatState.hasActiveProvider && !chatState.isStreaming
                ? _send
                : null,
            icon: chatState.isStreaming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  });

  final String content;
  final bool isUser;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
          ),
          child: content.isEmpty && isStreaming
              ? SizedBox(
                  width: 24,
                  height: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Icon(Icons.circle,
                            size: 6,
                            color: theme.colorScheme.onSurfaceVariant),
                      );
                    }),
                  ),
                )
              : SelectableText(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
