import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
 import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'password_auth.dart';
import 'databasehelper.dart';
import 'main.dart';
import 'backup_manager.dart';
import 'package:flutter/rendering.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.title});
  final String title;

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置"),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: SettingsList(),
      ),
    );
  }
}

class SettingsList extends StatefulWidget {
  const SettingsList({Key? key}) : super(key: key);

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> with SingleTickerProviderStateMixin {
  bool _hasPassword = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final ThemeManager _themeManager = ThemeManager();
  final SecurityManager _securityManager = SecurityManager();
  final BackupManager _backupManager = BackupManager();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  late AnimationController _controller;
  late Animation<double> _animation;

  // 预设的主题颜色
  final List<Color> _presetColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.indigo,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
  ];

  // 在类的开头添加版本常量
  static const String _version = '1.0.0';
  static const String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _checkPasswordStatus();
    _checkBiometricSupport();
    _themeManager.addListener(_themeListener);
    _securityManager.addListener(_themeListener);
  }

  @override
  void dispose() {
    _controller.dispose();
    _themeManager.removeListener(_themeListener);
    _securityManager.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  Future<void> _checkPasswordStatus() async {
    final hasPassword = await PasswordAuth.hasPassword();
    setState(() {
      _hasPassword = hasPassword;
    });
  }

  Future<void> _checkBiometricSupport() async {
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = [];
    
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (canCheckBiometrics) {
        availableBiometrics = await _localAuth.getAvailableBiometrics();
      }
    } on PlatformException {
      canCheckBiometrics = false;
    }

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
    });
  }

  void _showChangePasswordDialog() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_hasPassword ? '修改密码' : '设置密码'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasPassword)
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: !_isOldPasswordVisible,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '当前密码',
                        counterText: '',
                        helperText: '请输入6位数字密码',
                        errorText: _oldPasswordController.text.length > 0 && 
                                 _oldPasswordController.text.length != 6 
                                 ? '密码必须是6位数字' : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isOldPasswordVisible = !_isOldPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                  if (_hasPassword)
                    const SizedBox(height: 10),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      counterText: '',
                      helperText: '请输入6位数字密码',
                      errorText: _newPasswordController.text.length > 0 && 
                               _newPasswordController.text.length != 6 
                               ? '密码必须是6位数字' : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '确认新密码',
                      counterText: '',
                      helperText: '请再次输入6位数字密码',
                      errorText: _confirmPasswordController.text.length > 0 && 
                               _confirmPasswordController.text.length != 6 
                               ? '密码必须是6位数字' : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearPasswordFields();
                  },
                ),
                TextButton(
                  child: const Text('确认'),
                  onPressed: () async {
                    // 验证密码长度
                    if (_newPasswordController.text.length != 6 ||
                        _confirmPasswordController.text.length != 6 ||
                        (_hasPassword && _oldPasswordController.text.length != 6)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('密码必须是6位数字')),
                      );
                      return;
                    }

                    // 验证是否是数字
                    final RegExp digitOnly = RegExp(r'^\d+$');
                    if (!digitOnly.hasMatch(_newPasswordController.text) ||
                        !digitOnly.hasMatch(_confirmPasswordController.text) ||
                        (_hasPassword && !digitOnly.hasMatch(_oldPasswordController.text))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('密码只能包含数字')),
                      );
                      return;
                    }

                    if (_newPasswordController.text != _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('两次输入的新密码不一致')),
                      );
                      return;
                    }

                    if (_hasPassword) {
                      final bool isValid = await PasswordAuth.verifyPassword(_oldPasswordController.text);
                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('当前密码错误')),
                        );
                        return;
                      }
                    }
                    
                    await PasswordAuth.setPassword(_newPasswordController.text);
                    Navigator.of(context).pop();
                    _clearPasswordFields();
                    setState(() {
                      _hasPassword = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_hasPassword ? '密码修改成功' : '密码设置成功')),
                    );
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Widget _buildSettingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _themeManager.setThemeColor(color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 44 : 40,
        height: isSelected ? 44 : 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isSelected ? 0.4 : 0.3),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/pwdmanager_backup_$timestamp.pwd');
      
      // 导出数据
      await _backupManager.exportData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('备份文件已保存到: ${backupFile.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final files = directory.listSync().where((file) => 
        file.path.endsWith('.pwd') && 
        file is File
      ).toList();
      
      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到备份文件')),
          );
        }
        return;
      }
      
      // 按修改时间排序，最新的在前
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('选择要导入的备份文件'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final fileName = file.path.split('/').last;
                    final modifiedDate = file.statSync().modified;
                    
                    return ListTile(
                      title: Text(fileName),
                      subtitle: Text('修改时间: ${modifiedDate.toString()}'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        try {
                          await _backupManager.importData(file.path);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('导入成功')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('导入失败: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildAboutSection() {
    return _buildSettingSection(
      title: '关于',
      subtitle: '项目信息',
      icon: Icons.info_outline,
      children: [
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('项目地址'),
          subtitle: const Text('https://github.com/mhduiy/PWDManager'),
          onTap: () async {
            HapticFeedback.mediumImpact();
            final Uri url = Uri.parse('https://github.com/mhduiy/PWDManager');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('无法打开链接')),
                );
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('开发者'),
          subtitle: const Text('mhduiy'),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('版本信息'),
          subtitle: Text('Version $_version (Build $_buildNumber)'),
          onTap: () {
            HapticFeedback.lightImpact();
            _showAboutAnimation();
          },
        ),
      ],
    );
  }

  void _showAboutAnimation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo动画
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.lock,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // 应用名称
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: const Text(
                          'PWD Manager',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                // 版本信息
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Text(
                          'Version $_version (Build $_buildNumber)',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // 版权信息
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Text(
                          '© ${DateTime.now().year} mhduiy',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSettingSection(
          title: '外观',
          subtitle: '自定义应用的外观',
          icon: Icons.palette,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('跟随系统主题'),
              trailing: Switch(
                value: _themeManager.followSystem,
                onChanged: (bool value) {
                  HapticFeedback.lightImpact();
                  _themeManager.setThemeMode(
                    followSystem: value,
                    darkMode: value 
                      ? MediaQuery.of(context).platformBrightness == Brightness.dark
                      : _themeManager.darkMode,
                  );
                },
              ),
            ),
            if (!_themeManager.followSystem)
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('暗黑主题'),
                trailing: Switch(
                  value: _themeManager.darkMode,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _themeManager.setThemeMode(darkMode: value);
                  },
                ),
              ),
            ListTile(
              title: const Text('主题颜色'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              subtitle: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: _presetColors.map((color) => 
                    _buildColorCircle(color, color == _themeManager.themeColor)
                  ).toList(),
                ),
              ),
            ),
          ],
        ),

        _buildSettingSection(
          title: '备份',
          subtitle: '导出或导入您的密码数据',
          icon: Icons.backup,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('导出数据'),
              subtitle: const Text('将密码数据导出为加密文件'),
              onTap: () {
                HapticFeedback.mediumImpact();
                _exportData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('导入数据'),
              subtitle: const Text('从加密文件导入密码数据'),
              onTap: () {
                HapticFeedback.mediumImpact();
                _importData();
              },
            ),
          ],
        ),

        _buildSettingSection(
          title: '安全',
          subtitle: '保护您的数据安全',
          icon: Icons.security,
          children: [
            if (_canCheckBiometrics && _availableBiometrics.isNotEmpty && _hasPassword)
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('指纹解锁'),
                subtitle: const Text('使用指纹快速解锁应用'),
                trailing: Switch(
                  value: _securityManager.enableBiometric,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _securityManager.setEnableBiometric(value);
                  },
                ),
              ),
            if (_canCheckBiometrics && _availableBiometrics.isNotEmpty && _hasPassword && _securityManager.enableBiometric)
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('自动生物认证'),
                subtitle: const Text('进入认证界面时自动弹出生物认证'),
                trailing: Switch(
                  value: _securityManager.autoBiometric,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _securityManager.setAutoBiometric(value);
                  },
                ),
              ),
            ListTile(
              leading: const Icon(Icons.no_photography),
              title: const Text('防止截屏'),
              subtitle: const Text('在显示敏感信息时禁用截屏'),
              trailing: Switch(
                value: _securityManager.preventScreenshot,
                onChanged: (bool value) {
                  HapticFeedback.lightImpact();
                  _securityManager.setPreventScreenshot(value);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text(_hasPassword ? '修改密码' : '设置密码'),
              subtitle: _hasPassword 
                ? const Text('修改应用解锁密码')
                : const Text('请设置密码以保护您的数据安全', style: TextStyle(color: Colors.red)),
              onTap: () {
                HapticFeedback.mediumImpact();
                _showChangePasswordDialog();
              },
            ),
            if (_hasPassword)
              ListTile(
                leading: const Icon(Icons.no_encryption),
                title: const Text('清除密码'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showClearPasswordDialog();
                },
              ),
            if (_hasPassword)
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('重置密码'),
                subtitle: const Text('忘记密码时使用，将清除所有数据'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showResetPasswordDialog();
                },
              ),
            if (_hasPassword)
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('锁定超时'),
                subtitle: Text(_securityManager.lockDurationSeconds == 0 
                    ? '已关闭' 
                    : '错误尝试过多时的锁定时间：${_securityManager.lockDurationSeconds}秒'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showLockDurationDialog();
                },
              ),
            if (_hasPassword)
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('最大尝试次数'),
                subtitle: Text('超过此次数将锁定应用：${_securityManager.maxAttempts}次'),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showMaxAttemptsDialog();
                },
              ),
            if (_hasPassword && Platform.isAndroid)
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('后台自动锁定'),
                subtitle: const Text('应用进入后台时自动锁定'),
                trailing: Switch(
                  value: _securityManager.autoLockOnBackground,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _securityManager.setAutoLockOnBackground(value);
                  },
                ),
              ),
          ],
        ),

        _buildAboutSection(),
      ],
    );
  }

  void _showClearPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认清除密码'),
          content: const Text('清除密码后，任何人都可以直接访问您的数据。确定要继续吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((confirm) async {
      if (confirm == true) {
        await PasswordAuth.clearPassword();
        setState(() {
          _hasPassword = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码已清除')),
          );
        }
      }
    });
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('警告'),
          content: const Text('重置密码将会清除所有存储的密码数据！此操作不可恢复，确定要继续吗？'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('确定重置'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((confirm) async {
      if (confirm == true) {
        await PasswordAuth.clearPassword();
        final dbHelper = DatabaseHelper();
        await dbHelper.clearAllData();
        
        setState(() {
          _hasPassword = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码已重置，所有数据已清除')),
          );
        }
      }
    });
  }

  void _showLockDurationDialog() {
    double selectedDurationSeconds = (_securityManager.lockDurationSeconds).toDouble();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('设置锁定超时'),
              content: SizedBox(
                width: 300, // 设置固定宽度
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedDurationSeconds == 0 
                          ? '锁定功能已关闭' 
                          : '锁定时间：${selectedDurationSeconds.round()}秒',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selectedDurationSeconds == 0 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Slider(
                      value: selectedDurationSeconds,
                      min: 0,
                      max: 600,
                      divisions: 24, // 每25秒一个刻度
                      label: selectedDurationSeconds == 0 
                          ? '关闭' 
                          : '${selectedDurationSeconds.round()}秒',
                      onChanged: (value) {
                        setState(() {
                          selectedDurationSeconds = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '关闭',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '600秒',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    // 始终显示提示信息，避免宽度变化
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selectedDurationSeconds == 0 
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedDurationSeconds == 0 ? Icons.warning : Icons.info,
                            size: 16,
                            color: selectedDurationSeconds == 0 
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedDurationSeconds == 0 
                                  ? '关闭锁定功能后，密码错误将不会锁定应用'
                                  : '密码错误超过最大次数后，应用将被锁定指定时间',
                              style: TextStyle(
                                fontSize: 12,
                                color: selectedDurationSeconds == 0 
                                    ? Theme.of(context).colorScheme.onErrorContainer
                                    : Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('确认'),
                  onPressed: () {
                    // 将秒转换为分钟存储（向上取整）
                    int durationSeconds = selectedDurationSeconds == 0 
                        ? 0 
                        : selectedDurationSeconds.round();
                    _securityManager.setLockDurationSeconds(durationSeconds);
                    Navigator.of(context).pop();
                    setState(() {}); // 刷新主页面
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMaxAttemptsDialog() {
    double selectedAttempts = _securityManager.maxAttempts.toDouble();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('设置最大尝试次数'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '最大尝试次数：${selectedAttempts.round()}次',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Slider(
                      value: selectedAttempts,
                      min: 3,
                      max: 10,
                      divisions: 7,
                      label: '${selectedAttempts.round()}次',
                      onChanged: (value) {
                        setState(() {
                          selectedAttempts = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '3次',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '10次',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('确认'),
                  onPressed: () {
                    _securityManager.setMaxAttempts(selectedAttempts.round());
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SettingItem extends StatefulWidget {
  final String title;
  final String description;
  final bool showSwitch;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onChanged;

  const SettingItem({
    super.key,
    required this.title,
    required this.description,
    this.showSwitch = true,
    this.onTap,
    this.onChanged,
  });

  @override
  _SettingItemState createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem> {
  bool switchValue = true;
  
  void changeSwitchState(bool status) {
    setState(() {
      switchValue = !switchValue;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(switchValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        child: ListTile(
          title: Text(widget.title),
          subtitle: Text(
            widget.description,
            style: TextStyle(color: Colors.black.withAlpha(100)),
          ),
          trailing: widget.showSwitch ? Switch(
            value: switchValue,
            onChanged: changeSwitchState,
          ) : null,
        ),
      ),
    );
  }
}