import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class CryptoManager {
  static const String _encryptionPasswordKey = 'encryption_password_hash';
  static const String _saltKey = 'encryption_salt';
  static const String _cachedKeyKey = 'cached_encryption_key';
  static const String _cachedIVKey = 'cached_encryption_iv';
  
  // 缓存的密钥，避免重复计算
  static encrypt.Key? _cachedKey;
  static encrypt.IV? _cachedIV;
  
  /// 检查是否已设置加密密码
  static Future<bool> hasEncryptionPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_encryptionPasswordKey);
  }
  
  /// 设置加密密码
  static Future<void> setEncryptionPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 生成设备唯一的盐值
    final salt = await _generateOrGetSalt();
    
    // 计算密码哈希用于验证
    final passwordHash = _hashPassword(password, salt);
    await prefs.setString(_encryptionPasswordKey, passwordHash);
    
    // 派生并缓存密钥
    await _deriveAndCacheKey(password, salt);
    
    // 持久化密钥到安全存储
    await _persistKeys();
  }
  
  /// 验证加密密码
  static Future<bool> verifyEncryptionPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_encryptionPasswordKey);
    
    if (storedHash == null) return false;
    
    final salt = await _getSalt();
    if (salt == null) return false;
    
    final passwordHash = _hashPassword(password, salt);
    final isValid = passwordHash == storedHash;
    
    if (isValid) {
      // 验证成功，派生并缓存密钥
      await _deriveAndCacheKey(password, salt);
      // 持久化密钥到安全存储
      await _persistKeys();
    }
    
    return isValid;
  }
  
  /// 从持久存储加载密钥（用于访问密码验证成功后）
  static Future<bool> loadPersistedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keyString = prefs.getString(_cachedKeyKey);
    final ivString = prefs.getString(_cachedIVKey);
    
    if (keyString == null || ivString == null) {
      return false;
    }
    
    try {
      final keyBytes = base64.decode(keyString);
      final ivBytes = base64.decode(ivString);
      
      _cachedKey = encrypt.Key(keyBytes);
      _cachedIV = encrypt.IV(ivBytes);
      
      return true;
    } catch (e) {
      // 如果解码失败，清除损坏的数据
      await _clearPersistedKeys();
      return false;
    }
  }
  
  /// 持久化密钥到安全存储
  static Future<void> _persistKeys() async {
    if (_cachedKey == null || _cachedIV == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedKeyKey, base64.encode(_cachedKey!.bytes));
    await prefs.setString(_cachedIVKey, base64.encode(_cachedIV!.bytes));
  }
  
  /// 清除持久化的密钥
  static Future<void> _clearPersistedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedKeyKey);
    await prefs.remove(_cachedIVKey);
  }
  
  /// 获取缓存的加密密钥
  static encrypt.Key? getCachedKey() {
    return _cachedKey;
  }
  
  /// 获取缓存的IV
  static encrypt.IV? getCachedIV() {
    return _cachedIV;
  }
  
  /// 清除密钥缓存（用户锁定应用时）
  static void clearKeyCache() {
    _cachedKey = null;
    _cachedIV = null;
  }
  
  /// 生成或获取存储的盐值
  static Future<Uint8List> _generateOrGetSalt() async {
    final prefs = await SharedPreferences.getInstance();
    final saltString = prefs.getString(_saltKey);
    
    if (saltString != null) {
      return base64.decode(saltString);
    }
    
    // 生成新的随机盐值
    final salt = _generateRandomBytes(32);
    await prefs.setString(_saltKey, base64.encode(salt));
    return salt;
  }
  
  /// 获取存储的盐值
  static Future<Uint8List?> _getSalt() async {
    final prefs = await SharedPreferences.getInstance();
    final saltString = prefs.getString(_saltKey);
    
    if (saltString == null) return null;
    return base64.decode(saltString);
  }
  
  /// 使用PBKDF2派生密钥和IV
  static Future<void> _deriveAndCacheKey(String password, Uint8List salt) async {
    // 使用PBKDF2派生32字节的密钥材料 + 16字节IV = 48字节总计
    final derivedKey = _pbkdf2(password, salt, 100000, 48);
    
    // 分割密钥材料：前32字节作为AES密钥，后16字节作为IV
    final keyBytes = derivedKey.sublist(0, 32);
    final ivBytes = derivedKey.sublist(32, 48);
    
    _cachedKey = encrypt.Key(keyBytes);
    _cachedIV = encrypt.IV(ivBytes);
  }
  
  /// 密码哈希（用于验证）
  static String _hashPassword(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final combined = Uint8List.fromList([...passwordBytes, ...salt]);
    final digest = sha256.convert(combined);
    return digest.toString();
  }
  
  /// PBKDF2实现
  static Uint8List _pbkdf2(String password, Uint8List salt, int iterations, int keyLength) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);
    
    final result = Uint8List(keyLength);
    var resultOffset = 0;
    var blockIndex = 1;
    
    while (resultOffset < keyLength) {
      // 计算当前块
      final block = _pbkdf2Block(hmac, salt, iterations, blockIndex);
      final blockLength = (keyLength - resultOffset).clamp(0, block.length);
      
      result.setRange(resultOffset, resultOffset + blockLength, block);
      resultOffset += blockLength;
      blockIndex++;
    }
    
    return result;
  }
  
  /// PBKDF2单个块计算
  static Uint8List _pbkdf2Block(Hmac hmac, Uint8List salt, int iterations, int blockIndex) {
    // 初始化：Salt + BlockIndex (big-endian)
    final initialInput = Uint8List.fromList([
      ...salt,
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ]);
    
    var u = Uint8List.fromList(hmac.convert(initialInput).bytes);
    final result = Uint8List.fromList(u);
    
    // 迭代计算
    for (int i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      
      // XOR操作
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    
    return result;
  }
  
  /// 生成随机字节
  static Uint8List _generateRandomBytes(int length) {
    final random = math.Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
  
  /// 清除所有加密相关数据（重置应用时使用）
  static Future<void> clearEncryptionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_encryptionPasswordKey);
    await prefs.remove(_saltKey);
    await _clearPersistedKeys();
    clearKeyCache();
  }
}