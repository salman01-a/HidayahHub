import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'hidayahhub.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createHomePrayerPreferenceTable(db);
    await _createSurahReadBookmarksTable(db);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createHomePrayerPreferenceTable(db);
      await _createSurahReadBookmarksTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createHomePrayerPreferenceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS home_prayer_preferences (
        id INTEGER PRIMARY KEY,
        provinsi TEXT NOT NULL,
        kabkota TEXT NOT NULL,
        bulan INTEGER NOT NULL,
        tahun INTEGER NOT NULL,
        zona TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createSurahReadBookmarksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS surah_read_bookmarks (
        surah_no INTEGER PRIMARY KEY,
        ayat INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return UserModel.fromMap(res.first);
  }
}
