import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/money.dart';
import '../data/time_codec.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.store, this.expense});
  final FinanceStore store;
  final Expense? expense;
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  ExpenseCategory category = ExpenseCategory.food;
  PaymentMethod method = PaymentMethod.cash;
  late DateTime date;
  String? cardId;
  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      amount.text = formatPoundsForInput(expense.amount);
      note.text = expense.note ?? '';
      category = expense.category;
      method = expense.method;
      date = localDateOnly(expense.date);
      cardId = expense.cardId;
    } else {
      date = widget.store.today;
      if (widget.store.cards.isNotEmpty) {
        cardId = widget.store.cards.first.id;
      }
    }
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.expense == null ? 'إضافة مصروف' : 'تعديل المصروف'),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              suffixText: 'ج.م',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || n <= 0 ? 'أدخل مبلغاً صحيحاً' : null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: category,
            decoration: const InputDecoration(
              labelText: 'التصنيف',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: ExpenseCategory.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.icon, color: c.color, size: 20),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 16),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text('كاش'),
                icon: Icon(Icons.account_balance_wallet_outlined),
              ),
              ButtonSegment(
                value: PaymentMethod.credit,
                label: Text('كريديت'),
                icon: Icon(Icons.credit_card_outlined),
              ),
            ],
            selected: {method},
            onSelectionChanged: (v) => setState(() => method = v.first),
          ),
          if (method == PaymentMethod.credit) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: cardId,
              decoration: const InputDecoration(
                labelText: 'البطاقة',
                prefixIcon: Icon(Icons.credit_card),
              ),
              items: widget.store.cards
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => cardId = v),
              validator: (_) =>
                  cardId == null ? 'أضف بطاقة أولاً من شاشة بطاقاتي' : null,
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('التاريخ'),
            subtitle: Text(shortDate(date)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: widget.store.today,
              );
              if (picked != null) {
                setState(() => date = localDateOnly(picked));
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: note,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'ملاحظة (اختياري)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              widget.expense == null ? 'حفظ المصروف' : 'حفظ التعديلات',
            ),
          ),
        ],
      ),
    ),
  );
  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final noteValue = note.text.trim().isEmpty ? null : note.text.trim();
    final existing = widget.expense;
    try {
      if (existing == null) {
        await widget.store.addExpense(
          amount: double.parse(amount.text),
          category: category,
          method: method,
          date: date,
          cardId: method == PaymentMethod.credit ? cardId : null,
          note: noteValue,
        );
      } else {
        await widget.store.updateExpense(
          id: existing.id,
          amount: double.parse(amount.text),
          category: category,
          method: method,
          date: date,
          cardId: method == PaymentMethod.credit ? cardId : null,
          note: noteValue,
        );
      }
    } on PersistenceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? 'تمت إضافة المصروف' : 'تم تعديل المصروف',
        ),
      ),
    );
  }
}
