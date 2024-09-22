import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper extends ChangeNotifier{
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'passwords.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE passwords(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purpose TEXT,
        account TEXT,
        password TEXT,
        note TEXT
      )
    ''');
  }

  Future<int> insertPassword(Map<String, dynamic> password) async {
    Database db = await database;
    int id = await db.insert('passwords', password);
    notifyListeners(); // 通知监听者数据已更改
    return id;
  }

  Future<List<Map<String, dynamic>>> getPasswords() async {
    Database db = await database;
    return await db.query('passwords');
  }

  Future<int> deletePassword(int id) async {
    Database db = await database;
    int result = await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
    return result;
  }
}
