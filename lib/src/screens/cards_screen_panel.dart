part of 'cards_screen.dart';

class _CardPanel extends StatelessWidget {
  const _CardPanel({required this.store, required this.card});
  final FinanceStore store;
  final CreditCardAccount card;
  @override
  Widget build(BuildContext context) {
    final usage = store.cardUsage(card);
    final due = store.cardDue(card);
    final alertColor = usage >= .9
        ? Colors.red
        : usage >= .7
        ? Colors.orange
        : const Color(0xFF0D9488);
    final days = localCalendarDaysUntil(store.today, store.nextDueDate(card));
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _LabelValue(
                    'المستخدم'.tr(context, 'Used'),
                    money(context, due),
                  ),
                ),
                Expanded(
                  child: _LabelValue(
                    'المتبقي'.tr(context, 'Remaining'),
                    money(context, (card.limit - due).clamp(0, card.limit)),
                  ),
                ),
                Expanded(
                  child: _LabelValue(
                    'الحد'.tr(context, 'Limit'),
                    money(context, card.limit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: usage,
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              color: alertColor,
              backgroundColor: alertColor.withValues(alpha: .12),
            ),
            const SizedBox(height: 8),
            Text(
              context.isArabic
                  ? 'استخدام ${(usage * 100).round()}% من الحد'
                  : '${(usage * 100).round()}% of limit used',
              style: TextStyle(color: alertColor, fontWeight: FontWeight.w700),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${'المطلوب سداده'.tr(context, 'Amount due')}: ${money(context, due)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        context.isArabic
                            ? 'موعد السداد ${shortDate(store.nextDueDate(card))} • بعد $days يوم'
                            : 'Due ${shortDate(store.nextDueDate(card))} • in $days days',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: due <= 0 ? null : () => _showPayment(context, due),
                  child: Text('سددت البطاقة'.tr(context, 'Record payment')),
                ),
              ],
            ),
            if (days <= 7 || usage >= .7) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: alertColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        usage >= .9
                            ? 'تنبيه: تجاوز استخدام البطاقة 90%'.tr(
                                context,
                                'Alert: card usage exceeded 90%',
                              )
                            : usage >= .7
                            ? 'تنبيه: تجاوز استخدام البطاقة 70%'.tr(
                                context,
                                'Alert: card usage exceeded 70%',
                              )
                            : 'تذكير: موعد السداد خلال 7 أيام'.tr(
                                context,
                                'Reminder: payment is due within 7 days',
                              ),
                        style: TextStyle(
                          color: alertColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPayment(BuildContext context, int due) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentSheet(due: due),
    );
    if (amount == null || !context.mounted) return;
    try {
      final ok = await store.payCard(card, amount);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${'تم تسجيل سداد'.tr(context, 'Payment recorded')}: ${money(context, poundsToPiastres(amount))}'
                : 'تعذر السداد؛ تحقق من الرصيد والمبلغ'.tr(
                    context,
                    'Payment failed; check the balance and amount',
                  ),
          ),
        ),
      );
    } on PersistenceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.localizedError(context))),
      );
    }
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    ],
  );
}
