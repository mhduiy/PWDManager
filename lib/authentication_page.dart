import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';
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

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeAnimations();
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
    _securityManager.removeListener(_securityListener);
    _shakeController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _passwordController.dispose();
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
      width: 70,
      height: 70,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: GestureDetector(
          onTapDown: (_) => _animationControllers[number]?.forward(),
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
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 24,
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
      width: 70,
      height: 70,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: GestureDetector(
          onTapDown: (_) => _animationControllers[animationKey]?.forward(),
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
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _verifyPassword() async {
    if (_password.length == 6) {
      final bool isValid = await PasswordAuth.verifyPassword(_password);
      if (isValid) {
        _onAuthenticationSuccess();
      } else {
        setState(() {
          _password = "";
          _isError = true;
        });
        _shakeController.forward();
      }
    }
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
                  return Container(
                    margin: const EdgeInsets.all(10.0),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _password.length 
                        ? (_isError 
                            ? Colors.red 
                            : Theme.of(context).colorScheme.primary)
                        : (_isError 
                            ? Colors.red.withOpacity(0.2)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPassword) {
      return const MainFrame(title: "PWD Manager");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 32),
              _buildPasswordDots(),
              const SizedBox(height: 32),
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
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
                          Container(width: 70),
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
            ],
          ),
        ),
      ),
    );
  }
}