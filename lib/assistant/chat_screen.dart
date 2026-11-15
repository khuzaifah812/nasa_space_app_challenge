// The assistant: a chat that answers from the field's NASA figures and the
// crop table (always), and from an AI model when one is set up.
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'context.dart';
import 'knowledge.dart';
import 'llm.dart';
import 'offline.dart';
import 'settings.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _settings = AssistantSettings.fromEnv;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // after the first frame, so the button hides without interrupting the build
    WidgetsBinding.instance.addPostFrameCallback((_) => AssistantContext.chatOpen.value = true);
    _messages.add(ChatMessage('assistant', t('as_intro')));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) => AssistantContext.chatOpen.value = false);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _messages.add(ChatMessage('user', q));
      _busy = true;
    });
    _jump();
    final a = AssistantContext.analysis.value;
    String reply;
    if (_settings.online) {
      try {
        reply = await askModel(_settings, _messages, fieldKnowledge(a));
      } catch (_) {
        // no connection, or the AI service refused: answer from memory
        reply = '${offlineAnswer(q, a)}\n\n${t('as_connect')}';
      }
    } else {
      reply = '${offlineAnswer(q, a)}\n\n${t('as_connect')}';
    }
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage('assistant', reply.trim()));
      _busy = false;
    });
    _jump();
  }

  void _jump() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(padding: EdgeInsets.all(10), child: AgriSmartLogo(size: 36)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('as_title')),
            Text(_settings.online ? t('as_online') : t('as_offline'),
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                final m = _messages[i];
                final mine = m.role == 'user';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: mine ? scheme.primary : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: mine ? null : Border.all(color: scheme.outlineVariant),
                    ),
                    child: SelectableText(m.text,
                        style: TextStyle(
                            color: mine ? scheme.onPrimary : scheme.onSurface, height: 1.4)),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final q in quickQuestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(label: Text(t(q)), onPressed: () => _send(t(q))),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: t('as_hint'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: t('as_send'),
                    onPressed: _busy ? null : () => _send(_input.text),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(backgroundColor: green, minimumSize: const Size(48, 48)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The round button that opens the assistant, shown over every screen.
class AssistantButton extends StatelessWidget {
  const AssistantButton({super.key, required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AssistantContext.chatOpen,
      builder: (context, open, _) => open
          ? const SizedBox()
          : FloatingActionButton.extended(
              heroTag: 'assistant',
              backgroundColor: green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(t('as_button')),
              onPressed: () => navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(builder: (_) => const ChatScreen())),
            ),
    );
  }
}
