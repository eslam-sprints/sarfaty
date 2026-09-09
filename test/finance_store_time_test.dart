import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/data/time_codec.dart';
import 'package:sarfaty/src/data/money.dart';
import 'package:sarfaty/src/models/finance_models.dart';
import 'package:sarfaty/src/state/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('UTC date-only vs instant', () {
    test('local date round-trips through UTC ms without day shift', () {
      final local = DateTime(2026, 9, 8);
      final ms = encodeLocalDateToUtcMs(local);
      final back = decodeLocalDateFromUtcMs(ms);
      expect(back.year, 2026);
      expect(back.month, 9);
      expect(back.day, 8);
      expect(back.isUtc, isFalse);
      expect(back.hour, 0);
      expect(back.minute, 0);
    });

    test('instant JSON uses Z and round-trips to the same UTC moment', () {
      final instant = DateTime.utc(2026, 9, 8, 21, 30, 0);
      final encoded = encodeInstantToUtcIso(instant);
      expect(encoded.endsWith('Z'), isTrue);
      expect(encoded, isNot(contains('+')));
      final back = decodeInstantFromJson(encoded);
      expect(back.isUtc, isTrue);
      expect(back.millisecondsSinceEpoch, instant.millisecondsSinceEpoch);
      expect(encodeInstantToUtcMs(instant), instant.millisecondsSinceEpoch);
      expect(
        decodeInstantFromUtcMs(
          instant.millisecondsSinceEpoch,
        ).millisecondsSinceEpoch,
        instant.millisecondsSinceEpoch,
      );
    });

    test(
      'legacy JSON date without Z keeps the intended local calendar day',
      () {
        expect(
          decodeLocalDateFromJson('2026-01-02T00:00:00.000'),
          DateTime(2026, 1, 2),
        );
        expect(decodeLocalDateFromJson('2026-01-02'), DateTime(2026, 1, 2));
        expect(
          encodeLocalDateToJson(DateTime(2026, 1, 2, 18, 45)),
          '2026-01-02',
        );
      },
    );

    test(
      'monthExpenses respects month boundaries with a fixed clock',
      () async {
        final store = FinanceStore(
          startingBalance: poundsToPiastres(1000),
          clock: () => DateTime(2026, 9, 1, 0, 30),
        );
        await store.addExpense(
          amount: 10,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: DateTime(2026, 8, 31),
        );
        await store.addExpense(
          amount: 20,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: DateTime(2026, 9, 1),
        );
        await store.addExpense(
          amount: 30,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: DateTime(2026, 9, 30),
        );
        await store.addExpense(
          amount: 40,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: DateTime(2026, 10, 1),
        );

        expect(store.monthExpenses.map((e) => e.amount), [3000, 2000]);
        expect(store.monthlyTotal, poundsToPiastres(50));
        expect(store.cashTotal, poundsToPiastres(50));
        expect(
          store.availableBalance,
          poundsToPiastres(1000) - poundsToPiastres(50),
        );
      },
    );

    test('month roll at end of month with fixed clock', () async {
      final db = FakeDatabase();
      final store = FinanceStore(
        startingBalance: poundsToPiastres(500),
        database: db,
        clock: () => DateTime(2026, 9, 30, 23, 59),
      );
      await store.addExpense(
        amount: 5,
        category: ExpenseCategory.other,
        method: PaymentMethod.cash,
        date: DateTime(2026, 9, 30),
      );
      expect(store.monthExpenses, hasLength(1));

      final october = FinanceStore(
        startingBalance: poundsToPiastres(500),
        database: db,
        clock: () => DateTime(2026, 10, 1, 0, 1),
      );
      await october.refreshForTesting();
      expect(october.monthExpenses, isEmpty);
      expect(october.monthlyTotal, 0);
    });

    test('nextDueDate uses local calendar around midnight and month end', () {
      final onDueDay = FinanceStore(
        startingBalance: 0,
        cards: [
          CreditCardAccount(
            id: 'c',
            name: 't',
            limit: 100,
            statementDay: 20,
            dueDay: 8,
            openingDue: 1,
          ),
        ],
        clock: () => DateTime(2026, 9, 8, 0, 15),
      );
      expect(onDueDay.nextDueDate(onDueDay.cards.single), DateTime(2026, 9, 8));

      final afterDue = FinanceStore(
        startingBalance: 0,
        cards: onDueDay.cards,
        clock: () => DateTime(2026, 9, 9, 0, 0),
      );
      expect(
        afterDue.nextDueDate(afterDue.cards.single),
        DateTime(2026, 10, 8),
      );

      final monthEnd = FinanceStore(
        startingBalance: 0,
        cards: [
          CreditCardAccount(
            id: 'c2',
            name: 't2',
            limit: 100,
            statementDay: 1,
            dueDay: 31,
            openingDue: 1,
          ),
        ],
        clock: () => DateTime(2026, 8, 31, 23, 30),
      );
      expect(
        monthEnd.nextDueDate(monthEnd.cards.single),
        DateTime(2026, 8, 31),
      );

      final afterMonthEnd = FinanceStore(
        startingBalance: 0,
        cards: monthEnd.cards,
        clock: () => DateTime(2026, 9, 1, 0, 0),
      );
      expect(
        afterMonthEnd.nextDueDate(afterMonthEnd.cards.single),
        DateTime(2026, 9, 31),
      );
    });

    test('payment instant is stored UTC and counted in local month', () async {
      final card = CreditCardAccount(
        id: 'c',
        name: 'test',
        limit: poundsToPiastres(1000),
        statementDay: 20,
        dueDay: 8,
        openingDue: poundsToPiastres(100),
      );
      final store = FinanceStore(
        startingBalance: poundsToPiastres(1000),
        cards: [card],
        clock: () => DateTime(2026, 9, 15, 3, 0),
      );
      expect(await store.payCard(card, 50), isTrue);
      expect(store.monthPayments.single.date.isUtc, isTrue);
      expect(store.monthlyPayments, poundsToPiastres(50));

      final json = await store.exportJson();
      expect(RegExp(r'"exportedAt": "[^"]+Z"').hasMatch(json), isTrue);
      expect(RegExp(r'"date": "[^"]+Z"').hasMatch(json), isTrue);

      final restored = FinanceStore.fromBackupJson(
        json,
        clock: () => DateTime(2026, 9, 15, 3, 0),
      );
      expect(restored.monthPayments.single.date.isUtc, isTrue);
      expect(
        restored.monthPayments.single.date.millisecondsSinceEpoch,
        store.monthPayments.single.date.millisecondsSinceEpoch,
      );
    });

    test(
      'expense JSON date-only survives export/import without day shift',
      () async {
        final store = FinanceStore(
          startingBalance: 0,
          clock: () => DateTime(2026, 3, 10, 12),
        );
        await store.addExpense(
          amount: 1,
          category: ExpenseCategory.food,
          method: PaymentMethod.cash,
          date: DateTime(2026, 3, 10),
        );
        final restored = FinanceStore.fromBackupJson(await store.exportJson());
        expect(restored.monthExpenses.single.date, DateTime(2026, 3, 10));
        expect(
          encodeLocalDateToJson(restored.monthExpenses.single.date),
          '2026-03-10',
        );
      },
    );
  });
}
