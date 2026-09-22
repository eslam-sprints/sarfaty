import 'package:flutter/material.dart';
import '../data/time_codec.dart';
import '../l10n/app_strings.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';
import 'transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store, required this.onAdd});
  final FinanceStore store;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final dueCard = store.nearestDueCard;
    final dueDate = dueCard == null ? null : store.nextDueDate(dueCard);
    final daysUntilDue = dueDate == null
        ? null
        : localCalendarDaysUntil(store.today, dueDate);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أهلاً بك في صرفتي'.tr(context, 'Welcome to Sarfaty'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'خلّي فلوسك أوضح وأسهل'.tr(
                            context,
                            'Make your money clearer and easier',
                          ),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي مصروفات الشهر'.tr(context, 'Monthly expenses'),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(context, store.monthlyTotal),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _WhiteStat(
                            label: 'الرصيد المتاح'.tr(
                              context,
                              'Available balance',
                            ),
                            value: money(context, store.availableBalance),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WhiteStat(
                            label: 'مستحق الكريديت'.tr(context, 'Credit due'),
                            value: money(context, store.totalCreditDue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(
                          'سجّل مصروف جديد'.tr(context, 'Add a new expense'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'أقرب موعد سداد'.tr(context, 'Next payment due'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dueDate == null
                                  ? 'لا توجد مستحقات حاليًا'.tr(
                                      context,
                                      'No payments are currently due',
                                    )
                                  : '${shortDate(dueDate)} • ${dueCard!.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      if (daysUntilDue != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            daysUntilDue <= 0
                                ? 'اليوم'.tr(context, 'Today')
                                : context.isArabic
                                ? 'خلال $daysUntilDue يوم'
                                : 'In $daysUntilDue days',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آخر العمليات'.tr(context, 'Recent transactions'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionsScreen(store: store),
                      ),
                    ),
                    child: Text('عرض الكل'.tr(context, 'View all')),
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: store.recentExpenses.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 38,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'لا توجد عمليات بعد'.tr(
                                  context,
                                  'No transactions yet',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: onAdd,
                                icon: const Icon(Icons.add_rounded),
                                label: Text(
                                  'أضف أول مصروف'.tr(
                                    context,
                                    'Add your first expense',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: store.recentExpenses
                              .take(5)
                              .map((e) => ExpenseTile(expense: e))
                              .toList(),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhiteStat extends StatelessWidget {
  const _WhiteStat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
