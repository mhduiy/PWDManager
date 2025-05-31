import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PasswordAuth {
  static const String _passwordKey = 'auth_password';
  
  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordKey);
    
    if (storedHash == null) {
      return true; // 如果没有设置密码，返回true
    }
    
    final hashedPassword = _hashPassword(password);
    return hashedPassword == storedHash;
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
} 