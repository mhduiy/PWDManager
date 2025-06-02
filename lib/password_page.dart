import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pwd_manager/password_edit_full_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'password.dart';
import 'databasehelper.dart';
import 'utils/website_icons.dart';
import 'utils/password_category.dart';

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
  
  // 添加分类筛选
  String _selectedCategory = 'all';

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
      if (query.isEmpty && _selectedCategory == 'all') {
        _filteredPasswords = List.from(passwords);
      } else {
        _filteredPasswords = passwords.where((password) {
          bool matchesSearch = query.isEmpty ||
              password.purpose.toLowerCase().contains(query.toLowerCase()) ||
              password.account.toLowerCase().contains(query.toLowerCase());
          
          bool matchesCategory = _selectedCategory == 'all' || password.category == _selectedCategory;
          
          return matchesSearch && matchesCategory;
        }).toList();
      }
      _sortPasswords(); // 在过滤后进行排序
    });
  }

  void _filterByCategory(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    _filterPasswords(_searchController.text);
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
          
          // 分类筛选栏
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: CategoryManager.getAllCategories().length,
              itemBuilder: (context, index) {
                final category = CategoryManager.getAllCategories()[index];
                final isSelected = _selectedCategory == category.id;
                
                // 计算该分类的密码数量
                final categoryCount = category.id == 'all' 
                    ? passwords.length 
                    : passwords.where((p) => p.category == category.id).length;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _filterByCategory(category.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? category.color.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected 
                              ? category.color
                              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: category.color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 18,
                            color: isSelected 
                                ? category.color
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected 
                                  ? category.color
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          // 添加密码数量统计
                          if (categoryCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? category.color.withOpacity(0.2)
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$categoryCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected 
                                      ? category.color
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                            // 区分是搜索无结果还是真的没有密码
                            if (_searchController.text.isNotEmpty || _selectedCategory != 'all') ...[
                              // 搜索/筛选无结果状态
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '未找到匹配的密码',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_searchController.text.isNotEmpty)
                                Text(
                                  '尝试搜索 "${_searchController.text}" 的其他关键词',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              else
                                Text(
                                  '该分类下暂无密码记录',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_searchController.text.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterPasswords('');
                                      },
                                      icon: const Icon(Icons.clear),
                                      label: const Text('清除搜索'),
                                    ),
                                  if (_selectedCategory != 'all') ...[
                                    if (_searchController.text.isNotEmpty) const SizedBox(width: 16),
                                    TextButton.icon(
                                      onPressed: () => _filterByCategory('all'),
                                      icon: const Icon(Icons.category),
                                      label: const Text('查看全部'),
                                    ),
                                  ],
                                ],
                              ),
                            ] else ...[
                              // 真正的空状态（没有任何密码）
                              Icon(
                                Icons.lock_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '还没有保存的密码',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '点击右下角的按钮开始添加你的第一个密码',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '小提示',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '密码管理器可以帮你安全地存储所有网站和应用的登录信息',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    // 检查是否是最近访问的密码（24小时内）
    final isRecentlyViewed = password.lastViewedTime != null &&
        DateTime.now().difference(password.lastViewedTime!).inHours < 24;
    
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
        elevation: password.isFavorite ? 3 : 1,
        shadowColor: password.isFavorite 
            ? Colors.amber.withOpacity(0.3)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: password.isFavorite
                ? Colors.amber.withOpacity(0.3)
                : Colors.transparent,
            width: password.isFavorite ? 1.5 : 0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: password.isFavorite
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber.withOpacity(0.05),
                        Colors.orange.withOpacity(0.02),
                      ],
                    )
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 网站图标 - 保持左侧
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: WebsiteIcons.getIconColor(password.purpose, Theme.of(context).colorScheme).withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: WebsiteIcons.getIconColor(password.purpose, Theme.of(context).colorScheme).withOpacity(0.15),
                            child: Icon(
                              WebsiteIcons.getIcon(password.purpose),
                              color: WebsiteIcons.getIconColor(password.purpose, Theme.of(context).colorScheme),
                              size: 26,
                            ),
                          ),
                          // 收藏星标
                          if (password.isFavorite)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // 主要信息区域
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 第一行：用途 + 密码强度
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  password.purpose,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: password.isFavorite 
                                        ? Colors.amber.shade800
                                        : Theme.of(context).textTheme.titleMedium?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 密码强度指示器 - 移到用途右侧
                              _buildPasswordStrengthIndicator(password.password),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 第二行：账号 + 状态标签
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  password.account,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // 状态标签组
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 最近访问标签
                                  if (isRecentlyViewed)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '最近',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 右侧操作区域
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 展开按钮
                        IconButton(
                          icon: Icon(
                            _expandedItems.contains(password.id) 
                                ? Icons.keyboard_arrow_up 
                                : Icons.keyboard_arrow_down,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
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

  Widget _buildPasswordStrengthIndicator(String password) {
    final strength = _getPasswordStrength(password);
    final strengthColors = [
      Colors.red,       // 弱
      Colors.orange,    // 中等
      Colors.green,     // 强
    ];
    final strengthLabels = ['弱', '中', '强'];
    
    // 计算强度百分比
    final strengthPercentage = (strength + 1) / 3.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 色彩填充圆环
          Container(
            width: 16,
            height: 16,
            child: Stack(
              children: [
                // 背景圆环
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: strengthColors[strength].withOpacity(0.2),
                  ),
                ),
                // 填充圆环
                Container(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: strengthPercentage,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColors[strength]),
                  ),
                ),
                // 中心圆点
                Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: strengthColors[strength],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            strengthLabels[strength],
            style: TextStyle(
              fontSize: 10,
              color: strengthColors[strength],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _getPasswordStrength(String password) {
    int score = 0;
    
    // 长度评分
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // 复杂性评分
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    // 返回强度等级 (0: 弱, 1: 中等, 2: 强)
    if (score <= 2) return 0;  // 弱
    if (score <= 4) return 1;  // 中等
    return 2;                  // 强
  }
}