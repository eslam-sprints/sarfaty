import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.store});
  final FinanceStore store;
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  PaymentMethod? method;
  ExpenseCategory? category;
  String? cardId;
  DateTimeRange? period;

  List<_Transaction> get results {
    final items = <_Transaction>[
      ...widget.store.expenses
          .where((e) {
            if (method != null && e.method != method) return false;
            if (category != null && e.category != category) return false;
            if (cardId != null && e.cardId != cardId) return false;
            return _inPeriod(e.date);
          })
          .map(_Transaction.expense),
      if (category == null && method != PaymentMethod.cash)
        ...widget.store.payments
            .where(
              (p) =>
                  (cardId == null || p.cardId == cardId) && _inPeriod(p.date),
            )
            .map((p) {
              final matches = widget.store.cards.where((c) => c.id == p.cardId);
              return _Transaction.payment(
                p,
                matches.isEmpty ? null : matches.first,
              );
            }),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  bool _inPeriod(DateTime date) =>
      period == null ||
      (!date.isBefore(period!.start) &&
          date.isBefore(period!.end.add(const Duration(days: 1))));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('كل المصروفات')),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final items = results;
        final total = items.fold<double>(0, (sum, item) => sum + item.amount);
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  DropdownButton<PaymentMethod?>(
                    value: method,
                    hint: const Text('طريقة الدفع: الكل'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('الكل')),
                      DropdownMenuItem(
                        value: PaymentMethod.cash,
                        child: Text('كاش'),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.credit,
                        child: Text('كريديت'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      method = v;
                      if (v == PaymentMethod.cash) cardId = null;
                    }),
                  ),
                  const SizedBox(width: 14),
                  DropdownButton<ExpenseCategory?>(
                    value: category,
                    hint: const Text('كل التصنيفات'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('كل التصنيفات'),
                      ),
                      ...ExpenseCategory.values.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      ),
                    ],
                    onChanged: (v) => setState(() => category = v),
                  ),
                  if (method == PaymentMethod.credit) ...[
                    const SizedBox(width: 14),
                    DropdownButton<String?>(
                      value: cardId,
                      hint: const Text('كل البطاقات'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('كل البطاقات'),
                        ),
                        ...widget.store.cards.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => cardId = v),
                    ),
                  ],
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _pickPeriod,
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
                      onPressed: () => setState(() {
                        method = null;
                        category = null;
                        cardId = null;
                        period = null;
                      }),
                      tooltip: 'مسح الفلاتر',
                      icon: const Icon(Icons.filter_alt_off_outlined),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'إجمالي النتائج',
                      value: money(total),
                      icon: Icons.summarize_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      label: 'عدد النتائج',
                      value: '${items.length}',
                      icon: Icons.numbers_rounded,
                      tint: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 54,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'لا توجد معاملات تطابق الفلاتر',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => items[i].tile,
                    ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _pickPeriod() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: period,
    );
    if (picked != null) setState(() => period = picked);
  }
}

class _Transaction {
  _Transaction(this.amount, this.date, this.tile);
  factory _Transaction.expense(Expense e) =>
      _Transaction(e.amount, e.date, ExpenseTile(expense: e));
  factory _Transaction.payment(PaymentRecord p, CreditCardAccount? card) =>
      _Transaction(
        p.amount,
        p.date,
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(Icons.credit_score_rounded, color: Color(0xFF0369A1)),
          ),
          title: Text(
            'سداد ${card?.name ?? 'بطاقة'}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('سداد كريديت • ${shortDate(p.date)}'),
          trailing: Text(
            '- ${money(p.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0369A1),
            ),
          ),
        ),
      );
  final double amount;
  final DateTime date;
  final Widget tile;
}
