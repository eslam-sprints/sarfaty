import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/models/finance_models.dart';
import 'package:sarfaty/src/state/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('cash expense reduces available balance', () {
    final store = FinanceStore(startingBalance: 1000);
    store.addExpense(
      amount: 125,
      category: ExpenseCategory.food,
      method: PaymentMethod.cash,
      date: DateTime.now(),
    );
    expect(store.availableBalance, 875);
    expect(store.cashTotal, 125);
  });
  test('credit expense increases card due without reducing balance', () {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: 1000,
      statementDay: 20,
      dueDay: 8,
    );
    final store = FinanceStore(startingBalance: 1000, cards: [card]);
    store.addExpense(
      amount: 300,
      category: ExpenseCategory.shopping,
      method: PaymentMethod.credit,
      cardId: 'c',
      date: DateTime.now(),
    );
    expect(store.cardDue(card), 300);
    expect(store.availableBalance, 1000);
  });
  test('paying card clears due and reduces balance', () {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: 1000,
      statementDay: 20,
      dueDay: 8,
      openingDue: 250,
    );
    final store = FinanceStore(startingBalance: 1000, cards: [card]);
    expect(store.payCard(card, 250), isTrue);
    expect(store.cardDue(card), 0);
    expect(store.availableBalance, 750);
  });
  test('payment is rejected when balance is insufficient', () {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: 1000,
      statementDay: 20,
      dueDay: 8,
      openingDue: 500,
    );
    final store = FinanceStore(startingBalance: 100, cards: [card]);
    expect(store.payCard(card, 500), isFalse);
    expect(store.cardDue(card), 500);
  });
  test('partial payment reduces due and available balance', () {
    final card = CreditCardAccount(
      id: 'c',
      name: 'test',
      limit: 1000,
      statementDay: 20,
      dueDay: 8,
      openingDue: 500,
    );
    final store = FinanceStore(startingBalance: 1000, cards: [card]);
    expect(store.payCard(card, 200), isTrue);
    expect(store.cardDue(card), 300);
    expect(store.availableBalance, 800);
    expect(store.payments.single.amount, 200);
  });
  test('backup round-trip preserves all data', () {
    final original = FinanceStore.seeded();
    final restored = FinanceStore.fromBackupJson(original.exportJson());
    expect(restored.startingBalance, original.startingBalance);
    expect(restored.expenses.length, original.expenses.length);
    expect(restored.cards.length, original.cards.length);
  });
  test('invalid backup is rejected', () {
    expect(
      () => FinanceStore.fromBackupJson('{"schemaVersion":99}'),
      throwsFormatException,
    );
  });
}
