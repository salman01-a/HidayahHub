import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';

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
      print("Error Biometric: $e");
      return false;
    }
  }
  Future<Map<String, dynamic>> getBiometricDetails() async {
    try {
      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.face)) {
        return {
          'icon': Icons.face_rounded,
          'label': 'Face ID',
        };
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return {
          'icon': Icons.fingerprint_rounded,
          'label': 'Touch ID',
        };
      }
      
      return {
        'icon': Icons.fingerprint_rounded,
        'label': 'Biometrik',
      };
    } catch (e) {
      return {
        'icon': Icons.fingerprint_rounded,
        'label': 'Biometrik',
      };
    }
  }
}
