import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class BiometricAuthenticator {
  Future<bool> isAvailable();
  Future<bool> authenticate();
  Future<void> stopAuthentication();
}

class DeviceBiometricAuthenticator implements BiometricAuthenticator {
  DeviceBiometricAuthenticator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAuthentication.isDeviceSupported() &&
          (await _localAuthentication.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'تحقق من هويتك لفتح تطبيق صرفتي',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      debugPrint('Biometric authentication failed: ${error.code}');
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopAuthentication() =>
      _localAuthentication.stopAuthentication();
}
