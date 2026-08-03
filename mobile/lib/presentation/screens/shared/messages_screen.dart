import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/misc.dart';
import '../../providers/providers.dart';

/// Contacts for the signed-in user — `GET /chat/contacts`.
final AutoDisposeFutureProvider<List<ChatContact>> chatContactsProvider =
    FutureProvider.autoDispose<List<ChatContact>>((Ref ref) {
      return ref.watch(supportRepositoryProvider).chatContacts();
    });

/// Conversation with one contact — `GET /chat/:targetUserId`.
final AutoDisposeFutureProviderFamily<List<DirectMessage>, String>
conversationProvider = FutureProvider.autoDispose
    .family<List<DirectMessage>, String>((Ref ref, String targetUserId) {
      return ref.watch(supportRepositoryProvider).messages(targetUserId);
    });

/// Port of `frontend/src/pages/dashboard/DoctorInbox.jsx`.
///
/// Parents see "Message Your Doctor" with every doctor listed; doctors see
/// "Messenger — Parent Messages" with the parents they have appointments or
/// history with. The web shows contacts and the thread side by side; on a phone
/// the contact list opens the thread.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final UserRole? role = ref.watch(currentRoleProvider);
    final bool isDoctor = role == UserRole.doctor;
    final AsyncValue<List<ChatContact>> contacts = ref.watch(
      chatContactsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(isDoctor ? 'Messenger' : 'Message Doctor')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(chatContactsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: palette.border),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary600.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      size: 26,
                      color: AppColors.primary600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isDoctor
                              ? 'Messenger — Parent Messages'
                              : 'Message Your Doctor',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isDoctor
                              ? 'Reply, send prescriptions, reminders, advice '
                                    'and follow-up messages.'
                              : 'Ask questions, send pictures, and receive '
                                    'replies from your pediatrician.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contacts panel
            Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: palette.border),
                boxShadow: AppShadows.sm,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      border: Border(bottom: BorderSide(color: palette.border)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 15,
                          color: palette.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDoctor
                              ? "My Patients' Parents"
                              : 'Available Doctors',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  contacts.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'LOADING CONTACTS...',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    error: (Object error, StackTrace _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: ErrorBanner(
                        message: error is ApiException
                            ? error.detailedMessage
                            : error.toString(),
                      ),
                    ),
                    data: (List<ChatContact> items) {
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: palette.surfaceSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: palette.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No contacts yet',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isDoctor
                                    ? 'Parents will appear after appointments.'
                                    : 'Book an appointment to message a doctor.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: items
                            .map(
                              (ChatContact c) => _ContactRow(
                                contact: c,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext ctx) =>
                                        ConversationScreen(contact: c),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.onTap});

  final ChatContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: <Widget>[
            InitialsAvatar(initials: _initials(contact.name), size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final List<String> parts = name
        .replaceAll(RegExp(r'\(.*\)'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty && p != 'Dr.')
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// The thread — `GET /chat/:targetUserId` and `POST /chat`.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.contact});

  final ChatContact contact;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .sendMessage(receiverId: widget.contact.id, content: text);
      _input.clear();
      ref.invalidate(conversationProvider(widget.contact.id));
      await ref.read(conversationProvider(widget.contact.id).future);
      _scrollToEnd();
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final String? myId = ref.watch(currentUserProvider)?.id;
    final AsyncValue<List<DirectMessage>> thread = ref.watch(
      conversationProvider(widget.contact.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            InitialsAvatar(
              initials: _ContactRow._initials(widget.contact.name),
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    widget.contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    widget.contact.role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: thread.when(
              loading: () => const LoadingView(),
              error: (Object error, StackTrace _) => ErrorView(
                message: error is ApiException
                    ? error.detailedMessage
                    : error.toString(),
                onRetry: () =>
                    ref.invalidate(conversationProvider(widget.contact.id)),
              ),
              data: (List<DirectMessage> messages) {
                if (messages.isEmpty) {
                  return const EmptyView(
                    title: 'No messages yet',
                    message:
                        'Send the first message to start the conversation.',
                    icon: Icons.chat_bubble_outline_rounded,
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: AppSpacing.page,
                  itemCount: messages.length,
                  itemBuilder: (BuildContext context, int i) {
                    final DirectMessage m = messages[i];
                    return _Bubble(message: m, mine: m.senderId == myId);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _send,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(48),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
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
  const _Bubble({required this.message, required this.mine});

  final DirectMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mine ? Colors.white : palette.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              Fmt.time(message.createdAt),
              style: TextStyle(
                fontSize: 9.5,
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
