import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'password_page.dart';
import 'my_page.dart';
import 'password_edit_full_dialog.dart';
import 'authentication_page.dart';
import 'password_auth.dart';

// 全局主题管理器
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  bool _followSystem = true;
  bool _darkMode = false;
  Color _themeColor = Colors.deepPurple;

  bool get followSystem => _followSystem;
  bool get darkMode => _darkMode;
  Color get themeColor => _themeColor;

  ThemeManager._internal() {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _followSystem = prefs.getBool('follow_system_theme') ?? true;
    _darkMode = prefs.getBool('dark_mode') ?? false;
    _themeColor = Color(prefs.getInt('theme_color') ?? Colors.deepPurple.value);
    notifyListeners();
  }

  Future<void> setThemeMode({bool? followSystem, bool? darkMode}) async {
    final prefs = await SharedPreferences.getInstance();
    if (followSystem != null) {
      _followSystem = followSystem;
      await prefs.setBool('follow_system_theme', followSystem);
    }
    if (darkMode != null) {
      _darkMode = darkMode;
      await prefs.setBool('dark_mode', darkMode);
    }
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    _themeColor = color;
    await prefs.setInt('theme_color', color.value);
    notifyListeners();
  }
}

// 截屏防护管理器
class SecurityManager extends ChangeNotifier {
  static final SecurityManager _instance = SecurityManager._internal();
  factory SecurityManager() => _instance;

  bool _preventScreenshot = true;  // 默认开启截屏防护
  bool _enableBiometric = true;   // 默认开启指纹认证
  bool _autoBiometric = false;    // 默认关闭自动生物认证
  int _lockDurationSeconds = 300; // 默认锁定时间300秒(5分钟)
  int _maxAttempts = 5;           // 默认最大尝试次数5次
  bool _autoLockOnBackground = true; // 默认开启后台自动锁定

  bool get preventScreenshot => _preventScreenshot;
  bool get enableBiometric => _enableBiometric;
  bool get autoBiometric => _autoBiometric;
  int get lockDurationSeconds => _lockDurationSeconds;
  int get lockDurationMinutes => (_lockDurationSeconds / 60).ceil(); // 向上取整转换为分钟，保持兼容性
  int get maxAttempts => _maxAttempts;
  bool get autoLockOnBackground => _autoLockOnBackground;

  SecurityManager._internal() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _preventScreenshot = prefs.getBool('prevent_screenshot') ?? true;
    _enableBiometric = prefs.getBool('enable_biometric') ?? true;
    _autoBiometric = prefs.getBool('auto_biometric') ?? false;
    _autoLockOnBackground = prefs.getBool('auto_lock_on_background') ?? true;
    
    // 检查是否有新的秒级设置，如果没有则从分钟级设置迁移
    if (prefs.containsKey('lock_duration_seconds')) {
      _lockDurationSeconds = prefs.getInt('lock_duration_seconds') ?? 300;
    } else {
      // 从旧的分钟设置迁移
      final oldMinutes = prefs.getInt('lock_duration_minutes') ?? 5;
      _lockDurationSeconds = oldMinutes * 60;
    }
    
    _maxAttempts = prefs.getInt('max_attempts') ?? 5;
    notifyListeners();
  }

  Future<void> setPreventScreenshot(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _preventScreenshot = value;
    await prefs.setBool('prevent_screenshot', value);
    notifyListeners();
  }

  Future<void> setEnableBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _enableBiometric = value;
    await prefs.setBool('enable_biometric', value);
    notifyListeners();
  }

  Future<void> setAutoBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _autoBiometric = value;
    await prefs.setBool('auto_biometric', value);
    notifyListeners();
  }

  Future<void> setAutoLockOnBackground(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _autoLockOnBackground = value;
    await prefs.setBool('auto_lock_on_background', value);
    notifyListeners();
  }

  Future<void> setLockDurationMinutes(int value) async {
    await setLockDurationSeconds(value * 60);
  }

  Future<void> setLockDurationSeconds(int value) async {
    final prefs = await SharedPreferences.getInstance();
    _lockDurationSeconds = value;
    await prefs.setInt('lock_duration_seconds', value);
    // 同时更新分钟设置以保持兼容性
    await prefs.setInt('lock_duration_minutes', (value / 60).ceil());
    notifyListeners();
  }

  Future<void> setMaxAttempts(int value) async {
    final prefs = await SharedPreferences.getInstance();
    _maxAttempts = value;
    await prefs.setInt('max_attempts', value);
    notifyListeners();
  }
}

