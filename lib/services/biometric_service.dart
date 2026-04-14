import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canAuthenticateWithBiometrics && !isDeviceSupported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Gunakan biometrik untuk masuk ke Hidayah Hub',
        // Opsi ini mencakup setingan untuk Android dan iOS sekaligus tanpa import tambahan
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      // Jika error karena belum daftar fingerprint/faceid di HP
      print("Error Biometric: $e");
      return false;
    }
  }
}
