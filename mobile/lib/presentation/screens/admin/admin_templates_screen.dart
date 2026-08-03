import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/misc.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/admin/ManageChatbotTemplates.jsx` — the intro
/// card, the inline Create/Edit form and the template list.
class AdminTemplatesScreen extends ConsumerStatefulWidget {
  const AdminTemplatesScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  ConsumerState<AdminTemplatesScreen> createState() =>
      _AdminTemplatesScreenState();
}

class _AdminTemplatesScreenState extends ConsumerState<AdminTemplatesScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _keyword = TextEditingController();
  final TextEditingController _response = TextEditingController();

  String? _editingId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _keyword.dispose();
    _response.dispose();
    super.dispose();
  }

  void _startEdit(ChatbotTemplate template) {
    setState(() {
      _editingId = template.id;
      _keyword.text = template.triggerKeyword;
      _response.text = template.response;
      _error = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _keyword.clear();
      _response.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(chatbotRepositoryProvider)
          .saveTemplate(
            triggerKeyword: _keyword.text.trim(),
            response: _response.text.trim(),
          );
      ref.invalidate(chatbotTemplatesProvider);
      if (!mounted) return;
      _cancelEdit();
      Toast.success(context, 'Template saved');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(ChatbotTemplate template) async {
    final bool ok = await confirmAction(
      context,
      title: 'Delete template',
      message: 'Remove the override for "${template.triggerKeyword}"?',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    try {
      await ref.read(chatbotRepositoryProvider).deleteTemplate(template.id);
      ref.invalidate(chatbotTemplatesProvider);
      if (mounted) Toast.success(context, 'Template deleted');
    } on ApiException catch (error) {
      if (mounted) Toast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ChatbotTemplate>> templates = ref.watch(
      chatbotTemplatesProvider,
    );
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Chatbot Templates'))
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(chatbotTemplatesProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            // Intro card
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Manage Chatbot Templates',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Add trigger keywords and response templates used by the AI '
                    'engine. Use comma-separated keywords for broader coverage.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Inline create / edit form
            _Card(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      _editingId == null ? 'Create Template' : 'Edit Template',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...<Widget>[
                      ErrorBanner(message: _error ?? ''),
                      const SizedBox(height: 16),
                    ],
                    _Label('Trigger Keywords', palette: palette),
                    TextFormField(
                      controller: _keyword,
                      decoration: const InputDecoration(
                        hintText: 'fever, high temperature, child fever',
                      ),
                      validator: Validators.triggerKeyword,
                    ),
                    const SizedBox(height: 16),
                    _Label('Templated Response', palette: palette),
                    TextFormField(
                      controller: _response,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Provide safe pediatric guidance...',
                        alignLabelWithHint: true,
                      ),
                      validator: Validators.templateResponse,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: PrimaryButton(
                            label: _editingId == null
                                ? 'Create Template'
                                : 'Update Template',
                            icon: _editingId == null
                                ? Icons.add_rounded
                                : Icons.save_rounded,
                            isLoading: _busy,
                            onPressed: _submit,
                          ),
                        ),
                        if (_editingId != null) ...<Widget>[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _cancelEdit,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            templates.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: LoadingView(),
              ),
              error: (Object error, StackTrace _) => ErrorBanner(
                message: error is ApiException
                    ? error.detailedMessage
                    : error.toString(),
              ),
              data: (List<ChatbotTemplate> items) {
                if (items.isEmpty) {
                  return const EmptyView(
                    title: 'No keyword templates',
                    message:
                        'Add a keyword override above to answer common '
                        'questions instantly, without calling the AI model.',
                    icon: Icons.smart_toy_outlined,
                  );
                }
                return Column(
                  children: items
                      .map(
                        (ChatbotTemplate t) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TemplateCard(
                            template: t,
                            onEdit: () => _startEdit(t),
                            onDelete: () => _delete(t),
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
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.sm,
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.palette});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final ChatbotTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<String> keywords = template.triggerKeyword
        .split(',')
        .map((String k) => k.trim())
        .where((String k) => k.isNotEmpty)
        .toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: keywords
                      .map(
                        (String k) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.violet.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            k,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.violet,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: palette.textMuted,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.response,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
