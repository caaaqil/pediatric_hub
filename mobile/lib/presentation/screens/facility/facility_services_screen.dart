import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/facility.dart';
import '../../providers/providers.dart';

/// `/health-services` CRUD, scoped to the caller's facility by the
/// `requireFacilityScope` middleware.
class FacilityServicesScreen extends ConsumerWidget {
  const FacilityServicesScreen({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    HealthService? service,
  }) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => _ServiceSheet(service: service),
    );
    if (saved == true) {
      ref.invalidate(myHealthServicesProvider);
      ref.invalidate(facilityScopeProvider);
      if (context.mounted) Toast.success(context, 'Service saved');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HealthService>> services = ref.watch(
      myHealthServicesProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: AsyncView<List<HealthService>>(
        value: services,
        onRefresh: () => ref.refresh(myHealthServicesProvider.future),
        isEmpty: (List<HealthService> items) => items.isEmpty,
        emptyIcon: Icons.medical_information_outlined,
        emptyTitle: 'No services published',
        emptyMessage:
            'Publish the services your facility offers so parents can see them.',
        emptyActionLabel: 'Add service',
        onEmptyAction: () => _openForm(context, ref),
        builder: (List<HealthService> items) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.pageBottom,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (BuildContext context, int index) {
            final HealthService service = items[index];
            return AppCard(
              onTap: () => _openForm(context, ref, service: service),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      StatusBadge(
                        label: service.isActive ? 'Active' : 'Hidden',
                        color: service.isActive
                            ? AppColors.success
                            : AppColors.lightTextMuted,
                        dense: true,
                      ),
                    ],
                  ),
                  if (service.description != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      service.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Text(
                        service.price == null
                            ? 'No price set'
                            : Fmt.money(service.price ?? 0),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Archive',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.danger,
                        ),
                        onPressed: () async {
                          final bool ok = await confirmAction(
                            context,
                            title: 'Archive service',
                            message: 'Remove "${service.name}" from your list?',
                            confirmLabel: 'Archive',
                          );
                          if (!ok || !context.mounted) return;
                          try {
                            await ref
                                .read(facilityRepositoryProvider)
                                .archiveService(service.id);
                            ref.invalidate(myHealthServicesProvider);
                            ref.invalidate(facilityScopeProvider);
                            if (context.mounted) {
                              Toast.success(context, 'Service archived');
                            }
                          } on ApiException catch (error) {
                            if (context.mounted) Toast.error(context, error);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add service'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ServiceSheet extends ConsumerStatefulWidget {
  const _ServiceSheet({this.service});

  final HealthService? service;

  @override
  ConsumerState<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends ConsumerState<_ServiceSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.service?.name ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.service?.description ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.service?.price == null
        ? ''
        : (widget.service?.price ?? 0).toStringAsFixed(2),
  );

  late bool _active = widget.service?.isActive ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final String priceText = _price.text.trim();
    final double? price = priceText.isEmpty ? null : double.tryParse(priceText);

    try {
      final HealthService? existing = widget.service;
      if (existing == null) {
        await ref
            .read(facilityRepositoryProvider)
            .createService(
              name: _name.text.trim(),
              description: _description.text.trim(),
              price: price,
              isActive: _active,
            );
      } else {
        await ref
            .read(facilityRepositoryProvider)
            .updateService(
              id: existing.id,
              name: _name.text.trim(),
              description: _description.text.trim(),
              price: price,
              isActive: _active,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.service == null ? 'Add service' : 'Edit service',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Service name'),
                validator: Validators.serviceName,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                validator: (String? v) =>
                    Validators.maxLength(v, 2000, 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price (optional)',
                  prefixText: r'$ ',
                ),
                validator: Validators.optionalPrice,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile.adaptive(
                value: _active,
                onChanged: (bool value) => setState(() => _active = value),
                title: const Text('Visible to parents'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Save service',
                isLoading: _busy,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
