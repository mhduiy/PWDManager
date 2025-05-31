import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'databasehelper.dart';
import 'dart:math' as math;

class PasswordList extends StatefulWidget {
  const PasswordList({super.key});

  @override
  State<PasswordList> createState() => _PasswordListState();
}

class _PasswordListState extends State<PasswordList> with TickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _passwords = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabController;
  late AnimationController _listController;

  // 用于存储展开状态的密码ID
  final Set<int> _expandedItems = {};
  
  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _refreshPasswords();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPasswords() async {
    setState(() => _isLoading = true);
    final passwords = await _databaseHelper.getPasswords();
    setState(() {
      _passwords = passwords;
      _isLoading = false;
    });
    _listController.forward(from: 0);
  }

  void _toggleItemExpansion(int id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  Widget _buildPasswordCard(Map<String, dynamic> password, int index) {
    final bool isExpanded = _expandedItems.contains(password['id']);
    final Animation<double> animation = CurvedAnimation(
      parent: _listController,
      curve: Interval(
        index * 0.05,
        1.0,
        curve: Curves.easeOutQuart,
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isExpanded ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _toggleItemExpansion(password['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isExpanded 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
                  : null,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        password['title'][0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      password['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      password['username'],
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: password['password']));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('密码已复制到剪贴板'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: '复制密码',
                        ),
                        IconButton(
                          icon: AnimatedRotation(
                            duration: const Duration(milliseconds: 200),
                            turns: isExpanded ? 0.5 : 0,
                            child: const Icon(Icons.expand_more),
                          ),
                          onPressed: () => _toggleItemExpansion(password['id']),
                        ),
                      ],
                    ),
                  ),
                  ClipRect(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      heightFactor: isExpanded ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('用户名', password['username']),
                                const SizedBox(height: 8),
                                _buildDetailRow('密码', password['password'], isPassword: true),
                                if (password['notes']?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 8),
                                  _buildDetailRow('备注', password['notes']),
                                ],
                              ],
                            ),
                          ),
                          ButtonBar(
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('编辑'),
                                onPressed: () {
                                  // TODO: 实现编辑功能
                                  HapticFeedback.mediumImpact();
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('删除'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  HapticFeedback.mediumImpact();
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('确认删除'),
                                      content: const Text('确定要删除这条密码记录吗？此操作不可恢复。'),
                                      actions: [
                                        TextButton(
                                          child: const Text('取消'),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('删除'),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true) {
                                    await _databaseHelper.deletePassword(password['id']);
                                    _refreshPasswords();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPassword = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: isPassword
              ? _buildPasswordField(value)
              : SelectableText(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String password) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isVisible = false;
        return Row(
          children: [
            Expanded(
              child: SelectableText(
                isVisible ? password : '••••••••',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() => isVisible = !isVisible);
                HapticFeedback.lightImpact();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索密码...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (value) {
                // TODO: 实现搜索功能
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _passwords.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '还没有保存的密码',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击右下角的按钮添加新密码',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshPasswords,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _passwords.length,
                          itemBuilder: (context, index) {
                            return _buildPasswordCard(_passwords[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => _fabController.forward(),
        onClose: () => _fabController.reverse(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8.0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            label: '添加密码',
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: 实现添加密码功能
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.password),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            label: '生成随机密码',
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: 实现密码生成功能
            },
          ),
        ],
      ),
    );
  }
} 