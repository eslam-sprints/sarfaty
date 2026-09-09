import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/app.dart';
import 'package:sarfaty/src/screens/home_shell.dart';
import 'package:sarfaty/src/screens/onboarding_screen.dart';
import 'package:sarfaty/src/screens/splash_screen.dart';
import 'package:sarfaty/src/state/finance_store.dart';

void main() {
  testWidgets('shows splash until storeLoader completes then onboarding', (
    tester,
  ) async {
    final completer = Completer<FinanceStore>();
    await tester.pumpWidget(SarfatyApp(storeLoader: () => completer.future));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('صرفتي'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HomeShell), findsNothing);

    completer.complete(FinanceStore.seeded());
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('after splash shows HomeShell when onboarding already done', (
    tester,
  ) async {
    final completer = Completer<FinanceStore>();
    await tester.pumpWidget(SarfatyApp(storeLoader: () => completer.future));
    expect(find.byType(SplashScreen), findsOneWidget);

    completer.complete(
      FinanceStore(startingBalance: 0, onboardingCompleted: true),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  testWidgets('preloaded store skips splash', (tester) async {
    await tester.pumpWidget(SarfatyApp(store: FinanceStore.seeded()));
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('splash shows retry when storeLoader fails', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      SarfatyApp(
        storeLoader: () async {
          attempts++;
          if (attempts == 1) {
            throw Exception('db unavailable');
          }
          return FinanceStore.seeded();
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحميل البيانات المحلية'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(attempts, 2);
  });
}
