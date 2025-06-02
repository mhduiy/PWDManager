import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:math';
import 'password_auth.dart';
import 'databasehelper.dart';
import 'main.dart';
import 'backup_manager.dart';
import 'package:flutter/rendering.dart';
import 'crypto_manager.dart';
import 'welcome_page.dart';

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

  // 预设的主题颜色 - 增加更多选项
  final List<Color> _presetColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.indigo,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.cyan,
    Colors.lightGreen,
    Colors.amber,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
    Colors.lime,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Card(
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    Theme.of(context).colorScheme.primary.withOpacity(0.02),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 0.5),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (iconColor ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive 
                ? Theme.of(context).colorScheme.error
                : (iconColor ?? Theme.of(context).colorScheme.primary),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: isDestructive 
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildDangerousActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
        color: Theme.of(context).colorScheme.error.withOpacity(0.05),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.error.withOpacity(0.7),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEnhancedSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) labelFormatter,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            labelFormatter(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelFormatter(min),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                labelFormatter(max),
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

  // 重新设计的简洁颜色选择器
  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _themeManager.themeColor.withOpacity(0.2),
                      _themeManager.themeColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.palette,
                  color: _themeManager.themeColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '主题颜色',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 增加每行显示数量的颜色选择网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 400 ? 8 : 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _presetColors.length,
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              final isSelected = color.value == _themeManager.themeColor.value;
              return _buildSimpleColorOption(color, isSelected);
            },
          ),
        ],
      ),
    );
  }

  // 纯粹的颜色圆圈组件
  Widget _buildSimpleColorOption(Color color, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        onTap: () {
          HapticFeedback.mediumImpact();
          _themeManager.setThemeColor(color);
        },
        child: Container(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: isSelected ? 32 : 28,
            height: isSelected ? 32 : 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? Colors.white
                    : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isSelected ? 0.4 : 0.2),
                  blurRadius: isSelected ? 8 : 3,
                  offset: Offset(0, isSelected ? 2 : 1),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
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
        _buildEnhancedListTile(
          icon: Icons.code,
          title: '项目地址',
          subtitle: 'https://github.com/mhduiy/PWDManager',
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
        _buildEnhancedListTile(
          icon: Icons.person_outline,
          title: '开发者',
          subtitle: 'mhduiy',
        ),
        _buildEnhancedListTile(
          icon: Icons.info_outline,
          title: '版本信息',
          subtitle: 'Version $_version (Build $_buildNumber)',
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
            _buildEnhancedListTile(
              icon: Icons.brightness_auto,
              title: '跟随系统主题',
              subtitle: '自动切换深色和浅色主题',
              trailing: Switch(
                value: _themeManager.followSystem,
                onChanged: (bool value) {
                  HapticFeedback.lightImpact();
                  _themeManager.setThemeMode(followSystem: value);
                },
              ),
            ),
            if (!_themeManager.followSystem)
              _buildEnhancedListTile(
                icon: Icons.dark_mode,
                title: '深色模式',
                subtitle: '使用深色主题界面',
                trailing: Switch(
                  value: _themeManager.darkMode,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _themeManager.setThemeMode(darkMode: value);
                  },
                ),
              ),
            // 主题颜色选择器
            _buildColorSelector(),
          ],
        ),

        _buildSettingSection(
          title: '数据',
          subtitle: '备份和恢复您的数据',
          icon: Icons.backup,
          children: [
            _buildEnhancedListTile(
              icon: Icons.file_download,
              title: '导出数据',
              subtitle: '将密码数据导出为加密文件',
              onTap: () {
                HapticFeedback.mediumImpact();
                _exportData();
              },
            ),
            _buildEnhancedListTile(
              icon: Icons.file_upload,
              title: '导入数据',
              subtitle: '从加密文件导入密码数据',
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
              _buildEnhancedListTile(
                icon: Icons.fingerprint,
                title: '指纹解锁',
                subtitle: '使用指纹快速解锁应用',
                trailing: Switch(
                  value: _securityManager.enableBiometric,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _securityManager.setEnableBiometric(value);
                  },
                ),
              ),
            if (_canCheckBiometrics && _availableBiometrics.isNotEmpty && _hasPassword && _securityManager.enableBiometric)
              _buildEnhancedListTile(
                icon: Icons.auto_awesome,
                title: '自动生物认证',
                subtitle: '进入认证界面时自动弹出生物认证',
                trailing: Switch(
                  value: _securityManager.autoBiometric,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _securityManager.setAutoBiometric(value);
                  },
                ),
              ),
            _buildEnhancedListTile(
              icon: Icons.no_photography,
              title: '防止截屏',
              subtitle: '在显示敏感信息时禁用截屏',
              trailing: Switch(
                value: _securityManager.preventScreenshot,
                onChanged: (bool value) {
                  HapticFeedback.lightImpact();
                  _securityManager.setPreventScreenshot(value);
                },
              ),
            ),
            _buildEnhancedListTile(
              icon: Icons.lock,
              title: _hasPassword ? '修改密码' : '设置密码',
              subtitle: _hasPassword 
                ? '修改应用解锁密码'
                : '请设置密码以保护您的数据安全',
              onTap: () {
                HapticFeedback.mediumImpact();
                _showChangePasswordDialog();
              },
              iconColor: _hasPassword ? null : Colors.orange,
            ),
            if (_hasPassword)
              _buildEnhancedListTile(
                icon: Icons.timer,
                title: '锁定超时',
                subtitle: Text(_securityManager.lockDurationSeconds == 0 
                    ? '已关闭' 
                    : '错误尝试过多时的锁定时间：${_securityManager.lockDurationSeconds}秒').data!,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showLockDurationDialog();
                },
              ),
            if (_hasPassword)
              _buildEnhancedListTile(
                icon: Icons.security,
                title: '最大尝试次数',
                subtitle: '超过此次数将锁定应用：${_securityManager.maxAttempts}次',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showMaxAttemptsDialog();
                },
              ),
            if (_hasPassword && Platform.isAndroid)
              _buildEnhancedListTile(
                icon: Icons.exit_to_app,
                title: '后台自动锁定',
                subtitle: '应用进入后台时自动锁定',
                trailing: Switch(
                  value: _securityManager.autoLockOnBackground,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    _securityManager.setAutoLockOnBackground(value);
                  },
                ),
              ),
            // 危险操作放在最后
            if (_hasPassword)
              _buildDangerousActionTile(
                icon: Icons.no_encryption,
                title: '清除密码',
                subtitle: '移除应用密码保护',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showClearPasswordDialog();
                },
              ),
            if (_hasPassword)
              _buildDangerousActionTile(
                icon: Icons.restart_alt,
                title: '完全重置',
                subtitle: '清除所有数据并重新初始化应用',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _showCompleteResetDialog();
                },
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

  void _showCompleteResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final TextEditingController encryptionPasswordController = TextEditingController();
        bool isPasswordVisible = false;
        bool isLoading = false;
        String errorMessage = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                if (!isLoading) {
                  encryptionPasswordController.dispose();
                }
                return !isLoading;
              },
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text('完全重置确认'),
                  ],
                ),
                content: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ 危险操作',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '此操作将永久删除：\n• 所有保存的密码\n• 访问密码设置\n• 加密密码设置\n• 应用配置信息',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        '请输入加密密码以确认重置：',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: encryptionPasswordController,
                        obscureText: !isPasswordVisible,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: '加密密码',
                          hintText: '输入您的加密密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: errorMessage.isNotEmpty ? errorMessage : null,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isLoading ? null : () {
                      encryptionPasswordController.dispose();
                      Navigator.of(context).pop();
                    },
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (encryptionPasswordController.text.isEmpty) {
                        setState(() {
                          errorMessage = '请输入加密密码';
                        });
                        return;
                      }

                      setState(() {
                        isLoading = true;
                        errorMessage = '';
                      });

                      try {
                        // 验证加密密码
                        final isValid = await CryptoManager.verifyEncryptionPassword(
                          encryptionPasswordController.text,
                        );

                        if (isValid) {
                          // 验证成功，执行完全重置
                          await _performCompleteReset();
                          
                          // 跳转到欢迎页面
                          if (mounted) {
                            encryptionPasswordController.dispose();
                            Navigator.of(context).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const WelcomePage(),
                              ),
                              (route) => false,
                            );
                          }
                        } else {
                          setState(() {
                            errorMessage = '加密密码错误，请重新输入';
                            isLoading = false;
                          });
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage = '验证失败：$e';
                          isLoading = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('确认重置'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 执行完全重置操作
  Future<void> _performCompleteReset() async {
    try {
      // 1. 清除访问密码
      await PasswordAuth.clearPassword();
      
      // 2. 清除所有密码数据
      final dbHelper = DatabaseHelper();
      await dbHelper.clearAllData();
      
      // 3. 清除加密相关数据
      await CryptoManager.clearEncryptionData();
      
      // 4. 清除应用设置（可选，根据需要）
      final prefs = await SharedPreferences.getInstance();
      // 保留主题等用户偏好设置，只清除敏感数据
      // await prefs.clear(); // 如果要清除所有设置可以取消注释
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('应用已完全重置，所有数据已清除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('重置失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEnhancedSlider(
                      value: selectedDurationSeconds,
                      min: 0,
                      max: 600,
                      divisions: 24,
                      onChanged: (value) {
                        setState(() {
                          selectedDurationSeconds = value;
                        });
                      },
                      labelFormatter: (value) {
                        if (value == 0) {
                          return '锁定功能已关闭';
                        } else {
                          return '${value.round()}秒';
                        }
                      },
                    ),
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
                    int durationSeconds = selectedDurationSeconds == 0 
                        ? 0 
                        : selectedDurationSeconds.round();
                    _securityManager.setLockDurationSeconds(durationSeconds);
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
                child: _buildEnhancedSlider(
                  value: selectedAttempts,
                  min: 3,
                  max: 10,
                  divisions: 7,
                  onChanged: (value) {
                    setState(() {
                      selectedAttempts = value;
                    });
                  },
                  labelFormatter: (value) => '${value.round()}次',
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