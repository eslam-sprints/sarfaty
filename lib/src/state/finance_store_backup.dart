part of 'finance_store.dart';

extension FinanceStoreBackup on FinanceStore {
  /// Exports schemaVersion 1 with pound decimals so older importers still work.
  /// Instants use UTC `Z`; expense dates use date-only `YYYY-MM-DD`.
  Future<String> exportJson() async {
    List<Expense> exportExpenses = _monthExpenses;
    List<PaymentRecord> exportPayments = _monthPayments;

    if (_database != null) {
      final snapshot = await _database.readAll(
        monthStart: DateTime(2000),
        monthEnd: DateTime(2100),
      );
      exportExpenses = snapshot.monthExpenses;
      exportPayments = snapshot.monthPayments;
    }

    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'exportedAt': encodeInstantToUtcIso(now),
      'startingBalance': piastresToPounds(startingBalance),
      'expenses': exportExpenses.map((e) => e.toJson()).toList(),
      'customCategories': customCategories.map((c) => c.toJson()).toList(),
      'cards': cards.map((c) => c.toJson()).toList(),
      'payments': exportPayments.map((p) => p.toJson()).toList(),
      'settings': {
        'currency': 'EGP',
        'locale': languagePreference,
        'theme': themePreference,
        'onboardingCompleted': onboardingCompleted,
        'biometricLockEnabled': biometricLockEnabled,
        'expenseRemindersEnabled': expenseRemindersEnabled,
      },
    });
  }

  static FinanceStore fromBackupJson(String source, {Clock? clock}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('نسخة احتياطية غير مدعومة');
    }
    final balance = decoded['startingBalance'];
    final expenseData = decoded['expenses'];
    final cardData = decoded['cards'];
    final paymentData = decoded['payments'];
    final customCategoryData = decoded['customCategories'];
    if (balance is! num ||
        expenseData is! List ||
        cardData is! List ||
        paymentData is! List) {
      throw const FormatException('بيانات النسخة الاحتياطية ناقصة');
    }
    final settings = decoded['settings'];
    final theme = settings is Map ? settings['theme'] : null;
    final language = settings is Map ? settings['locale'] : null;
    final onboarding = settings is Map ? settings['onboardingCompleted'] : null;
    final biometric = settings is Map ? settings['biometricLockEnabled'] : null;
    final reminders = settings is Map
        ? settings['expenseRemindersEnabled']
        : null;
    if (customCategoryData != null && customCategoryData is! List) {
      throw const FormatException('بيانات النسخة الاحتياطية ناقصة');
    }
    final parsedCustomCategories = customCategoryData is List
        ? customCategoryData
              .map(
                (entry) => CustomExpenseCategory.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList()
        : <CustomExpenseCategory>[];
    final categoryIds = parsedCustomCategories.map((item) => item.id).toSet();
    final categoryNames = parsedCustomCategories
        .map((item) => item.name.trim().toLowerCase())
        .toSet();
    if (parsedCustomCategories.any(
          (item) => item.id.isEmpty || item.name.trim().isEmpty,
        ) ||
        categoryIds.length != parsedCustomCategories.length ||
        categoryNames.length != parsedCustomCategories.length) {
      throw const FormatException('بيانات النسخة الاحتياطية ناقصة');
    }
    final store = FinanceStore(
      startingBalance: poundsToPiastres(balance),
      themePreference:
          theme is String && {'system', 'light', 'dark'}.contains(theme)
          ? theme
          : 'system',
      languagePreference: language is String && {'ar', 'en'}.contains(language)
          ? language
          : 'ar',
      // النسخ القديمة بلا المفتاح تُعامل كمكتملة حتى لا تُعاد المقدمة بعد الاستيراد.
      onboardingCompleted: onboarding == null
          ? true
          : onboarding == true || onboarding == '1',
      biometricLockEnabled: biometric == true || biometric == '1',
      expenseRemindersEnabled: reminders == true || reminders == '1',
      customCategories: parsedCustomCategories,
      clock: clock,
    );

    // Populate fields
    store.cards.addAll(
      cardData.map(
        (e) => CreditCardAccount.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
    );

    final customCategoryNames = {
      for (final category in store.customCategories) category.id: category.name,
    };
    final importedExpenses = expenseData
        .map(
          (e) => Expense.fromJson(
            Map<String, dynamic>.from(e as Map),
            customCategoryNames: customCategoryNames,
          ),
        )
        .toList();

    final importedPayments = paymentData
        .map((e) => PaymentRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    store._monthExpenses.addAll(importedExpenses);
    store._monthPayments.addAll(importedPayments);
    store.recentExpenses.addAll(importedExpenses.take(5));

    for (final e in importedExpenses) {
      if (e.cardId != null) {
        store.cardExpensesTotal[e.cardId!] =
            (store.cardExpensesTotal[e.cardId!] ?? 0) + e.amount;
      }
    }
    store.allPaymentsTotal = importedPayments.fold(
      0,
      (sum, p) => sum + p.amount,
    );
    store._calculateAggregates();

    final cardIds = store.cards.map((c) => c.id).toSet();
    final customCategoryIds = store.customCategories.map((c) => c.id).toSet();
    if (store._monthExpenses.any(
      (expense) =>
          expense.customCategoryId != null &&
          !customCategoryIds.contains(expense.customCategoryId),
    )) {
      throw const FormatException('تحتوي النسخة على مراجع تصنيفات غير صحيحة');
    }
    if (store._monthExpenses.any(
          (e) =>
              e.method == PaymentMethod.credit &&
              (e.cardId == null || !cardIds.contains(e.cardId)),
        ) ||
        store._monthPayments.any((p) => !cardIds.contains(p.cardId))) {
      throw const FormatException('تحتوي النسخة على مراجع بطاقات غير صحيحة');
    }
    return store;
  }

  Future<void> importJson(String source) async {
    final imported = FinanceStoreBackup.fromBackupJson(source, clock: _clock);
    final snapshot = DatabaseSnapshot(
      startingBalance: imported.startingBalance,
      themePreference: imported.themePreference,
      languagePreference: imported.languagePreference,
      onboardingCompleted: imported.onboardingCompleted,
      biometricLockEnabled: imported.biometricLockEnabled,
      expenseRemindersEnabled: imported.expenseRemindersEnabled,
      customCategories: imported.customCategories,
      recentExpenses: imported.recentExpenses,
      monthExpenses: imported.monthExpenses.toList(),
      monthPayments: imported.monthPayments.toList(),
      cards: imported.cards,
      cardExpensesTotal: imported.cardExpensesTotal,
      allPaymentsTotal: imported.allPaymentsTotal,
    );
    await _write(
      _database?.replaceAll(snapshot),
      'تعذر استيراد النسخة الاحتياطية. حاول مرة أخرى.',
    );
    await _refresh();
  }
}
