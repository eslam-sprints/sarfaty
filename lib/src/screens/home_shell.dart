import 'package:flutter/material.dart';
import '../state/finance_store.dart';
import 'add_expense_screen.dart';
import 'cards_screen.dart';
import 'dashboard_screen.dart';
import 'summary_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});
  final FinanceStore store;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            DashboardScreen(store: widget.store, onAdd: _add),
            CardsScreen(store: widget.store),
            SummaryScreen(store: widget.store),
            SettingsScreen(store: widget.store),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card_rounded),
            label: 'بطاقاتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'الملخص',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مصروف'),
            )
          : null,
    ),
  );
  Future<void> _add() async => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AddExpenseScreen(store: widget.store)),
  );
}
