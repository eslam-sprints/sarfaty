import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Short transitional screen shown while local data (SQLite) initializes.
/// Matches the native Android launch theme colors and branding.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error, this.onRetry});

  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'صرفتي'.tr(context, 'Sarfaty'),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'إدارة مصروفاتك ببساطة'.tr(
                    context,
                    'Manage your expenses simply',
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                if (error != null) ...[
                  Text(
                    'تعذّر تحميل البيانات المحلية'.tr(
                      context,
                      'Could not load local data',
                    ),
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRetry,
                      child: Text('إعادة المحاولة'.tr(context, 'Try again')),
                    ),
                  ],
                ] else
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
