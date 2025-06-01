import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:io';

class DatabaseHelper extends ChangeNotifier {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  // 使用 AES 加密的密钥
  static final encrypt.Key _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  static final encrypt.IV _iv = encrypt.IV.fromUtf8('uigtrefghingftxp'); // 16个字符
  late final encrypt.Encrypter _encrypter;

  DatabaseHelper._internal() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    // 初始化数据库
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'passwords.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA encoding = "UTF-8"');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE passwords(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purpose TEXT,
        account TEXT,
        password TEXT,
        note TEXT,
        view_count INTEGER DEFAULT 0,
        last_viewed_time TEXT,
        created_time TEXT,
        is_favorite INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE passwords ADD COLUMN view_count INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE passwords ADD COLUMN last_viewed_time TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE passwords ADD COLUMN created_time TEXT');
      // 为现有记录设置默认创建时间
      final now = DateTime.now().toIso8601String();
      await db.execute('UPDATE passwords SET created_time = ? WHERE created_time IS NULL', [now]);
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE passwords ADD COLUMN is_favorite INTEGER DEFAULT 0');
    }
  }

  String doEncrypt(String data) {
    // 确保输入字符串有效
    if (data.isEmpty) return '';

    // 使用 UTF-8 编码
    List<int> bytes = utf8.encode(data);

    // 进行 AES 加密
    final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
    print('Encrypted: ${encrypted.base64}'); // 添加调试日志
    return encrypted.base64;
  }

  String doDecrypt(String encryptedData) {
    // 确保输入字符串有效
    if (encryptedData.isEmpty) return '';

    // 尝试使用 AES 解密
    try {
      // 使用 base64 解码得到字节数组
      final encryptedBytes = base64.decode(encryptedData);
      if (encryptedBytes.length % 16 != 0) {
        throw Exception('Invalid encrypted data length');
      }
      final decryptedBytes = _encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: _iv);
      final decryptedString = utf8.decode(decryptedBytes);
      print('Decrypted: $decryptedString'); // 添加调试日志
      return decryptedString; // 将字节数组转回字符串
    } catch (e) {
      // 如果解密失败，返回原字符串
      print('Decryption failed: $e'); // 添加调试日志
      return encryptedData;
    }
  }

  Future<int> insertPassword(Map<String, dynamic> password) async {
    Database db = await database;
    // 添加创建时间
    password['created_time'] = DateTime.now().toIso8601String();
    // 加密所有敏感数据
    password['purpose'] = doEncrypt(password['purpose']);
    password['account'] = doEncrypt(password['account']);
    password['password'] = doEncrypt(password['password']);
    password['note'] = doEncrypt(password['note']);
    int id = await db.insert('passwords', password);
    notifyListeners(); // 通知监听者数据已更改
    return id;
  }

  Future<List<Map<String, dynamic>>> getPasswords() async {
    Database db = await database;
    List<Map<String, dynamic>> passwords = await db.query('passwords');
    // 创建一个新的列表来存储解密后的数据
    List<Map<String, dynamic>> decryptedPasswords = [];

    // 解密所有敏感数据
    for (var password in passwords) {
      decryptedPasswords.add({
        'id': password['id'],
        'purpose': doDecrypt(password['purpose']),
        'account': doDecrypt(password['account']),
        'password': doDecrypt(password['password']),
        'note': doDecrypt(password['note']),
        'view_count': password['view_count'] ?? 0,
        'last_viewed_time': password['last_viewed_time'],
        'created_time': password['created_time'],
        'is_favorite': password['is_favorite'] ?? 0,
      });
    }

    return decryptedPasswords;
  }

  Future<int> deletePassword(int id) async {
    Database db = await database;
    int result = await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>?> getPasswordById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'passwords',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      // 创建一个新的 Map 来存储解密后的数据
      Map<String, dynamic> decryptedPassword = {
        'id': result.first['id'],
        'purpose': doDecrypt(result.first['purpose']),
        'account': doDecrypt(result.first['account']),
        'password': doDecrypt(result.first['password']),
        'note': doDecrypt(result.first['note']),
        'view_count': result.first['view_count'] ?? 0,
        'last_viewed_time': result.first['last_viewed_time'],
        'created_time': result.first['created_time'],
        'is_favorite': result.first['is_favorite'] ?? 0,
      };
      return decryptedPassword;
    }
    return null;
  }

  Future<int> updatePassword(int id, Map<String, dynamic> password) async {
    Database db = await database;
    // 加密所有敏感数据
    password['purpose'] = doEncrypt(password['purpose']);
    password['account'] = doEncrypt(password['account']);
    password['password'] = doEncrypt(password['password']);
    password['note'] = doEncrypt(password['note']);
    int result = await db.update(
      'passwords',
      password,
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners(); // 通知监听者数据已更改
    return result;
  }

  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('passwords');
    notifyListeners(); // 通知监听者数据已更改
  }

  Future<int> getPasswordCount() async {
    Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM passwords');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 添加更新阅读统计的方法
  Future<void> incrementViewCount(int id) async {
    Database db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.execute('''
      UPDATE passwords 
      SET view_count = COALESCE(view_count, 0) + 1, 
          last_viewed_time = ? 
      WHERE id = ?
    ''', [now, id]);
    
    notifyListeners();
  }

  // 添加切换收藏状态的方法
  Future<void> toggleFavorite(int id) async {
    Database db = await database;
    
    await db.execute('''
      UPDATE passwords 
      SET is_favorite = CASE 
        WHEN is_favorite = 1 THEN 0 
        ELSE 1 
      END 
      WHERE id = ?
    ''', [id]);
    
    notifyListeners();
  }
}
