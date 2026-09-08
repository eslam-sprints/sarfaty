import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'state/finance_store.dart';

class SarfatyApp extends StatelessWidget {
  const SarfatyApp({super.key, required this.store});
  final FinanceStore store;
  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D9488),
      surface: const Color(0xFFF7F8F6),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF14B8A6),
      brightness: Brightness.dark,
      surface: const Color(0xFF101817),
    );
    ThemeData makeTheme(ColorScheme scheme) => ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'صرفتي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        theme: makeTheme(lightScheme),
        darkTheme: makeTheme(darkScheme),
        themeMode: switch (store.themePreference) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: HomeShell(store: store),
      ),
    );
  }
}