// 应用程序入口
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_themeListener);
    _initializeWindowManager();
  }

  Future<void> _initializeWindowManager() async {
    if (Platform.isLinux || Platform.isWindows) {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
    }
  }

  @override
  void dispose() {
    _themeManager.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PWD Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeManager.themeColor,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeManager.themeColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeManager.followSystem 
        ? ThemeMode.system 
        : (_themeManager.darkMode ? ThemeMode.dark : ThemeMode.light),
      home: const AuthenticationPage(title: 'PWD Manager'),
    );
  }
}

class MainFrame extends StatefulWidget {
  const MainFrame({super.key, required this.title});
  final String title;

  @override
  State<MainFrame> createState() => MainFrameState();
}

// MyHomePage 对应的状态类
class MainFrameState extends State<MainFrame> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final SecurityManager _securityManager = SecurityManager();
  bool _hasPassword = false;
  final GlobalKey _lockIconKey = GlobalKey();

  static const List<Widget> _widgetOptions = <Widget>[
    PasswordPage(title: "密码"),
    MyPage(title: "我的")
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityManager.addListener(_securityListener);
    _updateSecuritySettings();
    _checkPasswordStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _securityManager.removeListener(_securityListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当应用进入后台且开启了后台自动锁定时，跳转到锁定页面
    if (state == AppLifecycleState.paused && 
        _hasPassword && 
        _securityManager.autoLockOnBackground &&
        Platform.isAndroid) {
      
      // 延迟一帧执行，确保当前页面更新完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(context, PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthenticationPage(
              title: "应用已锁定",
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ));
        }
      });
    }
  }

  void _securityListener() {
    _updateSecuritySettings();
  }

  Future<void> _updateSecuritySettings() async {
    if (Platform.isLinux || Platform.isWindows) {
      await windowManager.setPreventClose(_securityManager.preventScreenshot);
    }
  }

  Future<void> _checkPasswordStatus() async {
    final hasPassword = await PasswordAuth.hasPassword();
    setState(() {
      _hasPassword = hasPassword;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 首次启动时会调用这个函数来构建Widget
  @override
  Widget build(BuildContext context) {
    final GlobalKey<AnimatedListState> _listKey =
        GlobalKey<AnimatedListState>();
    final List<int> items = List<int>.generate(100, (int index) => index);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(fontSize: 18),),
        centerTitle: true,
        actions: [
          if (_hasPassword)  // 只在设置了密码时显示锁头
            IconButton(
              key: _lockIconKey,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.lock_open, size: 22,),
              onPressed: () {
                final RenderBox? renderBox = _lockIconKey.currentContext?.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);
                  final Size buttonSize = renderBox.size;
                  
                  // 计算图标在按钮中的居中位置
                  const double iconSize = 22.0;
                  final Offset iconPosition = Offset(
                    buttonPosition.dx + (buttonSize.width - iconSize) / 2,
                    buttonPosition.dy + (buttonSize.height - iconSize) / 2,
                  );
                  
                  Navigator.pushReplacement(context, PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => AuthenticationPage(
                      title: "锁定",
                      startPosition: iconPosition,
                      startSize: const Size(iconSize, iconSize),
                      startIcon: Icons.lock_open,
                    ),
                    transitionDuration: const Duration(milliseconds: 300),
                    reverseTransitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ));
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings, size: 22,),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return MyPage(title: "我的");
              }));
            },
          ),
          const SizedBox(width: 10,)
        ],
      ),
      drawer: const Drawer(
          child: Center(
        child: Text("无事发生"),
      )),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: '添加记录',
            onTap: () => showEditPasswordFullDialog(context),
          )
        ],
      ),
    );
  }
}
