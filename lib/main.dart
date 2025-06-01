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
import 'databasehelper.dart';
import 'utils/password_category.dart';

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
      drawer: Drawer(
        child: _buildDrawerContent(),
      ),
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

  Widget _buildDrawerContent() {
    return Column(
      children: [
        // 头部区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.lock,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'PWD Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '安全的密码管理',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 统计信息卡片
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '统计信息',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _getStatistics(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final stats = snapshot.data!;
                  final categoryStats = stats['categoryStats'] as Map<String, int>;
                  
                  return Column(
                    children: [
                      _buildStatItem('总密码数', '${stats['total']}', Icons.password),
                      const SizedBox(height: 8),
                      _buildStatItem('收藏密码', '${stats['favorites']}', Icons.star),
                      const SizedBox(height: 8),
                      _buildStatItem('今日新增', '${stats['todayAdded']}', Icons.add_circle_outline),
                      
                      // 添加分类统计
                      if (categoryStats.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '分类统计',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...categoryStats.entries
                            .where((entry) => entry.value > 0)
                            .take(5) // 只显示前5个分类
                            .map((entry) {
                          final category = CategoryManager.getCategoryById(entry.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  category.icon,
                                  size: 14,
                                  color: category.color,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: category.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        
                        // 如果有更多分类，显示省略号
                        if (categoryStats.entries.where((e) => e.value > 0).length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        
        // 导航菜单
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerItem(
                icon: Icons.dashboard_outlined,
                title: '仪表盘',
                onTap: () {
                  Navigator.pop(context);
                  // 可以添加仪表盘页面
                },
              ),
              _buildDrawerItem(
                icon: Icons.category_outlined,
                title: '分类管理',
                onTap: () {
                  Navigator.pop(context);
                  // 可以添加分类管理页面
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('分类管理功能开发中...')),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.backup_outlined,
                title: '备份管理',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const MyPage(title: "备份设置"),
                  ));
                },
              ),
              _buildDrawerItem(
                icon: Icons.security_outlined,
                title: '安全设置',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const MyPage(title: "安全设置"),
                  ));
                },
              ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.help_outline,
                title: '帮助与支持',
                onTap: () {
                  Navigator.pop(context);
                  _showHelpDialog();
                },
              ),
              _buildDrawerItem(
                icon: Icons.info_outline,
                title: '关于应用',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const MyPage(title: "关于"),
                  ));
                },
              ),
            ],
          ),
        ),
        
        // 底部快捷操作
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showEditPasswordFullDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加密码'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }

  Future<Map<String, dynamic>> _getStatistics() async {
    final dbHelper = DatabaseHelper();
    final passwords = await dbHelper.getPasswords();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    int favorites = 0;
    int todayAdded = 0;
    Map<String, int> categoryStats = {};
    
    for (var password in passwords) {
      // 统计收藏数量
      if (password['is_favorite'] == 1) {
        favorites++;
      }
      
      // 统计今日新增
      if (password['created_time'] != null) {
        final createdTime = DateTime.parse(password['created_time']);
        if (createdTime.isAfter(todayStart)) {
          todayAdded++;
        }
      }
      
      // 统计分类数量
      final category = password['category'] ?? 'other';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;
    }
    
    return {
      'total': passwords.length,
      'favorites': favorites,
      'todayAdded': todayAdded,
      'categoryStats': categoryStats,
    };
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('使用帮助'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem('🔒', '安全提示', '请定期备份数据，使用强密码保护应用'),
                const SizedBox(height: 12),
                _buildHelpItem('📱', '快捷操作', '长按密码卡片快速删除，左右滑动查看更多操作'),
                const SizedBox(height: 12),
                _buildHelpItem('⭐', '收藏功能', '点击星号收藏常用密码，收藏的密码会优先显示'),
                const SizedBox(height: 12),
                _buildHelpItem('🔍', '搜索技巧', '支持按用途和账号搜索，快速找到目标密码'),
                const SizedBox(height: 12),
                _buildHelpItem('🎨', '个性化', '可在设置中自定义主题颜色和安全选项'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('知道了'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
