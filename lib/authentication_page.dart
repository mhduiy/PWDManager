import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'main.dart';
import 'password_auth.dart';
import 'databasehelper.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';
import 'crypto_manager.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({
    super.key, 
    required this.title,
    this.startPosition,
    this.startSize,
    this.startIcon = Icons.lock_open,
  });
  
  final String title;
  final Offset? startPosition;
  final Size? startSize;
  final IconData startIcon;

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> with TickerProviderStateMixin {
  // 动画相关常量
  static const Duration _animationDuration = Duration(milliseconds: 800);
  static const Duration _breathingAnimationDuration = Duration(seconds: 25);
  
  // 布局相关常量
  static const double _containerSize = 100.0;
  static const double _startIconSize = 22.0;
  static const double _targetIconSize = 52.0;
  static const double _defaultOpacity = 0.7;
  static const double _maxOpacity = 0.85;
  
  // 布局比例常量
  static const double _numberButtonSize = 65.0;
  static const double _numberButtonPadding = 2.0;
  static const double _dotSize = 14.0;
  static const double _dotSpacing = 8.0;
  static const double _maxKeypadWidth = 240.0;
  
  // 间距常量
  static const double _keypadBottomSpacing = 30.0;
  static const double _dotsToKeypadSpacing = 35.0;
  static const double _lockToDotsSpacing = 45.0;

  // 动画权重常量
  static const double _initialAnimationWeight = 30.0;
  static const double _finalAnimationWeight = 70.0;

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
  
  // 添加锁头动画控制器
  late AnimationController _lockPositionController;
  late Animation<Offset> _lockPositionAnimation;
  late Animation<double> _lockSizeAnimation;
  late Animation<double> _lockOpacityAnimation;
  bool _isLockAnimationInitialized = false;

  // 初始化图标切换动画
  late AnimationController _iconChangeController;
  late Animation<double> _iconChangeAnimation;

  // 添加弹性动画控制器
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // 添加页面淡入动画控制器
  late AnimationController _pageOpacityController;
  late Animation<double> _pageOpacityAnimation;

  // 新增：锁定相关状态变量
  bool _isLocked = false;
  int _remainingLockTime = 0;
  Timer? _lockTimer;
  int _failedAttempts = 0;
  int _remainingAttempts = 5;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeAnimations();
    
    _breathingController = AnimationController(
      duration: _breathingAnimationDuration,
      vsync: this,
    );
    
    _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    );

    // 初始化页面淡入动画
    _pageOpacityController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pageOpacityAnimation = CurvedAnimation(
      parent: _pageOpacityController,
      curve: Curves.easeOut,
    );

    // 启动页面淡入动画，完成后启动背景呼吸动画
    _pageOpacityController.forward().then((_) {
      if (mounted) {
        _breathingController.repeat(reverse: true);
      }
    });

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    
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

    // 初始化弹性动画控制器
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutBack,
    ));

    // 动画完成后自动返回
    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bounceController.reverse();
      }
    });

    // 初始化图标切换动画
    _iconChangeController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    // 初始化锁头动画控制器
    _lockPositionController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.lightImpact();
        // 触发弹性动画
        _bounceController.forward();
      }
    });

    _iconChangeAnimation = CurvedAnimation(
      parent: _lockPositionController,
      curve: Curves.easeInOut,
    );

    // 只有在提供了起始位置时才初始化动画
    if (widget.startPosition != null && widget.startSize != null) {
      // 延迟到下一帧初始化动画
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeLockAnimation();
      });
    } else {
      setState(() {
        _isLockAnimationInitialized = true;
      });
    }
    
    // 新增：检查初始锁定状态
    _checkLockStatus();
  }

  void _initializeAnimations() {
    // 为数字0-9创建动画控制器
    for (int i = 0; i <= 9; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 50),
        vsync: this,
      );
      _animationControllers[i.toString()] = controller;
      _animations[i.toString()] = Tween<double>(begin: 1.0, end: 0.98).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.linear,
        ),
      );
    }
    // 为删除和指纹按钮创建动画控制器
    for (String key in ['delete', 'fingerprint']) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 50),
        vsync: this,
      );
      _animationControllers[key] = controller;
      _animations[key] = Tween<double>(begin: 1.0, end: 0.98).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.linear,
        ),
      );
    }
  }

  Offset _calculateLockPosition(BuildContext context, double availableTopSpace) {
    final size = MediaQuery.of(context).size;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    
    // 计算水平居中位置
    final horizontalCenter = size.width / 2;
    final containerOffset = _containerSize / 2;
    
    // 计算锁头顶部位置，最小保持40的上边距
    double topOffset = max(40.0, availableTopSpace * 0.5);
    
    return Offset(
      horizontalCenter - containerOffset,
      safeAreaTop + appBarHeight + topOffset,
    );
  }

  void _initializeLockAnimation() {
    if (_isLockAnimationInitialized) return;

    // 计算目标位置
    final targetPosition = _calculateLockPosition(context, 1.0);

    // 使用实际传递的按钮尺寸计算起始位置
    final actualStartSize = widget.startSize ?? const Size(_startIconSize, _startIconSize);
    final startIconCenter = Offset(
      widget.startPosition!.dx + actualStartSize.width / 2,
      widget.startPosition!.dy + actualStartSize.height / 2,
    );

    final startPosition = Offset(
      startIconCenter.dx - _containerSize / 2,
      startIconCenter.dy - _containerSize / 2,
    );

    // 创建位置动画
    _lockPositionAnimation = Tween<Offset>(
      begin: startPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _lockPositionController,
      curve: Curves.easeInOutCubic,
    ));

    // 创建大小动画，使用实际按钮尺寸
    _lockSizeAnimation = Tween<double>(
      begin: actualStartSize.width / _targetIconSize,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _lockPositionController,
      curve: Curves.easeInOutCubic,
    ));

    // 创建透明度动画
    _lockOpacityAnimation = Tween<double>(
      begin: _defaultOpacity,
      end: _defaultOpacity,  // 保持相同的透明度，减少视觉干扰
    ).animate(CurvedAnimation(
      parent: _lockPositionController,
      curve: Curves.easeInOutCubic,
    ));

    setState(() {
      _isLockAnimationInitialized = true;
    });

    // 启动动画
    _lockPositionController.forward();
  }

  @override
  void dispose() {
    _lockTimer?.cancel(); // 新增：清理锁定定时器
    _breathingController.dispose();
    _securityManager.removeListener(_securityListener);
    _shakeController.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _passwordController.dispose();
    _successController.dispose();
    _lockPositionController.dispose();
    _iconChangeController.dispose();
    _bounceController.dispose();  // 释放弹性动画控制器
    _pageOpacityController.dispose();
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

    // 认证状态检查完成后，检查是否需要自动触发生物认证
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoAuthentication();
    });
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

  void _onAuthenticationSuccess() async {
    // 访问密码验证成功后，尝试加载持久化的加密密钥
    final keysLoaded = await CryptoManager.loadPersistedKeys();
    
    if (keysLoaded) {
      // 成功加载密钥，直接进入主界面
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainFrame(title: "PWD Manager")),
      );
    } else {
      // 没有持久化的密钥，需要验证加密密码
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EncryptionPasswordVerifyPage()),
      );
    }
  }

  Widget _buildNumberButton(String number) {
    final isDisabled = _isLocked;
    
    return SizedBox(
      width: _numberButtonSize,
      height: _numberButtonSize,
      child: Padding(
        padding: EdgeInsets.all(_numberButtonPadding),
        child: Material(
          color: isDisabled 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: const CircleBorder(),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTapDown: isDisabled ? null : (_) {
              HapticFeedback.lightImpact();
            },
            onTap: isDisabled ? null : () {
              setState(() {
                _password += number;
                _verifyPassword();
              });
            },
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, String animationKey) {
    final isDisabled = _isLocked;
    
    return SizedBox(
      width: _numberButtonSize,
      height: _numberButtonSize,
      child: Padding(
        padding: EdgeInsets.all(_numberButtonPadding),
        child: Material(
          color: isDisabled 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          shape: const CircleBorder(),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTapDown: isDisabled ? null : (_) {
              HapticFeedback.lightImpact();
            },
            onTap: isDisabled ? null : onPressed,
            child: Center(
              child: Icon(
                icon,
                size: 28,
                color: isDisabled
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
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
          width: _dotSize,
          height: _dotSize,
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
                width: _dotSize,
                height: _dotSize,
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
              width: _dotSize,
              height: _dotSize,
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

  Widget _buildPasswordDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_isError ? _shakeAnimation.value : 0, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final dotsWidth = (6 * (_dotSize + 2 * _dotSpacing));
              final scale = min(1.0, screenWidth * 0.6 / dotsWidth);
              
              return Transform.scale(
                scale: scale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: EdgeInsets.all(_dotSpacing),
                      child: _buildDot(index),
                    );
                  }),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildKeypad() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = min(constraints.maxWidth, _maxKeypadWidth);
        final buttonSpacing = (availableWidth - 3 * _numberButtonSize) / 2;
        
        return Container(
          constraints: BoxConstraints(maxWidth: _maxKeypadWidth),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1, 2, 3].map((i) => _buildNumberButton(i.toString())).toList(),
              ),
              SizedBox(height: buttonSpacing * 0.7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [4, 5, 6].map((i) => _buildNumberButton(i.toString())).toList(),
              ),
              SizedBox(height: buttonSpacing * 0.7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [7, 8, 9].map((i) => _buildNumberButton(i.toString())).toList(),
              ),
              SizedBox(height: buttonSpacing * 0.7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!Platform.isLinux && _canCheckBiometrics && 
                      _availableBiometrics.isNotEmpty && 
                      _securityManager.enableBiometric)
                    _buildActionButton(Icons.fingerprint, _authenticateWithBiometrics, 'fingerprint')
                  else
                    SizedBox(width: _numberButtonSize),
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
        );
      },
    );
  }

  Widget _buildLockIcon() {
    if (!_isLockAnimationInitialized) return const SizedBox.shrink();

    Widget buildIcon(IconData icon, double opacity) {
      return Center(
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: Icon(
                icon,
                size: _targetIconSize,
                color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
              ),
            );
          },
        ),
      );
    }

    // 如果没有提供起始位置，直接显示在目标位置
    if (widget.startPosition == null || widget.startSize == null) {
      final targetPosition = _calculateLockPosition(context, 1.0);
      return Positioned(
        left: targetPosition.dx,
        top: targetPosition.dy,
        child: Container(
          width: _containerSize,
          height: _containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
          child: buildIcon(Icons.lock_outline, _defaultOpacity),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _lockPositionController,
      builder: (context, child) {
        return Positioned(
          left: _lockPositionAnimation.value.dx,
          top: _lockPositionAnimation.value.dy,
          child: Transform.scale(
            scale: _lockSizeAnimation.value,
            child: Container(
              width: _containerSize,
              height: _containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                children: [
                  Opacity(
                    opacity: 1 - _iconChangeAnimation.value,
                    child: buildIcon(widget.startIcon, _lockOpacityAnimation.value),
                  ),
                  Opacity(
                    opacity: _iconChangeAnimation.value,
                    child: buildIcon(Icons.lock_outline, _lockOpacityAnimation.value),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _verifyPassword() async {
    if (_isLocked) {
      return; // 如果已锁定，直接返回
    }
    
    if (_password.length == 6) {
      final bool isValid = await PasswordAuth.verifyPassword(_password);
      if (isValid) {
        setState(() {
          _isSuccess = true;
        });
        _successController.forward();
        HapticFeedback.mediumImpact();
        
        Future.delayed(const Duration(milliseconds: 300), () {
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
        
        // 新增：检查是否被锁定
        await _checkLockStatus();
      }
    }
  }

  // 新增：检查锁定状态
  Future<void> _checkLockStatus() async {
    final isLocked = await PasswordAuth.isLocked();
    final failedAttempts = await PasswordAuth.getFailedAttempts();
    final remainingAttempts = await PasswordAuth.getRemainingAttempts();
    final lockDuration = await PasswordAuth.lockDurationMinutes;
    
    if (isLocked) {
      final remainingTime = await PasswordAuth.getRemainingLockTime();
      setState(() {
        _isLocked = true;
        _remainingLockTime = remainingTime;
        _failedAttempts = failedAttempts;
        _remainingAttempts = 0;
      });
      _startLockTimer();
    } else {
      setState(() {
        _isLocked = false;
        _remainingLockTime = 0;
        _failedAttempts = failedAttempts;
        _remainingAttempts = lockDuration == 0 ? -1 : remainingAttempts; // -1表示锁定功能关闭
      });
    }
  }

  // 新增：启动锁定倒计时定时器
  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remainingTime = await PasswordAuth.getRemainingLockTime();
      if (remainingTime <= 0) {
        timer.cancel();
        await _checkLockStatus(); // 重新检查状态
      } else {
        setState(() {
          _remainingLockTime = remainingTime;
        });
      }
    });
  }

  // 新增：格式化倒计时显示
  String _formatLockTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _checkAutoAuthentication() {
    // 检查是否应该自动触发生物认证
    if (!Platform.isLinux && 
        _canCheckBiometrics && 
        _availableBiometrics.isNotEmpty && 
        _securityManager.enableBiometric && 
        _securityManager.autoBiometric) {
      // 延迟一小段时间后自动触发生物认证
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _authenticateWithBiometrics();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPassword) {
      return const MainFrame(title: "PWD Manager");
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: AnimatedBuilder(
        animation: _pageOpacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pageOpacityAnimation.value,
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                // 简化的颜色过渡动画
                final progress = _breathingAnimation.value;
                final color1 = Color.lerp(
                  primaryColor.withOpacity(0.15),
                  primaryColor.withOpacity(0.25),
                  progress,
                )!;
                final color2 = Color.lerp(
                  secondaryColor.withOpacity(0.1),
                  secondaryColor.withOpacity(0.2),
                  progress,
                )!;
                
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.5,
                          colors: [
                            color1,
                            color2,
                            primaryColor.withOpacity(0.05),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    _buildLockIcon(),
                    _buildContentLayout(),
                  ],
                );
              },
              child: _buildContentLayout(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentLayout() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 计算键盘部分
          final keypadHeight = _numberButtonSize * 4 + _numberButtonPadding * 6;
          
          // 计算指示器部分
          final dotsHeight = _dotSize + _dotSpacing * 2;
          
          // 计算状态提示部分高度
          final statusHeight = _isLocked || _failedAttempts > 0 ? 60.0 : 20.0;
          
          // 计算底部固定元素总高度
          final fixedElementsHeight = keypadHeight + dotsHeight + statusHeight + _keypadBottomSpacing + _dotsToKeypadSpacing;
          
          // 计算锁头可用的顶部空间
          final availableTopSpace = constraints.maxHeight - fixedElementsHeight - _lockToDotsSpacing;
          
          // 计算锁头位置
          final lockPosition = _calculateLockPosition(context, availableTopSpace);
          
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: _keypadBottomSpacing,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordDots(),
                    SizedBox(height: 16),
                    _buildStatusText(), // 新增：状态提示
                    SizedBox(height: _dotsToKeypadSpacing - 16),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: _buildKeypad(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 新增：构建状态提示文本
  Widget _buildStatusText() {
    if (_isLocked) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text(
              '输入错误次数过多',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '请等待 ${_formatLockTime(_remainingLockTime)} 后重试',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (_failedAttempts > 0) {
      if (_remainingAttempts == -1) {
        // 锁定功能关闭时的提示
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '密码错误，请重新输入',
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        // 正常锁定功能开启时的提示
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '密码错误，还可以尝试 ${_remainingAttempts} 次',
            style: TextStyle(
              color: _remainingAttempts <= 2 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.tertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
    }
    
    return SizedBox(height: 20); // 占位空间
  }
}