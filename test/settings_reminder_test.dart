import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/notifications/expense_reminder_service.dart';
import 'package:sarfaty/src/screens/settings_screen.dart';
import 'package:sarfaty/src/security/biometric_auth.dart';
import 'package:sarfaty/src/state/finance_store.dart';

import 'helpers/fake_database.dart';

class _FakeReminderService implements ExpenseReminderService {
  _FakeReminderService({required this.permissionGranted});

  final bool permissionGranted;
  var permissionRequests = 0;
  var replacements = 0;
  var cancellations = 0;

  @override
  Future<void> cancelScheduled() async => cancellations += 1;

  @override
  Future<void> ensureScheduled({required String languageCode}) async {}

  @override
  Future<void> replaceSchedule({required String languageCode}) async =>
      replacements += 1;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permissionGranted;
  }
}

class _FakeAuthenticator implements BiometricAuthenticator {
  @override
  Future<bool> authenticate() async => true;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> stopAuthentication() async {}
}

void main() {
  testWidgets('enabling reminders requests permission then persists schedule', (
    tester,
  ) async {
    final database = FakeDatabase();
    final store = FinanceStore(startingBalance: 0, database: database);
    final reminders = _FakeReminderService(permissionGranted: true);
    await tester.pumpWidget(_settingsApp(store, reminders));

    final reminderTitle = find.text('تذكيرات تسجيل المصروفات');
    await tester.scrollUntilVisible(reminderTitle, 200);
    await tester.tap(reminderTitle);
    await tester.pumpAndSettle();

    expect(reminders.permissionRequests, 1);
    expect(reminders.replacements, 1);
    expect(store.expenseRemindersEnabled, isTrue);
    expect(database.settings['expense_reminders_enabled'], '1');
  });

  testWidgets('denied permission leaves reminders disabled', (tester) async {
    final store = FinanceStore(startingBalance: 0, database: FakeDatabase());
    final reminders = _FakeReminderService(permissionGranted: false);
    await tester.pumpWidget(_settingsApp(store, reminders));

    final reminderTitle = find.text('تذكيرات تسجيل المصروفات');
    await tester.scrollUntilVisible(reminderTitle, 200);
    await tester.tap(reminderTitle);
    await tester.pumpAndSettle();

    expect(reminders.permissionRequests, 1);
    expect(reminders.replacements, 0);
    expect(store.expenseRemindersEnabled, isFalse);
  });
}

Widget _settingsApp(FinanceStore store, ExpenseReminderService reminders) =>
    MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SettingsScreen(
          store: store,
          biometricAuthenticator: _FakeAuthenticator(),
          reminderService: reminders,
        ),
      ),
    );
