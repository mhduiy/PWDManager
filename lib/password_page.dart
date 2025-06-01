import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pwd_manager/password_edit_full_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'password.dart';
import 'databasehelper.dart';
import 'utils/website_icons.dart';

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
  int _totalPasswords = 0;
  
  // 添加排序相关变量
  bool _sortAscending = true;
  String _sortField = 'purpose'; // 'purpose', 'account', 'created_time', 'view_count'

  // 添加展开项的集合
  final Set<int> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    DatabaseHelper dbHelper = DatabaseHelper();
    dbHelper.addListener(() {
      if (mounted) {
        _loadPasswords();
        _updatePasswordCount();
      }
    });
    _loadPasswords();
    _updatePasswordCount();
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

  Future<void> _updatePasswordCount() async {
    if (!mounted) return;
    DatabaseHelper dbHelper = DatabaseHelper();
    final count = await dbHelper.getPasswordCount();
    if (!mounted) return;  // 在setState前再次检查
    setState(() {
      _totalPasswords = count;
    });
  }

  // 修改排序方法以支持不同数据类型，收藏的密码优先显示
  void _sortPasswords() {
    setState(() {
      _filteredPasswords.sort((a, b) {
        // 首先按收藏状态排序，收藏的在前
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        
        // 然后按选择的字段排序
        int comparison;
        
        switch (_sortField) {
          case 'purpose':
            comparison = a.purpose.compareTo(b.purpose);
            break;
          case 'account':
            comparison = a.account.compareTo(b.account);
            break;
          case 'created_time':
            if (a.createdTime == null && b.createdTime == null) {
              comparison = 0;
            } else if (a.createdTime == null) {
              comparison = 1;
            } else if (b.createdTime == null) {
              comparison = -1;
            } else {
              comparison = a.createdTime!.compareTo(b.createdTime!);
            }
            break;
          case 'view_count':
            comparison = a.viewCount.compareTo(b.viewCount);
            break;
          default:
            comparison = a.purpose.compareTo(b.purpose);
        }
        
        return _sortAscending ? comparison : -comparison;
      });
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
      _sortPasswords(); // 在过滤后进行排序
    });
  }

  Future<void> _deletePassword(int id) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.deletePassword(id);
    await _loadPasswords();
  }

  // 添加切换收藏状态的方法
  Future<void> _toggleFavorite(Password password) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.toggleFavorite(password.id!);
    await _loadPasswords();
  }

  void _showShareDialog(BuildContext context, Password password) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String shareText = '''
用途：${password.purpose}
账号：${password.account}
密码：${password.password}
${password.note.isNotEmpty ? '\n备注：${password.note}' : ''}
''';

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    '分享密码',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    context: context,
                    icon: Icons.qr_code,
                    label: '二维码',
                    onTap: () {
                      Navigator.pop(context);
                      _showQRCode(context, shareText);
                    },
                  ),
                  _buildShareOption(
                    context: context,
                    icon: Icons.copy_all,
                    label: '复制文本',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: shareText));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制到剪贴板')),
                      );
                    },
                  ),
                  _buildShareOption(
                    context: context,
                    icon: Icons.share,
                    label: '系统分享',
                    onTap: () {
                      Navigator.pop(context);
                      Share.share(shareText);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context, String data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '扫描二维码',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterPasswords('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: _filterPasswords,
              textInputAction: TextInputAction.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  '记录数量：',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  '$_totalPasswords',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                // 添加排序按钮
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: '排序方式',
                  onSelected: (value) {
                    setState(() {
                      if (_sortField == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortField = value;
                        _sortAscending = true;
                      }
                      _sortPasswords();
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'purpose',
                      child: Row(
                        children: [
                          Icon(
                            _sortField == 'purpose'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.sort,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('按用途排序'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'account',
                      child: Row(
                        children: [
                          Icon(
                            _sortField == 'account'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.sort,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('按账号排序'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'created_time',
                      child: Row(
                        children: [
                          Icon(
                            _sortField == 'created_time'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.sort,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('按创建时间排序'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_count',
                      child: Row(
                        children: [
                          Icon(
                            _sortField == 'view_count'
                                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                                : Icons.sort,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('按阅读次数排序'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                        child: SlidableAutoCloseBehavior(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _filteredPasswords.length,
                            itemBuilder: (context, index) {
                              return _buildPasswordCard(_filteredPasswords[index]);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard(Password password) {
    return Slidable(
      key: ValueKey(password.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              showEditPasswordFullDialog(context, isEdit: true, id: password.id!);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (context) {
              _toggleFavorite(password);
            },
            backgroundColor: password.isFavorite ? Colors.orange : Colors.amber,
            foregroundColor: Colors.white,
            icon: password.isFavorite ? Icons.star : Icons.star_border,
            label: password.isFavorite ? '取消收藏' : '收藏',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              _showShareDialog(context, password);
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: '分享',
          ),
          SlidableAction(
            onPressed: (context) {
              _showDeleteConfirmationDialog(context, password.id!);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            setState(() {
              if (_expandedItems.contains(password.id)) {
                _expandedItems.remove(password.id);
              } else {
                _expandedItems.add(password.id!);
              }
            });
            HapticFeedback.lightImpact();
            
            // 如果是展开操作，则更新阅读统计
            if (_expandedItems.contains(password.id)) {
              DatabaseHelper dbHelper = DatabaseHelper();
              await dbHelper.incrementViewCount(password.id!);
              // 重新加载数据以更新显示
              await _loadPasswords();
            }
          },
          onLongPress: () {
            _showDeleteConfirmationDialog(context, password.id!);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: WebsiteIcons.getIconColor(password.purpose, Theme.of(context).colorScheme).withOpacity(0.1),
                          child: Icon(
                            WebsiteIcons.getIcon(password.purpose),
                            color: WebsiteIcons.getIconColor(password.purpose, Theme.of(context).colorScheme),
                            size: 24,
                          ),
                        ),
                        // 收藏星标
                        if (password.isFavorite)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  password.purpose,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            crossAxisAlignment: CrossAxisAlignment.center,
                          ),
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
                    // 收藏按钮
                    GestureDetector(
                      onTap: () => _toggleFavorite(password),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Icon(
                          password.isFavorite ? Icons.star : Icons.star_border,
                          color: password.isFavorite ? Colors.amber : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 将阅读统计信息移到右侧
                    if (password.viewCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${password.viewCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: Icon(
                        _expandedItems.contains(password.id) 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down
                      ),
                      onPressed: () async {
                        setState(() {
                          if (_expandedItems.contains(password.id)) {
                            _expandedItems.remove(password.id);
                          } else {
                            _expandedItems.add(password.id!);
                          }
                        });
                        HapticFeedback.lightImpact();
                        
                        // 如果是展开操作，则更新阅读统计
                        if (_expandedItems.contains(password.id)) {
                          DatabaseHelper dbHelper = DatabaseHelper();
                          await dbHelper.incrementViewCount(password.id!);
                          // 重新加载数据以更新显示
                          await _loadPasswords();
                        }
                      },
                    ),
                  ],
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _expandedItems.contains(password.id)
                        ? Column(
                            children: [
                              const Divider(height: 24),
                              // 添加详细的阅读统计信息
                              if (password.viewCount > 0 || password.lastViewedTime != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '阅读统计',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '查看次数: ${password.viewCount}次',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                                  ),
                                                ),
                                                if (password.lastViewedTime != null) ...[
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    '最后查看: ${_formatLastViewedTime(password.lastViewedTime!)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.copy,
                                    label: '复制账号',
                                    onTap: () => _copyToClipboard(password.account),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.vpn_key,
                                    label: '复制密码',
                                    onTap: () => _copyPasswordAndUpdateStats(password),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.edit,
                                    label: '编辑',
                                    onTap: () => showEditPasswordFullDialog(
                                      context, 
                                      isEdit: true, 
                                      id: password.id!
                                    ),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.share,
                                    label: '分享',
                                    onTap: () => _showShareDialog(context, password),
                                  ),
                                  _buildActionButton(
                                    icon: Icons.delete_outline,
                                    label: '删除',
                                    onTap: () => _showDeleteConfirmationDialog(
                                      context, 
                                      password.id!
                                    ),
                                  ),
                                ],
                              ),
                              if (password.note.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '备注',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        password.note,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
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

  // 修改复制密码的方法，不再增加阅读统计（因为展开时已经统计过了）
  void _copyPasswordAndUpdateStats(Password password) {
    _copyToClipboard(password.password);
    // 移除阅读统计更新，因为展开密码卡片时已经统计过了
  }

  // 添加格式化最后查看时间的方法
  String _formatLastViewedTime(DateTime lastViewed) {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${lastViewed.year}/${lastViewed.month}/${lastViewed.day}';
    }
  }
}