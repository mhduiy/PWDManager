import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'databasehelper.dart';
import 'crypto_manager.dart';

class BackupManager {
  static final BackupManager _instance = BackupManager._internal();
  factory BackupManager() => _instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // 移除硬编码的密钥，改为使用CryptoManager提供的动态密钥
  late final encrypt.Encrypter _encrypter;

  BackupManager._internal() {
    // 初始化加密器，但密钥将动态获取
    _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromBase64('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')));
  }

  /// 获取当前的加密密钥
  encrypt.Key get _key {
    final cachedKey = CryptoManager.getCachedKey();
    if (cachedKey == null) {
      throw Exception('加密密钥不可用，请先验证加密密码');
    }
    return cachedKey;
  }

  /// 获取当前的IV
  encrypt.IV get _iv {
    final cachedIV = CryptoManager.getCachedIV();
    if (cachedIV == null) {
      throw Exception('加密IV不可用，请先验证加密密码');
    }
    return cachedIV;
  }

  /// 获取实时的加密器
  encrypt.Encrypter get _currentEncrypter {
    return encrypt.Encrypter(encrypt.AES(_key));
  }

  Future<String> exportData() async {
    try {
      // 获取所有密码数据
      final passwords = await _dbHelper.getPasswords();
      
      // 转换为JSON字符串
      final jsonData = jsonEncode({
        'version': 1,  // 用于未来版本兼容
        'timestamp': DateTime.now().toIso8601String(),
        'data': passwords,
      });

      // 使用动态密钥加密数据
      final encrypted = _currentEncrypter.encrypt(jsonData, iv: _iv);
      
      // 获取应用文档目录
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/pwdmanager_backup_$timestamp.pwd');
      
      // 保存加密数据
      await file.writeAsString(encrypted.base64);
      
      return file.path;
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  Future<void> importData(String filePath) async {
    try {
      // 读取加密数据
      final file = File(filePath);
      final encryptedData = await file.readAsString();
      
      // 使用动态密钥解密数据
      final decrypted = _currentEncrypter.decrypt64(encryptedData, iv: _iv);
      
      // 解析JSON
      final jsonData = jsonDecode(decrypted);
      
      // 验证版本
      if (jsonData['version'] != 1) {
        throw Exception('不支持的备份版本');
      }

      // 清除现有数据
      await _dbHelper.clearAllData();
      
      // 导入新数据
      final List<dynamic> passwords = jsonData['data'];
      for (var password in passwords) {
        await _dbHelper.insertPassword(Map<String, dynamic>.from(password));
      }
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }
} 