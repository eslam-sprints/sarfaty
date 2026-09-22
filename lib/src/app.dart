import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'notifications/expense_reminder_service.dart';
import 'security/biometric_auth.dart';
import 'security/biometric_gate.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/finance_store.dart';

class SarfatyApp extends StatefulWidget {
  const SarfatyApp({
    super.key,
    this.store,
    this.storeLoader,
    this.biometricAuthenticator,
    this.reminderService = const DisabledExpenseReminderService(),
  }) : assert(
         store != null || storeLoader != null,
         'Provide store or storeLoader',
       );

  /// Ready store (tests / preloaded). Skips the transitional splash.
  final FinanceStore? store;

  /// Loads while [SplashScreen] is shown (production bootstrap).
  final Future<FinanceStore> Function()? storeLoader;
  final BiometricAuthenticator? biometricAuthenticator;
  final ExpenseReminderService reminderService;

  @override
  State<SarfatyApp> createState() => _SarfatyAppState();
}

class _SarfatyAppState extends State<SarfatyApp> {
  FinanceStore? _store;
  Object? _loadError;
  var _loading = false;
  late final BiometricAuthenticator _biometricAuthenticator;

  @override
  void initState() {
    super.initState();
    _biometricAuthenticator =
        widget.biometricAuthenticator ?? DeviceBiometricAuthenticator();
    _store = widget.store;
    if (_store == null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _load();
  }

  Future<void> _load() async {
    try {
      final store = await widget.storeLoader!();
      await _syncReminders(store);
      if (!mounted) return;
      setState(() {
        _store = store;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _syncReminders(FinanceStore store) async {
    if (!store.expenseRemindersEnabled) return;
    try {
      await widget.reminderService.ensureScheduled(
        languageCode: store.languagePreference,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while restoring expense reminders'),
        ),
      );
    }
  }

  ThemeData _makeTheme(ColorScheme scheme) => ThemeData(
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
    final theme = _makeTheme(lightScheme);
    final darkTheme = _makeTheme(darkScheme);

    final store = _store;
    if (store == null) {
      return MaterialApp(
        title: 'صرفتي',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: theme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: SplashScreen(
          error: _loadError,
          onRetry: _loadError != null && !_loading ? _bootstrap : null,
        ),
      );
    }

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'صرفتي',
        debugShowCheckedModeBanner: false,
        locale: Locale(store.languagePreference),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: theme,
        darkTheme: darkTheme,
        themeMode: switch (store.themePreference) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
        home: store.onboardingCompleted
            ? store.biometricLockEnabled
                  ? BiometricGate(
                      authenticator: _biometricAuthenticator,
                      child: HomeShell(
                        store: store,
                        biometricAuthenticator: _biometricAuthenticator,
                        reminderService: widget.reminderService,
                      ),
                    )
                  : HomeShell(
                      store: store,
                      biometricAuthenticator: _biometricAuthenticator,
                      reminderService: widget.reminderService,
                    )
            : OnboardingScreen(store: store),
      ),
    );
  }
}
