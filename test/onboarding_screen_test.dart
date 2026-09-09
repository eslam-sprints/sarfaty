import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarfaty/src/app.dart';
import 'package:sarfaty/src/screens/onboarding_screen.dart';
import 'package:sarfaty/src/state/finance_store.dart';

void main() {
  testWidgets('shows onboarding before home until completed', (tester) async {
    final store = FinanceStore.seeded();
    await tester.pumpWidget(SarfatyApp(store: store));
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('تابع مصروفاتك بسهولة'), findsOneWidget);

    await tester.tap(find.text('تخطّي'));
    await tester.pumpAndSettle();

    expect(store.onboardingCompleted, isTrue);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('أهلاً بك في صرفتي'), findsOneWidget);
  });

  testWidgets('next advances pages and start completes onboarding', (
    tester,
  ) async {
    final store = FinanceStore.seeded();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: OnboardingScreen(store: store),
      ),
    );

    expect(find.text('التالي'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('أدِر بطاقات الكريديت'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(find.text('بياناتك محفوظة محلياً'), findsOneWidget);
    expect(find.text('ابدأ'), findsOneWidget);

    await tester.tap(find.text('ابدأ'));
    await tester.pumpAndSettle();
    expect(store.onboardingCompleted, isTrue);
  });
}
