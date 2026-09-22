import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
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
  final String? category;
  final String? cardId;
  final DateTimeRange? period;
  final ValueChanged<PaymentMethod?> onMethodChanged;
  final ValueChanged<String?> onCategoryChanged;
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
            hint: Text('طريقة الدفع: الكل'.tr(context, 'Payment method: All')),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text('الكل'.tr(context, 'All')),
              ),
              DropdownMenuItem(
                value: PaymentMethod.cash,
                child: Text(PaymentMethod.cash.labelFor(context)),
              ),
              DropdownMenuItem(
                value: PaymentMethod.credit,
                child: Text(PaymentMethod.credit.labelFor(context)),
              ),
            ],
            onChanged: onMethodChanged,
          ),
          const SizedBox(width: 14),
          DropdownButton<String?>(
            value: category,
            hint: Text('كل التصنيفات'.tr(context, 'All categories')),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text('كل التصنيفات'.tr(context, 'All categories')),
              ),
              ...ExpenseCategory.values.map(
                (c) => DropdownMenuItem(
                  value: c.name,
                  child: Text(c.labelFor(context)),
                ),
              ),
              ...store.customCategories.map(
                (category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
              ),
            ],
            onChanged: onCategoryChanged,
          ),
          if (method == PaymentMethod.credit) ...[
            const SizedBox(width: 14),
            DropdownButton<String?>(
              value: cardId,
              hint: Text('كل البطاقات'.tr(context, 'All cards')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('كل البطاقات'.tr(context, 'All cards')),
                ),
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
                  ? 'كل التواريخ'.tr(context, 'All dates')
                  : '${shortDate(period!.start)} — ${shortDate(period!.end)}',
            ),
          ),
          if (method != null ||
              category != null ||
              cardId != null ||
              period != null)
            IconButton(
              onPressed: onClear,
              tooltip: 'مسح الفلاتر'.tr(context, 'Clear filters'),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
        ],
      ),
    );
  }
}
