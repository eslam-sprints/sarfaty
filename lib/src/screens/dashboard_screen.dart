import 'package:flutter/material.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store, required this.onAdd});
  final FinanceStore store;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final dueCard = store.nearestDueCard;
    final dueDate = dueCard == null ? null : store.nextDueDate(dueCard);
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
                          'أهلاً بك في صرفتي',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Text(
                          'خلّي فلوسك أوضح وأسهل',
                          style: TextStyle(color: Colors.black54),
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
                    const Text(
                      'إجمالي مصروفات الشهر',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      money(store.monthlyTotal),
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
                            label: 'الرصيد المتاح',
                            value: money(store.availableBalance),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WhiteStat(
                            label: 'مستحق الكريديت',
                            value: money(store.totalCreditDue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              MetricCard(
                label: 'أقرب موعد سداد',
                value: dueDate == null
                    ? 'لا توجد مستحقات'
                    : '${shortDate(dueDate)} • ${dueCard!.name}',
                icon: Icons.event_available_rounded,
                tint: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آخر العمليات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextButton(
                    onPressed: onAdd,
                    child: const Text('إضافة جديدة'),
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: store.expenses.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('لا توجد عمليات بعد')),
                        )
                      : Column(
                          children: store.expenses
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
