import 'package:flutter/material.dart';
import '../state/finance_store.dart';
import '../security/biometric_auth.dart';
import '../l10n/app_strings.dart';
import '../notifications/expense_reminder_service.dart';
import 'add_expense_screen.dart';
import 'cards_screen.dart';
import 'dashboard_screen.dart';
import 'summary_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.store,
    required this.biometricAuthenticator,
    required this.reminderService,
  });
  final FinanceStore store;
  final BiometricAuthenticator biometricAuthenticator;
  final ExpenseReminderService reminderService;
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
            SettingsScreen(
              store: widget.store,
              biometricAuthenticator: widget.biometricAuthenticator,
              reminderService: widget.reminderService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: 'الرئيسية'.tr(context, 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.credit_card_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: 'المحفظة'.tr(context, 'Wallet'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart_rounded),
            label: 'الملخص'.tr(context, 'Summary'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: 'الإعدادات'.tr(context, 'Settings'),
          ),
        ],
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text('إضافة مصروف'.tr(context, 'Add expense')),
            )
          : null,
    ),
  );
  Future<void> _add() async => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AddExpenseScreen(store: widget.store)),
  );
}
