import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong
}

class PasswordStrengthChecker {
  static PasswordStrength checkStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    
    int score = 0;
    
    // 长度检查
    if (password.length >= 8) score += 2;
    if (password.length >= 12) score += 2;
    if (password.length >= 16) score += 2;
    
    // 字符类型检查
    if (password.contains(RegExp(r'[A-Z]'))) score += 2; // 大写字母
    if (password.contains(RegExp(r'[a-z]'))) score += 2; // 小写字母
    if (password.contains(RegExp(r'[0-9]'))) score += 2; // 数字
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 2; // 特殊字符
    
    // 复杂性检查
    if (password.contains(RegExp(r'[A-Z]')) && 
        password.contains(RegExp(r'[a-z]')) && 
        password.contains(RegExp(r'[0-9]'))) {
      score += 2; // 同时包含大小写字母和数字
    }
    
    // 返回强度等级
    if (score >= 12) return PasswordStrength.veryStrong;
    if (score >= 8) return PasswordStrength.strong;
    if (score >= 5) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.veryStrong:
        return Colors.blue;
    }
  }

  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.medium:
        return '中';
      case PasswordStrength.strong:
        return '强';
      case PasswordStrength.veryStrong:
        return '非常强';
    }
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool animate;

  const PasswordStrengthIndicator({
    Key? key,
    required this.password,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrengthChecker.checkStrength(password);
    final color = PasswordStrengthChecker.getStrengthColor(strength);
    final text = PasswordStrengthChecker.getStrengthText(strength);
    
    // 计算强度值（0-1）
    double strengthValue;
    switch (strength) {
      case PasswordStrength.weak:
        strengthValue = 0.25;
        break;
      case PasswordStrength.medium:
        strengthValue = 0.5;
        break;
      case PasswordStrength.strong:
        strengthValue = 0.75;
        break;
      case PasswordStrength.veryStrong:
        strengthValue = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: animate 
                ? TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: strengthValue,
                    ),
                    builder: (context, value, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: color.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      );
                    },
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: strengthValue,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildStrengthTips(),
      ],
    );
  }

  Widget _buildStrengthTips() {
    final strength = PasswordStrengthChecker.checkStrength(password);
    String tips = '';
    
    switch (strength) {
      case PasswordStrength.weak:
        tips = '建议：使用大小写字母、数字和特殊字符组合';
        break;
      case PasswordStrength.medium:
        tips = '建议：增加密码长度和字符种类';
        break;
      case PasswordStrength.strong:
        tips = '很好！密码强度已经很不错了';
        break;
      case PasswordStrength.veryStrong:
        tips = '太棒了！这是一个非常安全的密码';
        break;
    }

    return Text(
      tips,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }
} 