import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';
import 'dart:ui';
import 'main.dart';
import 'password_auth.dart';
import 'databasehelper.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key, required this.title});
  final String title;

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> with TickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  String _password = "";
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<double>> _animations = {};
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isError = false;
  final SecurityManager _securityManager = SecurityManager();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _hasPassword = false;
  List<BiometricType> _availableBiometrics = [];
  String _errorText = '';
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _successController;
  late Animation<double> _successAnimation;
  bool _isSuccess = false;
  late AnimationController _lockIconController;
  late Animation<double> _lockIconAnimation;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeAnimations();
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    
    // 创建一个更简单的抖动动画
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 20.0),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 20.0, end: -20.0),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -20.0, end: 20.0),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 20.0, end: -20.0),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -20.0, end: 0.0),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ))..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
        setState(() {
          _isError = false;
        });
      }
    });

    _successController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeInOut,
    );

    _lockIconController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _lockIconAnimation = CurvedAnimation(
      parent: _lockIconController,
      curve: Curves.easeOutBack,
    );

    // 延迟一小会后开始锁头动画
    Future.delayed(const Duration(milliseconds: 200), () {
      _lockIconController.forward();
    });
  }

  void _initializeAnimations() {
    // 为数字0-9创建动画控制器
    for (int i = 0; i <= 9; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      );
      _animationControllers[i.toString()] = controller;
      _animations[i.toString()] = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }
    // 为删除和指纹按钮创建动画控制器
    for (String key in ['delete', 'fingerprint']) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 100),
        vsync: this,
      );
      _animationControllers[key] = controller;
      _animations[key] = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _securityManager.removeListener(_securityListener);
    _shakeController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _passwordController.dispose();
    _successController.dispose();
    _lockIconController.dispose();
    super.dispose();
  }

  void _securityListener() {
    _updateSecuritySettings();
  }

  Future<void> _updateSecuritySettings() async {
    if (Platform.isLinux || Platform.isWindows) {
      await windowManager.setPreventClose(_securityManager.preventScreenshot);
    }
  }

  Future<void> _checkAuthStatus() async {
    final hasPassword = await PasswordAuth.hasPassword();
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = [];
    
    try {
      // 只在非Linux平台上检查生物认证
      if (!Platform.isLinux) {
        canCheckBiometrics = await auth.canCheckBiometrics;
        if (canCheckBiometrics) {
          availableBiometrics = await auth.getAvailableBiometrics();
        }
      }
    } on PlatformException {
      canCheckBiometrics = false;
    }

    setState(() {
      _hasPassword = hasPassword;
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
    });

    // 如果支持指纹认证且已启用，自动开始认证（非Linux平台）
    if (!Platform.isLinux && 
        _canCheckBiometrics && 
        _availableBiometrics.isNotEmpty && 
        _hasPassword &&
        _securityManager.enableBiometric) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: '请验证指纹以解锁应用',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
    }

    if (authenticated && mounted) {
      _onAuthenticationSuccess();
    }
  }

  void _onAuthenticationSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainFrame(title: "PWD Manager")),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 85,
      height: 85,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTapDown: (_) {
            _animationControllers[number]?.forward();
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            _animationControllers[number]?.reverse();
            setState(() {
              _password += number;
              _verifyPassword();
            });
          },
          onTapCancel: () => _animationControllers[number]?.reverse(),
          child: ScaleTransition(
            scale: _animations[number] ?? _animations['0']!,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, String animationKey) {
    return SizedBox(
      width: 85,
      height: 85,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTapDown: (_) {
            _animationControllers[animationKey]?.forward();
            HapticFeedback.lightImpact();
          },
          onTapUp: (_) {
            _animationControllers[animationKey]?.reverse();
            onPressed();
          },
          onTapCancel: () => _animationControllers[animationKey]?.reverse(),
          child: ScaleTransition(
            scale: _animations[animationKey] ?? _animations['delete']!,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_isError ? _shakeAnimation.value : 0, 0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: _buildDot(index),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final bool isFilled = index < _password.length;
    final Color dotColor = _isSuccess 
        ? Colors.green
        : (_isError 
            ? Colors.red 
            : Theme.of(context).colorScheme.primary);
    
    return Stack(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor.withOpacity(0.2),
          ),
        ),
        if (isFilled)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor.withOpacity(value),
                ),
              );
            },
          ),
        if (_isSuccess && index == 5)
          ScaleTransition(
            scale: _successAnimation,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
              child: const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  void _verifyPassword() async {
    if (_password.length == 6) {
      final bool isValid = await PasswordAuth.verifyPassword(_password);
      if (isValid) {
        setState(() {
          _isSuccess = true;
        });
        _successController.forward();
        HapticFeedback.mediumImpact();
        
        // 延迟进入主界面
        Future.delayed(const Duration(milliseconds: 800), () {
          _onAuthenticationSuccess();
        });
      } else {
        setState(() {
          _password = "";
          _isError = true;
          _isSuccess = false;
        });
        HapticFeedback.heavyImpact();
        _shakeController.forward();
      }
    }
  }

  Widget _buildLockIcon() {
    return ScaleTransition(
      scale: _lockIconAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          Icons.lock_outline,
          size: 45,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPassword) {
      return const MainFrame(title: "PWD Manager");
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    
    // 创建一些柔和的颜色
    final softColors = [
      primaryColor.withOpacity(0.25),
      primaryColor.withBlue(255).withOpacity(0.22),
      secondaryColor.withOpacity(0.2),
      primaryColor.withOpacity(0.25),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) {
          // 使用多个正弦函数叠加创造不规律的效果，但减小振幅
          final progress = _breathingAnimation.value;
          final wave1 = sin(progress * pi) * 0.25;
          final wave2 = sin(progress * 1.5 * pi) * 0.2;
          final wave3 = cos(progress * 0.8 * pi) * 0.2;
          
          // 混合多个波形，使用更平滑的混合
          final mixedProgress = (wave1 + wave2 + wave3 + 1) / 2;
          
          // 创建更缓慢的渐变中心点移动
          final centerX = sin(progress * 0.8 * pi) * 0.15 + cos(progress * 0.6 * pi) * 0.1;
          final centerY = cos(progress * 0.7 * pi) * 0.15 + sin(progress * 0.5 * pi) * 0.1;
          
          return Container(
            decoration: BoxDecoration(
              gradient: SweepGradient(
                center: Alignment(centerX, centerY),
                colors: [
                  Color.lerp(softColors[0], softColors[1], mixedProgress)!,
                  Color.lerp(softColors[1], softColors[2], mixedProgress)!,
                  Color.lerp(softColors[2], softColors[3], mixedProgress)!,
                ],
                stops: const [0.3, 0.6, 1.0],
                transform: GradientRotation(mixedProgress * 2.5 * pi),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 40,
                sigmaY: 40,
              ),
              child: child,
            ),
          );
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLockIcon(),
                const SizedBox(height: 40),
                _buildPasswordDots(),
                const SizedBox(height: 32),
                Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [1, 2, 3].map((i) => _buildNumberButton(i.toString())).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [4, 5, 6].map((i) => _buildNumberButton(i.toString())).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [7, 8, 9].map((i) => _buildNumberButton(i.toString())).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!Platform.isLinux && _canCheckBiometrics && 
                              _availableBiometrics.isNotEmpty && 
                              _securityManager.enableBiometric)
                            _buildActionButton(Icons.fingerprint, _authenticateWithBiometrics, 'fingerprint')
                          else
                            Container(width: 85),
                          _buildNumberButton('0'),
                          _buildActionButton(Icons.backspace, () {
                            if (_password.isNotEmpty) {
                              setState(() {
                                _password = _password.substring(0, _password.length - 1);
                              });
                            }
                          }, 'delete'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}