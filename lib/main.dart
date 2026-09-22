import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/notifications/expense_reminder_service.dart';
import 'src/state/finance_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Show Flutter splash immediately while SQLite initializes — no artificial delay.
  runApp(
    SarfatyApp(
      storeLoader: FinanceStore.load,
      reminderService: AndroidExpenseReminderService(),
    ),
  );
}
