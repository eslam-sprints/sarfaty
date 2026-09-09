import 'package:flutter/material.dart';

import '../data/money.dart';
import '../data/time_codec.dart';

enum PaymentMethod { cash, credit }

enum ExpenseCategory {
  food('أكل ومشروبات', Icons.restaurant_rounded, Color(0xFFF59E0B)),
  transport('مواصلات', Icons.directions_car_rounded, Color(0xFF3B82F6)),
  bills('فواتير', Icons.receipt_long_rounded, Color(0xFF8B5CF6)),
  shopping('تسوق', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  entertainment('ترفيه', Icons.movie_rounded, Color(0xFF14B8A6)),
  health('صحة', Icons.favorite_rounded, Color(0xFFEF4444)),
  home('منزل', Icons.home_rounded, Color(0xFF6366F1)),
  education('تعليم', Icons.school_rounded, Color(0xFF0EA5E9)),
  transfers('تحويلات', Icons.swap_horiz_rounded, Color(0xFF64748B)),
  other('أخرى', Icons.more_horiz_rounded, Color(0xFF78716C));

  const ExpenseCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.method,
    required this.date,
    this.cardId,
    this.note,
  });
  final String id;

  /// Amount in piastres (قروش).
  final int amount;
  final ExpenseCategory category;
  final PaymentMethod method;

  /// Local **date-only** calendar day the user chose (see [time_codec]).
  final DateTime date;
  final String? cardId;
  final String? note;

  /// JSON keeps pound decimals for schemaVersion 1 compatibility.
  /// Expense [date] is date-only `YYYY-MM-DD`, not an instant.
  Map<String, Object?> toJson() => {
    'id': id,
    'amount': piastresToPounds(amount),
    'category': category.name,
    'method': method.name,
    'date': encodeLocalDateToJson(date),
    'cardId': cardId,
    'note': note,
  };
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: poundsToPiastres(json['amount'] as num),
    category: ExpenseCategory.values.byName(json['category'] as String),
    method: PaymentMethod.values.byName(json['method'] as String),
    date: decodeLocalDateFromJson(json['date'] as String),
    cardId: json['cardId'] as String?,
    note: json['note'] as String?,
  );
}

class CreditCardAccount {
  CreditCardAccount({
    required this.id,
    required this.name,
    required this.limit,
    required this.statementDay,
    required this.dueDay,
    this.openingDue = 0,
    this.paid = 0,
  });
  final String id;
  final String name;

  /// Credit limit in piastres.
  final int limit;
  final int statementDay;
  final int dueDay;

  /// Opening due in piastres.
  final int openingDue;

  /// Paid total in piastres.
  int paid;

  /// JSON keeps pound decimals for schemaVersion 1 compatibility.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'limit': piastresToPounds(limit),
    'statementDay': statementDay,
    'dueDay': dueDay,
    'openingDue': piastresToPounds(openingDue),
    'paid': piastresToPounds(paid),
  };
  factory CreditCardAccount.fromJson(Map<String, dynamic> json) =>
      CreditCardAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        limit: poundsToPiastres(json['limit'] as num),
        statementDay: json['statementDay'] as int,
        dueDay: json['dueDay'] as int,
        openingDue: poundsToPiastres(json['openingDue'] as num? ?? 0),
        paid: poundsToPiastres(json['paid'] as num? ?? 0),
      );
}

class PaymentRecord {
  PaymentRecord({
    required this.cardId,
    required this.amount,
    required this.date,
  });
  final String cardId;

  /// Amount in piastres.
  final int amount;

  /// Payment **instant** (UTC in storage/JSON; local for calendar math).
  final DateTime date;

  /// JSON keeps pound decimals for schemaVersion 1 compatibility.
  /// Payment [date] is a UTC instant (`…Z`).
  Map<String, Object?> toJson() => {
    'cardId': cardId,
    'amount': piastresToPounds(amount),
    'date': encodeInstantToUtcIso(date),
  };
  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    cardId: json['cardId'] as String,
    amount: poundsToPiastres(json['amount'] as num),
    date: decodeInstantFromJson(json['date'] as String),
  );
}

class TransactionItem {
  const TransactionItem({
    required this.amount,
    required this.date,
    this.expense,
    this.payment,
  });
  final int amount;
  final DateTime date;
  final Expense? expense;
  final PaymentRecord? payment;
  bool get isExpense => expense != null;
}

class TransactionPage {
  const TransactionPage({
    required this.items,
    required this.totalCount,
    required this.totalAmount,
  });
  final List<TransactionItem> items;
  final int totalCount;
  final int totalAmount;
}

class TransactionFilter {
  const TransactionFilter({
    this.method,
    this.category,
    this.cardId,
    this.period,
    this.offset = 0,
    this.limit = 20,
  });
  final PaymentMethod? method;
  final ExpenseCategory? category;
  final String? cardId;
  final DateTimeRange? period;
  final int offset;
  final int limit;
}
