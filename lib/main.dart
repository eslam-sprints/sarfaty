import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/state/finance_store.dart';

void main() => runApp(SarfatyApp(store: FinanceStore.seeded()));
