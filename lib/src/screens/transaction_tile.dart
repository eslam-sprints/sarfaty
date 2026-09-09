import 'package:flutter/material.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';

enum _ExpenseAction { edit, delete }

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.store,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionItem item;
  final FinanceStore store;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  @override
  Widget build(BuildContext context) {
    if (item.isExpense) {
      final expense = item.expense!;
      return ExpenseTile(
        expense: expense,
        action: PopupMenuButton<_ExpenseAction>(
          tooltip: 'خيارات المصروف',
          onSelected: (action) => switch (action) {
            _ExpenseAction.edit => onEdit(expense),
            _ExpenseAction.delete => onDelete(expense),
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _ExpenseAction.edit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text('تعديل'),
              ),
            ),
            PopupMenuItem(
              value: _ExpenseAction.delete,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline_rounded),
                title: Text('حذف'),
              ),
            ),
          ],
        ),
      );
    } else {
      final p = item.payment!;
      final matches = store.cards.where((c) => c.id == p.cardId);
      final card = matches.isEmpty ? null : matches.first;
      return ListTile(
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
      );
    }
  }
}
