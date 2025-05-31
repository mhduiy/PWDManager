import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pwd_manager/password_edit_full_dialog.dart';
import 'password.dart';
import 'databasehelper.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key, required this.title});
  final String title;

  @override
  State<PasswordPage> createState() => PasswordPageState();
}

class PasswordPageState extends State<PasswordPage> {
  List<Password> passwords = [];
  final TextEditingController _searchController = TextEditingController();
  List<Password> _filteredPasswords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.addListener(() {
      if (mounted) {
        _loadPasswords();
      }
    });
    _loadPasswords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswords() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> passwordMaps = await dbHelper.getPasswords();
    if (!mounted) return;
    setState(() {
      passwords = passwordMaps.map((map) => Password.fromMap(map)).toList();
      _filterPasswords(_searchController.text);
      _isLoading = false;
    });
  }

  void _filterPasswords(String query) {
    if (!mounted) return;
    setState(() {
      if (query.isEmpty) {
        _filteredPasswords = List.from(passwords);
      } else {
        _filteredPasswords = passwords.where((password) {
          return password.purpose.toLowerCase().contains(query.toLowerCase()) ||
                 password.account.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deletePassword(int id) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.deletePassword(id);
    await _loadPasswords();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
            onChanged: _filterPasswords,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPasswords.isEmpty
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
                      onRefresh: _loadPasswords,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredPasswords.length,
                        itemBuilder: (context, index) {
                          return _buildPasswordCard(_filteredPasswords[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPasswordCard(Password password) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showEditPasswordFullDialog(context, isEdit: true, id: password.id!);
        },
        onLongPress: () {
          _showDeleteConfirmationDialog(context, password.id!);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(
                  password.purpose[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      password.purpose,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      password.account,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: '复制账号',
                onPressed: () {
                  _copyToClipboard(password.account);
                  HapticFeedback.lightImpact();
                },
              ),
              IconButton(
                icon: const Icon(Icons.vpn_key),
                tooltip: '复制密码',
                onPressed: () {
                  _copyToClipboard(password.password);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这条密码记录吗？此操作不可恢复。'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除'),
              onPressed: () {
                _deletePassword(id);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}