import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/data/money.dart';
import 'package:sarfaty/src/models/finance_models.dart';
import 'package:sarfaty/src/state/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('poundsToPiastres rounding', () {
    test('0.01 pound is exactly 1 piastre', () {
      expect(poundsToPiastres(0.01), 1);
      expect(piastresToPounds(1), 0.01);
    });

    test('10.25 pounds is exactly 1025 piastres', () {
      expect(poundsToPiastres(10.25), 1025);
      expect(piastresToPounds(1025), 10.25);
    });

    test('half piastre rounds away from zero', () {
      // 1.005 LE → 100.5 piastres → 101
      expect(poundsToPiastres(1.005), 101);
      expect(poundsToPiastres(-1.005), -101);
      // 0.015 LE → 1.5 piastres → 2
      expect(poundsToPiastres(0.015), 2);
      expect(migrateRealPoundsToPiastres(10.255), 1026);
    });
  });

  test('cash expense reduces available balance', () async {
    final store = FinanceStore(
      startingBalance: poundsToPiastres(1000),
      clock: () => DateTime(2026, 9, 15, 12),
    );
    await store.addExpense(
      amount: 125,
      category: ExpenseCategory.food,
      method: PaymentMethod.cash,
      date: DateTime(2026, 9, 15),
    );
    expect(store.availableBalance, poundsToPiastres(875));
    expect(store.cashTotal, poundsToPiastres(125));
  });

  test('updating starting balance persists and recalculates balance', () async {
    final db = FakeDatabase();
    final store = FinanceStore(
      startingBalance: 0,
      database: db,
      clock: () => DateTime(2026, 9, 15, 12),
    );
    await store.addExpense(
      amount: 125,
      category: ExpenseCategory.food,
      method: PaymentMethod.cash,
      date: DateTime(2026, 9, 15),
    );

    expect(await store.setStartingBalance(1000), isTrue);
    expect(db.settings['starting_balance'], '${poundsToPiastres(1000)}');
    expect(store.availableBalance, poundsToPiastres(875));
    expect(await store.setStartingBalance(-1), isFalse);
  });

  test('updating language persists before changing memory', () async {
    final db = FakeDatabase();
    final store = FinanceStore(startingBalance: 0, database: db);

    await store.setLanguagePreference('en');

    expect(db.settings['language'], 'en');
    expect(store.languagePreference, 'en');

    db.failWrites = true;
    await expectLater(
      store.setLanguagePreference('ar'),
      throwsA(isA<PersistenceException>()),
    );
    expect(store.languagePreference, 'en');
  });

  test('expense reminder preference is persisted', () async {
    final db = FakeDatabase();
    final store = FinanceStore(startingBalance: 0, database: db);

    await store.setExpenseRemindersEnabled(true);

    expect(store.expenseRemindersEnabled, isTrue);
    expect(db.settings['expense_reminders_enabled'], '1');
  });

  test('custom category rejects empty and duplicate names', () async {
    final db = FakeDatabase();
    final store = FinanceStore(startingBalance: 0, database: db);

    await expectLater(
      store.addCustomCategory('   '),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'اسم التصنيف مطلوب',
        ),
      ),
    );
    final category = await store.addCustomCategory('بنزين');

    expect(category.name, 'بنزين');
    expect(db.customCategories.single.name, 'بنزين');
    await expectLater(
      store.addCustomCategory('  بنزين  '),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'هذا التصنيف موجود بالفعل',
        ),
      ),
    );
    await expectLater(
      store.addCustomCategory('فواتير'),
      throwsA(isA<FormatException>()),
    );
  });

  test('custom category is attached without becoming an enum value', () async {
    final db = FakeDatabase();
    final store = FinanceStore(
      startingBalance: poundsToPiastres(100),
      database: db,
      clock: () => DateTime(2026, 9, 15, 12),
    );
    final category = await store.addCustomCategory('بنزين');

    await store.addExpense(
      amount: 25,
      category: ExpenseCategory.other,
      customCategory: category,
      method: PaymentMethod.cash,
      date: DateTime(2026, 9, 15),
    );

    final expense = store.monthExpenses.single;
    expect(expense.category, ExpenseCategory.other);
    expect(expense.customCategoryId, category.id);
    expect(expense.customCategoryName, 'بنزين');
    expect(store.topCustomCategoryName, 'بنزين');
  });

  test('credit expense increases card due without reducing balance', () async {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: poundsToPiastres(1000),
      statementDay: 20,
      dueDay: 8,
    );
    final store = FinanceStore(
      startingBalance: poundsToPiastres(1000),
      cards: [card],
      clock: () => DateTime(2026, 9, 15, 12),
    );
    await store.addExpense(
      amount: 300,
      category: ExpenseCategory.shopping,
      method: PaymentMethod.credit,
      cardId: 'c',
      date: DateTime(2026, 9, 15),
    );
    expect(store.cardDue(card), poundsToPiastres(300));
    expect(store.availableBalance, poundsToPiastres(1000));
  });

  test('paying card clears due and reduces balance', () async {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: poundsToPiastres(1000),
      statementDay: 20,
      dueDay: 8,
      openingDue: poundsToPiastres(250),
    );
    final store = FinanceStore(
      startingBalance: poundsToPiastres(1000),
      cards: [card],
    );
    expect(await store.payCard(card, 250), isTrue);
    expect(store.cardDue(card), 0);
    expect(store.availableBalance, poundsToPiastres(750));
  });

  test('payment is rejected when balance is insufficient', () async {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: poundsToPiastres(1000),
      statementDay: 20,
      dueDay: 8,
      openingDue: poundsToPiastres(500),
    );
    final store = FinanceStore(
      startingBalance: poundsToPiastres(100),
      cards: [card],
    );
    expect(await store.payCard(card, 500), isFalse);
    expect(store.cardDue(card), poundsToPiastres(500));
  });

  test('partial payment reduces due and available balance', () async {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: poundsToPiastres(1000),
      statementDay: 20,
      dueDay: 8,
      openingDue: poundsToPiastres(500),
    );
    final store = FinanceStore(
      startingBalance: poundsToPiastres(1000),
      cards: [card],
    );
    expect(await store.payCard(card, 200), isTrue);
    expect(store.cardDue(card), poundsToPiastres(300));
    expect(store.availableBalance, poundsToPiastres(800));
    expect(store.monthPayments.single.amount, poundsToPiastres(200));
  });

  test('payment rejected when amount exceeds due after rounding', () async {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: poundsToPiastres(1000),
      statementDay: 20,
      dueDay: 8,
      openingDue: 1, // 0.01 LE
    );
    final store = FinanceStore(
      startingBalance: poundsToPiastres(1000),
      cards: [card],
    );
    expect(await store.payCard(card, 0.01), isTrue);
    expect(store.cardDue(card), 0);

    final card2 = CreditCardAccount(
      id: 'c2',
      name: 'test2',
      limit: poundsToPiastres(1000),
      statementDay: 20,
      dueDay: 8,
      openingDue: 1,
    );
    final store2 = FinanceStore(
      startingBalance: poundsToPiastres(1000),
      cards: [card2],
    );
    // 0.015 LE → 2 piastres > 1 due
    expect(await store2.payCard(card2, 0.015), isFalse);
    expect(card2.paid, 0);
  });

  test('stores 0.01 and 10.25 expenses as piastres', () async {
    final store = FinanceStore(
      startingBalance: poundsToPiastres(100),
      clock: () => DateTime(2026, 9, 15, 12),
    );
    await store.addExpense(
      amount: 0.01,
      category: ExpenseCategory.food,
      method: PaymentMethod.cash,
      date: DateTime(2026, 9, 15),
    );
    await store.addExpense(
      amount: 10.25,
      category: ExpenseCategory.bills,
      method: PaymentMethod.cash,
      date: DateTime(2026, 9, 15),
    );
    expect(store.monthExpenses.map((e) => e.amount), [1025, 1]);
    expect(store.availableBalance, poundsToPiastres(100) - 1025 - 1);
  });

  test('successful persist updates memory only after write', () async {
    final db = FakeDatabase();
    final store = FinanceStore(
      startingBalance: poundsToPiastres(500),
      database: db,
    );
    await store.addExpense(
      amount: 40,
      category: ExpenseCategory.food,
      method: PaymentMethod.cash,
      date: DateTime(2026, 9, 1),
    );
    expect(db.writeCount, 1);
    expect(db.expenses, hasLength(1));
    expect(store.monthExpenses, hasLength(1));
    expect(store.monthExpenses.single.amount, poundsToPiastres(40));
    expect(store.availableBalance, poundsToPiastres(460));
  });

  test(
    'failed persist leaves memory unchanged and throws Arabic message',
    () async {
      final db = FakeDatabase(failWrites: true);
      final store = FinanceStore(
        startingBalance: poundsToPiastres(500),
        database: db,
      );

      await expectLater(
        store.addExpense(
          amount: 40,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: DateTime(2026, 9, 1),
        ),
        throwsA(
          isA<PersistenceException>().having(
            (e) => e.message,
            'message',
            'تعذر حفظ المصروف. حاول مرة أخرى.',
          ),
        ),
      );
      expect(store.monthExpenses, isEmpty);
      expect(db.expenses, isEmpty);
      expect(store.availableBalance, poundsToPiastres(500));

      final card = CreditCardAccount(
        id: 'c',
        name: 'test',
        limit: poundsToPiastres(1000),
        statementDay: 20,
        dueDay: 8,
        openingDue: poundsToPiastres(100),
      );
      final payStore = FinanceStore(
        startingBalance: poundsToPiastres(500),
        cards: [card],
        database: db,
      );
      await expectLater(
        payStore.payCard(card, 50),
        throwsA(
          isA<PersistenceException>().having(
            (e) => e.message,
            'message',
            'تعذر تسجيل السداد. حاول مرة أخرى.',
          ),
        ),
      );
      expect(card.paid, 0);
      expect(payStore.monthPayments, isEmpty);
      expect(payStore.availableBalance, poundsToPiastres(500));
    },
  );
}
