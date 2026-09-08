import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_models.dart';

class FinanceStore extends ChangeNotifier {
  FinanceStore({
    required this.startingBalance,
    List<Expense>? expenses,
    List<CreditCardAccount>? cards,
    List<PaymentRecord>? payments,
    this.themePreference = 'system',
  }) : expenses = expenses ?? [],
       cards = cards ?? [],
       payments = payments ?? [];

  static const _storageKey = 'sarfaty_backup_v1';
  static Future<FinanceStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) {
      final store = FinanceStore.seeded();
      await store._save();
      return store;
    }
    try {
      return FinanceStore.fromBackupJson(stored);
    } catch (_) {
      return FinanceStore.seeded();
    }
  }

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
  String themePreference;
  final List<Expense> expenses;
  final List<CreditCardAccount> cards;
  final List<PaymentRecord> payments;
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
  double get monthlyPayments => payments
      .where((p) {
        final now = DateTime.now();
        return p.date.year == now.year && p.date.month == now.month;
      })
      .fold(0, (sum, p) => sum + p.amount);
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
    _changed();
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
    _changed();
  }

  bool payCard(CreditCardAccount card, double amount) {
    final due = cardDue(card);
    if (amount <= 0 || amount > due || availableBalance < amount) return false;
    card.paid += amount;
    payments.add(
      PaymentRecord(cardId: card.id, amount: amount, date: DateTime.now()),
    );
    _changed();
    return true;
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'startingBalance': startingBalance,
    'expenses': expenses.map((e) => e.toJson()).toList(),
    'cards': cards.map((c) => c.toJson()).toList(),
    'payments': payments.map((p) => p.toJson()).toList(),
    'settings': {'currency': 'EGP', 'locale': 'ar', 'theme': themePreference},
  });

  factory FinanceStore.fromBackupJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('نسخة احتياطية غير مدعومة');
    }
    final balance = decoded['startingBalance'];
    final expenseData = decoded['expenses'];
    final cardData = decoded['cards'];
    final paymentData = decoded['payments'];
    if (balance is! num ||
        expenseData is! List ||
        cardData is! List ||
        paymentData is! List) {
      throw const FormatException('بيانات النسخة الاحتياطية ناقصة');
    }
    final settings = decoded['settings'];
    final theme = settings is Map ? settings['theme'] : null;
    final store = FinanceStore(
      startingBalance: balance.toDouble(),
      themePreference:
          theme is String && {'system', 'light', 'dark'}.contains(theme)
          ? theme
          : 'system',
      expenses: expenseData
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      cards: cardData
          .map(
            (e) =>
                CreditCardAccount.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      payments: paymentData
          .map(
            (e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
    final cardIds = store.cards.map((c) => c.id).toSet();
    if (store.expenses.any(
          (e) =>
              e.method == PaymentMethod.credit &&
              (e.cardId == null || !cardIds.contains(e.cardId)),
        ) ||
        store.payments.any((p) => !cardIds.contains(p.cardId))) {
      throw const FormatException('تحتوي النسخة على مراجع بطاقات غير صحيحة');
    }
    return store;
  }

  Future<void> importJson(String source) async {
    final imported = FinanceStore.fromBackupJson(source);
    startingBalance = imported.startingBalance;
    themePreference = imported.themePreference;
    expenses
      ..clear()
      ..addAll(imported.expenses);
    cards
      ..clear()
      ..addAll(imported.cards);
    payments
      ..clear()
      ..addAll(imported.payments);
    await _save();
    notifyListeners();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void setThemePreference(String value) {
    if (!{'system', 'light', 'dark'}.contains(value)) return;
    themePreference = value;
    _changed();
  }

  Future<void> _save() async => (await SharedPreferences.getInstance())
      .setString(_storageKey, exportJson());
}
