import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../data/local_database.dart';
import '../data/money.dart';
import '../data/time_codec.dart';
import '../models/finance_models.dart';

part 'finance_store_mutations.dart';
part 'finance_store_backup.dart';

/// Thrown when a SQLite write fails after validation succeeded.
class PersistenceException implements Exception {
  const PersistenceException(this.message);
  final String message;

  @override
  String toString() => message;
}

typedef Clock = DateTime Function();

class FinanceStore extends ChangeNotifier {
  static Future<FinanceStore> load({Clock? clock}) async {
    final database = await LocalDatabase.open();
    final c = clock ?? DateTime.now;
    final now = c();
    final today = localDateOnly(now);
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);

    final snapshot = await database.readAll(
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
    return FinanceStore._fromSnapshot(snapshot, database, c);
  }

  factory FinanceStore.seeded({Clock? clock}) {
    return FinanceStore(startingBalance: 0, clock: clock);
  }

  FinanceStore._fromSnapshot(
    DatabaseSnapshot snapshot,
    FinanceDatabase database,
    Clock clock,
  ) : startingBalance = snapshot.startingBalance,
      themePreference = snapshot.themePreference,
      onboardingCompleted = snapshot.onboardingCompleted,
      biometricLockEnabled = snapshot.biometricLockEnabled,
      cards = snapshot.cards,
      recentExpenses = snapshot.recentExpenses,
      _monthExpenses = snapshot.monthExpenses,
      _monthPayments = snapshot.monthPayments,
      cardExpensesTotal = snapshot.cardExpensesTotal,
      allPaymentsTotal = snapshot.allPaymentsTotal,
      _database = database,
      _clock = clock {
    _calculateAggregates();
  }

  FinanceStore({
    required this.startingBalance,
    List<CreditCardAccount>? cards,
    this.themePreference = 'system',
    this.onboardingCompleted = false,
    this.biometricLockEnabled = false,
    FinanceDatabase? database,
    Clock? clock,
    @visibleForTesting List<Expense>? monthExpenses,
    @visibleForTesting List<PaymentRecord>? monthPayments,
  }) : cards = cards ?? [],
       recentExpenses = [],
       _monthExpenses = monthExpenses ?? [],
       _monthPayments = monthPayments ?? [],
       cardExpensesTotal = {},
       allPaymentsTotal = 0,
       _database = database,
       _clock = clock ?? DateTime.now {
    _calculateAggregates();
  }

  int startingBalance;
  String themePreference;
  bool onboardingCompleted;
  bool biometricLockEnabled;
  final List<CreditCardAccount> cards;
  final List<Expense> recentExpenses;
  final List<Expense> _monthExpenses;
  final List<PaymentRecord> _monthPayments;
  final Map<String, int> cardExpensesTotal;
  int allPaymentsTotal;
  final FinanceDatabase? _database;
  final Clock _clock;

  /// Injected "now" for calendar math and instants (tests pass a fixed clock).
  DateTime get now => _clock();

  /// Local calendar today (date-only).
  DateTime get today => localDateOnly(now);

  Iterable<Expense> get monthExpenses => _monthExpenses;
  Iterable<PaymentRecord> get monthPayments => _monthPayments;

  int monthlyTotal = 0;
  int cashTotal = 0;
  int creditTotal = 0;
  int monthlyPayments = 0;
  int availableBalance = 0;
  ExpenseCategory? topCategory;

  void _calculateAggregates() {
    monthlyTotal = _monthExpenses.fold(0, (sum, e) => sum + e.amount);
    cashTotal = _monthExpenses
        .where((e) => e.method == PaymentMethod.cash)
        .fold(0, (sum, e) => sum + e.amount);
    creditTotal = _monthExpenses
        .where((e) => e.method == PaymentMethod.credit)
        .fold(0, (sum, e) => sum + e.amount);
    monthlyPayments = _monthPayments
        .where((p) => isSameLocalMonth(p.date, today))
        .fold(0, (sum, p) => sum + p.amount);

    availableBalance = startingBalance - cashTotal - allPaymentsTotal;

    if (_monthExpenses.isEmpty) {
      topCategory = null;
    } else {
      final totals = <ExpenseCategory, int>{};
      for (final e in _monthExpenses) {
        totals[e.category] = (totals[e.category] ?? 0) + e.amount;
      }
      topCategory = totals.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }
  }

  int get totalCreditDue => cards.fold(0, (sum, card) => sum + cardDue(card));
  int cardDue(CreditCardAccount card) {
    final expensesTotal = cardExpensesTotal[card.id] ?? 0;
    final due = card.openingDue + expensesTotal - card.paid;
    return due < 0 ? 0 : due;
  }

  double cardUsage(CreditCardAccount card) =>
      card.limit == 0 ? 0 : (cardDue(card) / card.limit).clamp(0, 1);
  DateTime nextDueDate(CreditCardAccount card) =>
      nextLocalDueDate(today, card.dueDay);

  CreditCardAccount? get nearestDueCard {
    final active = cards.where((c) => cardDue(c) > 0).toList()
      ..sort((a, b) => nextDueDate(a).compareTo(nextDueDate(b)));
    return active.isEmpty ? null : active.first;
  }

  Future<TransactionPage> getTransactions(TransactionFilter filter) async {
    if (_database == null) {
      return const TransactionPage(items: [], totalCount: 0, totalAmount: 0);
    }
    return _database.getTransactions(filter);
  }

  @visibleForTesting
  Future<void> refreshForTesting() => _refresh();

  Future<void> _refresh() async {
    if (_database == null) return;
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);
    final snapshot = await _database.readAll(
      monthStart: monthStart,
      monthEnd: monthEnd,
    );
    cards
      ..clear()
      ..addAll(snapshot.cards);
    recentExpenses
      ..clear()
      ..addAll(snapshot.recentExpenses);
    _monthExpenses
      ..clear()
      ..addAll(snapshot.monthExpenses);
    _monthPayments
      ..clear()
      ..addAll(snapshot.monthPayments);
    cardExpensesTotal
      ..clear()
      ..addAll(snapshot.cardExpensesTotal);
    allPaymentsTotal = snapshot.allPaymentsTotal;
    _calculateAggregates();
    notifyListeners();
  }

  Future<void> _write(Future<void>? persistence, String message) async {
    if (persistence == null) return;
    try {
      await persistence;
    } catch (_) {
      throw PersistenceException(message);
    }
  }

  factory FinanceStore.fromBackupJson(String source, {Clock? clock}) {
    return FinanceStoreBackup.fromBackupJson(source, clock: clock);
  }
}
