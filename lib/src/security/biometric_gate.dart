import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'biometric_auth.dart';

class BiometricGate extends StatefulWidget {
  const BiometricGate({
    super.key,
    required this.authenticator,
    required this.child,
  });

  final BiometricAuthenticator authenticator;
  final Widget child;

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  var _unlocked = false;
  var _authenticating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  var _promptOnResume = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (mounted) setState(() => _unlocked = false);
    } else if (state == AppLifecycleState.resumed && !_unlocked) {
      if (_promptOnResume) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating || _unlocked || !mounted) return;
    setState(() {
      _authenticating = true;
      _message = null;
    });
    final success = await widget.authenticator.authenticate();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _unlocked = success;
      if (!success) {
        _message = 'لم يتم التحقق. حاول مرة أخرى.';
        _promptOnResume = false;
      } else {
        _promptOnResume = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.authenticator.stopAuthentication();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 52,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'صرفتي مقفول'.tr(context, 'Sarfaty is locked'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _message == null
                      ? 'استخدم البصمة أو قفل الجهاز لعرض بياناتك.'.tr(
                          context,
                          'Use biometrics or your device lock to view your data.',
                        )
                      : _message!.tr(
                          context,
                          'Authentication failed. Try again.',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _authenticating ? null : _authenticate,
                  icon: _authenticating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(
                    _authenticating
                        ? 'جاري التحقق…'.tr(context, 'Authenticating…')
                        : 'فتح بالبصمة'.tr(context, 'Unlock'),
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
