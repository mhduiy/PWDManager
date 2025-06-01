import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'main.dart'; // 导入SecurityManager

class PasswordAuth {
  static const String _passwordKey = 'auth_password';
  static const String _attemptCountKey = 'failed_attempts';
  static const String _lockTimeKey = 'lock_time';
  static const String _lastAttemptTimeKey = 'last_attempt_time';
  
  // 尝试窗口期（分钟） - 保持不变
  static const int attemptWindowMinutes = 15;
  
  // 获取配置参数
  static Future<int> get maxAttempts async {
    final securityManager = SecurityManager();
    return securityManager.maxAttempts;
  }
  
  static Future<int> get lockDurationMinutes async {
    final securityManager = SecurityManager();
    return securityManager.lockDurationMinutes;
  }
  
  static Future<int> get lockDurationSeconds async {
    final securityManager = SecurityManager();
    return securityManager.lockDurationSeconds;
  }
  
  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordKey);
    
    if (storedHash == null) {
      return true; // 如果没有设置密码，返回true
    }
    
    // 检查是否被锁定
    if (await isLocked()) {
      return false;
    }
    
    final hashedPassword = _hashPassword(password);
    final isValid = hashedPassword == storedHash;
    
    if (isValid) {
      // 密码正确，清除失败记录
      await _clearFailedAttempts();
      return true;
    } else {
      // 密码错误，记录失败尝试
      await _recordFailedAttempt();
      return false;
    }
  }
  
  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final hashedPassword = _hashPassword(password);
    await prefs.setString(_passwordKey, hashedPassword);
  }
  
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  static Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordKey);
  }

  static Future<void> clearPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
  }
  
  // 新增：记录失败尝试
  static Future<void> _recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastAttempt = prefs.getInt(_lastAttemptTimeKey) ?? 0;
    final currentAttempts = prefs.getInt(_attemptCountKey) ?? 0;
    final maxAttemptsConfig = await maxAttempts;
    final lockDurationSecondsConfig = await lockDurationSeconds;
    
    // 如果距离上次尝试超过窗口期，重置计数
    if (now - lastAttempt > attemptWindowMinutes * 60 * 1000) {
      await prefs.setInt(_attemptCountKey, 1);
    } else {
      await prefs.setInt(_attemptCountKey, currentAttempts + 1);
    }
    
    await prefs.setInt(_lastAttemptTimeKey, now);
    
    // 如果锁定时间为0，则不设置锁定（功能关闭）
    if (lockDurationSecondsConfig == 0) {
      return;
    }
    
    // 如果达到最大尝试次数，设置锁定时间
    final newAttempts = prefs.getInt(_attemptCountKey) ?? 0;
    if (newAttempts >= maxAttemptsConfig) {
      await prefs.setInt(_lockTimeKey, now + lockDurationSecondsConfig * 1000);
    }
  }
  
  // 新增：清除失败尝试记录
  static Future<void> _clearFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptCountKey);
    await prefs.remove(_lockTimeKey);
    await prefs.remove(_lastAttemptTimeKey);
  }
  
  // 新增：检查是否被锁定
  static Future<bool> isLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final lockTime = prefs.getInt(_lockTimeKey);
    
    if (lockTime == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= lockTime) {
      // 锁定时间已过，清除锁定状态
      await _clearFailedAttempts();
      return false;
    }
    
    return true;
  }
  
  // 新增：获取剩余锁定时间（秒）
  static Future<int> getRemainingLockTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockTime = prefs.getInt(_lockTimeKey);
    
    if (lockTime == null) return 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = lockTime - now;
    
    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }
  
  // 新增：获取当前失败尝试次数
  static Future<int> getFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAttempt = prefs.getInt(_lastAttemptTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 如果距离上次尝试超过窗口期，返回0
    if (now - lastAttempt > attemptWindowMinutes * 60 * 1000) {
      return 0;
    }
    
    return prefs.getInt(_attemptCountKey) ?? 0;
  }
  
  // 新增：获取剩余尝试次数
  static Future<int> getRemainingAttempts() async {
    final attempts = await getFailedAttempts();
    final maxAttemptsConfig = await maxAttempts;
    return maxAttemptsConfig - attempts;
  }
} 