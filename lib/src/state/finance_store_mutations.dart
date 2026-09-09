// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
part of 'finance_store.dart';

extension FinanceStoreMutations on FinanceStore {
  /// [amount] is in pounds (UI input); stored as piastres.
  /// [date] is the user's local **date-only** selection.
  Future<void> addExpense({
    required double amount,
    required ExpenseCategory category,
    required PaymentMethod method,
    required DateTime date,
    String? cardId,
    String? note,
  }) async {
    final expense = Expense(
      id: now.microsecondsSinceEpoch.toString(),
      amount: poundsToPiastres(amount),
      category: category,
      method: method,
      date: localDateOnly(date),
      cardId: cardId,
      note: note,
    );

    // Optimistic update
    recentExpenses.insert(0, expense);
    final addedToMonth = isSameLocalMonth(expense.date, today);
    if (addedToMonth) {
      _monthExpenses.insert(0, expense);
    }
    if (expense.cardId != null) {
      cardExpensesTotal[expense.cardId!] =
          (cardExpensesTotal[expense.cardId!] ?? 0) + expense.amount;
    }
    _calculateAggregates();
    notifyListeners();

    try {
      await _write(
        _database?.upsertExpense(expense),
        'تعذر حفظ المصروف. حاول مرة أخرى.',
      );
    } catch (e) {
      recentExpenses.remove(expense);
      if (addedToMonth) {
        _monthExpenses.remove(expense);
      }
      if (expense.cardId != null) {
        cardExpensesTotal[expense.cardId!] =
            (cardExpensesTotal[expense.cardId!] ?? 0) - expense.amount;
      }
      _calculateAggregates();
      notifyListeners();
      rethrow;
    }
    await _refresh();
  }

  /// [amount] is in pounds (UI input); stored as piastres.
  Future<bool> updateExpense({
    required String id,
    required double amount,
    required ExpenseCategory category,
    required PaymentMethod method,
    required DateTime date,
    String? cardId,
    String? note,
  }) async {
    final updated = Expense(
      id: id,
      amount: poundsToPiastres(amount),
      category: category,
      method: method,
      date: localDateOnly(date),
      cardId: method == PaymentMethod.credit ? cardId : null,
      note: note,
    );

    // Optimistic update
    final monthIndex = _monthExpenses.indexWhere((e) => e.id == id);
    Expense? old;
    if (monthIndex != -1) {
      old = _monthExpenses[monthIndex];
      if (old.cardId != null) {
        cardExpensesTotal[old.cardId!] =
            (cardExpensesTotal[old.cardId!] ?? 0) - old.amount;
      }
      _monthExpenses[monthIndex] = updated;
      if (updated.cardId != null) {
        cardExpensesTotal[updated.cardId!] =
            (cardExpensesTotal[updated.cardId!] ?? 0) + updated.amount;
      }
      _monthExpenses.sort((a, b) => b.date.compareTo(a.date));
      _calculateAggregates();
      notifyListeners();
    }

    try {
      await _write(
        _database?.upsertExpense(updated),
        'تعذر حفظ التعديلات. حاول مرة أخرى.',
      );
    } catch (e) {
      if (old != null) {
        final revertIndex = _monthExpenses.indexWhere((e) => e.id == id);
        if (revertIndex != -1) {
          if (updated.cardId != null) {
            cardExpensesTotal[updated.cardId!] =
                (cardExpensesTotal[updated.cardId!] ?? 0) - updated.amount;
          }
          _monthExpenses[revertIndex] = old;
          if (old.cardId != null) {
            cardExpensesTotal[old.cardId!] =
                (cardExpensesTotal[old.cardId!] ?? 0) + old.amount;
          }
          _monthExpenses.sort((a, b) => b.date.compareTo(a.date));
          _calculateAggregates();
          notifyListeners();
        }
      }
      rethrow;
    }
    await _refresh();
    return true;
  }

  Future<bool> deleteExpense(String id) async {
    // Optimistic update
    final monthIndex = _monthExpenses.indexWhere((e) => e.id == id);
    Expense? old;
    if (monthIndex != -1) {
      old = _monthExpenses.removeAt(monthIndex);
      if (old.cardId != null) {
        cardExpensesTotal[old.cardId!] =
            (cardExpensesTotal[old.cardId!] ?? 0) - old.amount;
      }
      _calculateAggregates();
      notifyListeners();
    }

    try {
      await _write(
        _database?.deleteExpense(id),
        'تعذر حذف المصروف. حاول مرة أخرى.',
      );
    } catch (e) {
      if (old != null) {
        _monthExpenses.add(old);
        if (old.cardId != null) {
          cardExpensesTotal[old.cardId!] =
              (cardExpensesTotal[old.cardId!] ?? 0) + old.amount;
        }
        _monthExpenses.sort((a, b) => b.date.compareTo(a.date));
        _calculateAggregates();
        notifyListeners();
      }
      rethrow;
    }
    await _refresh();
    return true;
  }

  /// [limit] is in pounds (UI input); stored as piastres.
  Future<void> addCard({
    required String name,
    required double limit,
    required int statementDay,
    required int dueDay,
  }) async {
    final card = CreditCardAccount(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      limit: poundsToPiastres(limit),
      statementDay: statementDay,
      dueDay: dueDay,
    );
    await _write(
      _database?.insertCard(card),
      'تعذر حفظ البطاقة. حاول مرة أخرى.',
    );
    await _refresh();
  }

  /// [amount] is in pounds (UI input); compared and stored as piastres.
  Future<bool> payCard(CreditCardAccount card, double amount) async {
    final due = cardDue(card);
    final amountPiastres = poundsToPiastres(amount);
    if (amountPiastres <= 0 ||
        amountPiastres > due ||
        availableBalance < amountPiastres) {
      return false;
    }
    final previousPaid = card.paid;
    final payment = PaymentRecord(
      cardId: card.id,
      amount: amountPiastres,
      date: now.toUtc(),
    );
    card.paid += amountPiastres;

    // Optimistic update
    if (isSameLocalMonth(payment.date, today)) {
      _monthPayments.add(payment);
    }
    allPaymentsTotal += amountPiastres;
    _calculateAggregates();
    notifyListeners();

    try {
      await _write(
        _database?.recordPayment(card, payment),
        'تعذر تسجيل السداد. حاول مرة أخرى.',
      );
    } on PersistenceException {
      card.paid = previousPaid;
      if (isSameLocalMonth(payment.date, today)) {
        _monthPayments.remove(payment);
      }
      allPaymentsTotal -= amountPiastres;
      _calculateAggregates();
      notifyListeners();
      rethrow;
    }
    await _refresh();
    return true;
  }

  Future<void> setThemePreference(String value) async {
    if (!{'system', 'light', 'dark'}.contains(value)) return;
    await _write(
      _database?.saveSetting('theme', value),
      'تعذر حفظ الإعدادات. حاول مرة أخرى.',
    );
    themePreference = value;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (onboardingCompleted) return;
    await _write(
      _database?.saveSetting('onboarding_completed', '1'),
      'تعذر حفظ الإعدادات. حاول مرة أخرى.',
    );
    onboardingCompleted = true;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    await _write(
      _database?.saveSetting('onboarding_completed', '0'),
      'تعذر حفظ الإعدادات. حاول مرة أخرى.',
    );
    onboardingCompleted = false;
    notifyListeners();
  }
}
