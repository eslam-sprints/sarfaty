import 'package:flutter/material.dart';
import '../models/finance_models.dart';

String money(double value) =>
    '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} ج.م';
String shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint = const Color(0xFF0D9488),
  });
  final String label, value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});
  final Expense expense;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: CircleAvatar(
      backgroundColor: expense.category.color.withValues(alpha: .13),
      child: Icon(expense.category.icon, color: expense.category.color),
    ),
    title: Text(
      expense.note?.trim().isNotEmpty == true
          ? expense.note!
          : expense.category.label,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${expense.category.label} • ${expense.method == PaymentMethod.cash ? 'كاش' : 'كريديت'} • ${shortDate(expense.date)}',
    ),
    trailing: Text(
      '- ${money(expense.amount)}',
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Color(0xFFB42318),
      ),
    ),
  );
}
