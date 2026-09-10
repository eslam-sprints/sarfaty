import 'package:sqflite/sqflite.dart';
import 'money.dart';

class DatabaseSchema {
  /// Current on-disk schema. v1 used REAL pounds; v2 uses INTEGER piastres.
  static const int schemaVersion = 2;

  static Future<void> createV2Schema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        credit_limit INTEGER NOT NULL CHECK(credit_limit > 0),
        statement_day INTEGER NOT NULL,
        due_day INTEGER NOT NULL,
        opening_due INTEGER NOT NULL CHECK(opening_due >= 0),
        paid INTEGER NOT NULL CHECK(paid >= 0)
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL CHECK(amount > 0),
        category TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        expense_date INTEGER NOT NULL,
        card_id TEXT,
        note TEXT,
        FOREIGN KEY(card_id) REFERENCES cards(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX expenses_date_idx ON expenses(expense_date DESC)',
    );
    await db.execute('CREATE INDEX expenses_card_idx ON expenses(card_id)');
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id TEXT NOT NULL,
        amount INTEGER NOT NULL CHECK(amount > 0),
        payment_date INTEGER NOT NULL,
        FOREIGN KEY(card_id) REFERENCES cards(id)
      )
    ''');
    await db.insert('settings', {'key': 'starting_balance', 'value': '0'});
    await db.insert('settings', {'key': 'theme', 'value': 'system'});
    await db.insert('settings', {'key': 'onboarding_completed', 'value': '0'});
    await db.insert('settings', {
      'key': 'biometric_lock_enabled',
      'value': '0',
    });
  }

  /// Safe v1 (REAL pounds) → v2 (INTEGER piastres) migration.
  ///
  /// Each amount is converted with [migrateRealPoundsToPiastres] (nearest
  /// piastre, half away from zero). On failure the upgrade aborts and SQLite
  /// leaves [user_version] unchanged (no partial bump).
  static Future<void> migrateV1RealToV2Piastres(DatabaseExecutor db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.execute('''
        CREATE TABLE cards_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          credit_limit INTEGER NOT NULL CHECK(credit_limit > 0),
          statement_day INTEGER NOT NULL,
          due_day INTEGER NOT NULL,
          opening_due INTEGER NOT NULL CHECK(opening_due >= 0),
          paid INTEGER NOT NULL CHECK(paid >= 0)
        )
      ''');
      final cardRows = await db.query('cards');
      for (final row in cardRows) {
        await db.insert('cards_new', {
          'id': row['id'],
          'name': row['name'],
          'credit_limit': migrateRealPoundsToPiastres(
            row['credit_limit'] as num,
          ),
          'statement_day': row['statement_day'],
          'due_day': row['due_day'],
          'opening_due': migrateRealPoundsToPiastres(row['opening_due'] as num),
          'paid': migrateRealPoundsToPiastres(row['paid'] as num),
        });
      }

      await db.execute('''
        CREATE TABLE expenses_new (
          id TEXT PRIMARY KEY,
          amount INTEGER NOT NULL CHECK(amount > 0),
          category TEXT NOT NULL,
          payment_method TEXT NOT NULL,
          expense_date INTEGER NOT NULL,
          card_id TEXT,
          note TEXT,
          FOREIGN KEY(card_id) REFERENCES cards_new(id)
        )
      ''');
      final expenseRows = await db.query('expenses');
      for (final row in expenseRows) {
        await db.insert('expenses_new', {
          'id': row['id'],
          'amount': migrateRealPoundsToPiastres(row['amount'] as num),
          'category': row['category'],
          'payment_method': row['payment_method'],
          'expense_date': row['expense_date'],
          'card_id': row['card_id'],
          'note': row['note'],
        });
      }

      await db.execute('''
        CREATE TABLE payments_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          card_id TEXT NOT NULL,
          amount INTEGER NOT NULL CHECK(amount > 0),
          payment_date INTEGER NOT NULL,
          FOREIGN KEY(card_id) REFERENCES cards_new(id)
        )
      ''');
      final paymentRows = await db.query('payments');
      for (final row in paymentRows) {
        await db.insert('payments_new', {
          'id': row['id'],
          'card_id': row['card_id'],
          'amount': migrateRealPoundsToPiastres(row['amount'] as num),
          'payment_date': row['payment_date'],
        });
      }

      await db.execute('DROP TABLE payments');
      await db.execute('DROP TABLE expenses');
      await db.execute('DROP TABLE cards');
      await db.execute('ALTER TABLE cards_new RENAME TO cards');
      await db.execute('ALTER TABLE expenses_new RENAME TO expenses');
      await db.execute('ALTER TABLE payments_new RENAME TO payments');
      await db.execute(
        'CREATE INDEX expenses_date_idx ON expenses(expense_date DESC)',
      );
      await db.execute('CREATE INDEX expenses_card_idx ON expenses(card_id)');

      final balanceRows = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: const ['starting_balance'],
      );
      if (balanceRows.isNotEmpty) {
        final raw = balanceRows.first['value'] as String? ?? '0';
        final pounds = double.tryParse(raw) ?? 0;
        await db.update(
          'settings',
          {'value': '${migrateRealPoundsToPiastres(pounds)}'},
          where: 'key = ?',
          whereArgs: const ['starting_balance'],
        );
      }
    } catch (_) {
      // Re-enable FKs before propagating so a failed open does not leave the
      // connection with foreign_keys OFF if the caller retries.
      await db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }
    await db.execute('PRAGMA foreign_keys = ON');
  }
}
