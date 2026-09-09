import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/state/finance_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Show Flutter splash immediately while SQLite initializes — no artificial delay.
  runApp(SarfatyApp(storeLoader: FinanceStore.load));
}
