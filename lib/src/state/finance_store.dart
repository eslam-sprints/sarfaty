import 'package:flutter/foundation.dart';
import '../models/finance_models.dart';

class FinanceStore extends ChangeNotifier {
  FinanceStore({
    required this.startingBalance,
    List<Expense>? expenses,
    List<CreditCardAccount>? cards,
  }) : expenses = expenses ?? [],
       cards = cards ?? [];
  factory FinanceStore.seeded() {
    final now = DateTime.now();
    final card = CreditCardAccount(
      id: 'card-1',
      name: 'بنك مصر •••• 4821',
      limit: 30000,
      statementDay: 20,
      dueDay: 8,
      openingDue: 1850,
    );
    return FinanceStore(
      startingBalance: 14200,
      cards: [card],
      expenses: [
        Expense(
          id: 'e1',
          amount: 245,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: now.subtract(const Duration(hours: 3)),
          note: 'غداء',
        ),
        Expense(
          id: 'e2',
          amount: 780,
          category: ExpenseCategory.shopping,
          method: PaymentMethod.credit,
          cardId: card.id,
          date: now.subtract(const Duration(days: 1)),
          note: 'مستلزمات',
        ),
        Expense(
          id: 'e3',
          amount: 120,
          category: ExpenseCategory.transport,
          method: PaymentMethod.cash,
          date: now.subtract(const Duration(days: 2)),
        ),
        Expense(
          id: 'e4',
          amount: 460,
          category: ExpenseCategory.bills,
          method: PaymentMethod.credit,
          cardId: card.id,
          date: now.subtract(const Duration(days: 4)),
        ),
      ],
    );
  }
  double startingBalance;
  final List<Expense> expenses;
  final List<CreditCardAccount> cards;
  final List<PaymentRecord> payments = [];
  Iterable<Expense> get monthExpenses {
    final now = DateTime.now();
    return expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
  }

  double get monthlyTotal => monthExpenses.fold(0, (sum, e) => sum + e.amount);
  double get cashTotal => monthExpenses
      .where((e) => e.method == PaymentMethod.cash)
      .fold(0, (sum, e) => sum + e.amount);
  double get creditTotal => monthExpenses
      .where((e) => e.method == PaymentMethod.credit)
      .fold(0, (sum, e) => sum + e.amount);
  double get availableBalance =>
      startingBalance -
      cashTotal -
      payments.fold(0, (sum, p) => sum + p.amount);
  double get totalCreditDue =>
      cards.fold(0, (sum, card) => sum + cardDue(card));
  double cardDue(CreditCardAccount card) =>
      (card.openingDue +
              expenses
                  .where((e) => e.cardId == card.id)
                  .fold<double>(0, (sum, e) => sum + e.amount) -
              card.paid)
          .clamp(0, double.infinity);
  double cardUsage(CreditCardAccount card) =>
      card.limit == 0 ? 0 : (cardDue(card) / card.limit).clamp(0, 1);
  DateTime nextDueDate(CreditCardAccount card) {
    final now = DateTime.now();
    var due = DateTime(now.year, now.month, card.dueDay);
    if (due.isBefore(DateTime(now.year, now.month, now.day))) {
      due = DateTime(now.year, now.month + 1, card.dueDay);
    }
    return due;
  }

  CreditCardAccount? get nearestDueCard {
    final active = cards.where((c) => cardDue(c) > 0).toList()
      ..sort((a, b) => nextDueDate(a).compareTo(nextDueDate(b)));
    return active.isEmpty ? null : active.first;
  }

  ExpenseCategory? get topCategory {
    if (monthExpenses.isEmpty) return null;
    final totals = <ExpenseCategory, double>{};
    for (final e in monthExpenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  void addExpense({
    required double amount,
    required ExpenseCategory category,
    required PaymentMethod method,
    required DateTime date,
    String? cardId,
    String? note,
  }) {
    expenses.insert(
      0,
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: amount,
        category: category,
        method: method,
        date: date,
        cardId: cardId,
        note: note,
      ),
    );
    notifyListeners();
  }

  void addCard({
    required String name,
    required double limit,
    required int statementDay,
    required int dueDay,
  }) {
    cards.add(
      CreditCardAccount(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        limit: limit,
        statementDay: statementDay,
        dueDay: dueDay,
      ),
    );
    notifyListeners();
  }

  bool payCard(CreditCardAccount card) {
    final amount = cardDue(card);
    if (amount <= 0 || availableBalance < amount) return false;
    card.paid += amount;
    payments.add(
      PaymentRecord(cardId: card.id, amount: amount, date: DateTime.now()),
    );
    notifyListeners();
    return true;
  }
}
