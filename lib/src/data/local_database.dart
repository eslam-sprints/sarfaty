import 'package:sqflite/sqflite.dart';

import '../models/finance_models.dart';
import 'database_schema.dart';
import 'finance_database.dart';
import 'money.dart';
import 'time_codec.dart';

export 'finance_database.dart';

class LocalDatabase implements FinanceDatabase {
  LocalDatabase._(this._db);

  final Database _db;

  static Future<LocalDatabase> open() async {
    final path = '${await getDatabasesPath()}/sarfaty.db';
    final db = await openDatabase(
      path,
      version: DatabaseSchema.schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) => DatabaseSchema.createCurrentSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await DatabaseSchema.migrateV1RealToV2Piastres(db);
        }
        if (oldVersion < 3) {
          await DatabaseSchema.migrateV2ToV3CustomCategories(db);
        }
      },
    );
    return LocalDatabase._(db);
  }

  @override
  Future<DatabaseSnapshot> readAll({
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    final settingsRows = await _db.query('settings');
    final settings = {
      for (final row in settingsRows)
        row['key'] as String: row['value'] as String,
    };
    final cardRows = await _db.query('cards');
    final customCategoryRows = await _db.query(
      'custom_categories',
      orderBy: 'name COLLATE NOCASE',
    );
    final customCategories = customCategoryRows
        .map(_customCategoryFromRow)
        .toList();
    final customCategoryNames = {
      for (final category in customCategories) category.id: category.name,
    };

    final recentExpenseRows = await _db.query(
      'expenses',
      orderBy: 'expense_date DESC',
      limit: 5,
    );

    final monthStartMs = encodeLocalDateToUtcMs(monthStart);
    final monthEndMs = encodeLocalDateToUtcMs(monthEnd);

    final monthExpenseRows = await _db.query(
      'expenses',
      where: 'expense_date >= ? AND expense_date <= ?',
      whereArgs: [monthStartMs, monthEndMs],
      orderBy: 'expense_date DESC',
    );

    final monthStartUtcMs = monthStart.toUtc().millisecondsSinceEpoch;
    final monthEndUtcMs =
        monthEnd.add(const Duration(days: 1)).toUtc().millisecondsSinceEpoch -
        1;

    final monthPaymentRows = await _db.query(
      'payments',
      where: 'payment_date >= ? AND payment_date <= ?',
      whereArgs: [monthStartUtcMs, monthEndUtcMs],
      orderBy: 'payment_date DESC',
    );

    final cardExpensesRows = await _db.rawQuery(
      'SELECT card_id, SUM(amount) as total FROM expenses WHERE card_id IS NOT NULL GROUP BY card_id',
    );
    final cardExpensesTotal = {
      for (final row in cardExpensesRows)
        row['card_id'] as String: _piastresFromRow(row['total']),
    };

    final allPaymentsRows = await _db.rawQuery(
      'SELECT SUM(amount) as total FROM payments',
    );
    final allPaymentsTotal =
        allPaymentsRows.isNotEmpty && allPaymentsRows.first['total'] != null
        ? _piastresFromRow(allPaymentsRows.first['total'])
        : 0;

    return DatabaseSnapshot(
      startingBalance: _parsePiastresSetting(settings['starting_balance']),
      themePreference: settings['theme'] ?? 'system',
      languagePreference: settings['language'] ?? 'ar',
      onboardingCompleted: settings['onboarding_completed'] == '1',
      biometricLockEnabled: settings['biometric_lock_enabled'] == '1',
      expenseRemindersEnabled: settings['expense_reminders_enabled'] == '1',
      customCategories: customCategories,
      cards: cardRows.map(_cardFromRow).toList(),
      recentExpenses: recentExpenseRows
          .map((row) => _expenseFromRow(row, customCategoryNames))
          .toList(),
      monthExpenses: monthExpenseRows
          .map((row) => _expenseFromRow(row, customCategoryNames))
          .toList(),
      monthPayments: monthPaymentRows.map(_paymentFromRow).toList(),
      cardExpensesTotal: cardExpensesTotal,
      allPaymentsTotal: allPaymentsTotal,
    );
  }

  @override
  Future<void> upsertExpense(Expense expense) => _db.insert(
    'expenses',
    _expenseRow(expense),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> insertCustomCategory(CustomExpenseCategory category) =>
      _db.insert('custom_categories', {
        'id': category.id,
        'name': category.name,
        'normalized_name': _normalizeCategoryName(category.name),
      });

  @override
  Future<void> deleteExpense(String id) =>
      _db.delete('expenses', where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> insertCard(CreditCardAccount card) => _db.insert(
    'cards',
    _cardRow(card),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  @override
  Future<void> recordPayment(
    CreditCardAccount card,
    PaymentRecord payment,
  ) async {
    await _db.transaction((txn) async {
      await txn.update(
        'cards',
        {'paid': card.paid},
        where: 'id = ?',
        whereArgs: [card.id],
      );
      await txn.insert('payments', _paymentRow(payment));
    });
  }

  @override
  Future<void> saveSetting(String key, String value) => _db.insert('settings', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> replaceAll(DatabaseSnapshot snapshot) async {
    await _db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('expenses');
      await txn.delete('custom_categories');
      await txn.delete('cards');
      for (final category in snapshot.customCategories) {
        await txn.insert('custom_categories', {
          'id': category.id,
          'name': category.name,
          'normalized_name': _normalizeCategoryName(category.name),
        });
      }
      for (final card in snapshot.cards) {
        await txn.insert('cards', _cardRow(card));
      }
      for (final expense in snapshot.monthExpenses) {
        await txn.insert('expenses', _expenseRow(expense));
      }
      for (final payment in snapshot.monthPayments) {
        await txn.insert('payments', _paymentRow(payment));
      }
      await txn.insert('settings', {
        'key': 'starting_balance',
        'value': '${snapshot.startingBalance}',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('settings', {
        'key': 'theme',
        'value': snapshot.themePreference,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('settings', {
        'key': 'language',
        'value': snapshot.languagePreference,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('settings', {
        'key': 'onboarding_completed',
        'value': snapshot.onboardingCompleted ? '1' : '0',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('settings', {
        'key': 'biometric_lock_enabled',
        'value': snapshot.biometricLockEnabled ? '1' : '0',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('settings', {
        'key': 'expense_reminders_enabled',
        'value': snapshot.expenseRemindersEnabled ? '1' : '0',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  static int _parsePiastresSetting(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(raw);
    if (asDouble != null) return migrateRealPoundsToPiastres(asDouble);
    return 0;
  }

  static int _piastresFromRow(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    throw FormatException('قيمة مالية غير صحيحة في قاعدة البيانات: $value');
  }

  static Map<String, Object?> _expenseRow(Expense expense) => {
    'id': expense.id,
    'amount': expense.amount,
    'category': expense.category.name,
    'payment_method': expense.method.name,
    'expense_date': encodeLocalDateToUtcMs(expense.date),
    'card_id': expense.cardId,
    'note': expense.note,
    'custom_category_id': expense.customCategoryId,
  };

  static Expense _expenseFromRow(
    Map<String, Object?> row,
    Map<String, String> customCategoryNames,
  ) => Expense(
    id: row['id'] as String,
    amount: _piastresFromRow(row['amount']),
    category: ExpenseCategory.values.byName(row['category'] as String),
    method: PaymentMethod.values.byName(row['payment_method'] as String),
    date: decodeLocalDateFromUtcMs(row['expense_date'] as int),
    cardId: row['card_id'] as String?,
    note: row['note'] as String?,
    customCategoryId: row['custom_category_id'] as String?,
    customCategoryName:
        customCategoryNames[row['custom_category_id'] as String?],
  );

  static CustomExpenseCategory _customCategoryFromRow(
    Map<String, Object?> row,
  ) => CustomExpenseCategory(
    id: row['id'] as String,
    name: row['name'] as String,
  );

  static String _normalizeCategoryName(String name) =>
      name.trim().toLowerCase();

  static Map<String, Object?> _cardRow(CreditCardAccount card) => {
    'id': card.id,
    'name': card.name,
    'credit_limit': card.limit,
    'statement_day': card.statementDay,
    'due_day': card.dueDay,
    'opening_due': card.openingDue,
    'paid': card.paid,
  };

  static CreditCardAccount _cardFromRow(Map<String, Object?> row) =>
      CreditCardAccount(
        id: row['id'] as String,
        name: row['name'] as String,
        limit: _piastresFromRow(row['credit_limit']),
        statementDay: row['statement_day'] as int,
        dueDay: row['due_day'] as int,
        openingDue: _piastresFromRow(row['opening_due']),
        paid: _piastresFromRow(row['paid']),
      );

  static Map<String, Object?> _paymentRow(PaymentRecord payment) => {
    'card_id': payment.cardId,
    'amount': payment.amount,
    'payment_date': encodeInstantToUtcMs(payment.date),
  };

  static PaymentRecord _paymentFromRow(Map<String, Object?> row) =>
      PaymentRecord(
        cardId: row['card_id'] as String,
        amount: _piastresFromRow(row['amount']),
        date: decodeInstantFromUtcMs(row['payment_date'] as int),
      );

  @override
  Future<TransactionPage> getTransactions(TransactionFilter filter) async {
    final conditions = <String>[];
    final args = <Object?>[];
    final customCategoryRows = await _db.query('custom_categories');
    final customCategoryNames = {
      for (final row in customCategoryRows)
        row['id'] as String: row['name'] as String,
    };

    if (filter.method != null) {
      conditions.add('payment_method = ?');
      args.add(filter.method!.name);
    }
    if (filter.category != null) {
      conditions.add('category = ?');
      args.add(filter.category!.name);
      conditions.add('custom_category_id IS NULL');
    }
    if (filter.customCategoryId != null) {
      conditions.add('custom_category_id = ?');
      args.add(filter.customCategoryId);
    }
    if (filter.cardId != null) {
      conditions.add('card_id = ?');
      args.add(filter.cardId);
    }
    if (filter.period != null) {
      conditions.add('date >= ? AND date <= ?');
      args.add(encodeLocalDateToUtcMs(filter.period!.start));
      args.add(encodeLocalDateToUtcMs(filter.period!.end) + 86400000 - 1);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    final includePayments =
        filter.category == null &&
        filter.customCategoryId == null &&
        filter.method != PaymentMethod.cash;

    final expenseQuery = '''
      SELECT id, amount, category, custom_category_id, payment_method, expense_date as date, card_id, note, 'expense' as type
      FROM expenses
    ''';

    final paymentQuery = '''
      SELECT CAST(id AS TEXT) as id, amount, NULL as category, NULL as custom_category_id, NULL as payment_method, payment_date as date, card_id, NULL as note, 'payment' as type
      FROM payments
    ''';

    final unionQuery = includePayments
        ? '$expenseQuery UNION ALL $paymentQuery'
        : expenseQuery;

    final countQuery =
        'SELECT COUNT(*) as c, SUM(amount) as s FROM ($unionQuery) $whereClause';
    final countResult = await _db.rawQuery(countQuery, args);
    final totalCount = (countResult.first['c'] as num?)?.toInt() ?? 0;
    final totalAmount = countResult.isNotEmpty && countResult.first['s'] != null
        ? _piastresFromRow(countResult.first['s'])
        : 0;

    final dataQuery =
        '''
      SELECT * FROM ($unionQuery)
      $whereClause
      ORDER BY date DESC
      LIMIT ? OFFSET ?
    ''';

    final dataArgs = [...args, filter.limit, filter.offset];
    final rows = await _db.rawQuery(dataQuery, dataArgs);

    final items = rows.map((row) {
      final type = row['type'] as String;
      if (type == 'expense') {
        return TransactionItem(
          amount: _piastresFromRow(row['amount']),
          date: decodeLocalDateFromUtcMs(row['date'] as int),
          expense: Expense(
            id: row['id'] as String,
            amount: _piastresFromRow(row['amount']),
            category: ExpenseCategory.values.byName(row['category'] as String),
            method: PaymentMethod.values.byName(
              row['payment_method'] as String,
            ),
            date: decodeLocalDateFromUtcMs(row['date'] as int),
            cardId: row['card_id'] as String?,
            note: row['note'] as String?,
            customCategoryId: row['custom_category_id'] as String?,
            customCategoryName: row['custom_category_id'] == null
                ? null
                : customCategoryNames[row['custom_category_id'] as String],
          ),
        );
      } else {
        return TransactionItem(
          amount: _piastresFromRow(row['amount']),
          date: decodeInstantFromUtcMs(row['date'] as int),
          payment: PaymentRecord(
            cardId: row['card_id'] as String,
            amount: _piastresFromRow(row['amount']),
            date: decodeInstantFromUtcMs(row['date'] as int),
          ),
        );
      }
    }).toList();

    return TransactionPage(
      items: items,
      totalCount: totalCount,
      totalAmount: totalAmount,
    );
  }
}
