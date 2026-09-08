import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.store});
  final FinanceStore store;
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  ExpenseCategory category = ExpenseCategory.food;
  PaymentMethod method = PaymentMethod.cash;
  DateTime date = DateTime.now();
  String? cardId;
  @override
  void initState() {
    super.initState();
    if (widget.store.cards.isNotEmpty) cardId = widget.store.cards.first.id;
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إضافة مصروف')),
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
            value: category,
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
              value: cardId,
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
            tileColor: Colors.white,
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
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => date = picked);
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
            label: const Text('حفظ المصروف'),
          ),
        ],
      ),
    ),
  );
  void _save() {
    if (!formKey.currentState!.validate()) return;
    widget.store.addExpense(
      amount: double.parse(amount.text),
      category: category,
      method: method,
      date: date,
      cardId: method == PaymentMethod.credit ? cardId : null,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة المصروف')));
  }
}
