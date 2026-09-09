import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/data/money.dart';

/// Simulates ordered migration steps; failure leaves prior steps only if
/// [commit] is never called — mirrors all-or-nothing upgrade abort.
class _MigrationSandbox {
  final Map<String, Object?> tables = {};
  int userVersion = 1;
  bool committed = false;

  Future<void> run(Future<void> Function(_MigrationSandbox s) body) async {
    final draft = Map<String, Object?>.of(tables);
    try {
      await body(this);
      committed = true;
      userVersion = 2;
    } catch (_) {
      tables
        ..clear()
        ..addAll(draft);
      committed = false;
      rethrow;
    }
  }
}

void main() {
  test(
    'failed migration rolls back draft state and keeps user_version',
    () async {
      final sandbox = _MigrationSandbox()
        ..tables['expense_amount'] = 10.25
        ..tables['starting_balance'] = '100.5';

      await expectLater(
        sandbox.run((s) async {
          s.tables['expense_amount'] = migrateRealPoundsToPiastres(
            s.tables['expense_amount']! as num,
          );
          s.tables['starting_balance'] = migrateRealPoundsToPiastres(
            double.parse(s.tables['starting_balance']! as String),
          );
          throw StateError('simulated migration failure');
        }),
        throwsStateError,
      );

      expect(sandbox.committed, isFalse);
      expect(sandbox.userVersion, 1);
      expect(sandbox.tables['expense_amount'], 10.25);
      expect(sandbox.tables['starting_balance'], '100.5');
    },
  );

  test('successful migration converts REAL pounds to piastres', () async {
    final sandbox = _MigrationSandbox()
      ..tables['expense_amount'] = 10.25
      ..tables['starting_balance'] = '100.5';

    await sandbox.run((s) async {
      s.tables['expense_amount'] = migrateRealPoundsToPiastres(
        s.tables['expense_amount']! as num,
      );
      s.tables['starting_balance'] = migrateRealPoundsToPiastres(
        double.parse(s.tables['starting_balance']! as String),
      );
    });

    expect(sandbox.committed, isTrue);
    expect(sandbox.userVersion, 2);
    expect(sandbox.tables['expense_amount'], 1025);
    expect(sandbox.tables['starting_balance'], 10050);
  });
}
