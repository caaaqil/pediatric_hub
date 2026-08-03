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
import '../../../data/models/enums.dart';
import '../../../data/models/misc.dart';
import '../../providers/providers.dart';

/// `GET /payments` and `POST /payments` (EVC Plus / WaafiPay).
///
/// These two endpoints bypass the standard response wrapper: the POST answers
/// `{ success, data, message }` with HTTP 402 when the charge is declined.
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final bool? paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _PaymentSheet(),
    );
    if (paid == true) ref.invalidate(paymentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Payment>> payments = ref.watch(paymentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: AsyncView<List<Payment>>(
        value: payments,
        onRefresh: () => ref.refresh(paymentsProvider.future),
        isEmpty: (List<Payment> items) => items.isEmpty,
        emptyIcon: Icons.receipt_long_outlined,
        emptyTitle: 'No payments yet',
        emptyMessage:
            'Payments made with EVC Plus appear here with their invoice IDs.',
        emptyActionLabel: 'Make a payment',
        onEmptyAction: () => _pay(context, ref),
        builder: (List<Payment> items) {
          final double paidTotal = items
              .where((Payment p) => p.status == PaymentStatus.paid)
              .fold<double>(0, (double sum, Payment p) => sum + p.amount);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageBottom,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      label: 'Total paid',
                      value: Fmt.money(paidTotal),
                      icon: Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      label: 'Transactions',
                      value: '${items.length}',
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'History'),
              ...items.map(
                (Payment payment) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                Fmt.money(
                                  payment.amount,
                                  currency: payment.currency,
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            StatusBadge(
                              label: payment.status.label,
                              color: payment.status.color,
                              dense: true,
                            ),
                          ],
                        ),
                        if (payment.description != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            payment.description ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const Divider(height: AppSpacing.xl),
                        DetailRow(
                          label: 'Wallet',
                          value: payment.accountNo,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        DetailRow(
                          label: 'Invoice',
                          value: payment.invoiceId,
                          icon: Icons.confirmation_number_outlined,
                        ),
                        DetailRow(
                          label: 'Reference',
                          value: payment.referenceId,
                          icon: Icons.tag_rounded,
                        ),
                        if (payment.transactionId != null)
                          DetailRow(
                            label: 'Transaction',
                            value: payment.transactionId ?? '',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        DetailRow(
                          label: 'Date',
                          value: Fmt.dateTime(payment.createdAt),
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pay(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pay'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// `POST /payments` — charges an EVC Plus wallet through WaafiPay.
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet();

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _amount = TextEditingController(text: '10');
  final TextEditingController _description = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final PaymentResult result = await ref
          .read(supportRepositoryProvider)
          .pay(
            accountNo: _phone.text.replaceAll(RegExp(r'\s+'), ''),
            amount: double.tryParse(_amount.text.trim()) ?? 0,
            description: _description.text.trim().isEmpty
                ? 'Pediatric Health Hub — Consultation fee'
                : _description.text.trim(),
          );

      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(
        () => _error =
            result.message ??
            'Payment was declined. Check your EVC Plus balance and try again.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      // A declined charge comes back as HTTP 402 with the provider's reason.
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
                'Pay with EVC Plus',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You will get an approval prompt on your phone. Approve it, then '
                'the payment completes.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_error != null) ...<Widget>[
                ErrorBanner(message: _error ?? ''),
                const SizedBox(height: AppSpacing.lg),
              ],
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'EVC Plus number',
                  hintText: '2526XXXXXXX or 06XXXXXXX',
                  prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
                ),
                validator: Validators.evcPhone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (USD)',
                  prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                ),
                validator: Validators.amount,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Pay now',
                icon: Icons.lock_rounded,
                isLoading: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
