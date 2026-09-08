import 'package:flutter/material.dart';

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
  final double amount;
  final ExpenseCategory category;
  final PaymentMethod method;
  final DateTime date;
  final String? cardId;
  final String? note;

  Map<String, Object?> toJson() => {
    'id': id,
    'amount': amount,
    'category': category.name,
    'method': method.name,
    'date': date.toIso8601String(),
    'cardId': cardId,
    'note': note,
  };
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: ExpenseCategory.values.byName(json['category'] as String),
    method: PaymentMethod.values.byName(json['method'] as String),
    date: DateTime.parse(json['date'] as String),
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
  final double limit;
  final int statementDay;
  final int dueDay;
  final double openingDue;
  double paid;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'limit': limit,
    'statementDay': statementDay,
    'dueDay': dueDay,
    'openingDue': openingDue,
    'paid': paid,
  };
  factory CreditCardAccount.fromJson(Map<String, dynamic> json) =>
      CreditCardAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        limit: (json['limit'] as num).toDouble(),
        statementDay: json['statementDay'] as int,
        dueDay: json['dueDay'] as int,
        openingDue: (json['openingDue'] as num?)?.toDouble() ?? 0,
        paid: (json['paid'] as num?)?.toDouble() ?? 0,
      );
}

class PaymentRecord {
  PaymentRecord({
    required this.cardId,
    required this.amount,
    required this.date,
  });
  final String cardId;
  final double amount;
  final DateTime date;

  Map<String, Object?> toJson() => {
    'cardId': cardId,
    'amount': amount,
    'date': date.toIso8601String(),
  };
  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    cardId: json['cardId'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );
}
