import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/db_helper.dart';

class AuthController {
  AuthController._();
  static final AuthController instance = AuthController._();

  final _db = DBHelper.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final nameTaken = await _db.isNameTaken(name, -1);
      if (nameTaken)
        return {'success': false, 'message': 'Username sudah digunakan'};

      final existing = await _db.getUserByEmail(email);
      if (existing != null)
        return {'success': false, 'message': 'Email sudah terdaftar'};

      final user = UserModel.create(
        name: name,
        email: email,
        password: password,
      );
      await _db.insertUser(user);
      return {'success': true, 'message': 'Pendaftaran berhasil'};
    } catch (e, st) {
      if (kDebugMode) {
        print('Register error: $e\n$st');
      }
      final msg = kDebugMode ? e.toString() : 'Gagal mendaftar';
      return {'success': false, 'message': msg};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null)
        return {'success': false, 'message': 'Email tidak ditemukan'};

      final hash = UserModel.hashPassword(password);
      if (hash != user.passwordHash)
        return {'success': false, 'message': 'Password salah'};

      return {'success': true, 'message': 'Login berhasil', 'user': user};
    } catch (e, st) {
      if (kDebugMode) print('Login error: $e\n$st');
      final msg = kDebugMode ? e.toString() : 'Gagal login';
      return {'success': false, 'message': msg};
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      return await _db.getUserByEmail(email);
    } catch (e, st) {
      if (kDebugMode) print('Get user by email error: $e\n$st');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int id,
    required String name,
    required String email,
    String? password,
    String? profilePath,
  }) async {
    try {
      final taken = await _db.isNameTaken(name, id);
      if (taken)
        return {'success': false, 'message': 'Username sudah digunakan'};

      final currentUser = await _db.getUserByEmail(email);
      String finalHash = currentUser?.passwordHash ?? '';
      String finalProfilePath =
          profilePath ??
          currentUser?.profilePath ??
          'assets/profile/default.png';

      if (password != null && password.isNotEmpty) {
        finalHash = UserModel.hashPassword(password);
      }

      final updatedUser = UserModel(
        id: id,
        name: name,
        email: email,
        passwordHash: finalHash,
        profilePath: finalProfilePath,
      );

      await _db.updateUser(updatedUser);
      return {
        'success': true,
        'message': 'Profil berhasil diperbarui',
        'user': updatedUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui profil'};
    }
  }
}
