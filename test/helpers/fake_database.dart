import 'package:sarfaty/src/data/local_database.dart';
import 'package:sarfaty/src/models/finance_models.dart';

class FakeDatabase implements FinanceDatabase {
  FakeDatabase({this.failWrites = false});

  bool failWrites;
  int writeCount = 0;
  final List<Expense> expenses = [];
  final List<CreditCardAccount> cards = [];
  final List<PaymentRecord> payments = [];
  final Map<String, String> settings = {};

  Future<void> _maybeFail() async {
    writeCount += 1;
    if (failWrites) {
      throw StateError('simulated write failure');
    }
  }

  @override
  Future<DatabaseSnapshot> readAll({
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    final cardExpensesTotal = <String, int>{};
    for (final e in expenses) {
      if (e.cardId != null) {
        cardExpensesTotal[e.cardId!] =
            (cardExpensesTotal[e.cardId!] ?? 0) + e.amount;
      }
    }
    final allPaymentsTotal = payments.fold(0, (sum, p) => sum + p.amount);

    return DatabaseSnapshot(
      startingBalance: int.tryParse(settings['starting_balance'] ?? '0') ?? 0,
      themePreference: settings['theme'] ?? 'system',
      onboardingCompleted: settings['onboarding_completed'] == '1',
      biometricLockEnabled: settings['biometric_lock_enabled'] == '1',
      recentExpenses: List.of(expenses.take(5)),
      monthExpenses: List.of(
        expenses.where(
          (e) => !e.date.isBefore(monthStart) && !e.date.isAfter(monthEnd),
        ),
      ),
      monthPayments: List.of(
        payments.where((p) {
          final localDate = DateTime(
            p.date.toLocal().year,
            p.date.toLocal().month,
            p.date.toLocal().day,
          );
          return !localDate.isBefore(monthStart) &&
              !localDate.isAfter(monthEnd);
        }),
      ),
      cards: List.of(cards),
      cardExpensesTotal: cardExpensesTotal,
      allPaymentsTotal: allPaymentsTotal,
    );
  }

  @override
  Future<void> upsertExpense(Expense expense) async {
    await _maybeFail();
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) {
      expenses.add(expense);
    } else {
      expenses[index] = expense;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _maybeFail();
    expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> insertCard(CreditCardAccount card) async {
    await _maybeFail();
    cards.add(card);
  }

  @override
  Future<void> recordPayment(
    CreditCardAccount card,
    PaymentRecord payment,
  ) async {
    await _maybeFail();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index].paid = card.paid;
    }
    payments.add(payment);
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    await _maybeFail();
    settings[key] = value;
  }

  @override
  Future<void> replaceAll(DatabaseSnapshot snapshot) async {
    await _maybeFail();
    expenses
      ..clear()
      ..addAll(snapshot.monthExpenses);
    cards
      ..clear()
      ..addAll(snapshot.cards);
    payments
      ..clear()
      ..addAll(snapshot.monthPayments);
    settings['theme'] = snapshot.themePreference;
    settings['onboarding_completed'] = snapshot.onboardingCompleted ? '1' : '0';
    settings['biometric_lock_enabled'] = snapshot.biometricLockEnabled
        ? '1'
        : '0';
    settings['starting_balance'] = '${snapshot.startingBalance}';
  }

  @override
  Future<TransactionPage> getTransactions(TransactionFilter filter) async {
    return const TransactionPage(items: [], totalCount: 0, totalAmount: 0);
  }
}
