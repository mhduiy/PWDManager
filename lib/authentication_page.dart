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
  static const Duration _animationDuration = Duration(milliseconds: 600);
  static const Duration _breathingAnimationDuration = Duration(seconds: 25);
  
  // 布局相关常量
  static const double _containerSize = 100.0;
  static const double _startIconSize = 22.0;
  static const double _targetIconSize = 45.0;
  static const double _defaultOpacity = 0.7;
  static const double _maxOpacity = 0.85;
  
  // 布局比例常量
  static const double _numberButtonSize = 85.0;
  static const double _numberButtonPadding = 8.0;
  static const double _dotSize = 16.0;
  static const double _dotSpacing = 10.0;
  static const double _maxKeypadWidth = 300.0;
  
  // 间距常量
  static const double _keypadBottomSpacing = 40.0;  // 键盘到底部的距离
  static const double _dotsToKeypadSpacing = 50.0;  // 指示器到键盘的距离
  static const double _lockToDotsSpacing = 60.0;    // 锁头到指示器的距离

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

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _initializeAnimations();
    
    _breathingController = AnimationController(
      duration: _breathingAnimationDuration,
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

    // 计算起始位置
    final startIconCenter = Offset(
      widget.startPosition!.dx + _startIconSize / 2,  // 起始图标的中心点
      widget.startPosition!.dy + _startIconSize / 2,
    );

    // 计算起始位置（考虑容器大小）
    final startPosition = Offset(
      startIconCenter.dx - _containerSize / 2,  // 使容器中心与图标中心对齐
      startIconCenter.dy - _containerSize / 2,
    );

    // 创建位置动画
    _lockPositionAnimation = Tween<Offset>(
      begin: startPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _lockPositionController,
      curve: Curves.easeOutCubic,
    ));

    // 创建大小动画
    _lockSizeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _startIconSize / _targetIconSize,
          end: (_startIconSize + 2) / _targetIconSize,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: _initialAnimationWeight,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: (_startIconSize + 2) / _targetIconSize,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: _finalAnimationWeight,
      ),
    ]).animate(_lockPositionController);

    // 创建透明度动画
    _lockOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _defaultOpacity,
          end: _maxOpacity,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: _initialAnimationWeight,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: _maxOpacity,
          end: _defaultOpacity,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: _finalAnimationWeight,
      ),
    ]).animate(_lockPositionController);

    setState(() {
      _isLockAnimationInitialized = true;
    });

    // 启动动画
    _lockPositionController.forward();
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
    _lockPositionController.dispose();
    _iconChangeController.dispose();
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
      width: _numberButtonSize,
      height: _numberButtonSize,
      child: Padding(
        padding: EdgeInsets.all(_numberButtonPadding),
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
      width: _numberButtonSize,
      height: _numberButtonSize,
      child: Padding(
        padding: EdgeInsets.all(_numberButtonPadding),
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
              SizedBox(height: buttonSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [4, 5, 6].map((i) => _buildNumberButton(i.toString())).toList(),
              ),
              SizedBox(height: buttonSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [7, 8, 9].map((i) => _buildNumberButton(i.toString())).toList(),
              ),
              SizedBox(height: buttonSpacing),
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
      return Center(  // 确保图标在容器中居中
        child: Icon(
          icon,
          size: _targetIconSize,
          color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPassword) {
      return const MainFrame(title: "PWD Manager");
    }

    final size = MediaQuery.of(context).size;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    
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
          final progress = _breathingAnimation.value;
          final wave1 = sin(progress * pi) * 0.25;
          final wave2 = sin(progress * 1.5 * pi) * 0.2;
          final wave3 = cos(progress * 0.8 * pi) * 0.2;
          
          final mixedProgress = (wave1 + wave2 + wave3 + 1) / 2;
          
          final centerX = sin(progress * 0.8 * pi) * 0.15 + cos(progress * 0.6 * pi) * 0.1;
          final centerY = cos(progress * 0.7 * pi) * 0.15 + sin(progress * 0.5 * pi) * 0.1;
          
          return Stack(
            children: [
              Container(
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
              ),
              _buildLockIcon(),
            ],
          );
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 计算键盘部分
              final keypadHeight = _numberButtonSize * 4 + _numberButtonPadding * 6;
              
              // 计算指示器部分
              final dotsHeight = _dotSize + _dotSpacing * 2;
              
              // 计算底部固定元素总高度
              final fixedElementsHeight = keypadHeight + dotsHeight + _keypadBottomSpacing + _dotsToKeypadSpacing;
              
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
                        SizedBox(height: _dotsToKeypadSpacing),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.05,
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
        ),
      ),
    );
  }
}