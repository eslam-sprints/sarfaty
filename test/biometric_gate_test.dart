import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/security/biometric_auth.dart';
import 'package:sarfaty/src/security/biometric_gate.dart';

class _FakeAuthenticator implements BiometricAuthenticator {
  _FakeAuthenticator(this.result);

  bool result;
  int authenticationCount = 0;

  @override
  Future<bool> authenticate() async {
    authenticationCount += 1;
    return result;
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> stopAuthentication() async {}
}

void main() {
  testWidgets('hides protected content until authentication succeeds', (
    tester,
  ) async {
    final authenticator = _FakeAuthenticator(false);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BiometricGate(
          authenticator: authenticator,
          child: const Text('بيانات محمية'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('صرفتي مقفول'), findsOneWidget);
    expect(find.text('بيانات محمية'), findsNothing);

    authenticator.result = true;
    await tester.tap(find.text('فتح بالبصمة'));
    await tester.pump();

    expect(find.text('بيانات محمية'), findsOneWidget);
    expect(authenticator.authenticationCount, 2);
  });
}
