import 'dart:convert';

import 'package:crypto/crypto.dart';

class UserModel {
  static const String defaultProfilePath = 'assets/profile/default.png';
  static const String _nameCipherPrefix = 'xor:';
  static const String _xorKey = 'HidayahHub2026';

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
      'name': encodeName(name),
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
      name: decodeName(m['name'] as String? ?? ''),
      email: m['email'] as String? ?? '',
      passwordHash: m['password'] as String? ?? '',
      profilePath: pPath,
    );
  }

  static String encodeName(String rawName) {
    if (rawName.isEmpty) return rawName;
    final encryptedBytes = _xorTransform(
      utf8.encode(rawName),
      utf8.encode(_xorKey),
    );
    final payload = base64UrlEncode(encryptedBytes);
    return '$_nameCipherPrefix$payload';
  }

  static String decodeName(String storedName) {
    if (storedName.isEmpty) return storedName;
    if (storedName.startsWith(_nameCipherPrefix)) {
      final payload = storedName.substring(_nameCipherPrefix.length);
      try {
        final encryptedBytes = base64Url.decode(base64Url.normalize(payload));
        final plainBytes = _xorTransform(encryptedBytes, utf8.encode(_xorKey));
        return utf8.decode(plainBytes);
      } catch (_) {
        return storedName;
      }
    }

    // Backward compatibility for usernames saved in plaintext.
    return storedName;
  }

  static List<int> _xorTransform(List<int> source, List<int> key) {
    if (source.isEmpty) return source;
    final output = <int>[];
    for (var i = 0; i < source.length; i++) {
      output.add(source[i] ^ key[i % key.length]);
    }
    return output;
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
