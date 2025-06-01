import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PasswordGenerator extends StatefulWidget {
  final Function(String) onPasswordGenerated;

  const PasswordGenerator({
    super.key,
    required this.onPasswordGenerated,
  });

  @override
  State<PasswordGenerator> createState() => _PasswordGeneratorState();
}

class _PasswordGeneratorState extends State<PasswordGenerator> {
  double _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  bool _excludeSimilar = false; // 排除相似字符如 0, O, l, 1
  String _generatedPassword = '';

  // 字符集定义
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  
  // 相似字符
  static const String _similarChars = '0O1l';

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    if (!_includeUppercase && !_includeLowercase && !_includeNumbers && !_includeSymbols) {
      setState(() {
        _generatedPassword = '';
      });
      return;
    }

    String charset = '';
    List<String> requiredChars = [];

    if (_includeUppercase) {
      String chars = _excludeSimilar ? _uppercase.replaceAll(RegExp('[$_similarChars]'), '') : _uppercase;
      charset += chars;
      requiredChars.add(chars[Random().nextInt(chars.length)]);
    }
    if (_includeLowercase) {
      String chars = _excludeSimilar ? _lowercase.replaceAll(RegExp('[$_similarChars]'), '') : _lowercase;
      charset += chars;
      requiredChars.add(chars[Random().nextInt(chars.length)]);
    }
    if (_includeNumbers) {
      String chars = _excludeSimilar ? _numbers.replaceAll(RegExp('[$_similarChars]'), '') : _numbers;
      charset += chars;
      requiredChars.add(chars[Random().nextInt(chars.length)]);
    }
    if (_includeSymbols) {
      charset += _symbols;
      requiredChars.add(_symbols[Random().nextInt(_symbols.length)]);
    }

    final random = Random();
    final length = _length.toInt();
    
    // 生成密码，确保包含所需字符类型
    List<String> passwordChars = List.from(requiredChars);
    
    // 填充剩余位置
    for (int i = requiredChars.length; i < length; i++) {
      passwordChars.add(charset[random.nextInt(charset.length)]);
    }
    
    // 打乱字符顺序
    passwordChars.shuffle(random);
    
    setState(() {
      _generatedPassword = passwordChars.join();
    });
  }

  String _getPasswordStrength() {
    if (_generatedPassword.isEmpty) return '无';
    
    int score = 0;
    if (_length >= 8) score++;
    if (_length >= 12) score++;
    if (_length >= 16) score++;
    if (_includeUppercase) score++;
    if (_includeLowercase) score++;
    if (_includeNumbers) score++;
    if (_includeSymbols) score++;
    
    if (score <= 2) return '弱';
    if (score <= 4) return '中等';
    if (score <= 6) return '强';
    return '很强';
  }

  Color _getStrengthColor() {
    final strength = _getPasswordStrength();
    switch (strength) {
      case '弱': return Colors.red;
      case '中等': return Colors.orange;
      case '强': return Colors.blue;
      case '很强': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.generating_tokens,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '密码生成器',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 生成的密码显示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '生成的密码',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStrengthColor(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPasswordStrength(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _generatedPassword,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _generatedPassword.isNotEmpty ? () {
                        Clipboard.setData(ClipboardData(text: _generatedPassword));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('密码已复制到剪贴板')),
                        );
                      } : null,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('复制'),
                    ),
                    TextButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('重新生成'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _generatedPassword.isNotEmpty ? () {
                        widget.onPasswordGenerated(_generatedPassword);
                        Navigator.pop(context);
                      } : null,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('使用'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 密码长度滑块
          Text(
            '密码长度: ${_length.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _length,
            min: 4,
            max: 32,
            divisions: 28,
            label: _length.toInt().toString(),
            onChanged: (value) {
              setState(() {
                _length = value;
              });
              _generatePassword();
            },
          ),
          
          const SizedBox(height: 16),
          
          // 字符类型选项
          const Text(
            '字符类型',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          CheckboxListTile(
            title: const Text('大写字母 (A-Z)'),
            subtitle: Text(_includeUppercase ? '包含' : '不包含'),
            value: _includeUppercase,
            onChanged: (value) {
              setState(() {
                _includeUppercase = value ?? false;
              });
              _generatePassword();
            },
            dense: true,
          ),
          
          CheckboxListTile(
            title: const Text('小写字母 (a-z)'),
            subtitle: Text(_includeLowercase ? '包含' : '不包含'),
            value: _includeLowercase,
            onChanged: (value) {
              setState(() {
                _includeLowercase = value ?? false;
              });
              _generatePassword();
            },
            dense: true,
          ),
          
          CheckboxListTile(
            title: const Text('数字 (0-9)'),
            subtitle: Text(_includeNumbers ? '包含' : '不包含'),
            value: _includeNumbers,
            onChanged: (value) {
              setState(() {
                _includeNumbers = value ?? false;
              });
              _generatePassword();
            },
            dense: true,
          ),
          
          CheckboxListTile(
            title: const Text('特殊字符 (!@#\$%^&*)'),
            subtitle: Text(_includeSymbols ? '包含' : '不包含'),
            value: _includeSymbols,
            onChanged: (value) {
              setState(() {
                _includeSymbols = value ?? false;
              });
              _generatePassword();
            },
            dense: true,
          ),
          
          CheckboxListTile(
            title: const Text('排除相似字符'),
            subtitle: Text(_excludeSimilar ? '排除 0, O, l, 1 等' : '包含所有字符'),
            value: _excludeSimilar,
            onChanged: (value) {
              setState(() {
                _excludeSimilar = value ?? false;
              });
              _generatePassword();
            },
            dense: true,
          ),
        ],
      ),
    );
  }
} 