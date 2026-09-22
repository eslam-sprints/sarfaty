import 'package:flutter/material.dart';
import '../data/money.dart';
import '../data/time_codec.dart';
import '../l10n/app_strings.dart';
import '../models/finance_models.dart';

/// Formats piastres for display as Egyptian pounds.
String money(BuildContext context, int piastres) {
  final value = piastresToPounds(piastres);
  final currency = context.isArabic ? 'ج.م' : 'EGP';
  return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)} $currency';
}

/// Displays a **date-only** value using the local calendar day.
String shortDate(DateTime date) {
  final local = localDateOnly(date);
  return '${local.day}/${local.month}/${local.year}';
}

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
  const ExpenseTile({super.key, required this.expense, this.action});
  final Expense expense;
  final Widget? action;
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
          : expense.categoryLabelFor(context),
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(
      '${expense.categoryLabelFor(context)} • '
      '${expense.method.labelFor(context)} • ${shortDate(expense.date)}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '- ${money(context, expense.amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFFB42318),
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}
