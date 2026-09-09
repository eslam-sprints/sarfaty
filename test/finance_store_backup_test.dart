import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/state/finance_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_database.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('backup round-trip preserves all data', () async {
    final original = FinanceStore.seeded();
    await original.completeOnboarding();
    final restored = FinanceStore.fromBackupJson(await original.exportJson());
    expect(restored.startingBalance, original.startingBalance);
    expect(restored.monthExpenses.length, original.monthExpenses.length);
    expect(restored.cards.length, original.cards.length);
    expect(restored.onboardingCompleted, isTrue);
  });

  test('schemaVersion 1 decimal JSON imports into piastres', () async {
    const legacy = '''
{
  "schemaVersion": 1,
  "exportedAt": "2026-01-01T00:00:00.000",
  "startingBalance": 10.25,
  "expenses": [
    {
      "id": "e1",
      "amount": 0.01,
      "category": "food",
      "method": "cash",
      "date": "2026-01-02T00:00:00.000",
      "cardId": null,
      "note": null
    }
  ],
  "cards": [
    {
      "id": "c1",
      "name": "بنك",
      "limit": 1000.5,
      "statementDay": 20,
      "dueDay": 8,
      "openingDue": 1.005,
      "paid": 0
    }
  ],
  "payments": [],
  "settings": {"currency": "EGP", "locale": "ar", "theme": "system"}
}
''';
    final restored = FinanceStore.fromBackupJson(legacy);
    expect(restored.startingBalance, 1025);
    expect(restored.monthExpenses.single.amount, 1);
    expect(restored.cards.single.limit, 100050);
    expect(restored.cards.single.openingDue, 101);
    expect(restored.onboardingCompleted, isTrue);

    final exported = await restored.exportJson();
    expect(exported, contains('"schemaVersion": 1'));
    expect(exported, contains('"startingBalance": 10.25'));
    expect(exported, contains('"amount": 0.01'));
    expect(exported, contains('"date": "2026-01-02"'));
  });

  test('invalid backup is rejected', () {
    expect(
      () => FinanceStore.fromBackupJson('{"schemaVersion":99}'),
      throwsFormatException,
    );
  });

  test('onboarding starts incomplete and can be completed or reset', () async {
    final store = FinanceStore.seeded();
    expect(store.onboardingCompleted, isFalse);
    await store.completeOnboarding();
    expect(store.onboardingCompleted, isTrue);
    await store.completeOnboarding();
    expect(store.onboardingCompleted, isTrue);
    await store.resetOnboarding();
    expect(store.onboardingCompleted, isFalse);
  });

  test('legacy backup without onboarding flag is treated as completed', () {
    const legacy = '''
{
  "schemaVersion": 1,
  "exportedAt": "2026-01-01T00:00:00.000",
  "startingBalance": 0,
  "expenses": [],
  "cards": [],
  "payments": [],
  "settings": {"currency": "EGP", "locale": "ar", "theme": "system"}
}
''';
    final restored = FinanceStore.fromBackupJson(legacy);
    expect(restored.onboardingCompleted, isTrue);
  });

  test('failed setting write does not flip onboarding flag', () async {
    final db = FakeDatabase(failWrites: true);
    final store = FinanceStore(startingBalance: 0, database: db);
    await expectLater(
      store.completeOnboarding(),
      throwsA(isA<PersistenceException>()),
    );
    expect(store.onboardingCompleted, isFalse);
  });
}
