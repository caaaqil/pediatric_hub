import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/misc.dart';
import '../../providers/providers.dart';
import 'admin_widgets.dart';

/// Port of `frontend/src/pages/admin/PaymentHistory.jsx` — the header with the
/// Refresh action, the three revenue tiles, the search field with its
/// ALL / PAID / PENDING / FAILED filter pills, and the transactions card.
class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  PaymentStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Payment>> payments = ref.watch(paymentsProvider);
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(paymentsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Payment History',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All EVC Plus / WaafiPay transactions',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(paymentsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            payments.maybeWhen(
              data: (List<Payment> items) {
                final double revenue = items
                    .where((Payment p) => p.status == PaymentStatus.paid)
                    .fold<double>(0, (double sum, Payment p) => sum + p.amount);
                final int paidCount = items
                    .where((Payment p) => p.status == PaymentStatus.paid)
                    .length;
                final int pending = items
                    .where((Payment p) => p.status == PaymentStatus.pending)
                    .length;
                final int failed = items
                    .where((Payment p) => p.status == PaymentStatus.failed)
                    .length;

                return Column(
                  children: <Widget>[
                    _RevenueTile(
                      icon: Icons.attach_money_rounded,
                      label: 'Total Revenue',
                      value: Fmt.money(revenue),
                      caption: '$paidCount successful payments',
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _RevenueTile(
                            icon: Icons.schedule_rounded,
                            label: 'Pending',
                            value: '$pending',
                            caption: 'Awaiting confirmation',
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RevenueTile(
                            icon: Icons.cancel_rounded,
                            label: 'Failed',
                            value: '$failed',
                            caption: 'Declined transactions',
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),

            AdminSearchField(
              hintText: 'Search by payer name, phone, or transaction ID...',
              controller: _search,
              onChanged: (String v) =>
                  setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _FilterPill(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  ...PaymentStatus.values.map(
                    (PaymentStatus s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterPill(
                        label: s.label,
                        selected: _filter == s,
                        onTap: () =>
                            setState(() => _filter = _filter == s ? null : s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            payments.when(
              loading: () =>
                  const AdminTableMessage(text: 'Loading transactions...'),
              error: (Object error, StackTrace _) => ErrorBanner(
                message: error is ApiException
                    ? error.detailedMessage
                    : error.toString(),
              ),
              data: (List<Payment> items) {
                final List<Payment> shown = items.where((Payment p) {
                  final bool matchesFilter =
                      _filter == null || p.status == _filter;
                  final bool matchesQuery =
                      _query.isEmpty ||
                      (p.payerName ?? '').toLowerCase().contains(_query) ||
                      (p.payerEmail ?? '').toLowerCase().contains(_query) ||
                      p.accountNo.toLowerCase().contains(_query) ||
                      (p.transactionId ?? '').toLowerCase().contains(_query);
                  return matchesFilter && matchesQuery;
                }).toList();

                return AdminTableCard(
                  header: 'Transactions (${shown.length})',
                  child: shown.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 44),
                          child: Column(
                            children: <Widget>[
                              Icon(
                                Icons.credit_card_rounded,
                                size: 34,
                                color: palette.textMuted,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No transactions found',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Payments will appear here once parents book '
                                'appointments',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: <Widget>[
                            for (int i = 0; i < shown.length; i++)
                              AdminTableRow(
                                last: i == shown.length - 1,
                                child: _PaymentRow(payment: shown[i]),
                              ),
                          ],
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueTile extends StatelessWidget {
  const _RevenueTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary600 : palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary600 : palette.border,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.white : palette.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    payment.payerName ?? 'Unknown payer',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    payment.payerEmail ?? '—',
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  Fmt.money(payment.amount, currency: payment.currency),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  payment.currency,
                  style: TextStyle(fontSize: 10, color: palette.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            AdminStatusChip(
              label: payment.status.label,
              color: payment.status.color,
            ),
            const SizedBox(width: 10),
            Text(
              payment.accountNo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              Fmt.dateShort(payment.createdAt),
              style: TextStyle(fontSize: 11, color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: palette.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            payment.transactionId == null
                ? '—'
                : (payment.transactionId ?? '').length > 20
                ? '${(payment.transactionId ?? '').substring(0, 20)}…'
                : (payment.transactionId ?? ''),
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
