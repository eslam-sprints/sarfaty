import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/state/finance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SarfatyApp(store: await FinanceStore.load()));
}
