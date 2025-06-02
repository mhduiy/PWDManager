import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'crypto_manager.dart';
import 'password_auth.dart';
import 'main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  
  // 动画控制器
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  // 动画
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // 表单控制器
  final TextEditingController _encryptionPasswordController = TextEditingController();
  final TextEditingController _confirmEncryptionPasswordController = TextEditingController();
  final TextEditingController _accessPasswordController = TextEditingController();
  final TextEditingController _confirmAccessPasswordController = TextEditingController();
  
  // 状态变量
  bool _isEncryptionPasswordVisible = false;
  bool _isConfirmEncryptionPasswordVisible = false;
  bool _isAccessPasswordVisible = false;
  bool _isConfirmAccessPasswordVisible = false;
  bool _skipAccessPassword = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // 启动入场动画
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _encryptionPasswordController.dispose();
    _confirmEncryptionPasswordController.dispose();
    _accessPasswordController.dispose();
    _confirmAccessPasswordController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentPage < 3) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 设置加密密码
      await CryptoManager.setEncryptionPassword(_encryptionPasswordController.text);
      
      // 如果用户选择设置访问密码
      if (!_skipAccessPassword && _accessPasswordController.text.isNotEmpty) {
        await PasswordAuth.setPassword(_accessPasswordController.text);
      }
      
      // 设置完成，进入主界面
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainFrame(title: 'PWD Manager'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置失败：$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 进度指示器
                    _buildProgressIndicator(),
                    
                    // 页面内容
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          _buildWelcomePage(),
                          _buildEncryptionPasswordPage(),
                          _buildAccessPasswordPage(),
                          _buildCompletePage(),
                        ],
                      ),
                    ),
                    
                    // 导航按钮
                    _buildNavigationButtons(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              child: isCompleted
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildWelcomePage() {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo和动画
              TweenAnimationBuilder<double>(
                duration: const Duration(seconds: 2),
                tween: Tween(begin: 0, end: 2 * math.pi),
                builder: (context, angle, child) {
                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              Text(
                '欢迎使用 PWD Manager',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                '您的密码安全管家',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              _buildFeatureCard(
                icon: Icons.enhanced_encryption,
                title: '军用级加密',
                description: 'AES-256加密算法保护您的密码数据',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                icon: Icons.fingerprint,
                title: '生物认证',
                description: '支持指纹和面容ID快速解锁',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeatureCard(
                icon: Icons.devices,
                title: '跨平台同步',
                description: '支持Android、iOS、Windows、macOS、Linux',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEncryptionPasswordPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '设置加密密码',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '这个密码将用于保护您的所有数据安全\n请设置一个强密码并牢记',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          TextField(
            controller: _encryptionPasswordController,
            obscureText: !_isEncryptionPasswordVisible,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '加密密码',
              hintText: '请输入8-32位强密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isEncryptionPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isEncryptionPasswordVisible = !_isEncryptionPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _confirmEncryptionPasswordController,
            obscureText: !_isConfirmEncryptionPasswordVisible,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '确认加密密码',
              hintText: '请再次输入密码',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmEncryptionPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmEncryptionPasswordVisible = !_isConfirmEncryptionPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildPasswordStrengthIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildPasswordStrengthIndicator() {
    final password = _encryptionPasswordController.text;
    final strength = _calculatePasswordStrength(password);
    
    Color strengthColor;
    String strengthText;
    
    if (strength < 0.3) {
      strengthColor = Theme.of(context).colorScheme.error;
      strengthText = '弱';
    } else if (strength < 0.7) {
      strengthColor = Colors.orange;
      strengthText = '中等';
    } else {
      strengthColor = Colors.green;
      strengthText = '强';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '密码强度',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              strengthText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
      ],
    );
  }
  
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // 长度检查
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.length >= 16) strength += 0.1;
    
    // 字符类型检查
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    
    // 复杂性检查
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= password.length * 0.7) strength += 0.1;
    
    return math.min(strength, 1.0);
  }
  
  Widget _buildAccessPasswordPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smartphone,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '设置访问密码（可选）',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '6位数字密码用于快速解锁应用\n您也可以跳过此步骤',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          CheckboxListTile(
            title: const Text('跳过访问密码设置'),
            subtitle: const Text('直接使用应用，无需每次解锁'),
            value: _skipAccessPassword,
            onChanged: (value) {
              setState(() {
                _skipAccessPassword = value ?? false;
                if (_skipAccessPassword) {
                  _accessPasswordController.clear();
                  _confirmAccessPasswordController.clear();
                }
              });
            },
          ),
          
          if (!_skipAccessPassword) ...[
            const SizedBox(height: 24),
            
            TextField(
              controller: _accessPasswordController,
              obscureText: !_isAccessPasswordVisible,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: '访问密码',
                hintText: '请输入6位数字',
                prefixIcon: const Icon(Icons.dialpad),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isAccessPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isAccessPasswordVisible = !_isAccessPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _confirmAccessPasswordController,
              obscureText: !_isConfirmAccessPasswordVisible,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: '确认访问密码',
                hintText: '请再次输入6位数字',
                prefixIcon: const Icon(Icons.dialpad),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmAccessPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmAccessPasswordVisible = !_isConfirmAccessPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCompletePage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '设置完成！',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '您的密码管理器已准备就绪\n开始安全地管理您的密码吧',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          if (_isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '开始使用',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton.icon(
              onPressed: _previousPage,
              icon: const Icon(Icons.arrow_back),
              label: const Text('上一步'),
            )
          else
            const SizedBox(width: 100),
          
          if (_currentPage < 3)
            ElevatedButton.icon(
              onPressed: _canProceed() ? _nextPage : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('下一步'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            )
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }
  
  bool _canProceed() {
    switch (_currentPage) {
      case 0: // 欢迎页面
        return true;
      case 1: // 加密密码页面
        return _encryptionPasswordController.text.length >= 8 &&
               _encryptionPasswordController.text == _confirmEncryptionPasswordController.text;
      case 2: // 访问密码页面
        if (_skipAccessPassword) return true;
        return _accessPasswordController.text.length == 6 &&
               _accessPasswordController.text == _confirmAccessPasswordController.text &&
               RegExp(r'^\d+$').hasMatch(_accessPasswordController.text);
      case 3: // 完成页面
        return true;
      default:
        return false;
    }
  }
} 