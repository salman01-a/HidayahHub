import 'dart:convert';

import 'package:crypto/crypto.dart';

class UserModel {
  static const String defaultProfilePath = 'assets/profile/default.png';

  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String profilePath;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.profilePath = defaultProfilePath,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': passwordHash,
      'profilePath': profilePath,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> m) {
    String pPath = m['profilePath'] as String? ?? defaultProfilePath;
    if (pPath == 'assets/default.png') pPath = defaultProfilePath;

    return UserModel(
      id: m['id'] as int?,
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? '',
      passwordHash: m['password'] as String? ?? '',
      profilePath: pPath,
    );
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Convenience factory to create user from plain password (it will be hashed)
  factory UserModel.create({
    int? id,
    required String name,
    required String email,
    required String password,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      passwordHash: hashPassword(password),
      profilePath: defaultProfilePath,
    );
  }
}
