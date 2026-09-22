import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/money.dart';
import '../data/time_codec.dart';
import '../l10n/app_strings.dart';
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
  static const _addCategoryValue = 'add';
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  ExpenseCategory category = ExpenseCategory.food;
  CustomExpenseCategory? customCategory;
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
      if (expense.customCategoryId != null) {
        customCategory = widget.store.customCategories
            .where((item) => item.id == expense.customCategoryId)
            .firstOrNull;
      }
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
      title: Text(
        widget.expense == null
            ? 'إضافة مصروف'.tr(context, 'Add expense')
            : 'تعديل المصروف'.tr(context, 'Edit expense'),
      ),
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
            decoration: InputDecoration(
              labelText: 'المبلغ'.tr(context, 'Amount'),
              suffixText: context.isArabic ? 'ج.م' : 'EGP',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || n <= 0
                  ? 'أدخل مبلغاً صحيحاً'.tr(context, 'Enter a valid amount')
                  : null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(customCategory?.id ?? category.name),
            initialValue: customCategory?.id ?? category.name,
            decoration: InputDecoration(
              labelText: 'التصنيف'.tr(context, 'Category'),
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: [
              ...ExpenseCategory.values.map(
                (c) => DropdownMenuItem(
                  value: c.name,
                  child: Row(
                    children: [
                      Icon(c.icon, color: c.color, size: 20),
                      const SizedBox(width: 8),
                      Text(c.labelFor(context)),
                    ],
                  ),
                ),
              ),
              ...widget.store.customCategories.map(
                (custom) => DropdownMenuItem(
                  value: custom.id,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.label_outline_rounded,
                        color: Color(0xFF78716C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(custom.name),
                    ],
                  ),
                ),
              ),
              DropdownMenuItem(
                value: _addCategoryValue,
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('إضافة تصنيف جديد'.tr(context, 'Add new category')),
                  ],
                ),
              ),
            ],
            onChanged: (value) async {
              if (value == _addCategoryValue) {
                await _addCustomCategory();
                return;
              }
              final custom = widget.store.customCategories
                  .where((item) => item.id == value)
                  .firstOrNull;
              setState(() {
                customCategory = custom;
                if (custom == null) {
                  category = ExpenseCategory.values.byName(value!);
                } else {
                  category = ExpenseCategory.other;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<PaymentMethod>(
            segments: [
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text(PaymentMethod.cash.labelFor(context)),
                icon: const Icon(Icons.account_balance_wallet_outlined),
              ),
              ButtonSegment(
                value: PaymentMethod.credit,
                label: Text(PaymentMethod.credit.labelFor(context)),
                icon: const Icon(Icons.credit_card_outlined),
              ),
            ],
            selected: {method},
            onSelectionChanged: (v) => setState(() => method = v.first),
          ),
          if (method == PaymentMethod.credit) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: cardId,
              decoration: InputDecoration(
                labelText: 'البطاقة'.tr(context, 'Card'),
                prefixIcon: const Icon(Icons.credit_card),
              ),
              items: widget.store.cards
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => cardId = v),
              validator: (_) => cardId == null
                  ? 'أضف بطاقة أولاً من شاشة بطاقاتي'.tr(
                      context,
                      'Add a card first from the Wallet screen',
                    )
                  : null,
            ),
          ],
          const SizedBox(height: 16),
          ListTile(
            tileColor: Theme.of(context).colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text('التاريخ'.tr(context, 'Date')),
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
            decoration: InputDecoration(
              labelText: 'ملاحظة (اختياري)'.tr(context, 'Note (optional)'),
              prefixIcon: const Icon(Icons.notes_rounded),
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
              widget.expense == null
                  ? 'حفظ المصروف'.tr(context, 'Save expense')
                  : 'حفظ التعديلات'.tr(context, 'Save changes'),
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
          customCategory: customCategory,
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
          customCategory: customCategory,
        );
      }
    } on PersistenceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.localizedError(context))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'تمت إضافة المصروف'.tr(context, 'Expense added')
              : 'تم تعديل المصروف'.tr(context, 'Expense updated'),
        ),
      ),
    );
  }

  Future<void> _addCustomCategory() async {
    final controller = TextEditingController();
    String? errorText;
    final created = await showDialog<CustomExpenseCategory>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('إضافة تصنيف جديد'.tr(context, 'Add new category')),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: 'اسم التصنيف'.tr(context, 'Category name'),
              hintText: 'مثال: بنزين'.tr(context, 'Example: Fuel'),
              errorText: errorText?.localizedError(context),
            ),
            onSubmitted: (_) async {
              final result = await _saveCustomCategory(
                controller.text,
                (message) => setDialogState(() => errorText = message),
              );
              if (result != null && dialogContext.mounted) {
                Navigator.pop(dialogContext, result);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء'.tr(context, 'Cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final result = await _saveCustomCategory(
                  controller.text,
                  (message) => setDialogState(() => errorText = message),
                );
                if (result != null && dialogContext.mounted) {
                  Navigator.pop(dialogContext, result);
                }
              },
              child: Text('حفظ'.tr(context, 'Save')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (created == null) {
      setState(() {});
      return;
    }
    setState(() {
      customCategory = created;
      category = ExpenseCategory.other;
    });
  }

  Future<CustomExpenseCategory?> _saveCustomCategory(
    String name,
    ValueChanged<String> showError,
  ) async {
    try {
      return await widget.store.addCustomCategory(name);
    } on FormatException catch (error) {
      showError(error.message);
    } on PersistenceException catch (error) {
      showError(error.message);
    }
    return null;
  }
}
