import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/misc.dart';
import '../../../data/repositories/chatbot_repository.dart';
import '../../providers/providers.dart';

/// PediaBot — `POST /chatbot/session`, `/:sessionId/chat`, `/:sessionId/history`,
/// `/sessions` and `/:sessionId/close`.
///
/// The backend answers in Somali by default (`language: 'so'`) with English
/// available; both are offered here.
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<ChatbotMessage> _messages = <ChatbotMessage>[];
  String? _sessionId;
  String _language = 'so';
  bool _booting = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _boot({bool forceNew = false}) async {
    setState(() {
      _booting = true;
      _error = null;
    });
    try {
      final ChatbotRepository repo = ref.read(chatbotRepositoryProvider);
      final ChatbotSession session = await repo.startSession(
        forceNew: forceNew,
        language: _language,
      );
      final List<ChatbotMessage> history = await repo.history(session.id);

      if (!mounted) return;
      setState(() {
        _sessionId = session.id;
        _language = session.language;
        _messages
          ..clear()
          ..addAll(history);
      });
      _scrollToEnd();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  Future<void> _newChat() async {
    final String? current = _sessionId;
    try {
      if (current != null) {
        await ref.read(chatbotRepositoryProvider).closeSession(current);
        ref.invalidate(chatbotSessionsProvider);
      }
    } on ApiException {
      // Closing is best-effort; a new session is created either way.
    }
    await _boot(forceNew: true);
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    final String? sessionId = _sessionId;
    if (text.isEmpty || sessionId == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
      _messages.add(ChatbotMessage.local(sessionId: sessionId, message: text));
    });
    _input.clear();
    _scrollToEnd();

    try {
      final ChatbotMessage reply = await ref
          .read(chatbotRepositoryProvider)
          .send(sessionId: sessionId, message: text, language: _language);
      if (!mounted) return;
      setState(() => _messages.add(reply));
      _scrollToEnd();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openHistory() async {
    final ChatbotSession? picked = await showModalBottomSheet<ChatbotSession>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _HistorySheet(),
    );
    if (picked == null) return;

    setState(() {
      _booting = true;
      _error = null;
    });
    try {
      final List<ChatbotMessage> history = await ref
          .read(chatbotRepositoryProvider)
          .history(picked.id);
      if (!mounted) return;
      setState(() {
        _sessionId = picked.id;
        _language = picked.language;
        _messages
          ..clear()
          ..addAll(history);
      });
      _scrollToEnd();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _booting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showAppBar,
        // Inside the parent shell this sits under the account header, so keep
        // it slim; as a standalone route it gets the normal toolbar height.
        toolbarHeight: widget.showAppBar ? null : 52,
        title: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.14),
                borderRadius: AppRadius.smAll,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('PediaBot'),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate_rounded),
            onSelected: (String value) => setState(() => _language = value),
            itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
              CheckedPopupMenuItem<String>(
                value: 'so',
                checked: _language == 'so',
                child: const Text('Af Soomaali'),
              ),
              CheckedPopupMenuItem<String>(
                value: 'en',
                checked: _language == 'en',
                child: const Text('English'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Chat history',
            onPressed: _openHistory,
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'New chat',
            onPressed: _booting ? null : _newChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ErrorBanner(message: _error ?? ''),
            ),
          Expanded(
            child: _booting
                ? const LoadingView(message: 'Starting your session…')
                : _messages.isEmpty
                ? _Suggestions(
                    language: _language,
                    onPick: (String prompt) {
                      _input.text = prompt;
                      _send();
                    },
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: AppSpacing.page,
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) =>
                        _Bubble(message: _messages[index]),
                  ),
          ),
          if (_sending)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'PediaBot is thinking…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: _language == 'so'
                            ? 'Wax su\'aal ah qor…'
                            : 'Ask a question…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending || _booting ? null : _send,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(48),
                      ),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatbotMessage message;

  @override
  Widget build(BuildContext context) {
    final bool mine = message.isFromUser;
    final AppPalette palette = context.palette;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary600 : palette.surface,
          border: mine ? null : Border.all(color: palette.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.md),
            topRight: const Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(mine ? AppRadius.md : 4),
            bottomRight: Radius.circular(mine ? 4 : AppRadius.md),
          ),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mine ? Colors.white : palette.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Fmt.time(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? Colors.white.withValues(alpha: 0.75)
                    : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.language, required this.onPick});

  final String language;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final List<String> prompts = language == 'so'
        ? <String>[
            'Waa maxay ORS?',
            'Sidee ayaan u yareeyaa xummadda cunugayga?',
            'Tallaalada 9 bilood waa kuwee?',
            'Cunuggaygu 6 bilood buu jiraa — maxaan quudiyaa?',
          ]
        : <String>[
            'What is ORS and when should I use it?',
            'How do I manage my baby fever at home?',
            'Which vaccines are due at 9 months?',
            'What foods can I start at 6 months?',
          ];

    return ListView(
      padding: AppSpacing.page,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppCardHeader(
                title: 'PediaBot',
                subtitle: 'Pediatric guidance in Somali or English',
                icon: Icons.smart_toy_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                language == 'so'
                    ? 'Waydii su\'aal ku saabsan caafimaadka cunugaaga. Xaalad degdeg ah, wac 252-1.'
                    : 'Ask anything about your child\'s health. In a true emergency, call 252-1.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Try asking'),
        ...prompts.map(
          (String prompt) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => onPick(prompt),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppColors.violet,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      prompt,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// `GET /chatbot/sessions` — up to 25 archived conversations.
class _HistorySheet extends ConsumerWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChatbotSession>> sessions = ref.watch(
      chatbotSessionsProvider,
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Chat history', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: sessions.when(
                loading: () => const LoadingView(),
                error: (Object error, StackTrace _) => ErrorView(
                  message: error is ApiException
                      ? error.detailedMessage
                      : error.toString(),
                  onRetry: () => ref.invalidate(chatbotSessionsProvider),
                ),
                data: (List<ChatbotSession> items) {
                  if (items.isEmpty) {
                    return const EmptyView(
                      title: 'No past chats',
                      message:
                          'Conversations appear here after you start a new chat.',
                      icon: Icons.history_rounded,
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int index) {
                      final ChatbotSession session = items[index];
                      return AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        onTap: () => Navigator.of(context).pop(session),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    session.displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${session.language.toUpperCase()} · ${Fmt.relative(session.createdAt)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
