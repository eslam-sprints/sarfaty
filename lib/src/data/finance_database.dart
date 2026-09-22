import '../models/finance_models.dart';

class DatabaseSnapshot {
  const DatabaseSnapshot({
    required this.startingBalance,
    required this.themePreference,
    this.languagePreference = 'ar',
    required this.onboardingCompleted,
    required this.biometricLockEnabled,
    this.expenseRemindersEnabled = false,
    this.customCategories = const [],
    required this.cards,
    required this.recentExpenses,
    required this.monthExpenses,
    required this.monthPayments,
    required this.cardExpensesTotal,
    required this.allPaymentsTotal,
  });

  /// Starting balance in piastres.
  final int startingBalance;
  final String themePreference;
  final String languagePreference;
  final bool onboardingCompleted;
  final bool biometricLockEnabled;
  final bool expenseRemindersEnabled;
  final List<CustomExpenseCategory> customCategories;
  final List<CreditCardAccount> cards;
  final List<Expense> recentExpenses;
  final List<Expense> monthExpenses;
  final List<PaymentRecord> monthPayments;
  final Map<String, int> cardExpensesTotal;
  final int allPaymentsTotal;
}

/// Writable local store surface used by [FinanceStore] (real SQLite or fakes).
abstract class FinanceDatabase {
  Future<DatabaseSnapshot> readAll({
    required DateTime monthStart,
    required DateTime monthEnd,
  });
  Future<void> upsertExpense(Expense expense);
  Future<void> insertCustomCategory(CustomExpenseCategory category);
  Future<void> deleteExpense(String id);
  Future<void> insertCard(CreditCardAccount card);
  Future<void> recordPayment(CreditCardAccount card, PaymentRecord payment);
  Future<void> saveSetting(String key, String value);
  Future<void> replaceAll(DatabaseSnapshot snapshot);
  Future<TransactionPage> getTransactions(TransactionFilter filter);
}
