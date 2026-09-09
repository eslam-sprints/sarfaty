import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

class TransactionFilters extends StatelessWidget {
  const TransactionFilters({
    super.key,
    required this.store,
    required this.method,
    required this.category,
    required this.cardId,
    required this.period,
    required this.onMethodChanged,
    required this.onCategoryChanged,
    required this.onCardIdChanged,
    required this.onPeriodChanged,
    required this.onClear,
  });

  final FinanceStore store;
  final PaymentMethod? method;
  final ExpenseCategory? category;
  final String? cardId;
  final DateTimeRange? period;
  final ValueChanged<PaymentMethod?> onMethodChanged;
  final ValueChanged<ExpenseCategory?> onCategoryChanged;
  final ValueChanged<String?> onCardIdChanged;
  final ValueChanged<DateTimeRange?> onPeriodChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          DropdownButton<PaymentMethod?>(
            value: method,
            hint: const Text('طريقة الدفع: الكل'),
            items: const [
              DropdownMenuItem(value: null, child: Text('الكل')),
              DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش')),
              DropdownMenuItem(
                value: PaymentMethod.credit,
                child: Text('كريديت'),
              ),
            ],
            onChanged: onMethodChanged,
          ),
          const SizedBox(width: 14),
          DropdownButton<ExpenseCategory?>(
            value: category,
            hint: const Text('كل التصنيفات'),
            items: [
              const DropdownMenuItem(value: null, child: Text('كل التصنيفات')),
              ...ExpenseCategory.values.map(
                (c) => DropdownMenuItem(value: c, child: Text(c.label)),
              ),
            ],
            onChanged: onCategoryChanged,
          ),
          if (method == PaymentMethod.credit) ...[
            const SizedBox(width: 14),
            DropdownButton<String?>(
              value: cardId,
              hint: const Text('كل البطاقات'),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل البطاقات')),
                ...store.cards.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: onCardIdChanged,
            ),
          ],
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: store.today,
                initialDateRange: period,
              );
              if (picked != null) onPeriodChanged(picked);
            },
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              period == null
                  ? 'كل التواريخ'
                  : '${shortDate(period!.start)} — ${shortDate(period!.end)}',
            ),
          ),
          if (method != null ||
              category != null ||
              cardId != null ||
              period != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'مسح الفلاتر',
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
        ],
      ),
    );
  }
}
